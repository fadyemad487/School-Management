import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { BusAttendanceStatus, NotificationType, NotificationChannel } from "@prisma/client";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";
import { getIO } from "../config/websocket";
import crypto from "crypto";

/** GET /api/mobile/transport/driver/dashboard — Driver manifest & routes */
export const getDriverDashboard = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) throw new ValidationError("Unauthorized");

  // Find Driver via AppCredential
  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId },
    include: {
      driver: {
        include: {
          school: true,
          bus: {
            include: {
              routes: true,
              supervisor: true,
              students: {
                where: { active: true },
                include: {
                  student: {
                    include: {
                      father: true,
                      mother: true,
                      guardian: true
                    }
                  },
                  route: true
                }
              }
            }
          }
        }
      }
    }
  });

  if (!credential || !credential.driver) {
    throw new NotFoundError("Driver profile not found");
  }

  const driver = credential.driver;
  if (!driver.bus) {
    return res.json({
      success: true,
      message: "لا يوجد باص مخصص لك حالياً.",
      data: { driver, bus: null }
    });
  }

  res.json({
    success: true,
    data: {
      driver,
      bus: driver.bus,
      students: driver.bus.students
    }
  });
});

/** GET /api/mobile/transport/supervisor/dashboard — Supervisor manifest & status */
export const getSupervisorDashboard = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) throw new ValidationError("Unauthorized");

  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId },
    include: {
      supervisor: {
        include: {
          school: true,
          bus: {
            include: {
              routes: true,
              students: {
                where: { active: true },
                include: {
                  student: {
                    include: {
                      father: true,
                      mother: true,
                      guardian: true
                    }
                  },
                  route: true
                }
              }
            }
          }
        }
      }
    }
  });

  if (!credential || !credential.supervisor) {
    throw new NotFoundError("Supervisor profile not found");
  }

  const supervisor = credential.supervisor;
  if (!supervisor.bus) {
    return res.json({
      success: true,
      message: "لا يوجد باص مخصص لكِ حالياً.",
      data: { supervisor, bus: null }
    });
  }

  // Get today's attendance logs (normalized to local date string at UTC midnight)
  const nowTime = new Date();
  const dateStr = `${nowTime.getFullYear()}-${String(nowTime.getMonth() + 1).padStart(2, "0")}-${String(nowTime.getDate()).padStart(2, "0")}`;
  const today = new Date(`${dateStr}T00:00:00.000Z`);

  const attendances = await prisma.busAttendance.findMany({
    where: {
      busId: supervisor.bus.id,
      date: today
    }
  });

  res.json({
    success: true,
    data: {
      supervisor,
      bus: supervisor.bus,
      students: supervisor.bus.students,
      attendances
    }
  });
});

/** POST /api/mobile/transport/supervisor/attendance — Mark boarded / absent and notify parents */
export const markBusAttendance = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) throw new ValidationError("Unauthorized");

  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId },
    include: { supervisor: true }
  });

  if (!credential || !credential.supervisor) {
    throw new ValidationError("فقط المشرفات لديهن صلاحية تسجيل الحضور والغياب للباص.");
  }

  const supervisor = credential.supervisor;
  if (!supervisor.busId) throw new ValidationError("غير مخصص لكِ أي باص حالياً لتسجيل الحضور.");

  const payload = z.object({
    studentId: z.string(),
    status: z.nativeEnum(BusAttendanceStatus),
    notes: z.string().optional().nullable()
  }).parse(req.body);

  const student = await prisma.student.findUnique({
    where: { id: payload.studentId },
    include: {
      user: true,
      father: { include: { user: true } },
      mother: { include: { user: true } },
      guardian: { include: { user: true } }
    }
  });

  if (!student) throw new NotFoundError("Student not found");

  const nowTime = new Date();
  const dateStr = `${nowTime.getFullYear()}-${String(nowTime.getMonth() + 1).padStart(2, "0")}-${String(nowTime.getDate()).padStart(2, "0")}`;
  const today = new Date(`${dateStr}T00:00:00.000Z`);

  // Record Attendance
  const attendance = await prisma.busAttendance.upsert({
    where: {
      studentId_date_busId: {
        studentId: payload.studentId,
        busId: supervisor.busId,
        date: today
      }
    },
    update: {
      status: payload.status,
      notes: payload.notes,
      supervisorId: supervisor.id
    },
    create: {
      schoolId: supervisor.schoolId,
      studentId: payload.studentId,
      busId: supervisor.busId,
      supervisorId: supervisor.id,
      date: today,
      status: payload.status,
      notes: payload.notes
    }
  });

  // Check if we need to notify parent
  // If boarded or absent, we trigger customized message
  const statusLabel = payload.status === BusAttendanceStatus.BOARDED ? "ركب الباص بنجاح" : "لم يركب الباص اليوم";
  const parentMessage = `تنبيه من باص المدرسة: طفلك ${student.nameAr || student.user.fullName} ${statusLabel} للرحلة اليومية.`;

  // Find Parent's User ID to send the notification
  const parentUserIds: string[] = [];
  if (student.father?.userId) parentUserIds.push(student.father.userId);
  if (student.mother?.userId) parentUserIds.push(student.mother.userId);
  if (student.guardian?.userId) parentUserIds.push(student.guardian.userId);

  const io = getIO();

  for (const recipientId of parentUserIds) {
    // Create notification record
    const notification = await prisma.notification.create({
      data: {
        schoolId: supervisor.schoolId,
        recipientId,
        title: "تنبيه حضور باص المدرسة",
        message: parentMessage,
        type: NotificationType.GENERAL,
        channel: NotificationChannel.SYSTEM
      }
    });

    // Emit live WebSocket notification
    io.to(`user:${recipientId}`).emit("notification:new", notification);
  }

  // Notify driver of progress change too
  io.to(`school:${supervisor.schoolId}`).emit("bus:attendance_updated", {
    busId: supervisor.busId,
    studentId: payload.studentId,
    status: payload.status
  });

  res.json({
    success: true,
    message: "تم حفظ حالة حضور الطالب بنجاح وإشعار ولي الأمر.",
    data: attendance
  });
});

