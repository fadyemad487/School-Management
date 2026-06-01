import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";
import crypto from "crypto";

/** Convert null schoolId to undefined for Prisma compatibility */
function sid(req: Request): string | undefined {
  return req.schoolId ?? undefined;
}

/** Require schoolId — throws if missing */
function requireSid(req: Request): string {
  if (!req.schoolId) throw new ValidationError("School context required");
  return req.schoolId;
}

// ─── Helpers ──────────────────────────────────────────

function generateLoginId(prefix: string, schoolCode: string, counter: number): string {
  return `${prefix}-${schoolCode}-${String(counter).padStart(5, "0")}`;
}

function generatePassword(length = 8): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
  let pw = "";
  for (let i = 0; i < length; i++) {
    pw += chars.charAt(crypto.randomInt(chars.length));
  }
  return pw;
}

function hashPassword(pw: string): string {
  return crypto.createHash("sha256").update(pw).digest("hex");
}

// ─── Schemas ──────────────────────────────────────────────

const generateSchema = z.object({
  role: z.enum(["STUDENT", "TEACHER", "PARENT"]),
  entityId: z.string(), // studentId, teacherId, or parentId
  customLoginId: z.string().optional(),
  customEmail: z.string().email().optional(),
  customPassword: z.string().min(6).optional(),
  count: z.coerce.number().min(1).max(10).optional().default(1), // Generate multiple
});

const bulkGenerateSchema = z.object({
  role: z.enum(["STUDENT", "TEACHER", "PARENT"]),
  entityIds: z.array(z.string()).min(1).max(100),
});

// ─── Controllers ──────────────────────────────────────────

/** POST /api/credentials/generate — Generate credentials for a student/teacher/parent */
export const generateCredentials = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const { role, entityId, customLoginId, customEmail, customPassword, count } = generateSchema.parse(req.body);

  // Validate entity exists
  if (role === "STUDENT") {
    const s = await prisma.student.findFirst({ where: { id: entityId as string, schoolId: schoolId as string } });
    if (!s) throw new NotFoundError("Student not found");
  } else if (role === "TEACHER") {
    const t = await prisma.teacher.findFirst({ where: { id: entityId as string, schoolId: schoolId as string } });
    if (!t) throw new NotFoundError("Teacher not found");
  } else if (role === "PARENT") {
    const p = await prisma.parent.findFirst({ where: { id: entityId as string, schoolId: schoolId as string } });
    if (!p) throw new NotFoundError("Parent not found");
  }

  // Get school code for prefix
  const school = await prisma.school.findUnique({ where: { id: schoolId as string }, select: { code: true } });
  const prefix = role === "STUDENT" ? "STU" : role === "TEACHER" ? "TCH" : "PAR";
  const existingCount = await prisma.appCredential.count({ where: { schoolId: schoolId as string, role: role as any } });

  const credentials = [];
  for (let i = 0; i < count; i++) {
    const loginId = customLoginId && i === 0
      ? customLoginId
      : generateLoginId(prefix, school?.code || "SCH", existingCount + i + 1);

    const plainPw = customPassword && i === 0 ? customPassword : generatePassword();

    // Check uniqueness
    const existingLogin = await prisma.appCredential.findUnique({ where: { loginId } });
    if (existingLogin) throw new ValidationError(`Login ID "${loginId}" already exists`);

    if (customEmail && i === 0) {
      const existingEmail = await prisma.appCredential.findUnique({ where: { loginEmail: customEmail } });
      if (existingEmail) throw new ValidationError(`Email "${customEmail}" already in use`);
    }

    const cred = await prisma.appCredential.create({
      data: {
        loginId,
        loginEmail: customEmail && i === 0 ? customEmail : null,
        passwordHash: hashPassword(plainPw),
        plainTextPw: plainPw, // Stored temporarily
        role: role as any,
        schoolId: schoolId as string,
        studentId: role === "STUDENT" ? entityId : null,
        teacherId: role === "TEACHER" ? entityId : null,
        parentId: role === "PARENT" ? entityId : null,
      },
    });

    credentials.push({
      id: cred.id,
      loginId: cred.loginId,
      loginEmail: cred.loginEmail,
      password: plainPw, // Return plain text for admin to share
      role: cred.role,
    });
  }

  res.status(201).json({ success: true, data: credentials });
});

