import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { requireSid } from "../utils/tenant";
import { FeeType } from "@prisma/client";

/** GET /api/fee-structures - List all fee rules for the school */
export const getFeeStructures = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const data = await prisma.feeStructure.findMany({
    where: { schoolId: schoolId as string },
    include: {
      grade: true,
      academicYear: true,
      student: { include: { user: true } }
    },
    orderBy: { createdAt: "desc" }
  });
  res.json({ success: true, data });
});

/** POST /api/fee-structures - Create a fee rule (Global/Grade/Student) */
export const createFeeStructure = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const rawPayload = z.object({
    name: z.string(),
    feeType: z.nativeEnum(FeeType),
    amount: z.coerce.number().positive(),
    gradeId: z.string().optional().nullable(),
    academicYearId: z.string().optional().nullable(),
    studentId: z.string().optional().nullable(),
  }).parse(req.body);

  // Convert empty strings to null for optional relations
  const payload = {
    ...rawPayload,
    gradeId: rawPayload.gradeId || null,
    academicYearId: rawPayload.academicYearId || null,
    studentId: rawPayload.studentId || null,
  };

  const data = await prisma.feeStructure.create({
    data: {
      ...payload,
      schoolId: schoolId as string,
    },
    include: {
      grade: true,
      student: { include: { user: true } }
    }
  });

  res.status(201).json({ success: true, data });
});

/** DELETE /api/fee-structures/:id */
export const deleteFeeStructure = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  
  await prisma.feeStructure.deleteMany({
    where: { id, schoolId: schoolId as string }
  });

  res.json({ success: true, message: "Fee structure deleted" });
});