/** POST /api/mobile/transport/driver/attendance — Driver marks boarded / absent */
export const markDriverBusAttendance = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) throw new ValidationError("Unauthorized");

  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId },
    include: { driver: { include: { bus: { include: { supervisor: true } } } } }
  });

  if (!credential || !credential.driver) {
    throw new ValidationError("فقط السائق لديه صلاحية تسجيل حالة طلاب الرحلة من شاشة القيادة.");
  }

  const driver = credential.driver;
  if (!driver.busId) throw new ValidationError("غير مخصص لك أي باص حالياً لتسجيل الحضور.");
  const supervisorId = driver.bus?.supervisor?.id;
  if (!supervisorId) throw new ValidationError("لا توجد مشرفة مرتبطة بهذا الباص لتسجيل حالة الرحلة.");

  const payload = z.object({
    studentId: z.string(),
    status: z.nativeEnum(BusAttendanceStatus),
    notes: z.string().optional().nullable()
  }).parse(req.body);

  const student = await prisma.student.findUnique({
    where: { id: payload.studentId },
    include: {
      user: true,
      father: { include: { user: true } },
      mother: { include: { user: true } },
      guardian: { include: { user: true } }
    }
  });

  if (!student) throw new NotFoundError("Student not found");

  const nowTime = new Date();
  const dateStr = `${nowTime.getFullYear()}-${String(nowTime.getMonth() + 1).padStart(2, "0")}-${String(nowTime.getDate()).padStart(2, "0")}`;
  const today = new Date(`${dateStr}T00:00:00.000Z`);

  const attendance = await prisma.busAttendance.upsert({
    where: {
      studentId_date_busId: {
        studentId: payload.studentId,
        busId: driver.busId,
        date: today
      }
    },
    update: {
      status: payload.status,
      notes: payload.notes
    },
    create: {
      schoolId: driver.schoolId,
      studentId: payload.studentId,
      busId: driver.busId,
      supervisorId,
      date: today,
      status: payload.status,
      notes: payload.notes
    }
  });

  const statusLabel = payload.status === BusAttendanceStatus.BOARDED ? "ركب الباص بنجاح" : "لم يركب الباص اليوم";
  const parentMessage = `تنبيه من سائق باص المدرسة: طفلك ${student.nameAr || student.user.fullName} ${statusLabel} للرحلة اليومية.`;
  const parentUserIds: string[] = [];
  if (student.father?.userId) parentUserIds.push(student.father.userId);
  if (student.mother?.userId) parentUserIds.push(student.mother.userId);
  if (student.guardian?.userId) parentUserIds.push(student.guardian.userId);

  const io = getIO();
  for (const recipientId of parentUserIds) {
    const notification = await prisma.notification.create({
      data: {
        schoolId: driver.schoolId,
        recipientId,
        title: "تنبيه حضور باص المدرسة",
        message: parentMessage,
        type: NotificationType.GENERAL,
        channel: NotificationChannel.SYSTEM
      }
    });
    io.to(`user:${recipientId}`).emit("notification:new", notification);
  }

  io.to(`school:${driver.schoolId}`).emit("bus:attendance_updated", {
    busId: driver.busId,
    studentId: payload.studentId,
    status: payload.status
  });

  res.json({
    success: true,
    message: "تم حفظ حالة الطالب من شاشة السائق وإشعار ولي الأمر.",
    data: attendance
  });
});