/** POST /api/credentials/bulk-generate — Bulk generate for multiple entities */
export const bulkGenerateCredentials = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const { role, entityIds } = bulkGenerateSchema.parse(req.body);

  const school = await prisma.school.findUnique({ where: { id: schoolId as string }, select: { code: true } });
  const prefix = role === "STUDENT" ? "STU" : role === "TEACHER" ? "TCH" : "PAR";
  const existingCount = await prisma.appCredential.count({ where: { schoolId: schoolId as string, role: role as any } });

  const results = [];
  for (let i = 0; i < entityIds.length; i++) {
    const entityId = entityIds[i];
    const loginId = generateLoginId(prefix, school?.code || "SCH", existingCount + i + 1);
    const plainPw = generatePassword();

    const cred = await prisma.appCredential.create({
      data: {
        loginId,
        passwordHash: hashPassword(plainPw),
        plainTextPw: plainPw,
        role: role as any,
        schoolId: schoolId as string,
        studentId: role === "STUDENT" ? entityId : null,
        teacherId: role === "TEACHER" ? entityId : null,
        parentId: role === "PARENT" ? entityId : null,
      },
    });

    results.push({
      entityId,
      loginId: cred.loginId,
      password: plainPw,
    });
  }

  res.status(201).json({ success: true, data: results });
});

/** GET /api/credentials — List all credentials for the school */
export const getCredentials = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = sid(req);
  const role = z.string().optional().parse(req.query.role);
  const entityId = z.string().optional().parse(req.query.entityId);

  const where: any = { schoolId: schoolId as string };
  if (role) where.role = role;
  if (entityId) {
    where.OR = [
      { studentId: entityId },
      { teacherId: entityId },
      { parentId: entityId },
    ];
  }

  const data = await prisma.appCredential.findMany({
    where,
    orderBy: { createdAt: "desc" },
    select: {
      id: true,
      loginId: true,
      loginEmail: true,
      plainTextPw: true,
      role: true,
      isActive: true,
      lastLoginAt: true,
      createdAt: true,
      student: { select: { nameAr: true, studentCode: true } },
      teacher: { select: { nameAr: true } },
      parent: { 
        select: { 
          nameAr: true,
          fatherOf: { select: { nameAr: true, studentCode: true } },
          motherOf: { select: { nameAr: true, studentCode: true } }
        } 
      },
      driver: { select: { name: true, nameAr: true } },
      supervisor: { select: { name: true, nameAr: true } },
    },
  });

  res.json({ success: true, data });
});

/** PATCH /api/credentials/:id/toggle — Enable/disable a credential */
export const toggleCredential = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const cred = await prisma.appCredential.findFirst({ where: { id: id as string, schoolId: schoolId as string } });
  if (!cred) throw new NotFoundError("Credential not found");

  const updated = await prisma.appCredential.update({
    where: { id: id as string },
    data: { isActive: !cred.isActive },
  });

  res.json({ success: true, data: { isActive: updated.isActive } });
});

/** PATCH /api/credentials/:id/reset-password — Reset password */
export const resetCredentialPassword = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const { password } = z.object({ password: z.string().min(6).optional() }).parse(req.body);
  const schoolId = requireSid(req);
  console.log(`[Credentials] Updating password for ID: ${id} (School: ${schoolId})`);

  const cred = await prisma.appCredential.findFirst({ where: { id: id as string, schoolId: schoolId as string } });
  if (!cred) throw new NotFoundError("Credential not found");

  const newPassword = password || generatePassword();
  await prisma.appCredential.update({
    where: { id: id as string },
    data: {
      passwordHash: hashPassword(newPassword),
      plainTextPw: newPassword,
    },
  });

  res.json({ success: true, data: { loginId: cred.loginId, newPassword } });
});

/** DELETE /api/credentials/:id — Delete credential */
export const deleteCredential = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const cred = await prisma.appCredential.findFirst({ where: { id: id as string, schoolId: schoolId as string } });
  if (!cred) throw new NotFoundError("Credential not found");

  await prisma.appCredential.delete({ where: { id: id as string } });
  res.json({ success: true, message: "Credential deleted" });
});
