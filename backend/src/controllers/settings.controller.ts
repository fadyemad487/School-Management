import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError } from "../utils/AppError";
import { getIO } from "../config/websocket";

/** Require schoolId — throws if missing */
function requireSid(req: Request): string {
  if (!req.schoolId) throw new ValidationError("School context required");
  return req.schoolId;
}

export const getSettings = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  let settings = await prisma.schoolSettings.findUnique({
    where: { schoolId },
  });

  // If settings don't exist yet, create default
  if (!settings) {
    settings = await prisma.schoolSettings.create({
      data: {
        schoolId,
        language: "ar",
        currency: "EGP",
        timezone: "Africa/Cairo",
        dateFormat: "DD/MM/YYYY",
        attendanceMode: "DAILY",
        workingDays: [0, 1, 2, 3, 4], // Sun-Thu
        periodsPerDay: 7,
      },
    });
  }

  res.json({ success: true, data: settings });
});

export const updateSettings = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const workingDaysSchema = z
    .array(z.number().int().min(0).max(6))
    .max(7)
    .refine((days) => new Set(days).size === days.length, "workingDays must not contain duplicates");

  const schema = z.object({
    language: z.string().optional(),
    currency: z.string().optional(),
    timezone: z.string().optional(),
    dateFormat: z.string().optional(),
    smsEnabled: z.boolean().optional(),
    emailEnabled: z.boolean().optional(),
    whatsappEnabled: z.boolean().optional(),
    printHeader: z.string().optional().nullable(),
    printFooter: z.string().optional().nullable(),
    attendanceMode: z.enum(["DAILY", "PERIODIC"]).optional(),
    workingDays: workingDaysSchema.optional(),
    periodsPerDay: z.number().int().min(1).max(15).optional(),
    zoomEnabled: z.boolean().optional(),
    zoomAccountId: z.string().optional().nullable(),
    zoomClientId: z.string().optional().nullable(),
    zoomClientSecret: z.string().optional().nullable(),
  });

  const payload = schema.parse(req.body);

  const updated = await prisma.schoolSettings.upsert({
    where: { schoolId },
    update: payload,
    create: {
      ...payload,
      school: { connect: { id: schoolId } },
    },
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("settings:updated", updated);

  res.json({ success: true, data: updated });
});
