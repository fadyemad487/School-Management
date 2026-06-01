import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { requireSid } from "../utils/tenant";
import { NotFoundError, ValidationError } from "../utils/AppError";

/** GET /api/archives - List all archived items */
export const getArchives = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { entityType } = req.query;

  const where: any = { schoolId };
  if (entityType) where.entityType = entityType;

  const data = await prisma.archive.findMany({
    where,
    orderBy: { archivedAt: "desc" }
  });

  res.json({ success: true, data });
});

/** POST /api/archives/:id/restore - Restore an archived item */
export const restoreArchive = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const archive = await prisma.archive.findFirst({
    where: { id, schoolId }
  });

  if (!archive) throw new NotFoundError("Archive record not found");

  const data = archive.entityData as any;

  if (archive.entityType === "STUDENT") {
    console.log(`DEBUG: Attempting to restore student ${data.id} (${data.nameEn || data.nameAr})`);

    // Check if user already exists
    let existingUser = await prisma.user.findFirst({
      where: { email: data.user.email },
      include: { student: true, teacher: true, parent: true }
    });
    
    let userIdToUse = data.user.id;

    if (existingUser) {
      // If it's the same email but different ID
      if (existingUser.id !== data.user.id) {
        // Check if this existing user is actually "busy" with another record
        const isBusy = existingUser.student || existingUser.teacher || existingUser.parent;
        
        if (isBusy) {
          const ownerType = existingUser.student ? "Student" : (existingUser.teacher ? "Teacher" : "Parent");
          const ownerName = existingUser.fullName;
          throw new ValidationError(`Cannot restore: Email ${data.user.email} is currently being used by active ${ownerType} '${ownerName}'.`);
        }

        // If not busy, it's a "ghost" user. We will update its ID to match the archived one to avoid primary key conflicts later
        console.log(`DEBUG: Found orphaned user with same email but different ID. Re-mapping ID from ${existingUser.id} to ${data.user.id}`);
        // We'll handle this by using the EXISTING ID instead of the archived one to be safe
        userIdToUse = existingUser.id;
      } else {
        // Same ID, same email - perfect match
        userIdToUse = existingUser.id;
      }
    }

    // Check if student already exists
    const studentConflicts: any[] = [{ id: data.id }];
    if (data.nationalId) studentConflicts.push({ nationalId: data.nationalId });
    if (data.studentCode) studentConflicts.push({ studentCode: data.studentCode });

    const existingStudent = await prisma.student.findFirst({
      where: { 
        OR: studentConflicts,
        schoolId
      }
    });

    if (existingStudent) {
      const conflictField = existingStudent.id === data.id ? "ID" : 
                           (existingStudent.nationalId === data.nationalId ? "National ID" : "Student Code");
      throw new ValidationError(`Cannot restore: A student with this ${conflictField} already exists in the active system.`);
    }

    await prisma.$transaction(async (tx) => {
      // 1. Restore Student User
      let studentUser = await tx.user.findFirst({
        where: { OR: [{ id: data.user.id }, { email: data.user.email }] }
      });

      if (!studentUser) {
        studentUser = await tx.user.create({
          data: {
            id: data.user.id,
            email: data.user.email,
            fullName: data.user.fullName,
            role: data.user.role,
            schoolId: data.user.schoolId,
            createdAt: data.user.createdAt,
          }
        });
      }

      // 2. Helper to restore Parent if missing
      const restoreParent = async (parentData: any) => {
        if (!parentData) return null;
        
        // Check if user exists
        let pUser = await tx.user.findFirst({ where: { OR: [{ id: parentData.user.id }, { email: parentData.user.email }] } });
        if (!pUser) {
          pUser = await tx.user.create({
            data: {
              id: parentData.user.id,
              email: parentData.user.email,
              fullName: parentData.user.fullName,
              role: parentData.user.role,
              schoolId: parentData.user.schoolId,
              createdAt: parentData.user.createdAt,
            }
          });
        }

        // Check if parent record exists
        let pRecord = await tx.parent.findUnique({ where: { id: parentData.id } });
        const parentPayload = {
          userId: pUser.id,
          schoolId: parentData.schoolId,
          nameAr: parentData.nameAr,
          nationalId: parentData.nationalId,
          occupation: parentData.occupation,
          employer: parentData.employer,
          phone: parentData.phone,
          whatsapp: parentData.whatsapp,
          email: parentData.email,
          address: parentData.address,
          relationship: parentData.relationship,
        };

        if (!pRecord) {
          pRecord = await tx.parent.create({
            data: { id: parentData.id, ...parentPayload }
          });
        } else {
          pRecord = await tx.parent.update({
            where: { id: parentData.id },
            data: parentPayload
          });
        }

        // Restore Credentials if missing
        if (parentData.credentials) {
          for (const cred of parentData.credentials) {
            const exists = await tx.appCredential.findUnique({ where: { loginId: cred.loginId } });
            if (!exists) {
              await tx.appCredential.create({
                data: {
                  loginId: cred.loginId,
                  passwordHash: cred.passwordHash,
                  plainTextPw: cred.plainTextPw,
                  role: cred.role,
                  schoolId: cred.schoolId,
                  parentId: pRecord.id
                }
              });
            } else if (!exists.parentId) {
              // Ensure it's linked to the parent
              await tx.appCredential.update({
                where: { loginId: cred.loginId },
                data: { parentId: pRecord.id }
              });
            }
          }
        }
        return pRecord.id;
      };

      const fatherId = await restoreParent(data.father);
      const motherId = await restoreParent(data.mother);

      // 3. Restore Student (using upsert logic style)
      let student = await tx.student.findUnique({ where: { id: data.id } });
      const studentPayload = {
        userId: studentUser.id,
        schoolId: data.schoolId,
        studentCode: data.studentCode,
        nameAr: data.nameAr,
        nameEn: data.nameEn,
        nationalId: data.nationalId,
        dob: data.dob,
        gender: data.gender,
        gradeId: data.gradeId,
        classId: data.classId,
        academicYearId: data.academicYearId,
        fatherId: fatherId,
        motherId: motherId,
        nationality: data.nationality,
        religion: data.religion,
        address: data.address,
        photo: data.photo,
        bloodType: data.bloodType,
        healthStatus: data.healthStatus,
        allergies: data.allergies,
        rollNumber: data.rollNumber,
        enrollmentDate: data.enrollmentDate,
        useBus: data.useBus,
        status: "ACTIVE" as any
      };

      if (!student) {
        student = await tx.student.create({
          data: { id: data.id, ...studentPayload }
        });
      } else {
        student = await tx.student.update({
          where: { id: data.id },
          data: studentPayload
        });
      }

      // 4. Restore Student Credentials
      if (data.credentials && data.credentials.length > 0) {
        for (const cred of data.credentials) {
          const existingCred = await tx.appCredential.findUnique({ where: { loginId: cred.loginId } });
          if (!existingCred) {
            await tx.appCredential.create({
              data: {
                loginId: cred.loginId,
                passwordHash: cred.passwordHash,
                plainTextPw: cred.plainTextPw,
                role: cred.role,
                schoolId: cred.schoolId,
                studentId: student.id
              }
            });
          }
        }
      }

      // 5. Delete Archive record
      await tx.archive.delete({ where: { id: archive.id } });
    });
  }

  res.json({ success: true, message: "Record restored successfully" });
});
