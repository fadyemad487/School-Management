import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";

const eventSchema = z.object({
  title: z.string().min(1),
  day: z.number().min(1).max(31),
  month: z.number().min(0).max(11),
  year: z.number(),
  startTime: z.string(),
  endTime: z.string(),
  type: z.string().optional()
});

export async function getEvents(req: Request, res: Response) {
  try {
    const { month, year } = req.query;
    const where: any = { schoolId: req.schoolId };

    if (month !== undefined) where.month = parseInt(month as string);
    if (year !== undefined) where.year = parseInt(year as string);

    const events = await prisma.calendarEvent.findMany({
      where,
      orderBy: { day: "asc" }
    });

    res.json({ success: true, data: events });
  } catch (err: any) {
    res.status(500).json({ success: false, message: err.message });
  }
}

export async function createEvent(req: Request, res: Response) {
  try {
    const data = eventSchema.parse(req.body);
    const event = await prisma.calendarEvent.create({
      data: {
        ...data,
        schoolId: req.schoolId!
      }
    });

    res.json({ success: true, data: event });
  } catch (err: any) {
    res.status(400).json({ success: false, message: err.message });
  }
}

export async function deleteEvent(req: Request, res: Response) {
  try {
    const id = req.params.id as string;
    await prisma.calendarEvent.deleteMany({
      where: { id, schoolId: req.schoolId || undefined }
    });
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ success: false, message: err.message });
  }
}
