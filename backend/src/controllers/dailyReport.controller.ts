import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";

export const createDailyReport = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const teacherId = (req as any).teacherId;

  const payload = z
    .object({
      classId: z.string().min(1),
      interactionLevel: z.string().min(1),
      attentionPercent: z.number().min(0).max(100),
      participationPercent: z.number().min(0).max(100),
      summary: z.string().min(1),
    })
    .parse(req.body);

  const report = await prisma.dailyReport.create({
    data: {
      schoolId,
      teacherId: teacherId,
      classId: payload.classId,
      interactionLevel: payload.interactionLevel,
      attentionPercent: payload.attentionPercent,
      participationPercent: payload.participationPercent,
      summary: payload.summary,
    },
    include: {
      class: true,
      teacher: true,
    }
  });

  getIO().to(`school:${schoolId}`).emit("dailyReport:created", report);
  res.status(201).json({ success: true, data: report });
});

export const getDailyReports = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { classId, teacherId, date } = req.query;

  const where: any = { schoolId };
  if (classId) where.classId = classId;
  if (teacherId) where.teacherId = teacherId;
  
  if (date) {
    const startDate = new Date(date as string);
    startDate.setHours(0, 0, 0, 0);
    const endDate = new Date(date as string);
    endDate.setHours(23, 59, 59, 999);
    where.date = { gte: startDate, lte: endDate };
  }

  const reports = await prisma.dailyReport.findMany({
    where,
    include: {
      class: true,
      teacher: true,
    },
    orderBy: { date: "desc" }
  });

  res.json({ success: true, data: reports });
});
