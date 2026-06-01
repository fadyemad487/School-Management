import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { Role } from "@prisma/client";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError, ConflictError } from "../utils/AppError";
import { getSessionsForTeacher, revokeSessionForTeacher, revokeAllSessionsForTeacher } from "../utils/sessionStore";
import { getIO } from "../config/websocket";
import crypto from "crypto";

export const getTeachers = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  const where = schoolId ? { schoolId } : {};
  const teachers = await prisma.teacher.findMany({
    where,
    include: {
      user: true,
      credentials: true,
      teacherSubjects: {
        include: {
          subject: { select: { id: true, name: true } },
          class: { select: { id: true, name: true, section: true } }
        }
      }
    },
    orderBy: { user: { fullName: "asc" } }
  });

  // 1. Check if any teacher is missing app credentials, and generate them
  const teachersWithoutCreds = teachers.filter(t => !t.credentials || t.credentials.length === 0);
  if (teachersWithoutCreds.length > 0 && schoolId) {
    const school = await prisma.school.findUnique({ where: { id: schoolId }, select: { code: true } });
    const schoolCode = school?.code || "SCH";

    for (const teacher of teachersWithoutCreds) {
      const loginId = teacher.code || `TCH-${teacher.id.slice(0, 8)}`;

      // Ensure uniqueness
      let finalLoginId = loginId;
      let checkCount = 1;
      while (true) {
        const dup = await prisma.appCredential.findUnique({ where: { loginId: finalLoginId } });
        if (!dup) break;
        finalLoginId = `${loginId}-${checkCount}`;
        checkCount++;
      }

      // Generate random password
      const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
      let plainTextPw = "";
      for (let i = 0; i < 8; i++) {
        plainTextPw += chars.charAt(crypto.randomInt(chars.length));
      }
      const passwordHash = crypto.createHash("sha256").update(plainTextPw).digest("hex");

      const newCred = await prisma.appCredential.create({
        data: {
          loginId: finalLoginId,
          passwordHash,
          plainTextPw,
          role: "TEACHER",
          schoolId,
          teacherId: teacher.id
        }
      });

      teacher.credentials = [newCred];
    }
  }

  // 2. Migrate any existing old "TCH-" prefix login IDs to teacher.code
  if (schoolId) {
    for (const teacher of teachers) {
      if (teacher.credentials && teacher.credentials.length > 0) {
        const cred = teacher.credentials[0];
        if (cred.loginId.startsWith("TCH-") && teacher.code) {
          let finalLoginId = teacher.code;
          let checkCount = 1;
          while (true) {
            const dup = await prisma.appCredential.findUnique({ where: { loginId: finalLoginId, NOT: { id: cred.id } } });
            if (!dup) break;
            finalLoginId = `${teacher.code}-${checkCount}`;
            checkCount++;
          }

          const updatedCred = await prisma.appCredential.update({
            where: { id: cred.id },
            data: { loginId: finalLoginId }
          });

          teacher.credentials[0] = updatedCred;
        }
      }
    }
  }

  res.json({ success: true, data: teachers });
});

const generateTeacherCode = async () => {
  const yearSuffix = new Date().getFullYear().toString().slice(-2); // e.g. "26"
  
  // Find the latest teacher code starting with this year suffix
  const latestTeacher = await prisma.teacher.findFirst({
    where: { code: { startsWith: yearSuffix } },
    orderBy: { code: "desc" }
  });

  let nextSerial = 1;
  if (latestTeacher && latestTeacher.code && latestTeacher.code.length > 2) {
    const lastSerial = parseInt(latestTeacher.code.slice(2));
    if (!isNaN(lastSerial)) {
      nextSerial = lastSerial + 1;
    }
  }

  // Format as YearSuffix + 4 digit serial, e.g. 260001, 260002, etc.
  return `${yearSuffix}${String(nextSerial).padStart(4, "0")}`;
};

