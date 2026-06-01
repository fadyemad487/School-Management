import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError } from "../utils/AppError";
import { getIO } from "../config/websocket";

export const getClasses = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  const where = schoolId ? { schoolId } : {};
  const data = await prisma.schoolClass.findMany({ 
    where,
    include: { teacher: { include: { user: true } } },
    orderBy: { name: "asc" }
  });
  res.json({ success: true, data });
});

export const createClass = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  if (!schoolId) {
    throw new ValidationError("School context is required to create a class.");
  }

  const payload = z.object({
    name: z.string().min(1),
    section: z.string().min(1),
    maxCapacity: z.coerce.number().optional().default(40),
    roomNumber: z.string().optional(),
    floor: z.string().optional(),
    gradeId: z.string().optional(),
    academicYearId: z.string().optional()
  }).parse(req.body);

  const data = await prisma.schoolClass.create({ 
    data: { 
      name: payload.name,
      section: payload.section,
      maxCapacity: payload.maxCapacity,
      roomNumber: payload.roomNumber,
      floor: payload.floor,
      gradeId: payload.gradeId,
      academicYearId: payload.academicYearId,
      schoolId 
    },
    include: { teacher: { include: { user: true } }, grade: true }
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("class:created", data);
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.status(201).json({ success: true, data });
});

export const deleteClass = asyncHandler(async (req: Request, res: Response) => {
  const classId = req.params.id as string;
  const schoolId = req.schoolId;

  if (!classId) {
    throw new ValidationError("Class ID is required.");
  }

  // Verify class exists and belongs to this school
  const targetClass = await prisma.schoolClass.findFirst({
    where: { id: classId, ...(schoolId ? { schoolId } : {}) }
  });

  if (!targetClass) {
    throw new ValidationError("Class not found or access denied.");
  }

  await prisma.$transaction(async (tx) => {
    // Remove class reference from students (don't delete students)
    await tx.student.updateMany({ where: { classId: classId }, data: { classId: null as any } });
    // Delete related records
    await tx.attendance.deleteMany({ where: { classId: classId } });
    await tx.teacherSubject.deleteMany({ where: { classId: classId } });
    await tx.timetable.deleteMany({ where: { classId: classId } });
    await tx.homework.deleteMany({ where: { classId: classId } });
    await tx.exam.deleteMany({ where: { classId: classId } });
    // Now delete the class
    await tx.schoolClass.delete({ where: { id: classId } });
  });

  if (schoolId) {
    const io = getIO();
    io.to(`school:${schoolId}`).emit("class:deleted", { id: classId });
    io.to(`school:${schoolId}`).emit("dashboard:update");
  }

  res.json({ success: true, message: "Class deleted successfully" });
});
