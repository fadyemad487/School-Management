import { Request, Response } from "express";
import axios from "axios";
import { prisma } from "../config/prisma";
import { Role } from "@prisma/client";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError } from "../utils/AppError";
import { getIO } from "../config/websocket";
import { clearDashboardCache } from "./dashboard.controller";
import crypto from "crypto";

// Helper for password
function generateRandomPassword(length = 6): string {
  const chars = "1234567890ABCDEFGHJKLMNPQRSTUVWXYZ";
  let pw = "";
  for (let i = 0; i < length; i++) {
    pw += chars.charAt(crypto.randomInt(chars.length));
  }
  return pw;
}

function hashPassword(pw: string): string {
  return crypto.createHash("sha256").update(pw).digest("hex");
}

export const paginationSchema = z.object({
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(10)
});

export const getStudents = asyncHandler(async (req: Request, res: Response) => {
  const { page, limit } = paginationSchema.parse(req.query);
  const schoolId = req.schoolId;
  const where = schoolId ? { schoolId } : {};

  const [data, total] = await Promise.all([
    prisma.student.findMany({
      where,
      skip: (page - 1) * limit,
      take: limit,
      include: { user: true, class: true, fromApplication: true },
      orderBy: { user: { fullName: "asc" } }
    }),
    prisma.student.count({ where })
  ]);
  
  res.json({ success: true, data, meta: { page, limit, total } });
});

export const getStudentById = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = req.schoolId;

  const student = await prisma.student.findFirst({
    where: { id, schoolId: schoolId as string },
    include: {
      user: true,
      class: true,
      grade: true,
      father: { include: { user: true } },
      mother: { include: { user: true } }
    }
  });

  if (!student) {
    throw new ValidationError("Student not found or access denied.");
  }

  res.json({ success: true, data: student });
});

export const createStudent = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  if (!schoolId) {
    throw new ValidationError("School context is required to create a student.");
  }

  const payload = z.object({
    email: z.string().email(),
    fullName: z.string().min(2),
    nameEn: z.string().optional(),
    nationalId: z.string().optional(),
    dob: z.string().optional(),
    gender: z.enum(["MALE", "FEMALE"]).optional(),
    classId: z.string().optional(),
    gradeId: z.string().optional(),
    rollNumber: z.string().optional()
  }).parse(req.body);

  const user = await prisma.user.create({
    data: { 
      email: payload.email, 
      fullName: payload.fullName, 
      role: Role.STUDENT,
      schoolId
    }
  });

  const studentCount = await prisma.student.count({ where: { schoolId: schoolId as string } });
  const studentCode = `22${String(studentCount + 1).padStart(4, "0")}`;

  const student = await prisma.student.create({
    data: { 
      userId: user.id, 
      schoolId,
      studentCode,
      classId: payload.classId === "" ? null : payload.classId, 
      gradeId: payload.gradeId === "" ? null : payload.gradeId,
      rollNumber: payload.rollNumber,
      nameAr: payload.fullName,
      nameEn: payload.nameEn,
      nationalId: payload.nationalId,
      dob: payload.dob ? new Date(payload.dob) : undefined,
      gender: payload.gender,
      enrollmentDate: new Date(),
      status: "ACTIVE"
    },
    include: { user: true, class: true }
  });

  // Create AppCredential for the Student
  const plainPw = generateRandomPassword(6);
  await prisma.appCredential.create({
    data: {
      loginId: studentCode,
      passwordHash: hashPassword(plainPw),
      plainTextPw: plainPw,
      role: "STUDENT",
      schoolId: schoolId as string,
      studentId: student.id,
    }
  });

  // Emit real-time event to the school's room
  const io = getIO();
  io.to(`school:${schoolId}`).emit("student:created", student);
  io.to(`school:${schoolId}`).emit("dashboard:update");
  
  // Clear dashboard cache to show new student immediately
  clearDashboardCache(schoolId);
  
  res.status(201).json({ success: true, data: student });
});