export const createTeacher = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  if (!schoolId) {
    throw new ValidationError("School context is required to create a teacher.");
  }

  const teacherCode = await generateTeacherCode();

  const payload = z.object({
    email: z.string().email().optional().or(z.literal("")),
    fullName: z.string().min(2),
    nameEn: z.string().optional(),
    nationalId: z.string().optional(),
    dob: z.string().optional(),
    gender: z.enum(["MALE", "FEMALE"]).optional(),
    phone: z.string().optional(),
    address: z.string().optional(),
    // Job Info
    jobTitle: z.string().optional(),
    subject: z.string().optional(),
    stage: z.string().optional(),
    appointmentDate: z.string().optional(),
    contractType: z.enum(["FULL_TIME", "PART_TIME", "TEMPORARY", "PROBATION"]).optional(),
    salary: z.coerce.number().optional(),
    // Qualifications
    qualification: z.string().optional(),
    specialization: z.string().optional(),
    graduationYear: z.string().optional(),
    graduationGrade: z.string().optional(),
    experienceYears: z.coerce.number().optional(),
    // Documents
    idCopy: z.string().optional(),
    graduationCert: z.string().optional(),
    militaryService: z.string().optional(),
    criminalRecord: z.string().optional(),
    personalPhoto: z.string().optional(),
    experienceCerts: z.string().optional(),
  }).parse(req.body);

  let finalEmail = payload.email;
  if (!finalEmail || finalEmail === "") {
    if (!payload.nationalId) {
      throw new ValidationError("البريد الإلكتروني أو الرقم القومي مطلوب لإنشاء الحساب.");
    }
    finalEmail = `teacher_${payload.nationalId}@educontrol.me`;
  }

  // Check if user already exists
  const existingUser = await prisma.user.findUnique({ where: { email: finalEmail } });
  if (existingUser) {
    throw new ValidationError("البريد الإلكتروني (أو الرقم القومي) مسجل بالفعل لمستخدم آخر.");
  }

  const teacher = await prisma.$transaction(async (tx) => {
    const user = await tx.user.create({
      data: {
        email: finalEmail!,
        fullName: payload.fullName,
        role: Role.TEACHER,
        schoolId
      }
    });

    const newTeacher = await tx.teacher.create({
      data: {
        userId: user.id,
        schoolId,
        code: teacherCode,
        nameAr: payload.fullName,
        nameEn: payload.nameEn,
        nationalId: payload.nationalId,
        dob: payload.dob ? new Date(payload.dob) : undefined,
        gender: payload.gender,
        phone: payload.phone,
        address: payload.address,
        email: payload.email,
        // Job
        jobTitle: payload.jobTitle,
        subject: payload.subject,
        stage: payload.stage,
        appointmentDate: payload.appointmentDate ? new Date(payload.appointmentDate) : new Date(),
        contractType: payload.contractType,
        salary: payload.salary,
        // Quals
        qualification: payload.qualification,
        specialization: payload.specialization,
        graduationYear: payload.graduationYear,
        graduationGrade: payload.graduationGrade,
        experienceYears: payload.experienceYears,
        // Docs
        idCopy: payload.idCopy,
        graduationCert: payload.graduationCert,
        militaryService: payload.militaryService,
        criminalRecord: payload.criminalRecord,
        experienceCerts: payload.experienceCerts,
        photo: payload.personalPhoto, // Duplicate to photo field for frontend consistency
        personalPhoto: payload.personalPhoto,
        status: "ACTIVE"
      }
    });

    // Auto-generate credentials for the new teacher
    const loginId = newTeacher.code || `TCH-${newTeacher.id.slice(0, 8)}`;

    // Ensure uniqueness
    let finalLoginId = loginId;
    let checkCount = 1;
    while (true) {
      const dup = await tx.appCredential.findUnique({ where: { loginId: finalLoginId } });
      if (!dup) break;
      finalLoginId = `${loginId}-${checkCount}`;
      checkCount++;
    }

    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
    let plainTextPw = "";
    for (let i = 0; i < 8; i++) {
      plainTextPw += chars.charAt(crypto.randomInt(chars.length));
    }
    const passwordHash = crypto.createHash("sha256").update(plainTextPw).digest("hex");

    await tx.appCredential.create({
      data: {
        loginId: finalLoginId,
        passwordHash,
        plainTextPw,
        role: "TEACHER",
        schoolId,
        teacherId: newTeacher.id
      }
    });

    return await tx.teacher.findUnique({
      where: { id: newTeacher.id },
      include: { user: true, credentials: true }
    });
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("teacher:created", teacher);
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.status(201).json({ success: true, data: teacher });
});

