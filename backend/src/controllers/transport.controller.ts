import { Request, Response } from "express";
import { BusStatus } from "@prisma/client";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";

export const getBuses = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const data = await prisma.bus.findMany({
    where: { schoolId: schoolId as string },
    include: {
      driver: true,
      supervisor: true,
      routes: true,
      students: {
        include: {
          student: {
            include: {
              class: true,
              grade: true,
              BusAttendance: {
                include: {
                  supervisor: true
                },
                orderBy: {
                  date: 'desc'
                }
              }
            }
          }
        }
      },
      _count: { select: { students: true } }
    }
  });
  res.json({ success: true, data });
});

/** POST /api/transport/buses — Create/Update a bus */
export const upsertBus = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const statusSchema = z
    .enum(["ACTIVE", "MAINTENANCE", "OUT_OF_SERVICE", "INACTIVE"])
    .default("ACTIVE")
    .transform((v) => (v === "INACTIVE" ? "OUT_OF_SERVICE" : v) as BusStatus);

  const payload = z.object({
    id: z.string().optional(),
    number: z.string(),
    plateNumber: z.string().optional(),
    capacity: z.coerce.number().default(30),
    status: statusSchema,
    driverId: z.string().optional().nullable(),
    supervisorId: z.string().optional().nullable()
  }).parse(req.body);

  const { id, driverId, supervisorId, ...data } = payload;

  const result = await prisma.$transaction(async (tx) => {
    // 1. Validation: Check if this driver is already assigned to ANOTHER bus
    if (driverId) {
      const otherBus = await tx.bus.findFirst({
        where: {
          schoolId: schoolId as string,
          driver: { id: driverId },
          NOT: id ? { id } : undefined // If updating, ignore current bus
        }
      });

      if (otherBus) {
        throw new ValidationError(`السائق مختار بالفعل للباص رقم (${otherBus.number}). لا يمكن تخصيص السائق لأكثر من باص.`);
      }
    }

    // 2. Create or Update the Bus
    const bus = id 
      ? await tx.bus.update({ where: { id }, data })
      : await tx.bus.create({ data: { ...data, schoolId: schoolId as string } });

    // 3. Handle Driver Assignment if provided
    if (driverId) {
      // Clear this driver from any other bus just in case
      await tx.driver.update({
        where: { id: driverId },
        data: { busId: bus.id }
      });

      // Clear any other driver that was previously on THIS bus
      await tx.driver.updateMany({
        where: { 
          busId: bus.id,
          schoolId: schoolId as string,
          NOT: { id: driverId } 
        },
        data: { busId: null }
      });
    } else if (driverId === null) {
       // If driverId is explicitly null, clear the driver for this bus
       await tx.driver.updateMany({
         where: { busId: bus.id, schoolId: schoolId as string },
         data: { busId: null }
       });
    }

    // 4. Handle Supervisor Assignment if provided
    if (supervisorId) {
      const otherBusSup = await tx.bus.findFirst({
        where: {
          schoolId: schoolId as string,
          supervisor: { id: supervisorId },
          NOT: id ? { id } : undefined
        }
      });

      if (otherBusSup) {
        throw new ValidationError(`المشرفة معينة بالفعل للباص رقم (${otherBusSup.number}).`);
      }

      await tx.busSupervisor.update({
        where: { id: supervisorId },
        data: { busId: bus.id }
      });

      await tx.busSupervisor.updateMany({
        where: { 
          busId: bus.id,
          schoolId: schoolId as string,
          NOT: { id: supervisorId } 
        },
        data: { busId: null }
      });
    } else if (supervisorId === null) {
       await tx.busSupervisor.updateMany({
         where: { busId: bus.id, schoolId: schoolId as string },
         data: { busId: null }
       });
    }

    return bus;
  });

  res.json({ success: true, data: result });
});

