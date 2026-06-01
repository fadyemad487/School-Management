import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";
import { getIO } from "../config/websocket";
import { clearDashboardCache } from "./dashboard.controller";
import { requireSid } from "../utils/tenant";
import crypto from "crypto";

/** Convert null schoolId to undefined for Prisma compatibility */
function sid(req: Request): string | undefined {
  return req.schoolId ?? undefined;
}

// Helper for numeric login ID
async function generateNumericLoginId(tx: any) {
  const chars = "1234567890";
  let id = "";
  for (let i = 0; i < 6; i++) {
    id += chars.charAt(crypto.randomInt(chars.length));
  }
  // Ensure uniqueness
  const exists = await tx.appCredential.findUnique({ where: { loginId: id } });
  if (exists) return generateNumericLoginId(tx);
  return id;
}

// Helper for password
function generateRandomPassword(length = 8): string {
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

/** GET /api/admissions — List all applications */
export const getApplications = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = sid(req);
  const q = z.string().optional().parse(req.query.q);
  const status = z.string().optional().parse(req.query.status);

  const where: any = { schoolId: schoolId as string };
  if (status) where.status = status as any;
  if (q) {
    where.OR = [
      { childNameAr: { contains: q, mode: "insensitive" } },
      { childNameEn: { contains: q, mode: "insensitive" } },
      { childNationalId: { contains: q } },
      { applicationNo: { contains: q } },
    ];
  }

  const data = await prisma.application.findMany({
    where,
    include: {
      grade: true,
      father: true,
      mother: true,
    },
    orderBy: { createdAt: "desc" },
  });

  res.json({ success: true, data });
});

/** GET /api/admissions/stats — Get admission statistics */
export const getAdmissionStats = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  
  const stats = await prisma.application.groupBy({
    by: ['status'],
    where: { schoolId },
    _count: { _all: true }
  });

  // Format for frontend
  const formatted = stats.reduce((acc: any, curr) => {
    acc[curr.status] = curr._count._all;
    return acc;
  }, {});

  res.json({ success: true, data: formatted });
});

/** GET /api/admissions/:id — Get single application */
export const getApplication = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const data = await prisma.application.findFirst({
    where: { id: id as string, schoolId: schoolId as string },
    include: {
      grade: true,
      academicYear: true,
      father: true,
      mother: true,
      guardian: true,
      residence: true,
      documents: true,
      interview: true,
      fees: true,
      statusLogs: { orderBy: { changedAt: "desc" } },
      contacts: { orderBy: { date: "desc" } },
    },
  });

  if (!data) throw new NotFoundError("Application not found");
  res.json({ success: true, data });
});

/** POST /api/admissions — Create new application */
export const createApplication = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const data = req.body;

  let result;
  let retries = 5;

  while (retries > 0) {
    try {
      result = await prisma.$transaction(async (tx) => {
        // Generate application number inside transaction for real-time freshness
        const yearSuffix = new Date().getFullYear().toString().slice(-2);
        const latestApp = await tx.application.findFirst({
          where: { applicationNo: { startsWith: yearSuffix } },
          orderBy: { applicationNo: 'desc' }
        });

        let nextSerial = 1;
        if (latestApp && latestApp.applicationNo.length >= 6) {
          const lastSerial = parseInt(latestApp.applicationNo.slice(2));
          if (!isNaN(lastSerial)) nextSerial = lastSerial + 1;
        }
        const applicationNo = `${yearSuffix}${String(nextSerial).padStart(4, "0")}`;

        const application = await tx.application.create({
          data: {
            schoolId,
            applicationNo,
            childNameAr: data.childNameAr,
            childNameEn: data.childNameEn,
            childNationalId: data.childNationalId,
            childDob: new Date(data.childDob),
            childGender: data.childGender,
            childNationality: data.childNationality || "مصري",
            childReligion: data.childReligion,
            childAddress: data.childAddress,
            childPhoto: data.childPhoto,
            childBloodType: data.childBloodType,
            academicYearId: data.academicYearId,
            gradeId: data.gradeId,
            previousSchool: data.previousSchool,
            status: "NEW",
            father: data.father ? { create: data.father } : undefined,
            mother: data.mother ? { create: data.mother } : undefined,
            guardian: data.guardian ? { create: data.guardian } : undefined,
            residence: data.residence ? { create: data.residence } : undefined,
            documents: data.documents && data.documents.length > 0 ? {
              create: data.documents.map((doc: any) => ({
                documentType: doc.documentType,
                fileUrl: doc.fileUrl,
                received: doc.received || false,
                validityStatus: doc.validityStatus || "NOT_RECEIVED"
              }))
            } : undefined,
          }
        });

        await tx.applicationStatusLog.create({
          data: {
            applicationId: application.id,
            fromStatus: "NEW",
            toStatus: "NEW",
            notes: "تم تسجيل الطلب عبر النظام",
          }
        });

        return application;
      });
      break; // Success, escape retry loop
    } catch (error: any) {
      // Prisma error code P2002 signifies a unique constraint violation.
      // We retry immediately to generate a fresh incremental application number.
      if (error.code === "P2002") {
        retries--;
        if (retries === 0) throw error;
        // Wait briefly with a random backoff to avoid thundering herd / lock contention
        await new Promise((resolve) => setTimeout(resolve, Math.random() * 200 + 50));
      } else {
        throw error;
      }
    }
  }

  const io = getIO();
  io.to(`school:${schoolId}`).emit("dashboard:update");
  clearDashboardCache(schoolId);

  res.status(201).json({ success: true, data: result });
});