export const updateTeacher = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = req.schoolId;

  const payload = z.object({
    fullName: z.string().min(2).optional(),
    nameEn: z.string().optional(),
    nationalId: z.string().optional(),
    dob: z.string().optional(),
    gender: z.enum(["MALE", "FEMALE"]).optional(),
    phone: z.string().optional(),
    address: z.string().optional(),
    email: z.string().email().optional(),
    jobTitle: z.string().optional(),
    subject: z.string().optional(),
    stage: z.string().optional(),
    appointmentDate: z.string().optional(),
    contractType: z.enum(["FULL_TIME", "PART_TIME", "TEMPORARY", "PROBATION"]).optional(),
    salary: z.coerce.number().optional(),
    qualification: z.string().optional(),
    specialization: z.string().optional(),
    graduationYear: z.string().optional(),
    graduationGrade: z.string().optional(),
    experienceYears: z.coerce.number().optional(),
    status: z.enum(["ACTIVE", "INACTIVE", "ON_LEAVE"]).optional(),
    // Docs
    idCopy: z.string().optional(),
    graduationCert: z.string().optional(),
    militaryService: z.string().optional(),
    criminalRecord: z.string().optional(),
    personalPhoto: z.string().optional(),
    experienceCerts: z.string().optional(),
  }).parse(req.body);

  const teacher = await prisma.teacher.findFirst({
    where: { id: id as string, schoolId: schoolId as string },
    include: { user: true, credentials: true }
  });

  if (!teacher) throw new ValidationError("Teacher not found");

  const updatedTeacher = await prisma.$transaction(async (tx) => {
    // Update User if fullName or email changed
    if (payload.fullName || payload.email) {
      await tx.user.update({
        where: { id: teacher.userId },
        data: {
          fullName: payload.fullName || undefined,
          email: payload.email || undefined
        }
      });
    }

    // Update Teacher
    return await tx.teacher.update({
      where: { id },
      data: {
        nameAr: payload.fullName || undefined,
        nameEn: payload.nameEn,
        nationalId: payload.nationalId,
        dob: payload.dob ? new Date(payload.dob) : undefined,
        gender: payload.gender,
        phone: payload.phone,
        address: payload.address,
        email: payload.email,
        jobTitle: payload.jobTitle,
        subject: payload.subject,
        stage: payload.stage,
        appointmentDate: payload.appointmentDate ? new Date(payload.appointmentDate) : undefined,
        contractType: payload.contractType,
        salary: payload.salary,
        qualification: payload.qualification,
        specialization: payload.specialization,
        graduationYear: payload.graduationYear,
        graduationGrade: payload.graduationGrade,
        experienceYears: payload.experienceYears,
        status: (payload.status as any) || undefined,
        idCopy: payload.idCopy,
        graduationCert: payload.graduationCert,
        militaryService: payload.militaryService,
        criminalRecord: payload.criminalRecord,
        photo: payload.personalPhoto || undefined, // Sync with photo field
        personalPhoto: payload.personalPhoto,
        experienceCerts: payload.experienceCerts,
      },
      include: { user: true, credentials: true }
    });
  });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("teacher:updated", updatedTeacher);

  res.json({ success: true, data: updatedTeacher });
});