/** POST /api/transport/buses/:id/trip — Start/End a trip */
export const toggleTrip = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const { action } = req.body; // "START" or "END"
  const schoolId = requireSid(req);

  const bus = await prisma.bus.findFirst({ where: { id: id as string, schoolId: schoolId as string } });
  if (!bus) throw new NotFoundError("Bus not found");

  // In a real app, we would update a 'trip_status' in DB or Redis.
  // For now, we emit a socket event to notify mobile apps.
  const io = getIO();
  const event = action === "START" ? "bus:trip_started" : "bus:trip_ended";
  
  io.to(`school:${schoolId}`).emit(event, { 
    busId: bus.id, 
    busNumber: bus.number,
    timestamp: new Date()
  });

  res.json({ success: true, message: `Trip ${action}ED successfully` });
});

/** GET /api/transport/routes — List all routes */
export const getRoutes = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const data = await prisma.busRoute.findMany({
    where: { schoolId: schoolId as string },
    include: { bus: true, _count: { select: { students: true } } }
  });
  res.json({ success: true, data });
});

/** POST /api/transport/routes — Create a new route */
export const createRoute = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const payload = z.object({
    name: z.string(),
    busId: z.string().optional(),
    pickupTime: z.string().optional(),
    dropoffTime: z.string().optional(),
    stops: z.any().optional(), // Should be JSON
  }).parse(req.body);

  const route = await prisma.busRoute.create({
    data: { ...payload, schoolId: schoolId as string }
  });

  res.status(201).json({ success: true, data: route });
});

/** DELETE /api/transport/buses/:id — Delete a bus */
export const deleteBus = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const bus = await prisma.bus.findFirst({ where: { id, schoolId: schoolId as string } });
  if (!bus) throw new NotFoundError("Bus not found");

  // Also clear any drivers assigned to this bus before deleting
  await prisma.driver.updateMany({
    where: { busId: id },
    data: { busId: null }
  });

  // Clear supervisors
  await prisma.busSupervisor.updateMany({
    where: { busId: id },
    data: { busId: null }
  });

  await prisma.bus.delete({ where: { id } });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("bus:deleted", id);
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.json({ success: true, message: "Bus deleted successfully" });
});

/** DELETE /api/transport/routes/:id — Delete a route */
export const deleteRoute = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const route = await prisma.busRoute.findFirst({ where: { id, schoolId: schoolId as string } });
  if (!route) throw new NotFoundError("Route not found");

  await prisma.busRoute.delete({ where: { id } });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("route:deleted", id);

  res.json({ success: true, message: "Route deleted successfully" });
});

/** GET /api/transport/students — Fetch all students with their bus/route assignments */
export const getTransportStudents = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const data = await prisma.student.findMany({
    where: { schoolId: schoolId as string },
    include: {
      user: true,
      grade: true,
      class: true,
      BusAttendance: {
        include: {
          supervisor: true
        },
        orderBy: {
          date: 'desc'
        }
      },
      busAssignment: {
        include: {
          bus: {
            include: {
              routes: true
            }
          },
          route: true
        }
      }
    },
    orderBy: { user: { fullName: "asc" } }
  });
  res.json({ success: true, data });
});

/** POST /api/transport/buses/:id/students — Assign students to a bus */
export const assignStudentsToBus = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  const payload = z.object({
    studentIds: z.array(z.string())
  }).parse(req.body);

  const bus = await prisma.bus.findFirst({ where: { id, schoolId: schoolId as string } });
  if (!bus) throw new NotFoundError("Bus not found");

  await prisma.$transaction(async (tx) => {
    // 1. Remove all students previously on this bus
    await tx.studentBus.updateMany({
      where: { busId: id },
      data: { busId: null }
    });

    // 2. Associate the new students to this bus
    for (const studentId of payload.studentIds) {
      await tx.studentBus.upsert({
        where: { studentId },
        create: { studentId, busId: id, active: true },
        update: { busId: id, active: true }
      });
    }
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.json({ success: true, message: "Students assigned to bus successfully" });
});