/** PUT /api/admissions/:id — Update application */
export const updateApplication = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  const data = req.body;

  const existing = await prisma.application.findFirst({ where: { id, schoolId } });
  if (!existing) throw new NotFoundError("Application not found");

  const updated = await prisma.$transaction(async (tx) => {
    // Basic update
    const app = await tx.application.update({
      where: { id },
      data: {
        childNameAr: data.childNameAr,
        childNameEn: data.childNameEn,
        childNationalId: data.childNationalId,
        childDob: data.childDob ? new Date(data.childDob) : undefined,
        childGender: data.childGender,
        childReligion: data.childReligion,
        childAddress: data.childAddress,
        childPhoto: data.childPhoto,
        childBloodType: data.childBloodType,
        gradeId: data.gradeId,
        academicYearId: data.academicYearId,
        previousSchool: data.previousSchool,
      }
    });

    // Update sub-records if provided
    if (data.father) {
      const { id: _, applicationId: __, ...fatherData } = data.father;
      await tx.applicationFather.upsert({
        where: { applicationId: id },
        update: fatherData,
        create: { ...fatherData, applicationId: id }
      });
    }
    if (data.mother) {
      const { id: _, applicationId: __, ...motherData } = data.mother;
      await tx.applicationMother.upsert({
        where: { applicationId: id },
        update: motherData,
        create: { ...motherData, applicationId: id }
      });
    }

    // Sync with Student table if already converted
    if (app.convertedStudentId) {
      await tx.student.update({
        where: { id: app.convertedStudentId },
        data: {
          nameAr: data.childNameAr,
          nameEn: data.childNameEn,
          nationalId: data.childNationalId,
          dob: data.childDob ? new Date(data.childDob) : undefined,
          gender: data.childGender,
          address: data.childAddress,
          bloodType: data.childBloodType,
        }
      });
    }

    return app;
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("dashboard:update");
  clearDashboardCache(schoolId);

  res.json({ success: true, data: updated });
});

/** PATCH /api/admissions/:id/status — Update application status */
export const changeApplicationStatus = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const { status, notes } = z.object({
    status: z.string(),
    notes: z.string().optional(),
  }).parse(req.body);

  const schoolId = requireSid(req);

  const app = await prisma.application.findFirst({
    where: { id: id as string, schoolId: schoolId as string },
  });
  if (!app) throw new NotFoundError("Application not found");

  const updated = await prisma.$transaction(async (tx) => {
    await tx.applicationStatusLog.create({
      data: {
        applicationId: id as string,
        fromStatus: app.status,
        toStatus: status as any,
        notes,
      },
    });

    return tx.application.update({
      where: { id: id as string },
      data: { status: status as any },
    });
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.json({ success: true, data: updated });
});