export const deleteTeacher = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = req.schoolId;

  const teacher = await prisma.teacher.findFirst({ where: { id, schoolId: schoolId! } });
  if (!teacher) throw new ValidationError("Teacher not found");

  // Delete User (will cascade to Teacher)
  await prisma.user.delete({ where: { id: teacher.userId } });

  const io = getIO();
  io.to(`school:${schoolId}`).emit("teacher:deleted", id);
  io.to(`school:${schoolId}`).emit("dashboard:update");

  res.json({ success: true, message: "Teacher deleted successfully" });
});

export const getMobileTeacherDashboard = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = (req as any).teacherId;
  const schoolId = req.schoolId;

  if (!teacherId) {
    throw new ValidationError("Teacher context is required.");
  }

  const teacher = await prisma.teacher.findFirst({
    where: { id: teacherId, schoolId: schoolId! },
    include: { user: true }
  });

  if (!teacher) {
    throw new ValidationError("Teacher profile not found.");
  }

  const teacherSubjects = await prisma.teacherSubject.findMany({
    where: { teacherId, class: { schoolId: schoolId! } },
    select: { classId: true }
  });

  const classIds = Array.from(new Set(teacherSubjects.map(ts => ts.classId)));

  const totalStudents = classIds.length > 0
    ? await prisma.student.count({ where: { classId: { in: classIds }, schoolId: schoolId! } })
    : 0;

  const todayDay = new Date().getDay();
  const todayTimetable = await prisma.timetable.findMany({
    where: { teacherId, schoolId: schoolId!, day: todayDay },
    include: { class: true, subject: true },
    orderBy: { periodNumber: "asc" }
  });

  const now = new Date();
  const currentHours = now.getHours();
  const currentMinutes = now.getMinutes();

  let finishedPeriodsCount = 0;
  todayTimetable.forEach(slot => {
    if (slot.endTime) {
      const [hoursStr, minutesStr] = slot.endTime.split(":");
      const endHours = parseInt(hoursStr, 10);
      const endMinutes = parseInt(minutesStr, 10);
      if (currentHours > endHours || (currentHours === endHours && currentMinutes >= endMinutes)) {
        finishedPeriodsCount++;
      }
    }
  });

  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);
  const endOfToday = new Date();
  endOfToday.setHours(23, 59, 59, 999);

  const absentStudentsToday = classIds.length > 0
    ? await prisma.attendance.count({
        where: {
          classId: { in: classIds },
          schoolId: schoolId!,
          date: { gte: startOfToday, lte: endOfToday },
          status: "ABSENT",
          type: "STUDENT"
        }
      })
    : 0;

  const activeHomeworks = await prisma.homework.findMany({
    where: { teacherId, schoolId: schoolId!, status: "OPEN" },
    include: {
      class: {
        select: {
          id: true,
          name: true,
          students: { select: { id: true } }
        }
      },
      subject: true,
      submissions: { select: { id: true } }
    },
    orderBy: { sentDate: "desc" },
    take: 5
  });

  const formattedHomework = activeHomeworks.map(hw => {
    const totalStudentsInClass = hw.class?.students.length || 0;
    const submissionsCount = hw.submissions.length;
    const progress = totalStudentsInClass > 0 ? (submissionsCount / totalStudentsInClass) : 0.0;
    return {
      id: hw.id,
      title: hw.title,
      className: hw.class?.name || "",
      subjectName: hw.subject?.name || "",
      progressText: `${submissionsCount}/${totalStudentsInClass} طالب`,
      progress,
      dueDate: hw.dueDate
    };
  });

  res.json({
    success: true,
    data: {
      profile: {
        fullName: teacher.nameAr || teacher.user.fullName,
        photo: teacher.personalPhoto || teacher.photo || null,
        phone: teacher.phone || "",
        email: teacher.email || teacher.user.email || "",
        jobTitle: teacher.jobTitle || teacher.subject || ""
      },
      stats: {
        totalStudents,
        finishedPeriods: `${finishedPeriodsCount}/${todayTimetable.length}`,
        absentStudents: absentStudentsToday
      },
      schedule: todayTimetable.map(slot => ({
        id: slot.id,
        startTime: slot.startTime,
        endTime: slot.endTime,
        subjectName: slot.subject?.name || "مادة غير محددة",
        className: slot.class?.name || "",
        periodNumber: slot.periodNumber,
        isCurrent: false
      })),
      homeworks: formattedHomework
    }
  });
});

