import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";
import { createNotification } from "./notification.controller";

export const createBehaviorReport = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const teacherId = (req as any).teacherId;

  const payload = z
    .object({
      studentId: z.string().min(1),
      classId: z.string().min(1),
      type: z.enum(["POSITIVE", "NEGATIVE", "FOLLOWUP"]),
      traits: z.array(z.string()).min(1),
      notes: z.string().optional(),
      teacherId: z.string().optional(),
    })
    .parse(req.body);

  const report = await prisma.behaviorReport.create({
    data: {
      schoolId,
      teacherId: teacherId || payload.teacherId, // Allow admin override if needed, but normally from token
      studentId: payload.studentId,
      classId: payload.classId,
      type: payload.type,
      traits: JSON.stringify(payload.traits),
      notes: payload.notes,
    },
    include: {
      student: { include: { father: true, mother: true } },
      teacher: { include: { user: true } },
    }
  });

  // Create notifications for all parents (father, mother, guardian)
  const parentsToNotify = [];
  if (report.student.fatherId) parentsToNotify.push(report.student.father);
  if (report.student.motherId) parentsToNotify.push(report.student.mother);
  if (report.student.guardianId) {
    const guardian = await prisma.parent.findUnique({
      where: { id: report.student.guardianId }
    });
    if (guardian) parentsToNotify.push(guardian);
  }

  let notifTitle = "تقرير سلوك";
  if (payload.type === "POSITIVE") notifTitle = "تقرير سلوك إيجابي";
  else if (payload.type === "FOLLOWUP") notifTitle = "متابعة سلوكية";
  else if (payload.type === "NEGATIVE") notifTitle = "تنبيه سلوكي";

  const teacherName = report.teacher?.user?.fullName || "المعلم";

  for (const parent of parentsToNotify) {
    if (parent?.userId) {
      await createNotification({
        schoolId,
        recipientId: parent.userId,
        title: notifTitle,
        message: `${teacherName}: ${payload.traits.join(", ")} - ${report.student.nameAr || report.student.nameEn}`,
        type: "BEHAVIOR" as any,
        channel: "SYSTEM" as any
      });
    }
  }

  getIO().to(`school:${schoolId}`).emit("behavior:created", {
    reportId: report.id,
    studentId: report.studentId,
    studentName: report.student.nameAr || report.student.nameEn,
    teacherId: report.teacherId,
    teacherName: report.teacher?.user?.fullName || "المعلم",
    type: report.type,
    traits: payload.traits,
    notes: report.notes,
    createdAt: report.createdAt,
  });
  res.status(201).json({ success: true, data: report });
});

export const getBehaviorReports = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { classId, studentId, teacherId, type } = req.query;

  const where: any = { schoolId };
  if (classId) where.classId = classId;
  if (studentId) where.studentId = studentId;
  if (teacherId) where.teacherId = teacherId;
  if (type) where.type = type;

  const reports = await prisma.behaviorReport.findMany({
    where,
    include: {
      student: true,
      teacher: { include: { user: true } },
      class: true
    },
    orderBy: { createdAt: "desc" }
  });

  res.json({ success: true, data: reports });
});

// Get behavior reports for teacher only
export const getTeacherBehaviorReports = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const teacherId = (req as any).teacherId;

  if (!teacherId) {
    return res.status(403).json({ success: false, message: "Teacher ID required" });
  }

  const { classId, studentId, type } = req.query;

  const where: any = { schoolId, teacherId };
  if (classId) where.classId = classId;
  if (studentId) where.studentId = studentId;
  if (type) where.type = type;

  const reports = await prisma.behaviorReport.findMany({
    where,
    include: {
      student: true,
      teacher: { include: { user: true } },
      class: true
    },
    orderBy: { createdAt: "desc" }
  });

  res.json({ success: true, data: reports });
});

// Get behavior reports for parent's children only
export const getParentBehaviorReports = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const parentId = (req as any).parentId;

  if (!parentId) {
    return res.status(403).json({ success: false, message: "Parent ID required" });
  }

  // Get all children of this parent
  const parent = await prisma.parent.findUnique({
    where: { id: parentId },
    include: {
      fatherOf: true,
      motherOf: true,
      guardianOf: true
    }
  });

  if (!parent) {
    return res.status(404).json({ success: false, message: "Parent not found" });
  }

  // Collect all student IDs
  const studentIds = new Set<string>();
  parent.fatherOf.forEach((s: any) => studentIds.add(s.id));
  parent.motherOf.forEach((s: any) => studentIds.add(s.id));
  parent.guardianOf.forEach((s: any) => studentIds.add(s.id));

  if (studentIds.size === 0) {
    return res.json({ success: true, data: [] });
  }

  // Get behavior reports for these students only
  const reports = await prisma.behaviorReport.findMany({
    where: {
      schoolId,
      studentId: { in: Array.from(studentIds) }
    },
    include: {
      student: true,
      teacher: { include: { user: true } },
      class: true
    },
    orderBy: { createdAt: "desc" }
  });

  res.json({ success: true, data: reports });
});