/** POST /api/admissions/:id/convert — Convert accepted application to student */
/** POST /api/admissions/:id/convert — Convert accepted application to student */
export const convertToStudent = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const app = await prisma.application.findFirst({
    where: {
      id: id as string,
      schoolId: schoolId as string
    },
    include: { father: true, mother: true, guardian: true, grade: true },
  });

  if (!app) throw new NotFoundError("Application not found");
  if (app.status !== "FINAL_ACCEPTED") {
    throw new ValidationError("Only FINAL_ACCEPTED applications can be converted to students");
  }
  if (app.convertedStudentId) {
    throw new ValidationError("Application already converted to student");
  }

  // Fetch school to get the code for a unique email prefix
  const school = await prisma.school.findUnique({ where: { id: schoolId as string } });
  const schoolCode = school?.code.toLowerCase() || "school";

  let result;
  let retries = 5;

  while (retries > 0) {
    try {
      result = await prisma.$transaction(async (tx) => {
        // Query the latest student globally to generate a globally unique and sequential student ID
        const latestStudent = await tx.student.findFirst({
          where: { studentCode: { startsWith: "22" } },
          orderBy: { studentCode: "desc" }
        });

        let nextSerial = 1;
        if (latestStudent && latestStudent.studentCode && latestStudent.studentCode.length >= 6) {
          const lastSerial = parseInt(latestStudent.studentCode.slice(2));
          if (!isNaN(lastSerial)) nextSerial = lastSerial + 1;
        }
        const studentCode = `22${String(nextSerial).padStart(4, "0")}`;
        const tempEmail = `${schoolCode}-${studentCode}@EduControl.com`;

        const studentCount = await tx.student.count({ where: { schoolId: schoolId as string } });

        // 1. Create or Reuse Student User
        let user = await tx.user.findUnique({ where: { email: tempEmail } });
        if (!user) {
          user = await tx.user.create({
            data: {
              email: tempEmail,
              fullName: app.childNameAr,
              role: "STUDENT",
              schoolId: schoolId as string,
            },
          });
        } else {
          user = await tx.user.update({
            where: { id: user.id },
            data: { role: "STUDENT", schoolId: schoolId as string, fullName: app.childNameAr }
          });
        }

        let fatherId: string | undefined;
        if (app.father) {
          const fatherEmail = app.father.email || `father-${schoolCode}-${studentCode}@educontrol.com`;
          let fatherUser = await tx.user.findUnique({ where: { email: fatherEmail } });
          
          if (!fatherUser) {
            fatherUser = await tx.user.create({
              data: {
                email: fatherEmail,
                fullName: app.father.fullName,
                role: "PARENT",
                schoolId: schoolId as string,
              }
            });
          }

          const fatherParent = await tx.parent.upsert({
            where: { userId: fatherUser.id },
            update: { 
              nameAr: app.father.fullName,
              phone: app.father.phone,
              whatsapp: app.father.whatsapp,
              occupation: app.father.occupation,
              nationalId: app.father.nationalId,
              relationship: "أب",
              schoolId: schoolId as string
            },
            create: {
              userId: fatherUser.id,
              schoolId: schoolId as string,
              nameAr: app.father.fullName,
              phone: app.father.phone,
              whatsapp: app.father.whatsapp,
              occupation: app.father.occupation,
              nationalId: app.father.nationalId,
              relationship: "أب"
            }
          });
          fatherId = fatherParent.id;

          const existingFatherCred = await tx.appCredential.findFirst({ where: { parentId: fatherParent.id } });
          if (!existingFatherCred) {
            const loginId = await generateNumericLoginId(tx);
            const plainPw = generateRandomPassword();
            await tx.appCredential.create({
              data: {
                loginId,
                passwordHash: hashPassword(plainPw),
                plainTextPw: plainPw,
                role: "PARENT",
                schoolId: schoolId as string,
                parentId: fatherParent.id,
              }
            });
          }
        }

        let motherId: string | undefined;
        if (app.mother) {
          const motherEmail = app.mother.email || `mother-${schoolCode}-${studentCode}@educontrol.com`;
          let motherUser = await tx.user.findUnique({ where: { email: motherEmail } });

          if (!motherUser) {
            motherUser = await tx.user.create({
              data: {
                email: motherEmail,
                fullName: app.mother.fullName,
                role: "PARENT",
                schoolId: schoolId as string,
              }
            });
          }

          const motherParent = await tx.parent.upsert({
            where: { userId: motherUser.id },
            update: {
              nameAr: app.mother.fullName,
              phone: app.mother.phone,
              whatsapp: app.mother.whatsapp,
              occupation: app.mother.occupation,
              nationalId: app.mother.nationalId,
              relationship: "أم",
              schoolId: schoolId as string
            },
            create: {
              userId: motherUser.id,
              schoolId: schoolId as string,
              nameAr: app.mother.fullName,
              phone: app.mother.phone,
              whatsapp: app.mother.whatsapp,
              occupation: app.mother.occupation,
              nationalId: app.mother.nationalId,
              relationship: "أم"
            }
          });
          motherId = motherParent.id;

          const existingMotherCred = await tx.appCredential.findFirst({ where: { parentId: motherParent.id } });
          if (!existingMotherCred) {
            const loginId = await generateNumericLoginId(tx);
            const plainPw = generateRandomPassword();
            await tx.appCredential.create({
              data: {
                loginId,
                passwordHash: hashPassword(plainPw),
                plainTextPw: plainPw,
                role: "PARENT",
                schoolId: schoolId as string,
                parentId: motherParent.id,
              }
            });
          }
        }

        const student = await tx.student.upsert({
          where: { userId: user.id },
          update: {
            schoolId: schoolId as string,
            studentCode,
            nameAr: app.childNameAr,
            nameEn: app.childNameEn,
            nationalId: app.childNationalId,
            dob: app.childDob,
            gender: app.childGender,
            address: app.childAddress,
            gradeId: app.gradeId,
            academicYearId: app.academicYearId,
            fatherId,
            motherId,
            photo: app.childPhoto,
            bloodType: app.childBloodType,
            rollNumber: String(studentCount + 1),
            status: "ACTIVE",
          },
          create: {
            userId: user.id,
            schoolId: schoolId as string,
            studentCode,
            nameAr: app.childNameAr,
            nameEn: app.childNameEn,
            nationalId: app.childNationalId,
            dob: app.childDob,
            gender: app.childGender,
            address: app.childAddress,
            gradeId: app.gradeId,
            academicYearId: app.academicYearId,
            fatherId,
            motherId,
            photo: app.childPhoto,
            bloodType: app.childBloodType,
            rollNumber: String(studentCount + 1),
            status: "ACTIVE",
          },
        });

        await tx.application.update({
          where: { id: id as string },
          data: {
            convertedStudentId: student.id,
            status: "FINAL_ACCEPTED",
          },
        });

        // 2. Create AppCredential for the Student so they can log in too!
        const existingStudentCred = await tx.appCredential.findFirst({ where: { studentId: student.id } });
        if (!existingStudentCred) {
          const plainPw = generateRandomPassword(6); // 6 char password/PIN for kids
          await tx.appCredential.create({
            data: {
              loginId: studentCode, // Kids login using their studentCode!
              passwordHash: hashPassword(plainPw),
              plainTextPw: plainPw,
              role: "STUDENT",
              schoolId: schoolId as string,
              studentId: student.id,
            }
          });
        }

        // AUTOMATIC BILLING: Create invoices based on FeeStructure rules with priority
        const allRules = await tx.feeStructure.findMany({
          where: {
            schoolId: schoolId as string,
            OR: [
              { studentId: student.id },
              { gradeId: app.gradeId },
              { AND: [{ gradeId: null }, { studentId: null }] }
            ]
          }
        });

        const feeTypeMap: Record<string, any> = {};
        for (const rule of allRules) {
          const existing = feeTypeMap[rule.feeType];
          if (!existing) {
            feeTypeMap[rule.feeType] = rule;
          } else {
            if (rule.studentId) {
              feeTypeMap[rule.feeType] = rule;
            } else if (rule.gradeId && !existing.studentId) {
              feeTypeMap[rule.feeType] = rule;
            }
          }
        }

        const rulesToApply = Object.values(feeTypeMap);

        if (rulesToApply.length > 0) {
          for (const rule of rulesToApply) {
            await tx.invoice.create({
              data: {
                schoolId: schoolId as string,
                studentId: student.id,
                feeType: rule.feeType,
                totalAmount: rule.amount,
                remaining: rule.amount,
                notes: `Auto-generated from rule: ${rule.name}`,
                status: "UNPAID",
              }
            });
          }
        }

        return student;
      }, { timeout: 20000 });
      break;
    } catch (error: any) {
      if (error.code === "P2002") {
        retries--;
        if (retries === 0) throw error;
        await new Promise((resolve) => setTimeout(resolve, Math.random() * 200 + 50));
      } else {
        throw error;
      }
    }
  }

  const io = getIO();
  io.to(`school:${schoolId}`).emit("dashboard:update");
  clearDashboardCache(schoolId);

  res.status(201).json({ success: true, data: result });
});

/** POST /api/admissions/:id/contact — Add contact log */
export const addContactLog = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const { method, notes } = req.body;

  const contact = await prisma.applicationContact.create({
    data: {
      applicationId: id,
      method,
      notes,
    }
  });

  res.json({ success: true, data: contact });
});

/** DELETE /api/admissions/:id — Delete application */
export const deleteApplication = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const existing = await prisma.application.findFirst({ where: { id, schoolId } });
  if (!existing) throw new NotFoundError("Application not found");

  await prisma.application.delete({
    where: { id }
  });

  res.json({ success: true, message: "Application deleted" });
});