/* ══════════════════════════════════════════════════
   TEACHER ↔ CLASS ↔ SUBJECT ASSIGNMENT (Dashboard)
   ══════════════════════════════════════════════════ */

/** GET /teachers/:id/assignments — list all class-subject mappings */
export const getTeacherAssignments = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = req.params.id as string;
  const schoolId = req.schoolId;

  const assignments = await prisma.teacherSubject.findMany({
    where: { teacherId, class: { schoolId: schoolId! } },
    include: {
      subject: { select: { id: true, name: true } },
      class: { select: { id: true, name: true, section: true } }
    }
  });

  res.json({ success: true, data: assignments });
});

/** POST /teachers/:id/assignments — assign teacher to class+subject */
export const assignTeacher = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = req.params.id as string;
  const schoolId = req.schoolId;

  const { subjectId, classId } = z.object({
    subjectId: z.string().min(1),
    classId: z.string().min(1),
  }).parse(req.body);

  // Verify teacher belongs to school
  const teacher = await prisma.teacher.findFirst({ where: { id: teacherId, schoolId: schoolId! } });
  if (!teacher) throw new NotFoundError("Teacher");

  // Verify class belongs to school
  const cls = await prisma.schoolClass.findFirst({ where: { id: classId, schoolId: schoolId! } });
  if (!cls) throw new NotFoundError("Class");

  // Verify subject belongs to school
  const subject = await prisma.subject.findFirst({ where: { id: subjectId, schoolId: schoolId! } });
  if (!subject) throw new NotFoundError("Subject");

  // Check if already assigned
  const existing = await prisma.teacherSubject.findUnique({
    where: { teacherId_subjectId_classId: { teacherId, subjectId, classId } }
  });
  if (existing) throw new ConflictError("Teacher is already assigned to this class and subject.");

  const assignment = await prisma.teacherSubject.create({
    data: { teacherId, subjectId, classId },
    include: {
      subject: { select: { id: true, name: true } },
      class: { select: { id: true, name: true, section: true } }
    }
  });

  getIO().to(`school:${schoolId}`).emit("teacher:assigned", assignment);
  res.status(201).json({ success: true, data: assignment });
});

/** DELETE /teachers/:id/assignments/:assignmentId — unassign */
export const unassignTeacher = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = req.params.id as string;
  const assignmentId = req.params.assignmentId as string;
  const schoolId = req.schoolId;

  const assignment = await prisma.teacherSubject.findFirst({
    where: { id: assignmentId, teacherId, class: { schoolId: schoolId! } }
  });
  if (!assignment) throw new NotFoundError("Assignment");

  await prisma.teacherSubject.delete({ where: { id: assignmentId } });
  getIO().to(`school:${schoolId}`).emit("teacher:unassigned", { teacherId, assignmentId });
  res.json({ success: true });
});

export const getMobileTeacherClasses = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = (req as any).teacherId;
  const schoolId = req.schoolId;

  if (!teacherId) {
    throw new ValidationError("Teacher context is required.");
  }

  const teacherSubjects = await prisma.teacherSubject.findMany({
    where: { teacherId, class: { schoolId: schoolId! } },
    include: {
      class: {
        include: {
          students: {
            select: {
              id: true,
              nameAr: true,
              nameEn: true,
              studentCode: true,
              rollNumber: true,
              photo: true
            },
            orderBy: { nameAr: "asc" }
          }
        }
      },
      subject: true
    }
  });

  const classMap = new Map<string, any>();
  teacherSubjects.forEach(ts => {
    const cls = ts.class;
    if (!classMap.has(cls.id)) {
      classMap.set(cls.id, {
        id: cls.id,
        name: cls.name,
        subject: ts.subject.name,
        studentCount: cls.students.length,
        students: cls.students.map((student, index) => ({
          id: student.id,
          name: student.nameAr || student.nameEn || "طالب",
          number: index + 1,
          avatar: student.photo || "https://images.unsplash.com/photo-1596870230751-ebdfce98ec42?w=80&h=80&fit=crop"
        }))
      });
    }
  });

  res.json({
    success: true,
    data: Array.from(classMap.values())
  });
});

