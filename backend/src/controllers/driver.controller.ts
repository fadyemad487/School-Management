import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { Role } from "@prisma/client";
import { z, ZodError } from "zod";
import crypto from "crypto";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";

/** List all drivers */
export const getDrivers = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const data = await prisma.driver.findMany({
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

const generateDriverCode = async () => {
  const year = new Date().getFullYear().toString().slice(-2);
  let code = "";
  let isUnique = false;

  while (!isUnique) {
    const random = Math.floor(10000 + Math.random() * 90000); // 5 digits
    code = `${year}${random}`;
    const existing = await prisma.driver.findUnique({ where: { code } });
    if (!existing) isUnique = true;
  }
  return code;
};

/** Create a new driver */
export const createDriver = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const driverCode = await generateDriverCode();

  const payload = z.object({
    // Personal
    name: z.string().min(3),
    nameAr: z.string().optional().nullable(),
    nameEn: z.string().optional().nullable(),
    nationalId: z.string().length(14),
    dob: z.string().optional().nullable(),
    phone: z.string().optional().nullable(),
    whatsapp: z.string().optional().nullable(),
    email: z.string().email().optional().or(z.literal("")).nullable(),
    address: z.string().optional().nullable(),
    maritalStatus: z.string().optional().nullable(),
    photo: z.string().optional().nullable(),
    // License
    licenseType: z.string().optional().nullable(),
    licenseNumber: z.string().optional().nullable(),
    licenseIssueDate: z.string().optional().nullable(),
    licenseExpiry: z.string().optional().nullable(),
    licenseAuthority: z.string().optional().nullable(),
    // Professional
    contractType: z.string().optional().nullable(),
    appointmentDate: z.string().optional().nullable(),
    salary: z.coerce.number().optional().nullable(),
    workingHours: z.string().optional().nullable(),
    assignedRoute: z.string().optional().nullable(),
    // Documents
    idCopy: z.string().optional(),
    idCopyFront: z.string().optional(),
    idCopyBack: z.string().optional(),
    licenseCopy: z.string().optional(),
    criminalRecord: z.string().optional(),
    medicalCert: z.string().optional(),
    militaryCert: z.string().optional(),
  }).parse(req.body);

  let finalEmail = payload.email;
  if (!finalEmail || finalEmail === "") {
    // Use the generated numeric System ID (e.g. 2210077) for the login email
    finalEmail = `${driverCode}@educontrol.me`;
  }

  // Check if user already exists
  const existingUser = await prisma.user.findUnique({ where: { email: finalEmail } });
  if (existingUser) {
    throw new ValidationError("البريد الإلكتروني (أو الرقم القومي) مسجل بالفعل لمستخدم آخر.");
  }

  const driver = await prisma.$transaction(async (tx) => {
    const user = await tx.user.create({
      data: { 
        email: finalEmail!, 
        fullName: payload.name, 
        role: Role.DRIVER,
        schoolId
      }
    });

    const toDate = (val: string | null | undefined) => {
      if (!val || val === "") return null;
      const d = new Date(val);
      return isNaN(d.getTime()) ? null : d;
    };

    const newDriver = await tx.driver.create({
      data: { 
        code: driverCode,
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
        maritalStatus: payload.maritalStatus,
        photo: payload.photo,
        licenseType: payload.licenseType,
        licenseNumber: payload.licenseNumber,
        licenseIssueDate: toDate(payload.licenseIssueDate),
        licenseExpiry: toDate(payload.licenseExpiry),
        licenseAuthority: payload.licenseAuthority,
        contractType: payload.contractType,
        appointmentDate: toDate(payload.appointmentDate),
        salary: payload.salary,
        workingHours: payload.workingHours,
        assignedRoute: payload.assignedRoute,
        idCopy: payload.idCopy,
        idCopyFront: payload.idCopyFront,
        idCopyBack: payload.idCopyBack,
        licenseCopy: payload.licenseCopy,
        criminalRecord: payload.criminalRecord,
        medicalCert: payload.medicalCert,
        militaryCert: payload.militaryCert,
        status: "ACTIVE"
      }
    });

    // Generate App Credentials for the driver (6-digit numeric ID as requested)
    const appLogin = await generateAppLogin();
    const passwordHash = crypto.createHash("sha256").update(appLogin.password).digest("hex");

    await tx.appCredential.create({
      data: {
        loginId: appLogin.loginId, 
        loginEmail: finalEmail,
        passwordHash,
        plainTextPw: appLogin.password,
        role: Role.DRIVER,
        schoolId,
        driverId: newDriver.id
      }
    });

    return await tx.driver.findUnique({
      where: { id: newDriver.id },
      include: { user: true, bus: true }
    });
  });

  res.status(201).json({ success: true, data: driver });
});

