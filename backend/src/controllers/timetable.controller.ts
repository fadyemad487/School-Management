import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";

/** Require schoolId — throws if missing */
function requireSid(req: Request): string {
  if (!req.schoolId) throw new ValidationError("School context required");
  return req.schoolId;
}

export const getTimetable = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { classId, teacherId } = req.query;

  const where: any = { schoolId };
  if (classId && typeof classId === "string" && classId.trim() !== "") {
    where.classId = classId;
  }
  if (teacherId && typeof teacherId === "string" && teacherId.trim() !== "") {
    where.teacherId = teacherId;
  }

  const data = await prisma.timetable.findMany({
    where,
    include: {
      subject: true,
      teacher: { include: { user: true } },
      class: true,
    },
    orderBy: [
      { day: "asc" },
      { periodNumber: "asc" }
    ],
  });

  res.json({ success: true, data });
});

export const upsertTimetableSlot = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const payload = z.object({
    id: z.string().optional(),
    classId: z.string(),
    // Convert empty strings or nulls from selects to undefined for Prisma compatibility
    subjectId: z.string().nullable().optional().transform(v => !v ? undefined : v),
    teacherId: z.string().nullable().optional().transform(v => !v ? undefined : v),
    // Coerce strings to numbers (e.g. from FormData or specific inputs)
    day: z.coerce.number().min(0).max(6), 
    periodNumber: z.coerce.number().min(1),
    room: z.string().nullable().optional().transform(v => !v ? undefined : v),
    startTime: z.string().nullable().optional().transform(v => !v ? undefined : v),
    endTime: z.string().nullable().optional().transform(v => !v ? undefined : v),
  }).parse(req.body);

  // --- OVERLAP PREVENTION LOGIC ---

  // 1. Check if class is already busy
  const classConflict = await prisma.timetable.findFirst({
    where: {
      schoolId,
      classId: payload.classId,
      day: payload.day,
      periodNumber: payload.periodNumber,
      NOT: payload.id ? { id: payload.id } : undefined
    }
  });

  if (classConflict) {
    throw new ValidationError(`الفصل مشغول بالفعل في هذا الوقت (الحصة ${payload.periodNumber})`);
  }

  // 2. Check if teacher is already busy (if teacherId provided)
  if (payload.teacherId) {
    const teacherConflict = await prisma.timetable.findFirst({
      where: {
        schoolId,
        teacherId: payload.teacherId,
        day: payload.day,
        periodNumber: payload.periodNumber,
        NOT: payload.id ? { id: payload.id } : undefined
      },
      include: { class: true }
    });

    if (teacherConflict) {
      throw new ValidationError(`المعلم مشغول بالفعل في فصل ${teacherConflict.class.name} في هذا الوقت`);
    }
  }

  // Save logic: explicit create/update instead of hacky upsert
  let slot;
  if (payload.id) {
    slot = await prisma.timetable.update({
      where: { id: payload.id },
      data: {
        subjectId: payload.subjectId,
        teacherId: payload.teacherId,
        day: payload.day,
        periodNumber: payload.periodNumber,
        room: payload.room,
        startTime: payload.startTime,
        endTime: payload.endTime,
      },
      include: { subject: true, teacher: { include: { user: true } } }
    });
  } else {
    slot = await prisma.timetable.create({
      data: {
        schoolId,
        classId: payload.classId,
        subjectId: payload.subjectId,
        teacherId: payload.teacherId,
        day: payload.day,
        periodNumber: payload.periodNumber,
        room: payload.room,
        startTime: payload.startTime,
        endTime: payload.endTime,
      },
      include: { subject: true, teacher: { include: { user: true } } }
    });
  }

  res.json({ success: true, data: slot });
});

export const deleteTimetableSlot = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const existing = await prisma.timetable.findFirst({
    where: { id: id as string, schoolId }
  });

  if (!existing) throw new NotFoundError("Slot not found");

  await prisma.timetable.delete({ where: { id: id as string } });
  res.json({ success: true, message: "Deleted" });
});

export const autoGenerateTimetable = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { classId } = req.body;
  if (!classId) throw new ValidationError("classId is required");

  // 1. Get Settings (Days & Periods)
  const settings = await prisma.schoolSettings.findUnique({ where: { schoolId } });
  const periodsCount = settings?.periodsPerDay || 7;
  const workingDays = settings?.workingDays || [0, 1, 2, 3, 4]; // default Sun-Thu

  // 2. Get subjects assigned to this class
  const teacherSubjects = await prisma.teacherSubject.findMany({
    where: { classId, teacher: { schoolId } }
  });

  if (teacherSubjects.length === 0) {
    throw new ValidationError("لم يتم تخصيص مواد لهذا الفصل. قم بتخصيص المعلمين أولاً.");
  }

  // Clear existing schedule for this class to regenerate cleanly
  await prisma.timetable.deleteMany({
    where: { schoolId, classId }
  });

  // Fetch all other timetables to avoid teacher conflicts
  const allOtherTimetables = await prisma.timetable.findMany({
    where: { schoolId, NOT: { classId } }
  });

  const slotsToCreate: any[] = [];
  
  // Greedy scheduling: Distribute subjects evenly
  // We want to fill workingDays x periodsCount
  let subjectIndex = 0;
  for (const day of workingDays) {
    for (let periodNumber = 1; periodNumber <= periodsCount; periodNumber++) {
      // Try to find a subject that the teacher is available to teach
      let assigned = false;
      let startIdx = subjectIndex;
      
      for (let i = 0; i < teacherSubjects.length; i++) {
        const ts = teacherSubjects[(startIdx + i) % teacherSubjects.length];
        
        // Check if teacher is busy
        const isBusy = allOtherTimetables.some(
          t => t.teacherId === ts.teacherId && t.day === day && t.periodNumber === periodNumber
        ) || slotsToCreate.some(
          t => t.teacherId === ts.teacherId && t.day === day && t.periodNumber === periodNumber
        );

        if (!isBusy) {
          slotsToCreate.push({
            schoolId,
            classId,
            subjectId: ts.subjectId,
            teacherId: ts.teacherId,
            day,
            periodNumber,
          });
          subjectIndex = (startIdx + i + 1) % teacherSubjects.length;
          assigned = true;
          break;
        }
      }
      
      // If we couldn't assign anyone (all busy), leave it empty (free period)
    }
  }

  if (slotsToCreate.length > 0) {
    await prisma.timetable.createMany({ data: slotsToCreate });
  }

  res.json({ success: true, message: "تم إنشاء الجدول بنجاح", count: slotsToCreate.length });
});
