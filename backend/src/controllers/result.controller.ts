import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { requireSid } from "../utils/tenant";
import { NotFoundError } from "../utils/AppError";

export const listSchoolResults = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const data = await prisma.schoolResult.findMany({
    where: { schoolId },
    orderBy: { createdAt: "desc" }
  });
  res.json({ success: true, data });
});

export const uploadSchoolResult = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const payload = z.object({
    name: z.string().min(2),
    fileUrl: z.string().url(),
    category: z.string().optional(),
    term: z.string().optional(),
    year: z.string().optional()
  }).parse(req.body);

  const data = await prisma.schoolResult.create({
    data: {
      schoolId,
      ...payload
    }
  });

  res.status(201).json({ success: true, data });
});

export const deleteSchoolResult = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const existing = await prisma.schoolResult.findFirst({ where: { id: id as string, schoolId } });
  if (!existing) throw new NotFoundError("Result document not found");

  await prisma.schoolResult.delete({ where: { id: id as string } });
  res.json({ success: true });
});