/** Update driver */
export const updateDriver = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const existing = await prisma.driver.findFirst({ where: { id, schoolId } });
  if (!existing) throw new NotFoundError("Driver not found");

  const payload = z.object({
    name: z.string().optional(),
    nameAr: z.string().optional().nullable(),
    nameEn: z.string().optional().nullable(),
    nationalId: z.string().length(14),
    dob: z.string().optional().nullable(),
    phone: z.string().optional().nullable(),
    whatsapp: z.string().optional().nullable(),
    address: z.string().optional().nullable(),
    maritalStatus: z.string().optional().nullable(),
    email: z.string().email().optional().or(z.literal("")).nullable(),
    photo: z.string().optional().nullable(),
    licenseType: z.string().optional().nullable(),
    licenseNumber: z.string().optional().nullable(),
    licenseIssueDate: z.string().optional().nullable(),
    licenseExpiry: z.string().optional().nullable(),
    licenseAuthority: z.string().optional().nullable(),
    contractType: z.string().optional().nullable(),
    appointmentDate: z.string().optional().nullable(),
    salary: z.coerce.number().optional().nullable(),
    workingHours: z.string().optional().nullable(),
    assignedRoute: z.string().optional().nullable(),
    idCopyFront: z.string().optional().nullable(),
    idCopyBack: z.string().optional().nullable(),
    licenseCopy: z.string().optional().nullable(),
    criminalRecord: z.string().optional().nullable(),
    medicalCert: z.string().optional().nullable(),
    militaryCert: z.string().optional().nullable(),
    idCopy: z.string().optional().nullable(),
    status: z.string().optional(),
  }).parse(req.body);

  const updated = await prisma.$transaction(async (tx) => {
    // Update linked user if name changed
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

    return await tx.driver.update({
      where: { id },
      data: {
        ...payload,
        dob: toDate(payload.dob),
        licenseIssueDate: toDate(payload.licenseIssueDate),
        licenseExpiry: toDate(payload.licenseExpiry),
        appointmentDate: toDate(payload.appointmentDate),
      },
      include: { user: true, bus: true }
    });
  });

  res.json({ success: true, data: updated });
});

/** Delete driver */
export const deleteDriver = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const driver = await prisma.driver.findFirst({ where: { id, schoolId } });
  if (!driver) throw new NotFoundError("Driver not found");

  await prisma.$transaction(async (tx) => {
    // 1. Delete app credentials for this driver
    await tx.appCredential.deleteMany({ where: { driverId: id } });
    
    // 2. Soft delete the driver (archive)
    await tx.driver.update({
      where: { id },
      data: {
        status: "DELETED",
        busId: null // Free up the bus
      }
    });

    // 3. Free up the user email so it can be reused
    const user = await tx.user.findUnique({ where: { id: driver.userId } });
    if (user) {
      await tx.user.update({
        where: { id: driver.userId },
        data: { email: `deleted_${Date.now()}_${user.email}` }
      });
    }
  });

  res.json({ success: true, message: "Driver deleted successfully" });
});
