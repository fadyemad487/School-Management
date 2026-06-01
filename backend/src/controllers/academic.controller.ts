import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";

/** Convert null schoolId to undefined for Prisma compatibility */
function sid(req: Request): string | undefined {
  return req.schoolId ?? undefined;
}

/** Require schoolId — throws if missing */
function requireSid(req: Request): string {
  if (!req.schoolId) throw new ValidationError("School context required");
  return req.schoolId;
}

// ─── Academic Year ──────────────────────────────────────────

export const getAcademicYears = asyncHandler(async (req: Request, res: Response) => {
  const data = await prisma.academicYear.findMany({
    where: { schoolId: sid(req) as string },
    orderBy: { startDate: "desc" },
  });
  res.json({ success: true, data });
});

export const createAcademicYear = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const payload = z.object({
    name: z.string().min(2),
    startDate: z.string(),
    endDate: z.string(),
    isCurrent: z.boolean().optional().default(false),
  }).parse(req.body);

  if (payload.isCurrent) {
    await prisma.academicYear.updateMany({
      where: { schoolId: schoolId as string },
      data: { isCurrent: false },
    });
  }

  const year = await prisma.academicYear.create({
    data: {
      schoolId: schoolId as string,
      name: payload.name,
      startDate: new Date(payload.startDate),
      endDate: new Date(payload.endDate),
      isCurrent: payload.isCurrent,
    },
  });

  res.status(201).json({ success: true, data: year });
});

export const updateAcademicYear = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const existing = await prisma.academicYear.findFirst({ 
    where: { 
      id: id as string, 
      schoolId: schoolId as string 
    } 
  });
  if (!existing) throw new NotFoundError("Academic year not found");

  const payload = z.object({
    name: z.string().optional(),
    startDate: z.string().optional(),
    endDate: z.string().optional(),
    isCurrent: z.boolean().optional(),
  }).parse(req.body);

  if (payload.isCurrent) {
    await prisma.academicYear.updateMany({
      where: { schoolId: schoolId as string, NOT: { id: id as string } },
      data: { isCurrent: false },
    });
  }

  const updated = await prisma.academicYear.update({
    where: { id: id as string },
    data: {
      name: payload.name,
      startDate: payload.startDate ? new Date(payload.startDate) : undefined,
      endDate: payload.endDate ? new Date(payload.endDate) : undefined,
      isCurrent: payload.isCurrent,
    },
  });

  res.json({ success: true, data: updated });
});

export const deleteAcademicYear = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  const existing = await prisma.academicYear.findFirst({ 
    where: { 
      id: id as string, 
      schoolId: schoolId as string 
    } 
  });
  if (!existing) throw new NotFoundError("Academic year not found");
  await prisma.academicYear.delete({ where: { id: id as string } });
  res.json({ success: true, message: "Deleted" });
});

// ─── Grades ──────────────────────────────────────────

export const getGrades = asyncHandler(async (req: Request, res: Response) => {
  const data = await prisma.grade.findMany({
    where: { schoolId: sid(req) as string },
    orderBy: { order: "asc" },
    include: {
      _count: { select: { classes: true, students: true, subjects: true } },
    },
  });
  res.json({ success: true, data });
});

export const createGrade = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const payload = z.object({
    name: z.string().min(2),
    nameEn: z.string().optional(),
    order: z.number().min(1).max(6),
  }).parse(req.body);

  const grade = await prisma.grade.create({
    data: { schoolId: schoolId as string, ...payload },
  });

  res.status(201).json({ success: true, data: grade });
});

export const updateGrade = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  const existing = await prisma.grade.findFirst({ 
    where: { 
      id: id as string, 
      schoolId: schoolId as string 
    } 
  });
  if (!existing) throw new NotFoundError("Grade not found");

  const payload = z.object({
    name: z.string().optional(),
    nameEn: z.string().optional(),
    order: z.number().min(1).max(6).optional(),
  }).parse(req.body);

  const updated = await prisma.grade.update({ 
    where: { id: id as string }, 
    data: payload 
  });
  res.json({ success: true, data: updated });
});

export const deleteGrade = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  const existing = await prisma.grade.findFirst({ 
    where: { 
      id: id as string, 
      schoolId: schoolId as string 
    } 
  });
  if (!existing) throw new NotFoundError("Grade not found");
  await prisma.grade.delete({ where: { id: id as string } });
  res.json({ success: true, message: "Deleted" });
});

/** POST /api/grades/seed — Seed default Egyptian primary grades */
export const seedDefaultGrades = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const defaults = [
    { name: "الصف الأول الابتدائي", nameEn: "Grade 1", order: 1 },
    { name: "الصف الثاني الابتدائي", nameEn: "Grade 2", order: 2 },
    { name: "الصف الثالث الابتدائي", nameEn: "Grade 3", order: 3 },
    { name: "الصف الرابع الابتدائي", nameEn: "Grade 4", order: 4 },
    { name: "الصف الخامس الابتدائي", nameEn: "Grade 5", order: 5 },
    { name: "الصف السادس الابتدائي", nameEn: "Grade 6", order: 6 },
  ];

  const created = [];
  for (const g of defaults) {
    const existing = await prisma.grade.findFirst({ 
      where: { 
        schoolId: schoolId as string, 
        order: g.order 
      } 
    });
    if (!existing) {
      created.push(await prisma.grade.create({ 
        data: { schoolId: schoolId as string, ...g } 
      }));
    }
  }

  res.status(201).json({ success: true, data: created, message: `${created.length} grades seeded` });
});

