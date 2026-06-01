import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError } from "../utils/AppError";
import { getIO } from "../config/websocket";
import { NotificationService } from "../services/notification.service";

export const getAttendance = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  const where = schoolId ? { schoolId } : {};
  const data = await prisma.attendance.findMany({ 
    where,
    include: { student: { include: { user: true } }, class: true },
    orderBy: { date: "desc" }
  });
  res.json({ success: true, data });
});

export const markBulkAttendance = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  if (!schoolId) {
    throw new ValidationError("School context is required.");
  }

  const payload = z.object({
    date: z.string(),
    periodNumber: z.number().optional(),
    classId: z.string(),
    records: z.array(z.object({
      studentId: z.string(),
      status: z.enum(["PRESENT", "ABSENT", "LATE", "EXCUSED"]),
      notes: z.string().optional()
    }))
  }).parse(req.body);

  const attendanceDate = new Date(payload.date);

  // Perform in a transaction to ensure atomic updates
  const results = await prisma.$transaction(async (tx) => {
    const createdRecords = [];

    for (const record of payload.records) {
      // Upsert: Clean existing records for the same student/date/period if they exist
      // This allows correcting attendance
      if (payload.periodNumber) {
        await tx.attendance.deleteMany({
          where: {
            studentId: record.studentId,
            date: attendanceDate,
            periodNumber: payload.periodNumber,
            schoolId
          }
        });
      } else {
        await tx.attendance.deleteMany({
          where: {
            studentId: record.studentId,
            date: attendanceDate,
            periodNumber: null,
            schoolId
          }
        });
      }

      const attendance = await tx.attendance.create({
        data: {
          schoolId,
          classId: payload.classId,
          studentId: record.studentId,
          status: record.status,
          date: attendanceDate,
          periodNumber: payload.periodNumber,
          notes: record.notes,
          type: "STUDENT"
        },
        include: { student: { include: { user: true, guardian: { include: { user: true } } } } }
      });

      createdRecords.push(attendance);

      // Trigger notification if ABSENT
      if (record.status === "ABSENT") {
        // Find guardian user if exists, otherwise student user
        const recipientUserId = attendance.student?.guardian?.userId || attendance.student?.user?.id || null;
        const studentName = attendance.student?.nameAr || attendance.student?.user?.fullName || "الطالب";
        
        await NotificationService.sendAbsenceAlert(
          schoolId,
          recipientUserId,
          studentName,
          attendanceDate,
          payload.periodNumber
        );
      }
    }

    return createdRecords;
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("attendance:bulk_marked", { count: results.length });
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.status(201).json({ success: true, data: results });
});

export const createAttendance = asyncHandler(async (req: Request, res: Response) => {
  // Keeping for backward compatibility or single manual edits
  const schoolId = req.schoolId;
  if (!schoolId) {
    throw new ValidationError("School context is required.");
  }

  const payload = z.object({
    studentId: z.string(),
    classId: z.string(),
    status: z.enum(["PRESENT", "ABSENT", "LATE", "EXCUSED"]),
    date: z.string(),
    periodNumber: z.number().optional()
  }).parse(req.body);

  const data = await prisma.attendance.create({ 
    data: { ...payload, date: new Date(payload.date), schoolId },
    include: { student: { include: { user: true } }, class: true }
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("attendance:marked", data);
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.status(201).json({ success: true, data });
});
