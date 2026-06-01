import type { Request, Response } from "express";
import { Prisma } from "@prisma/client";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { NotFoundError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";
import { createNotification } from "./notification.controller";

export const listExams = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { classId, gradeId, subjectId, type, locked } = req.query;

  const where: any = { schoolId };
  if (classId && typeof classId === "string" && classId) where.classId = classId;
  if (gradeId && typeof gradeId === "string" && gradeId) where.gradeId = gradeId;
  if (subjectId && typeof subjectId === "string" && subjectId) where.subjectId = subjectId;
  if (type && typeof type === "string" && type) where.type = type;
  if (locked && typeof locked === "string") where.locked = locked === "1" || locked === "true";

  const data = await prisma.exam.findMany({
    where,
    include: {
      subject: true,
      grade: true,
      class: true,
      _count: { select: { results: true } },
    },
    orderBy: { date: "desc" },
  });

  res.json({ success: true, data });
});

export const createExam = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const payload = z
    .object({
      name: z.string().min(2),
      type: z.enum(["QUIZ", "MONTHLY", "MIDTERM", "FINAL", "ORAL", "PRACTICAL", "ASSIGNMENT"]),
      date: z.string().optional(),
      subjectId: z.string().optional(),
      gradeId: z.string().optional(),
      classId: z.string().optional(),
      maxScore: z.coerce.number().positive().optional(),
      passScore: z.coerce.number().min(0).optional(),
      notes: z.string().optional(),
    })
    .parse(req.body);

  const data = await prisma.exam.create({
    data: {
      schoolId,
      name: payload.name,
      type: payload.type,
      date: payload.date ? new Date(payload.date) : null,
      subjectId: payload.subjectId || null,
      gradeId: payload.gradeId || null,
      classId: payload.classId || null,
      notes: payload.notes,
    },
    include: { subject: true, grade: true, class: true },
  });

  getIO().to(`school:${schoolId}`).emit("exam:created", data);
  res.status(201).json({ success: true, data });
});

export const updateExam = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const id = req.params.id as string;

  const payload = z
    .object({
      name: z.string().min(2).optional(),
      type: z.enum(["QUIZ", "MONTHLY", "MIDTERM", "FINAL", "ORAL", "PRACTICAL", "ASSIGNMENT"]).optional(),
      date: z.string().optional().nullable(),
      subjectId: z.string().optional().nullable(),
      gradeId: z.string().optional().nullable(),
      classId: z.string().optional().nullable(),
      maxScore: z.coerce.number().positive().optional(),
      passScore: z.coerce.number().min(0).optional(),
      notes: z.string().optional().nullable(),
      locked: z.boolean().optional(),
    })
    .parse(req.body);

  const existing = await prisma.exam.findFirst({ where: { id: id as string, schoolId } });
  if (!existing) throw new NotFoundError("Exam");

  const dataPatch: Prisma.ExamUncheckedUpdateInput = {
    ...payload,
    date: payload.date === undefined ? undefined : payload.date ? new Date(payload.date) : null,
  };

  const data = await prisma.exam.update({
    where: { id: id as string },
    data: dataPatch,
    include: { subject: true, grade: true, class: true },
  });

  getIO().to(`school:${schoolId}`).emit("exam:updated", data);
  res.json({ success: true, data });
});

export const deleteExam = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const id = req.params.id as string;

  const existing = await prisma.exam.findFirst({ where: { id: id as string, schoolId } });
  if (!existing) throw new NotFoundError("Exam");

  await prisma.exam.delete({ where: { id: id as string } });
  getIO().to(`school:${schoolId}`).emit("exam:deleted", { id });
  res.json({ success: true });
});