export const updateStudent = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = req.schoolId;
  
  const payload = z.object({
    fullName: z.string().optional(),
    nameEn: z.string().optional(),
    nationalId: z.string().optional(),
    dob: z.string().optional(),
    gender: z.enum(["MALE", "FEMALE"]).optional(),
    classId: z.string().optional(),
    gradeId: z.string().optional(),
    rollNumber: z.string().optional(),
    status: z.enum(["ACTIVE", "WITHDRAWN", "SUSPENDED", "GRADUATED", "TRANSFERRED"]).optional()
  }).parse(req.body);

  // Verify ownership first
  const existing = await prisma.student.findFirst({
    where: { id, schoolId: schoolId as string }
  });

  if (!existing) {
    throw new ValidationError("Student not found or access denied.");
  }

  const updateData: any = {
    nameAr: payload.fullName,
    nameEn: payload.nameEn,
    nationalId: payload.nationalId,
    dob: payload.dob ? new Date(payload.dob) : undefined,
    gender: payload.gender,
    rollNumber: payload.rollNumber,
    status: payload.status,
  };

  // Handle Class relation explicitly
  if (payload.classId !== undefined) {
    if (payload.classId && payload.classId !== "") {
      updateData.class = { connect: { id: payload.classId } };
    } else {
      updateData.class = { disconnect: true };
    }
  }

  // Handle Grade relation explicitly
  if (payload.gradeId !== undefined) {
    if (payload.gradeId && payload.gradeId !== "") {
      updateData.grade = { connect: { id: payload.gradeId } };
    } else {
      updateData.grade = { disconnect: true };
    }
  }

  if (payload.fullName) {
    updateData.user = { update: { fullName: payload.fullName } };
  }

  try {
    const student = await prisma.student.update({
      where: { id },
      data: updateData,
      include: { user: true, class: true }
    });

    // Emit real-time WebSocket events so mobile app and other dashboard sessions receive the update instantly!
    if (student.schoolId) {
      const io = getIO();
      io.to(`school:${student.schoolId}`).emit("student:updated", student);
      io.to(`school:${student.schoolId}`).emit("dashboard:update");
    }

    res.json({ success: true, data: student });
  } catch (error: any) {
    console.error("Update Student Error:", error);
    // Return a more descriptive error if possible for debugging
    res.status(400).json({ 
      success: false, 
      message: error.code === 'P2002' 
        ? "Unique constraint failed" 
        : (error.message || "An error occurred during update") 
    });
  }
});

export const deleteStudent = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = req.schoolId;

  // 1. Fetch student with ALL related data to snapshot
  const student = await prisma.student.findFirst({
    where: { id, schoolId: schoolId as string },
    include: {
      user: true,
      credentials: true,
      father: { include: { user: true, credentials: true } },
      mother: { include: { user: true, credentials: true } },
    }
  });

  if (!student) {
    throw new ValidationError("Student not found or access denied.");
  }

  await prisma.$transaction(async (tx) => {
    // 2. Save snapshot to Archive
    await tx.archive.create({
      data: {
        schoolId: schoolId as string,
        entityType: "STUDENT",
        entityId: student.id,
        entityData: JSON.parse(JSON.stringify(student)),
        archivedBy: req.userId || "system"
      }
    });

    // 3. Delete Student User (Cascades to Student and Student Credentials)
    if (student.userId) {
      await tx.user.delete({ where: { id: student.userId } });
    }

    // 4. Handle Parents (Delete Parent if no other children exist in the school)
    const handleParentArchive = async (parentId?: string | null) => {
      if (!parentId) return;
      const otherChildren = await tx.student.count({
        where: { 
          OR: [{ fatherId: parentId }, { motherId: parentId }],
          NOT: { id: student.id }
        }
      });

      if (otherChildren === 0) {
        const parent = await tx.parent.findUnique({ where: { id: parentId } });
        if (parent && parent.userId) {
          await tx.user.delete({ where: { id: parent.userId } }); // Cascades to Parent and Parent Credentials
        }
      }
    };

    await handleParentArchive(student.fatherId);
    await handleParentArchive(student.motherId);
  });

  res.json({ success: true, message: "Student and related data have been archived and removed from active records." });
});

/* ── GET /api/students/mobile/game-state ── */
export const getMobileStudentGameState = asyncHandler(async (req: Request, res: Response) => {
  const studentId = (req as any).studentId;

  if (!studentId) {
    throw new ValidationError("Unauthorized: Student context missing.");
  }

  const student = await prisma.student.findUnique({
    where: { id: studentId },
    select: {
      points: true,
      game1Lvl: true,
      game2Lvl: true,
      game3Lvl: true,
      game4Lvl: true,
      game5Lvl: true,
      photo: true
    }
  });

  if (!student) {
    throw new ValidationError("Student record not found.");
  }

  res.json({
    success: true,
    data: {
      points: student.points,
      game1Lvl: student.game1Lvl,
      game2Lvl: student.game2Lvl,
      game3Lvl: student.game3Lvl,
      game4Lvl: student.game4Lvl,
      game5Lvl: student.game5Lvl,
      photo: student.photo
    }
  });
});