/* ── GET /teachers/mobile/reports ── */
export const getMobileTeacherReports = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = (req as any).teacherId;
  const schoolId = req.schoolId;

  if (!teacherId) {
    throw new ValidationError("Teacher context is required.");
  }

  // Fetch classes assigned to teacher
  const teacherSubjects = await prisma.teacherSubject.findMany({
    where: { teacherId, class: { schoolId: schoolId! } },
    select: { classId: true, class: { select: { name: true } } }
  });
  const classIds = Array.from(new Set(teacherSubjects.map(ts => ts.classId)));

  let attendanceRate = 0;
  
  if (classIds.length > 0) {
    const totalAttendances = await prisma.attendance.count({
      where: { classId: { in: classIds }, schoolId: schoolId!, type: "STUDENT" }
    });
    const presentAttendances = await prisma.attendance.count({
      where: { classId: { in: classIds }, schoolId: schoolId!, type: "STUDENT", status: "PRESENT" }
    });
    if (totalAttendances > 0) {
      attendanceRate = presentAttendances / totalAttendances;
    }
  }

  // Basic mock/calculated data
  res.json({
    success: true,
    data: {
      overview: {
        className: "كافة الفصول الموكلة",
        generalAverage: 85,
        attendanceRate: attendanceRate > 0 ? Math.round(attendanceRate * 100) : 92,
        progress: 12,
      },
      metrics: {
        actualAttendance: attendanceRate > 0 ? attendanceRate : 0.92,
        homeworkSubmissions: 0.85,
        classParticipation: 0.78,
      },
      grades: {
        excellent: 35,
        veryGood: 25,
        good: 20,
        acceptable: 15,
        weak: 5
      }
    }
  });
});

/* ── PUT /teachers/mobile/profile ── */
export const updateMobileTeacherProfile = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = (req as any).teacherId;
  if (!teacherId) {
    throw new ValidationError("Unauthorized: Teacher session not found.");
  }

  const payload = z
    .object({
      phone: z.string().optional().nullable(),
      email: z.string().email().optional().nullable(),
      photo: z.string().optional().nullable(),
    })
    .parse(req.body);

  const updated = await prisma.teacher.update({
    where: { id: teacherId },
    data: {
      phone: payload.phone,
      email: payload.email,
      personalPhoto: payload.photo,
      photo: payload.photo || undefined,
    },
  });

  if (payload.email) {
    await prisma.user.update({
      where: { id: updated.userId },
      data: { email: payload.email },
    });
  }

  res.json({ success: true, data: updated });
});

/* ── POST /teachers/mobile/change-password ── */
export const changeMobileTeacherPassword = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  const teacherId = (req as any).teacherId;
  if (!credentialId || !teacherId) {
    throw new ValidationError("Unauthorized: Session not found.");
  }

  const { newPassword } = z
    .object({
      newPassword: z.string().min(6, "New password must be at least 6 characters")
    })
    .parse(req.body);

  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId }
  });

  if (!credential) {
    throw new NotFoundError("AppCredential");
  }

  const newHash = crypto.createHash("sha256").update(newPassword).digest("hex");

  await prisma.appCredential.update({
    where: { id: credentialId },
    data: {
      passwordHash: newHash,
      plainTextPw: newPassword
    }
  });

  revokeAllSessionsForTeacher(teacherId);

  res.json({ success: true, message: "Password updated successfully." });
});

