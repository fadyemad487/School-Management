import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError } from "../utils/AppError";
import { getIO } from "../config/websocket";
import { LeaveStatus } from "@prisma/client";

export const getLeaveRequests = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  const { status } = req.query;

  const where: any = { schoolId };
  if (status) where.status = status;

  const data = await prisma.leaveRequest.findMany({
    where,
    include: {
      student: { include: { user: true } },
      teacher: { include: { user: true } },
    },
    orderBy: { applyDate: "desc" }
  });

  res.json({ success: true, data });
});

export const updateLeaveStatus = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = req.schoolId;
  const userId = req.userId;

  const payload = z.object({
    status: z.nativeEnum(LeaveStatus),
    adminNotes: z.string().optional()
  }).parse(req.body);

  const request = await prisma.leaveRequest.findUnique({ where: { id } });
  if (!request || request.schoolId !== schoolId) {
    throw new ValidationError("Leave request not found.");
  }

  const data = await prisma.leaveRequest.update({
    where: { id },
    data: {
      status: payload.status,
      adminNotes: payload.adminNotes,
      actionBy: userId,
      actionDate: new Date()
    },
    include: {
      student: { include: { user: true } },
      teacher: { include: { user: true } },
    }
  });

  // Emit websocket event for real-time dashboard updates
  const io = getIO();
  io.to(`school:${schoolId}`).emit("leave:updated", data);
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.json({ success: true, data });
});

/** 
 * Mock creation (to simulate Mobile App submissions) 
 * In a real scenario, this would be an endpoint for the Mobile App
 */
export const createLeaveRequest = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId as string;
  
  const payload = z.object({
    studentId: z.string().optional(),
    teacherId: z.string().optional(),
    type: z.string(),
    reason: z.string().optional(),
    startDate: z.coerce.date(),
    endDate: z.coerce.date()
  }).parse(req.body);

  const data = await prisma.leaveRequest.create({
    data: {
      ...payload,
      schoolId,
      status: "PENDING",
      applyDate: new Date()
    },
    include: {
      student: { include: { user: true } },
      teacher: { include: { user: true } },
    }
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("leave:created", data);
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.status(201).json({ success: true, data });
});
