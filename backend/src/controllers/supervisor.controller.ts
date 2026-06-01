import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { Role } from "@prisma/client";
import { z } from "zod";
import crypto from "crypto";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";

/** List all supervisors */
export const getSupervisors = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const data = await prisma.busSupervisor.findMany({
    where: { schoolId, status: { not: "DELETED" } },
    include: { 
      user: true, 
      bus: true,
      credentials: {
        select: { loginId: true, plainTextPw: true }
      }
    },
    orderBy: { name: "asc" }
  });
  res.json({ success: true, data });
});

const generateAppLogin = async () => {
  let loginId = "";
  let isUnique = false;
  while (!isUnique) {
    loginId = Math.floor(100000 + Math.random() * 899999).toString();
    const existing = await prisma.appCredential.findUnique({ where: { loginId } });
    if (!existing) isUnique = true;
  }
  const password = Math.random().toString(36).slice(-8); // Random 8 chars
  return { loginId, password };
};

const generateSupervisorCode = async () => {
  const year = new Date().getFullYear().toString().slice(-2);
  let code = "";
  let isUnique = false;

  while (!isUnique) {
    const random = Math.floor(10000 + Math.random() * 90000); // 5 digits
    code = `S${year}${random}`;
    const existing = await prisma.busSupervisor.findUnique({ where: { code } });
    if (!existing) isUnique = true;
  }
  return code;
};

/** Create a new supervisor */
export const createSupervisor = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const supervisorCode = await generateSupervisorCode();

  const payload = z.object({
    name: z.string().min(3),
    nameAr: z.string().optional().nullable(),
    nameEn: z.string().optional().nullable(),
    nationalId: z.string().length(14).optional().nullable(),
    dob: z.string().optional().nullable(),
    phone: z.string().optional().nullable(),
    whatsapp: z.string().optional().nullable(),
    email: z.string().email().optional().or(z.literal("")).nullable(),
    address: z.string().optional().nullable(),
    gender: z.enum(["MALE", "FEMALE"]).optional().nullable(),
    qualification: z.string().optional().nullable(),
    appointmentDate: z.string().optional().nullable(),
    idCopyFront: z.string().optional().nullable(),
    idCopyBack: z.string().optional().nullable(),
    personalPhoto: z.string().optional().nullable(),
  }).parse(req.body);

  let finalEmail = payload.email;
  if (!finalEmail || finalEmail === "") {
    finalEmail = `${supervisorCode}@educontrol.me`;
  }

  const existingUser = await prisma.user.findUnique({ where: { email: finalEmail } });
  if (existingUser) {
    throw new ValidationError("البريد الإلكتروني مسجل بالفعل لمستخدم آخر.");
  }

  const supervisor = await prisma.$transaction(async (tx) => {
    const user = await tx.user.create({
      data: { 
        email: finalEmail!, 
        fullName: payload.name, 
        role: Role.BUS_SUPERVISOR,
        schoolId
      }
    });

    const toDate = (val: string | null | undefined) => {
      if (!val || val === "") return null;
      const d = new Date(val);
      return isNaN(d.getTime()) ? null : d;
    };

    const newSupervisor = await tx.busSupervisor.create({
      data: { 
        code: supervisorCode,
        userId: user.id, 
        schoolId,
        name: payload.name,
        nameAr: payload.nameAr,
        nameEn: payload.nameEn,
        nationalId: payload.nationalId,
        dob: toDate(payload.dob),
        phone: payload.phone,
        whatsapp: payload.whatsapp,
        email: finalEmail,
        address: payload.address,
        gender: payload.gender,
        qualification: payload.qualification,
        appointmentDate: toDate(payload.appointmentDate),
        idCopyFront: payload.idCopyFront,
        idCopyBack: payload.idCopyBack,
        personalPhoto: payload.personalPhoto,
        status: "ACTIVE"
      }
    });

    const appLogin = await generateAppLogin();
    const passwordHash = crypto.createHash("sha256").update(appLogin.password).digest("hex");

    await tx.appCredential.create({
      data: {
        loginId: appLogin.loginId, 
        loginEmail: finalEmail,
        passwordHash,
        plainTextPw: appLogin.password,
        role: Role.BUS_SUPERVISOR,
        schoolId,
        supervisorId: newSupervisor.id
      }
    });

    return await tx.busSupervisor.findUnique({
      where: { id: newSupervisor.id },
      include: { user: true, bus: true }
    });
  });

  res.status(201).json({ success: true, data: supervisor });
});

/** Update supervisor */
export const updateSupervisor = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const existing = await prisma.busSupervisor.findFirst({ where: { id, schoolId } });
  if (!existing) throw new NotFoundError("Supervisor not found");

  const payload = z.object({
    name: z.string().optional(),
    nameAr: z.string().optional().nullable(),
    nameEn: z.string().optional().nullable(),
    nationalId: z.string().length(14).optional().nullable(),
    dob: z.string().optional().nullable(),
    phone: z.string().optional().nullable(),
    whatsapp: z.string().optional().nullable(),
    address: z.string().optional().nullable(),
    gender: z.enum(["MALE", "FEMALE"]).optional().nullable(),
    qualification: z.string().optional().nullable(),
    email: z.string().email().optional().or(z.literal("")).nullable(),
    personalPhoto: z.string().optional().nullable(),
    idCopyFront: z.string().optional().nullable(),
    idCopyBack: z.string().optional().nullable(),
    appointmentDate: z.string().optional().nullable(),
    status: z.string().optional(),
  }).parse(req.body);

  const updated = await prisma.$transaction(async (tx) => {
    if (payload.name) {
      await tx.user.update({
        where: { id: existing.userId },
        data: { fullName: payload.name }
      });
    }

    const toDate = (val: string | null | undefined) => {
      if (!val || val === "") return undefined;
      const d = new Date(val);
      return isNaN(d.getTime()) ? undefined : d;
    };

    return await tx.busSupervisor.update({
      where: { id },
      data: {
        ...payload,
        dob: toDate(payload.dob),
        appointmentDate: toDate(payload.appointmentDate),
      },
      include: { user: true, bus: true }
    });
  });

  res.json({ success: true, data: updated });
});

/** Delete supervisor */
export const deleteSupervisor = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const supervisor = await prisma.busSupervisor.findFirst({ where: { id, schoolId } });
  if (!supervisor) throw new NotFoundError("Supervisor not found");

  await prisma.$transaction(async (tx) => {
    await tx.appCredential.deleteMany({ where: { supervisorId: id } });
    
    await tx.busSupervisor.update({
      where: { id },
      data: {
        status: "DELETED",
        busId: null
      }
    });

    const user = await tx.user.findUnique({ where: { id: supervisor.userId } });
    if (user) {
      await tx.user.update({
        where: { id: supervisor.userId },
        data: { email: `deleted_${Date.now()}_${user.email}` }
      });
    }
  });

  res.json({ success: true, message: "Supervisor deleted successfully" });
});
