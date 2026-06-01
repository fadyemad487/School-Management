import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError } from "../utils/AppError";
import { getIO } from "../config/websocket";
import { FeeType, PaymentMethod, PaymentStatus } from "@prisma/client";

export const getPayments = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  const where = schoolId ? { schoolId } : {};
  const data = await prisma.payment.findMany({ 
    where,
    include: { student: { include: { user: true } } },
    orderBy: { createdAt: "desc" }
  });
  res.json({ success: true, data });
});

export const createPayment = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  if (!schoolId) {
    throw new ValidationError("School context is required to create a payment.");
  }

  const payload = z.object({
    studentId: z.string(),
    amount: z.coerce.number().positive(),
    feeType: z.nativeEnum(FeeType).optional(),
    paymentMethod: z.nativeEnum(PaymentMethod).optional(),
    status: z.nativeEnum(PaymentStatus).default("PAID"),
    notes: z.string().optional()
  }).parse(req.body);

  const data = await prisma.payment.create({ 
    data: { 
      ...payload, 
      schoolId,
      paidAt: payload.status === "PAID" ? new Date() : null
    },
    include: { student: { include: { user: true } } }
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("payment:received", data);
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.status(201).json({ success: true, data });
});