// Save exam results for students
export const saveExamResults = asyncHandler(async (req: Request, res: Response) => {
  console.log("saveExamResults called");
  console.log("Request params:", req.params);
  console.log("Request body:", req.body);

  // Get schoolId from either dashboard auth or mobile auth
  let schoolId: string;
  try {
    schoolId = requireSid(req);
    console.log("Got schoolId from requireSid:", schoolId);
  } catch {
    // If not from dashboard, get from mobile auth context
    const mobileSchoolId = (req as any).schoolId;
    console.log("Got schoolId from mobile auth:", mobileSchoolId);
    if (!mobileSchoolId) {
      console.log("School ID missing from mobile auth");
      return res.status(403).json({ success: false, message: "School ID required" });
    }
    schoolId = mobileSchoolId;
  }

  const examId = req.params.id as string;
  console.log("Exam ID:", examId);
  console.log("School ID:", schoolId);

  const payload = z
    .object({
      results: z.array(
        z.object({
          studentId: z.string(),
          score: z.coerce.number().min(0).max(100),
          absent: z.boolean().optional().default(false),
          notes: z.string().optional(),
        })
      ),
    })
    .parse(req.body);

  console.log("Parsed payload:", payload);
  console.log("Number of results to save:", payload.results.length);

  // Verify exam belongs to school
  const exam = await prisma.exam.findFirst({
    where: { id: examId, schoolId },
    include: { subject: true, grade: true, class: true },
  });
  if (!exam) {
    console.log("Exam not found with ID:", examId, "for school:", schoolId);
    throw new NotFoundError("Exam");
  }

  console.log("Exam found:", exam.name);

  // Save or update each result
  let savedResults;
  try {
    savedResults = await Promise.all(
      payload.results.map(async (result) => {
        const existing = await prisma.examResult.findFirst({
          where: { examId, studentId: result.studentId },
        });

        if (existing) {
          console.log("Updating existing result for student:", result.studentId);
          return prisma.examResult.update({
            where: { id: existing.id },
            data: {
              score: result.score,
              absent: result.absent,
              notes: result.notes,
              approved: true, // Auto-approve when saved by teacher
            },
          });
        } else {
          console.log("Creating new result for student:", result.studentId);
          return prisma.examResult.create({
            data: {
              examId,
              studentId: result.studentId,
              score: result.score,
              absent: result.absent,
              notes: result.notes,
              approved: true,
            },
          });
        }
      })
    );
    console.log("Results saved successfully, count:", savedResults.length);
  } catch (error) {
    console.error("Error saving results:", error);
    throw error;
  }

  // Send WebSocket notification to school
  getIO().to(`school:${schoolId}`).emit("exam:results_published", {
    examId,
    examName: exam.name,
    subject: exam.subject?.name,
    grade: exam.grade?.name,
    class: exam.class?.name,
    resultsCount: savedResults.length,
  });

  // Send notifications to parents
  const studentIds = payload.results.map((r) => r.studentId);
  const students = await prisma.student.findMany({
    where: { id: { in: studentIds } },
    include: {
      user: true,
      father: { include: { user: true } },
      mother: { include: { user: true } },
      guardian: { include: { user: true } },
    },
  });

  for (const student of students) {
    // Get student name from user relation
    const studentName = student.user?.fullName || student.nameAr || student.nameEn || "الطالب";

    // Collect all parents to notify
    const parents = [
      student.father,
      student.mother,
      student.guardian,
    ].filter((p) => p !== null);

    // Send notification to each parent using createNotification
    for (const parent of parents) {
      if (parent.userId) {
        await createNotification({
          schoolId,
          recipientId: parent.userId,
          title: "📊 نشر النتائج",
          message: `تم نشر درجة الطالب ${studentName} في امتحان ${exam.name} (${exam.subject?.name})`,
          type: "RESULT" as any,
          channel: "SYSTEM" as any
        });
      }
    }
  }

  res.json({ success: true, data: savedResults });
});

// Get exam results for a specific exam
export const getExamResults = asyncHandler(async (req: Request, res: Response) => {
  // Get schoolId from either dashboard auth or mobile auth
  let schoolId: string;
  try {
    schoolId = requireSid(req);
  } catch {
    // If not from dashboard, get from mobile auth context
    const mobileSchoolId = (req as any).schoolId;
    if (!mobileSchoolId) {
      return res.status(403).json({ success: false, message: "School ID required" });
    }
    schoolId = mobileSchoolId;
  }

  const examId = req.params.id as string;

  const exam = await prisma.exam.findFirst({
    where: { id: examId, schoolId },
    include: { subject: true, grade: true, class: true },
  });
  if (!exam) throw new NotFoundError("Exam");

  const results = await prisma.examResult.findMany({
    where: { examId },
    include: {
      student: {
        include: {
          user: true,
        },
      },
    },
  });

  res.json({ success: true, data: { exam, results } });
});

// Get student results for dashboard
export const getStudentResults = asyncHandler(async (req: Request, res: Response) => {
  // Get schoolId from either dashboard auth or mobile auth
  let schoolId: string;
  try {
    schoolId = requireSid(req);
  } catch {
    // If not from dashboard, get from mobile auth context
    const mobileSchoolId = (req as any).schoolId;
    if (!mobileSchoolId) {
      return res.status(403).json({ success: false, message: "School ID required" });
    }
    schoolId = mobileSchoolId;
  }

  const { studentId, subjectId, gradeId, classId } = req.query;

  if (!studentId) {
    return res.status(400).json({ success: false, message: "studentId is required" });
  }

  const results = await prisma.examResult.findMany({
    where: {
      studentId: studentId as string,
      exam: {
        schoolId,
        ...(subjectId && typeof subjectId === "string" ? { subjectId } : {}),
        ...(gradeId && typeof gradeId === "string" ? { gradeId } : {}),
        ...(classId && typeof classId === "string" ? { classId } : {}),
      },
    },
    include: {
      exam: {
        include: {
          subject: true,
          grade: true,
          class: true,
        },
      },
    },
    orderBy: {
      exam: {
        date: "desc",
      },
    },
  });

  res.json({ success: true, data: results });
});