/* ── GET /teachers/mobile/devices ── */
export const getMobileTeacherDevices = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = (req as any).teacherId;
  const currentToken = (req as any).token;
  if (!teacherId) {
    throw new ValidationError("Unauthorized: Teacher session not found.");
  }

  const sessions = getSessionsForTeacher(teacherId);
  const formatted = sessions.map((s) => ({
    id: s.id,
    deviceName: s.deviceName,
    location: s.location,
    ipAddress: s.ipAddress,
    isActive: s.isActive,
    isCurrent: s.token === currentToken,
    createdAt: s.createdAt,
    lastActiveAt: s.lastActiveAt
  }));

  res.json({ success: true, data: formatted });
});

/* ── POST /teachers/mobile/devices/logout ── */
export const logoutMobileTeacherDevice = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = (req as any).teacherId;
  if (!teacherId) {
    throw new ValidationError("Unauthorized: Teacher session not found.");
  }

  const { sessionId } = z
    .object({
      sessionId: z.string().min(1, "Session ID is required")
    })
    .parse(req.body);

  const success = revokeSessionForTeacher(sessionId, teacherId);
  if (!success) {
    throw new NotFoundError("Device session not found or unauthorized.");
  }

  res.json({ success: true, message: "Device logged out successfully." });
});

/* ── POST /teachers/mobile/devices/logout-all ── */
export const logoutAllOtherTeacherDevices = asyncHandler(async (req: Request, res: Response) => {
  const teacherId = (req as any).teacherId;
  const currentToken = (req as any).token;
  if (!teacherId) {
    throw new ValidationError("Unauthorized: Teacher session not found.");
  }

  const sessions = getSessionsForTeacher(teacherId);
  const currentSession = sessions.find((s) => s.token === currentToken);

  revokeAllSessionsForTeacher(teacherId, currentSession?.id);

  res.json({ success: true, message: "Logged out from all other devices successfully." });
});

/* ── GET /teachers/mobile/social/status ── */
export const getTeacherSocialStatus = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) {
    throw new ValidationError("Unauthorized: Session not found.");
  }

  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId }
  });

  if (!credential) {
    throw new NotFoundError("AppCredential");
  }

  res.json({
    success: true,
    googleLinked: !!credential.googleId,
    googleEmail: credential.googleEmail,
    appleLinked: !!credential.appleId,
    appleEmail: credential.appleEmail
  });
});

/* ── POST /teachers/mobile/social/link ── */
export const linkTeacherSocialAccount = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) {
    throw new ValidationError("Unauthorized: Session not found.");
  }

  const { provider, socialId, email } = z
    .object({
      provider: z.enum(["google", "apple"]),
      socialId: z.string().min(1, "Social ID is required"),
      email: z.string().email("Please provide a valid social email").optional().nullable()
    })
    .parse(req.body);

  const existing = await prisma.appCredential.findFirst({
    where: {
      OR: [
        { googleId: provider === "google" ? socialId : undefined },
        { appleId: provider === "apple" ? socialId : undefined }
      ]
    }
  });

  if (existing) {
    throw new ConflictError("This social account is already linked to another user.");
  }

  await prisma.appCredential.update({
    where: { id: credentialId },
    data: {
      googleId: provider === "google" ? socialId : undefined,
      googleEmail: provider === "google" ? email : undefined,
      appleId: provider === "apple" ? socialId : undefined,
      appleEmail: provider === "apple" ? email : undefined
    }
  });

  res.json({ success: true, message: `${provider === "google" ? "Google" : "Apple"} account linked successfully.` });
});

/* ── POST /teachers/mobile/social/unlink ── */
export const unlinkTeacherSocialAccount = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) {
    throw new ValidationError("Unauthorized: Session not found.");
  }

  const { provider } = z
    .object({
      provider: z.enum(["google", "apple"])
    })
    .parse(req.body);

  await prisma.appCredential.update({
    where: { id: credentialId },
    data: {
      googleId: provider === "google" ? null : undefined,
      googleEmail: provider === "google" ? null : undefined,
      appleId: provider === "apple" ? null : undefined,
      appleEmail: provider === "apple" ? null : undefined
    }
  });

  res.json({ success: true, message: `${provider === "google" ? "Google" : "Apple"} account unlinked successfully.` });
});
