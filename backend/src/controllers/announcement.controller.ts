import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError } from "../utils/AppError";
import { getIO } from "../config/websocket";

export const getAnnouncements = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  const where = schoolId ? { schoolId } : {};
  const data = await prisma.announcement.findMany({ 
    where,
    orderBy: { createdAt: "desc" } 
  });
  res.json({ success: true, data });
});

export const createAnnouncement = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  if (!schoolId) {
    throw new ValidationError("School context is required to create an announcement.");
  }

  const payload = z.object({
    title: z.string().min(3),
    body: z.string().min(3),
    audience: z.string().default("all")
  }).parse(req.body);

  const data = await prisma.announcement.create({ 
    data: { ...payload, schoolId }
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("announcement:created", data);

  res.status(201).json({ success: true, data });
});

export const deleteAnnouncement = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = req.schoolId;

  const announcement = await prisma.announcement.findFirst({
    where: { id, schoolId: schoolId! }
  });

  if (!announcement) {
    throw new ValidationError("Announcement not found");
  }

  await prisma.announcement.delete({
    where: { id }
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("announcement:deleted", id);

  res.json({ success: true, message: "Announcement deleted successfully" });
});