/** PUT /api/mobile/transport/supervisor/profile — Update supervisor profile details (name, phone, photo, password) */
export const updateSupervisorProfile = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) throw new ValidationError("Unauthorized");

  const payloadSchema = z.object({
    name: z.string().optional(),
    phone: z.string().optional(),
    personalPhoto: z.string().optional(),
    oldPassword: z.string().optional(),
    newPassword: z.string().optional()
  });

  const payload = payloadSchema.parse(req.body);

  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId },
    include: { supervisor: true }
  });

  if (!credential || !credential.supervisor) {
    throw new NotFoundError("Supervisor profile not found");
  }

  const supervisor = credential.supervisor;

  // 1. Update personal photo or phone or name if provided
  const updateData: any = {};
  if (payload.name !== undefined) updateData.name = payload.name;
  if (payload.phone !== undefined) updateData.phone = payload.phone;
  if (payload.personalPhoto !== undefined) updateData.personalPhoto = payload.personalPhoto;

  if (Object.keys(updateData).length > 0) {
    await prisma.busSupervisor.update({
      where: { id: supervisor.id },
      data: updateData
    });

    // Sync name to User record if linked
    if (supervisor.userId && payload.name !== undefined) {
      await prisma.user.update({
        where: { id: supervisor.userId },
        data: { fullName: payload.name }
      });
    }
  }

  // 2. Update password if newPassword is provided directly
  if (payload.newPassword) {
    const newHash = crypto.createHash("sha256").update(payload.newPassword).digest("hex");
    await prisma.appCredential.update({
      where: { id: credentialId },
      data: {
        passwordHash: newHash,
        plainTextPw: payload.newPassword
      }
    });
  }

  // Fetch updated supervisor details to return
  const updatedSupervisor = await prisma.busSupervisor.findUnique({
    where: { id: supervisor.id },
    include: { school: true }
  });

  res.json({
    success: true,
    message: "تم تحديث الملف الشخصي بنجاح",
    data: { supervisor: updatedSupervisor }
  });
});

/** PUT /api/mobile/transport/driver/profile — Update driver profile (phone, password) */
export const updateDriverProfile = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) throw new ValidationError("Unauthorized");

  const payloadSchema = z.object({
    phone: z.string().optional(),
    personalPhoto: z.string().optional(),
    oldPassword: z.string().optional(),
    newPassword: z.string().min(6).optional()
  });

  const payload = payloadSchema.parse(req.body);

  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId },
    include: { driver: true }
  });

  if (!credential || !credential.driver) {
    throw new NotFoundError("Driver profile not found");
  }

  const driver = credential.driver;

  // 1. Update phone / personalPhoto if provided
  const updateData: any = {};
  if (payload.phone !== undefined) updateData.phone = payload.phone;
  if (payload.personalPhoto !== undefined) updateData.personalPhoto = payload.personalPhoto;

  if (Object.keys(updateData).length > 0) {
    await prisma.driver.update({
      where: { id: driver.id },
      data: updateData
    });
  }

  // 2. Update password if newPassword is provided
  if (payload.newPassword) {
    // Verify old password if provided
    if (payload.oldPassword) {
      const oldHash = crypto.createHash("sha256").update(payload.oldPassword).digest("hex");
      if (oldHash !== credential.passwordHash) {
        throw new ValidationError("كلمة المرور الحالية غير صحيحة.");
      }
    }

    const newHash = crypto.createHash("sha256").update(payload.newPassword).digest("hex");
    await prisma.appCredential.update({
      where: { id: credentialId },
      data: {
        passwordHash: newHash,
        plainTextPw: payload.newPassword
      }
    });
  }

  // Fetch updated driver details to return
  const updatedDriver = await prisma.driver.findUnique({
    where: { id: driver.id },
    include: { school: true, bus: true }
  });

  res.json({
    success: true,
    message: "تم تحديث بيانات السائق بنجاح",
    data: { driver: updatedDriver }
  });
});

/** POST /api/mobile/transport/driver/location — Update and broadcast driver's live GPS coordinates */
export const updateDriverLocation = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) throw new ValidationError("Unauthorized");

  const payload = z.object({
    lat: z.number(),
    lng: z.number(),
    tripActive: z.boolean()
  }).parse(req.body);

  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId },
    include: { driver: true }
  });

  if (!credential || !credential.driver) {
    throw new NotFoundError("Driver profile not found");
  }

  const driver = credential.driver;
  if (!driver.busId) {
    throw new ValidationError("لم يتم ربط هذا السائق بحافلة لنقل موقعها.");
  }

  // Broadcast the location live via WebSockets to everyone in the school room (including parents)
  const io = getIO();
  io.to(`school:${driver.schoolId}`).emit("bus:location_updated", {
    busId: driver.busId,
    driverId: driver.id,
    lat: payload.lat,
    lng: payload.lng,
    tripActive: payload.tripActive,
    timestamp: new Date().toISOString()
  });

  res.json({
    success: true,
    message: "تم تحديث موقع الحافلة وبثّه حياً بنجاح.",
    data: {
      lat: payload.lat,
      lng: payload.lng,
      tripActive: payload.tripActive
    }
  });
});