/* ── POST /api/students/mobile/game-state ── */
export const updateMobileStudentGameState = asyncHandler(async (req: Request, res: Response) => {
  const studentId = (req as any).studentId;

  if (!studentId) {
    throw new ValidationError("Unauthorized: Student context missing.");
  }

  const payload = z.object({
    points: z.number().int().min(0).optional(),
    game1Lvl: z.number().int().min(1).optional(),
    game2Lvl: z.number().int().min(1).optional(),
    game3Lvl: z.number().int().min(1).optional(),
    game4Lvl: z.number().int().min(1).optional(),
    game5Lvl: z.number().int().min(1).optional(),
    photo: z.string().optional().nullable()
  }).parse(req.body);

  const student = await prisma.student.update({
    where: { id: studentId },
    data: {
      points: payload.points,
      game1Lvl: payload.game1Lvl,
      game2Lvl: payload.game2Lvl,
      game3Lvl: payload.game3Lvl,
      game4Lvl: payload.game4Lvl,
      game5Lvl: payload.game5Lvl,
      photo: payload.photo
    },
    select: {
      id: true,
      schoolId: true,
      points: true,
      game1Lvl: true,
      game2Lvl: true,
      game3Lvl: true,
      game4Lvl: true,
      game5Lvl: true,
      photo: true
    }
  });

  // Emit real-time WebSocket events to school members to sync points instantly!
  if (student.schoolId) {
    const io = getIO();
    io.to(`school:${student.schoolId}`).emit("student:updated", student);
    io.to(`school:${student.schoolId}`).emit("dashboard:update");
  }

  res.json({
    success: true,
    data: student
  });
});

/* ── POST /api/students/mobile/ai-chat ── */
export const studentMobileAiChat = asyncHandler(async (req: Request, res: Response) => {
  const studentId = (req as any).studentId as string | undefined;
  const schoolId = req.schoolId;

  if (!studentId) {
    throw new ValidationError("Unauthorized: Student context missing.");
  }

  const { message, history } = req.body as {
    message?: string;
    history?: { role: string; parts: { text: string }[] }[];
  };

  if (!message?.trim()) {
    throw new ValidationError("Message is required.");
  }

  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ success: false, message: "AI Configuration missing (OpenRouter API Key)." });
  }

  const student = await prisma.student.findFirst({
    where: { id: studentId, schoolId },
    select: { nameAr: true, points: true },
  });

  if (!student) {
    throw new ValidationError("Student record not found.");
  }

  const systemPrompt = `
أنت "رفيق WeCircle الفضائي" — مساعد ذكي ودود للطلاب في المدارس المصرية (ابتدائي).
تتحدث بالعربية الفصحى البسيطة مع لمسة مصرية خفيفة.
اسم الطالب: ${student.nameAr ?? "بطل"}.
نقاطه الحالية: ${student.points ?? 0}.

قواعد مهمة:
- لا تناقش مواضيع غير مناسبة للأطفال.
- شجّع الطالب على الصدق، اللطف، احترام المعلمين والأهل.
- إذا ذكر مشكلة خطيرة أو خطراً، اطلب منه يخبر ولي أمره أو المعلم فوراً.
- اجعل الردود قصيرة (3-6 جمل) مع إيموجي مناسبة 🚀.
- لا تطلب بيانات شخصية حساسة.
`.trim();

  const messages: { role: string; content: string }[] = [
    { role: "system", content: systemPrompt },
    ...(history || []).map((h) => ({
      role: h.role === "user" ? "user" : "assistant",
      content: h.parts?.[0]?.text ?? "",
    })),
    { role: "user", content: message.trim() },
  ];

  const response = await axios.post(
    "https://openrouter.ai/api/v1/chat/completions",
    { model: "openai/gpt-4o-mini", messages },
    { headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" } }
  );

  const reply = response.data?.choices?.[0]?.message?.content?.trim()
    || "أنا معاك يا بطل! جرّب تسألني تاني 🌟";

  res.json({ success: true, reply });
});

