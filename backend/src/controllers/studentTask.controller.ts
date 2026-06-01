import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";
import { createNotification } from "./notification.controller";
import { NotFoundError } from "../utils/AppError";

export const createStudentTask = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const teacherId = (req as any).teacherId;

  const payload = z
    .object({
      classId: z.string().min(1),
      title: z.string().min(2),
      description: z.string().min(2),
      dueDate: z.string().optional(),
      rewardPoints: z.coerce.number().min(0).default(0),
    })
    .parse(req.body);

  const task = await prisma.studentTask.create({
    data: {
      schoolId,
      teacherId: teacherId,
      classId: payload.classId,
      title: payload.title,
      description: payload.description,
      dueDate: payload.dueDate ? new Date(payload.dueDate) : null,
      rewardPoints: payload.rewardPoints,
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
      teacher: { include: { user: true } }
    }
  });

  // Notify all parents of students in this class
  if (task.class && task.class.students) {
    const parentIds = new Set<string>();
    
    for (const student of task.class.students) {
      if (student.father?.userId) parentIds.add(student.father.userId);
      if (student.mother?.userId) parentIds.add(student.mother.userId);
      if (student.guardianId) {
        const guardian = await prisma.parent.findUnique({
          where: { id: student.guardianId }
        });
        if (guardian?.userId) parentIds.add(guardian.userId);
      }
    }
    
    const teacherName = task.teacher?.user?.fullName || "المعلم";
    const className = task.class.name;

    for (const parentId of parentIds) {
      if (parentId) {
        await createNotification({
          schoolId,
          recipientId: parentId,
          title: "🎯 مهمة جديدة",
          message: `${teacherName}: مهمة جديدة (${task.title}) للفصل ${className}`,
          type: "GENERAL" as any,
          channel: "SYSTEM" as any
        });
      }
    }
  }

  getIO().to(`school:${schoolId}`).emit("studentTask:created", task);
  res.status(201).json({ success: true, data: task });
});

export const getStudentTasks = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { classId, teacherId } = req.query;

  const where: any = { schoolId };
  if (classId) where.classId = classId;
  if (teacherId) where.teacherId = teacherId;

  const tasks = await prisma.studentTask.findMany({
    where,
    include: {
      class: true,
      teacher: true,
      completions: true, // Include completions so teacher can see who finished
    },
    orderBy: { createdAt: "desc" }
  });

  res.json({ success: true, data: tasks });
});

export const deleteStudentTask = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const teacherId = (req as any).teacherId;
  const id = req.params.id as string;

  // Verify task belongs to school and teacher
  const task = await prisma.studentTask.findFirst({
    where: { id, schoolId, teacherId },
  });

  if (!task) {
    throw new NotFoundError("StudentTask");
  }

  // Delete task
  await prisma.studentTask.delete({
    where: { id },
  });

  // Emit websocket event to notify all clients
  getIO().to(`school:${schoolId}`).emit("studentTask:deleted", { taskId: id });

  res.json({ success: true, message: "Task deleted successfully" });
});

export const markTaskCompleted = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const teacherId = (req as any).teacherId; // Ensure only teachers can mark complete
  const id = req.params.id as string;
  const { studentId } = z.object({ studentId: z.string().min(1) }).parse(req.body);

  // 1. Verify task belongs to this teacher/school
  const task = await prisma.studentTask.findUnique({
    where: { id: id }
  });

  if (!task || task.schoolId !== schoolId || task.teacherId !== teacherId) {
    return res.status(404).json({ success: false, message: "Task not found or unauthorized" });
  }

  // 2. Verify student exists
  const student = await prisma.student.findUnique({
    where: { id: studentId }
  });

  if (!student) {
    return res.status(404).json({ success: false, message: "Student not found" });
  }

  // 3. Prevent duplicate completions
  const existingCompletion = await prisma.studentTaskCompletion.findUnique({
    where: {
      taskId_studentId: {
        taskId: id,
        studentId: studentId
      }
    }
  });

  if (existingCompletion) {
    return res.status(400).json({ success: false, message: "Task already completed by this student" });
  }

  // 4. Create completion and award points
  const result = await prisma.$transaction(async (tx) => {
    const completion = await tx.studentTaskCompletion.create({
      data: {
        taskId: id,
        studentId: studentId
      }
    });

    const updatedStudent = await tx.student.update({
      where: { id: studentId },
      data: {
        points: { increment: task.rewardPoints }
      }
    });

    return { completion, updatedStudent };
  });

  // 5. Notify parent
  if (student.fatherId) {
    const father = await prisma.parent.findUnique({ where: { id: student.fatherId } });
    if (father && father.userId) {
      await createNotification({
        schoolId,
        recipientId: father.userId,
        title: "إنجاز مهمة",
        message: `تم إنجاز المهمة "${task.title}" بنجاح! وحصل الطالب على ${task.rewardPoints} نقطة.`,
        type: "GENERAL"
      });
    }
  }

  // 6. Socket emit to update student game state live
  getIO().to(`user:${student.userId}`).emit("student:updated", {
    studentId: student.id,
    points: result.updatedStudent.points
  });

  res.json({ success: true, message: "Task marked as completed", data: result.completion });
});
