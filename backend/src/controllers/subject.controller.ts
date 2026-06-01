import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";
import { getIO } from "../config/websocket";

function requireSid(req: Request): string {
  if (!req.schoolId) throw new ValidationError("School context required");
  return req.schoolId;
}

export const getSubjects = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const data = await prisma.subject.findMany({
    where: { schoolId },
    include: { grade: true },
    orderBy: { name: "asc" }
  });
  res.json({ success: true, data });
});

export const createSubject = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const payload = z.object({
    name: z.string().min(2),
    code: z.string().optional().transform(v => v === "" ? undefined : v),
    gradeId: z.string().optional().transform(v => v === "" ? undefined : v),
  }).parse(req.body);

  const subject = await prisma.subject.create({
    data: {
      schoolId,
      name: payload.name,
      code: payload.code,
      gradeId: payload.gradeId
    }
  });

  getIO().to(`school:${schoolId}`).emit("subject:created", subject);
  res.status(201).json({ success: true, data: subject });
});

export const deleteSubject = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const existing = await prisma.subject.findFirst({ where: { id: id as string, schoolId } });
  if (!existing) throw new NotFoundError("Subject not found");

  await prisma.subject.delete({ where: { id: id as string } });
  getIO().to(`school:${schoolId}`).emit("subject:deleted", { id });
  res.json({ success: true, message: "Deleted" });
});

export const bulkCreateSubjects = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const payload = z.object({
    subjects: z.array(z.object({
      name: z.string().min(2),
      code: z.string().optional(),
      gradeId: z.string().optional()
    }))
  }).parse(req.body);

  const created = await prisma.subject.createMany({
    data: payload.subjects.map(s => ({
      schoolId,
      name: s.name,
      code: s.code,
      gradeId: s.gradeId
    })),
    skipDuplicates: true
  });

  getIO().to(`school:${schoolId}`).emit("subjects:bulk_created", { count: created.count });
  res.status(201).json({ success: true, count: created.count });
});
