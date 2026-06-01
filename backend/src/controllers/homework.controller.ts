import type { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { NotFoundError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";
import { createNotification } from "./notification.controller";

export const listHomework = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { classId, subjectId, teacherId, status } = req.query;

  const where: any = { schoolId };
  if (classId && typeof classId === "string" && classId) where.classId = classId;
  if (subjectId && typeof subjectId === "string" && subjectId) where.subjectId = subjectId;
  if (teacherId && typeof teacherId === "string" && teacherId) where.teacherId = teacherId;
  if (status && typeof status === "string" && status) where.status = status;

  const data = await prisma.homework.findMany({
    where,
    include: {
      class: true,
      subject: true,
      teacher: { include: { user: true } },
      _count: { select: { submissions: true } },
    },
    orderBy: { sentDate: "desc" },
  });

  res.json({ success: true, data });
});

export const createHomework = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const payload = z
    .object({
      classId: z.string().min(1),
      subjectId: z.string().optional(),
      teacherId: z.string().optional(),
      title: z.string().min(2),
      description: z.string().optional(),
      attachments: z.string().url().optional(),
      dueDate: z.string().optional(),
      maxScore: z.coerce.number().positive().optional(),
      status: z.enum(["DRAFT", "OPEN", "CLOSED"]).optional(),
    })
    .parse(req.body);

  const data = await prisma.homework.create({
    data: {
      schoolId,
      classId: payload.classId,
      subjectId: payload.subjectId || null,
      teacherId: payload.teacherId || null,
      title: payload.title,
      description: payload.description,
      attachments: payload.attachments,
      dueDate: payload.dueDate ? new Date(payload.dueDate) : null,
      maxScore: payload.maxScore,
      status: payload.status,
    },
    include: { 
      class: { 
        include: { 
          students: { 
            include: { 
              father: true, 
              mother: true 
            } 
          } 
        } 
      }, 
      subject: true, 
      teacher: { include: { user: true } } 
    },
  });

  // Create notifications for all parents in the class
  const parentsToNotify = new Set<string>();
  for (const student of data.class.students) {
    if (student.fatherId) {
      const father = await prisma.parent.findUnique({
        where: { id: student.fatherId }
      });
      if (father && father.userId) parentsToNotify.add(father.userId);
    }
    if (student.motherId) {
      const mother = await prisma.parent.findUnique({
        where: { id: student.motherId }
      });
      if (mother && mother.userId) parentsToNotify.add(mother.userId);
    }
    if (student.guardianId) {
      const guardian = await prisma.parent.findUnique({
        where: { id: student.guardianId }
      });
      if (guardian && guardian.userId) parentsToNotify.add(guardian.userId);
    }
  }

  const teacherName = data.teacher?.user?.fullName || "المعلم";
  const className = data.class.name;

  for (const parentUserId of parentsToNotify) {
    await createNotification({
      schoolId,
      recipientId: parentUserId,
      title: "واجب جديد 📚",
      message: `${teacherName}: واجب جديد (${data.title}) للفصل ${className}`,
      type: "HOMEWORK" as any,
      channel: "SYSTEM" as any
    });
  }

  getIO().to(`school:${schoolId}`).emit("homework:created", data);
  res.status(201).json({ success: true, data });
});

export const updateHomework = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const id = req.params.id as string;

  const payload = z
    .object({
      classId: z.string().min(1).optional(),
      subjectId: z.string().optional().nullable(),
      teacherId: z.string().optional().nullable(),
      title: z.string().min(2).optional(),
      description: z.string().optional().nullable(),
      attachments: z.string().url().optional().nullable(),
      dueDate: z.string().optional().nullable(),
      maxScore: z.coerce.number().positive().optional().nullable(),
      status: z.enum(["DRAFT", "OPEN", "CLOSED"]).optional(),
    })
    .parse(req.body);

  const existing = await prisma.homework.findFirst({ where: { id: id as string, schoolId } });
  if (!existing) throw new NotFoundError("Homework");

  const data = await prisma.homework.update({
    where: { id: id as string },
    data: {
      ...payload,
      subjectId: payload.subjectId === undefined ? undefined : payload.subjectId,
      teacherId: payload.teacherId === undefined ? undefined : payload.teacherId,
      dueDate: payload.dueDate === undefined ? undefined : payload.dueDate ? new Date(payload.dueDate) : null,
    },
    include: { class: true, subject: true, teacher: { include: { user: true } } },
  });

  getIO().to(`school:${schoolId}`).emit("homework:updated", data);
  res.json({ success: true, data });
});

export const deleteHomework = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const id = req.params.id as string;

  const existing = await prisma.homework.findFirst({ where: { id: id as string, schoolId } });
  if (!existing) throw new NotFoundError("Homework");

  await prisma.homework.delete({ where: { id: id as string } });
  getIO().to(`school:${schoolId}`).emit("homework:deleted", { id });
  res.json({ success: true });
});

export const submitHomework = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const homeworkId = req.params.id as string;

  const payload = z
    .object({
      studentId: z.string().min(1),
      fileUrl: z.string().min(1),
    })
    .parse(req.body);

  const homework = await prisma.homework.findFirst({
    where: { id: homeworkId, schoolId },
  });
  if (!homework) throw new NotFoundError("Homework");

  const data = await prisma.homeworkSubmission.upsert({
    where: {
      homeworkId_studentId: {
        homeworkId,
        studentId: payload.studentId,
      },
    },
    update: {
      fileUrl: payload.fileUrl,
      submittedAt: new Date(),
    },
    create: {
      homeworkId,
      studentId: payload.studentId,
      fileUrl: payload.fileUrl,
      submittedAt: new Date(),
    },
  });

  getIO().to(`school:${schoolId}`).emit("homework:submitted", data);
  res.status(201).json({ success: true, data });
});

export const getHomeworkSubmissions = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const homeworkId = req.params.id as string;

  const homework = await prisma.homework.findFirst({
    where: { id: homeworkId, schoolId },
  });
  if (!homework) throw new NotFoundError("Homework");

  const submissions = await prisma.homeworkSubmission.findMany({
    where: { homeworkId },
    include: {
      student: {
        include: {
          user: true,
        },
      },
    },
    orderBy: { submittedAt: "desc" },
  });

  res.json({ success: true, data: submissions });
});
