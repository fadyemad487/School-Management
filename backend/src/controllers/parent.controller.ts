import type { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import crypto from "crypto";
import { NotFoundError, ValidationError, ConflictError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";
import { getSessionsForParent, revokeSession, revokeAllSessionsForParent } from "../utils/sessionStore";

export const listParents = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { q } = req.query;

  const query = typeof q === "string" ? q.trim() : "";
  const where: any = { schoolId };
  if (query) {
    where.OR = [
      { nameAr: { contains: query, mode: "insensitive" } },
      { phone: { contains: query, mode: "insensitive" } },
      { nationalId: { contains: query, mode: "insensitive" } },
      { email: { contains: query, mode: "insensitive" } },
      { user: { email: { contains: query, mode: "insensitive" } } },
      { fatherOf: { some: { user: { fullName: { contains: query, mode: "insensitive" } } } } },
      { fatherOf: { some: { nameEn: { contains: query, mode: "insensitive" } } } },
      { fatherOf: { some: { nameAr: { contains: query, mode: "insensitive" } } } },
      { fatherOf: { some: { studentCode: { contains: query, mode: "insensitive" } } } },
      { motherOf: { some: { user: { fullName: { contains: query, mode: "insensitive" } } } } },
      { motherOf: { some: { nameEn: { contains: query, mode: "insensitive" } } } },
      { motherOf: { some: { nameAr: { contains: query, mode: "insensitive" } } } },
      { motherOf: { some: { studentCode: { contains: query, mode: "insensitive" } } } },
    ];
  }

  const data = await prisma.parent.findMany({
    where,
    include: { 
      user: true,
      credentials: { select: { loginId: true, plainTextPw: true } },
      fatherOf: { include: { user: true, grade: true } },
      motherOf: { include: { user: true, grade: true } },
      guardianOf: { include: { user: true, grade: true } }
    },
    orderBy: { id: "desc" },
  });

  res.json({ success: true, data });
});

export const updateParent = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const id = req.params.id as string;

  const payload = z
    .object({
      nameAr: z.string().optional().nullable(),
      nationalId: z.string().optional().nullable(),
      occupation: z.string().optional().nullable(),
      employer: z.string().optional().nullable(),
      phone: z.string().optional().nullable(),
      whatsapp: z.string().optional().nullable(),
      email: z.string().email().optional().nullable(),
      address: z.string().optional().nullable(),
      relationship: z.string().optional().nullable(),
    })
    .parse(req.body);

  const existing = await prisma.parent.findFirst({ where: { id: id as string, schoolId } });
  if (!existing) throw new NotFoundError("Parent");

  const data = await prisma.parent.update({
    where: { id: id as string },
    data: payload,
    include: { user: true },
  });

  res.json({ success: true, data });
});

export const attachParentToStudent = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { studentId } = req.params;
  const payload = z
    .object({
      parentId: z.string().min(1),
      role: z.enum(["FATHER", "MOTHER", "GUARDIAN"]),
    })
    .parse(req.body);

  const student = await prisma.student.findFirst({ where: { id: studentId as string, schoolId } });
  if (!student) throw new NotFoundError("Student");

  const parent = await prisma.parent.findFirst({ where: { id: payload.parentId, schoolId } });
  if (!parent) throw new NotFoundError("Parent");

  if (payload.role === "FATHER") {
    if (student.fatherId && student.fatherId !== payload.parentId) throw new ValidationError("Student already has a father linked.");
    await prisma.student.update({ where: { id: student.id }, data: { fatherId: payload.parentId } });
  } else if (payload.role === "MOTHER") {
    if (student.motherId && student.motherId !== payload.parentId) throw new ValidationError("Student already has a mother linked.");
    await prisma.student.update({ where: { id: student.id }, data: { motherId: payload.parentId } });
  } else {
    if (student.guardianId && student.guardianId !== payload.parentId) throw new ValidationError("Student already has a guardian linked.");
    await prisma.student.update({ where: { id: student.id }, data: { guardianId: payload.parentId } });
  }

  res.json({ success: true });
});

/* ── GET /parents/mobile/dashboard ── */
export const getMobileParentDashboard = asyncHandler(async (req: Request, res: Response) => {
  const parentId = (req as any).parentId;
  if (!parentId) {
    throw new ValidationError("Unauthorized: Parent session not found.");
  }

  // 1. Fetch parent details with children, including deep class/teacher/bus relations
  const parent = await prisma.parent.findUnique({
    where: { id: parentId },
    include: {
      user: true,
      fatherOf: {
        include: {
          class: {
            include: {
              teacher: {
                include: {
                  user: true
                }
              }
            }
          },
          grade: true,
          busAssignment: {
            include: {
              bus: {
                include: {
                  driver: true,
                  supervisor: true
                }
              },
              route: true
            }
          }
        }
      },
      motherOf: {
        include: {
          class: {
            include: {
              teacher: {
                include: {
                  user: true
                }
              }
            }
          },
          grade: true,
          busAssignment: {
            include: {
              bus: {
                include: {
                  driver: true,
                  supervisor: true
                }
              },
              route: true
            }
          }
        }
      },
      guardianOf: {
        include: {
          class: {
            include: {
              teacher: {
                include: {
                  user: true
                }
              }
            }
          },
          grade: true,
          busAssignment: {
            include: {
              bus: {
                include: {
                  driver: true,
                  supervisor: true
                }
              },
              route: true
            }
          }
        }
      }
    }
  });

  if (!parent) {
    throw new NotFoundError("Parent not found.");
  }

  // 2. Combine all children unique list
  const uniqueChildrenMap = new Map<string, any>();
  const addChildren = (children: any[]) => {
    for (const c of children) {
      if (!uniqueChildrenMap.has(c.id)) {
        uniqueChildrenMap.set(c.id, c);
      }
    }
  };

  addChildren(parent.fatherOf);
  addChildren(parent.motherOf);
  addChildren(parent.guardianOf);

  const childrenList = Array.from(uniqueChildrenMap.values());

  // 3. For each child, find today's attendance record and calculate stats
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const enrichedChildren = await Promise.all(
    childrenList.map(async (child) => {
      const attendance = await prisma.attendance.findFirst({
        where: {
          studentId: child.id,
          date: {
            gte: today,
            lt: tomorrow
          }
        }
      });

      // Format Class Name nicely (e.g. "الصف الخامس • فصل أ")
      const className = child.class 
        ? `${child.class.name}`
        : "غير محدد";

      const gradeName = child.grade 
        ? `${child.grade.name}` 
        : "غير محدد";

      // 1. Calculate Attendance Rate & Fetch Logs (last 60 days)
      const totalAtt = await prisma.attendance.count({
        where: { studentId: child.id, type: "STUDENT" }
      });
      const presentAtt = await prisma.attendance.count({
        where: { studentId: child.id, type: "STUDENT", status: { in: ["PRESENT", "LATE"] } }
      });
      const attendanceRate = totalAtt > 0 ? `${Math.round((presentAtt / totalAtt) * 100)}%` : "100%";

      const attendanceRecords = await prisma.attendance.findMany({
        where: { studentId: child.id, type: "STUDENT" },
        orderBy: { date: "desc" },
        take: 60
      });

      const attendanceLogs = attendanceRecords.map(r => ({
        id: r.id,
        date: r.date.toISOString(),
        status: r.status,
        timeIn: r.timeIn || "-",
        timeOut: r.timeOut || "-",
        notes: r.notes || ""
      }));

      // 2. Fetch Behavior/Conduct status
      const latestBehavior = await prisma.behaviorReport.findFirst({
        where: { studentId: child.id },
        orderBy: { createdAt: "desc" }
      });
      let conduct = "ممتاز";
      if (latestBehavior) {
        if (latestBehavior.type === "POSITIVE") conduct = "ممتاز";
        else if (latestBehavior.type === "FOLLOWUP") conduct = "جيد جداً";
        else if (latestBehavior.type === "NEGATIVE") conduct = "مقبول";
        else conduct = latestBehavior.type;
      }

      // 3. Fetch homeworks assigned to the child's class
      let homeworks: any[] = [];
      let pendingHomeworksCount = 0;
      if (child.classId) {
        const rawHomeworks = await prisma.homework.findMany({
          where: { classId: child.classId },
          include: {
            subject: true,
            submissions: {
              where: { studentId: child.id }
            }
          },
          orderBy: { sentDate: "desc" }
        });

        homeworks = rawHomeworks.map((hw) => {
          const sub = hw.submissions[0];
          return {
            id: hw.id,
            title: hw.title,
            description: hw.description || "",
            attachments: hw.attachments || "",
            sentDate: hw.sentDate.toISOString(),
            dueDate: hw.dueDate ? hw.dueDate.toISOString() : null,
            maxScore: hw.maxScore || 100,
            subjectNameAr: hw.subject?.name || "مادة عامة",
            subjectNameEn: hw.subject?.name || "General",
            isSubmitted: !!sub,
            score: sub?.score ?? null,
            submittedAt: sub?.submittedAt ? sub.submittedAt.toISOString() : null,
            teacherComment: sub?.teacherComment || "",
            fileUrl: sub?.fileUrl || ""
          };
        });

        pendingHomeworksCount = homeworks.filter(hw => !hw.isSubmitted).length;
      }

      // 4. Fetch ExamResult records and Calculate GPA
      const examResults = await prisma.examResult.findMany({
        where: { studentId: child.id, approved: true }
      });
      let gpa = "4.00";
      let avgPercentage = 100;
      let gradeLetter = "A";
      let gradeLetterAr = "امتياز";
      if (examResults.length > 0) {
        const validScores = examResults.filter(r => r.score !== null && r.score !== undefined);
        if (validScores.length > 0) {
          const totalScore = validScores.reduce((sum, r) => sum + r.score!, 0);
          avgPercentage = Math.round(totalScore / validScores.length);
          gpa = ((avgPercentage / 100) * 4.0).toFixed(2);
          
          if (avgPercentage >= 95) { gradeLetter = "A+"; gradeLetterAr = "امتياز مرتفع"; }
          else if (avgPercentage >= 90) { gradeLetter = "A"; gradeLetterAr = "امتياز"; }
          else if (avgPercentage >= 85) { gradeLetter = "B+"; gradeLetterAr = "جيد جداً مرتفع"; }
          else if (avgPercentage >= 80) { gradeLetter = "B"; gradeLetterAr = "جيد جداً"; }
          else if (avgPercentage >= 75) { gradeLetter = "C+"; gradeLetterAr = "جيد مرتفع"; }
          else if (avgPercentage >= 70) { gradeLetter = "C"; gradeLetterAr = "جيد"; }
          else if (avgPercentage >= 60) { gradeLetter = "D"; gradeLetterAr = "مقبول"; }
          else { gradeLetter = "F"; gradeLetterAr = "ضعيف"; }
        }
      } else {
        // Default GPA values if no exam results are present
        gpa = "3.92";
        gradeLetter = "A-";
        gradeLetterAr = "امتياز";
      }

      // 5. Fetch Homeroom Teacher details
      const homeroomTeacher = child.class?.teacher
        ? (child.class.teacher.nameAr || child.class.teacher.user?.fullName || "غير محدد")
        : "غير محدد";

      // 6. Fetch Room location details
      const roomNumber = child.class?.roomNumber
        ? `قاعة ${child.class.roomNumber}`
        : "غير محدد";

      // 7. Fetch Bus route details
      let busRoute = "لا يوجد";
      let busDetails: any = null;
      if (child.busAssignment) {
        const routeName = child.busAssignment.route?.name || "بدون مسار";
        const plateNum = child.busAssignment.bus?.plateNumber || child.busAssignment.bus?.number || "";
        busRoute = `${routeName} ${plateNum ? `(${plateNum})` : ""}`.trim();

        if (child.busAssignment.bus) {
          const busObj = child.busAssignment.bus;
          const routeObj = child.busAssignment.route;
          busDetails = {
            busId: busObj.id,
            number: busObj.number,
            plateNumber: busObj.plateNumber || "",
            routeName: routeObj?.name || "بدون مسار",
            pickupPoint: child.busAssignment.pickupPoint || "",
            dropoffPoint: child.busAssignment.dropoffPoint || "",
            driver: busObj.driver ? {
              id: busObj.driver.id,
              name: busObj.driver.nameAr || busObj.driver.name || "غير محدد",
              phone: busObj.driver.phone || "",
              photo: busObj.driver.photo || "",
            } : null,
            supervisor: busObj.supervisor ? {
              id: busObj.supervisor.id,
              name: busObj.supervisor.name || "غير محدد",
              phone: busObj.supervisor.phone || "",
              photo: busObj.supervisor.personalPhoto || "",
            } : null
          };
        }
      }

      // 8. Academic Performance grades
      const studentGrades = await prisma.examResult.findMany({
        where: { studentId: child.id },
        include: {
          exam: {
            include: {
              subject: true
            }
          }
        }
      });
      const academicPerformance = studentGrades.map((g) => {
        const subjectNameAr = g.exam.subject?.name || "مادة عامة";
        const score = g.score !== null ? g.score : 0;
        const maxScore = g.exam.maxScore || 100;
        const progress = maxScore > 0 ? score / maxScore : 0;
        return {
          subjectNameAr,
          subjectNameEn: g.exam.subject?.name || "General",
          score,
          maxScore,
          progress
        };
      });

      const finalGrades = academicPerformance.length > 0 ? academicPerformance : [
        { subjectNameAr: "اللغة العربية", subjectNameEn: "Arabic Language", score: 95, maxScore: 100, progress: 0.95 },
        { subjectNameAr: "الرياضيات", subjectNameEn: "Mathematics", score: 90, maxScore: 100, progress: 0.90 },
        { subjectNameAr: "العلوم العامة", subjectNameEn: "General Science", score: 88, maxScore: 100, progress: 0.88 }
      ];

      return {
        id: child.id,
        nameAr: child.nameAr,
        nameEn: child.nameEn || child.nameAr,
        gender: child.gender, // "MALE" or "FEMALE"
        rollNumber: child.rollNumber,
        studentCode: child.studentCode || child.rollNumber || child.id.substring(0, 8),
        className,
        gradeName,
        attendanceRate,
        attendanceLogs,
        homeworks,
        pendingHomeworksCount,
        conduct,
        gpa,
        gradeLetter,
        gradeLetterAr,
        homeroomTeacher,
        roomNumber,
        busRoute,
        bus: busDetails,
        academicPerformance: finalGrades,
        image: child.photo
          ? child.photo
          : (child.gender === "FEMALE"
            ? "https://images.unsplash.com/photo-1605648916319-cf082f7524a1?w=100&h=100&fit=crop&crop=face"
            : "https://images.unsplash.com/photo-1596870230751-ebdfce98ec42?w=100&h=100&fit=crop&crop=face"),
        attendance: attendance
          ? {
              status: attendance.status, // PRESENT, ABSENT, LATE, EXCUSED, EMERGENCY
              timeIn: attendance.timeIn || "08:00",
              timeOut: attendance.timeOut,
              notes: attendance.notes
            }
          : null
      };
    })
  );

  // Fetch school announcements for this parent's children
  const schoolId = parent.schoolId || (childrenList[0] && childrenList[0].schoolId);
  let announcementsList: any[] = [];
  if (schoolId) {
    const classIds = childrenList.map(c => c.classId).filter(Boolean) as string[];
    const gradeIds = childrenList.map(c => c.gradeId).filter(Boolean) as string[];

    const rawAnnouncements = await prisma.announcement.findMany({
      where: { schoolId },
      orderBy: { createdAt: "desc" },
      take: 50
    });

    announcementsList = rawAnnouncements.filter(ann => {
      const aud = ann.audience || "all";
      if (aud === "all" || aud === "parents") {
        return true;
      }
      
      const parts = aud.split(",").map(p => p.trim());
      const matchesClass = parts.some(p => classIds.includes(p) || p === `class:${p}`);
      if (matchesClass) return true;

      if (ann.targetClass && classIds.includes(ann.targetClass)) return true;
      if (ann.targetGrade && gradeIds.includes(ann.targetGrade)) return true;

      return false;
    });

    announcementsList = announcementsList.slice(0, 15);
  }

  // 4. Formulate today's Arabic date details
  const daysInArabic = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"];
  const monthsInArabic = [
    "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
    "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
  ];
  const now = new Date();
  const dayName = daysInArabic[now.getDay()];
  const todayFormatted = `${now.getDate()} ${monthsInArabic[now.getMonth()]} ${now.getFullYear()}`;

  res.json({
    success: true,
    data: {
      parentName: parent.nameAr,
      parentPhoto: (parent as any).photo,
      parentPhone: parent.phone,
      parentEmail: parent.email || (parent.user ? parent.user.email : ""),
      dayName,
      todayFormatted,
      children: enrichedChildren,
      announcements: announcementsList
    }
  });
});

/* ── PUT /parents/mobile/profile ── */
export const updateMobileParentProfile = asyncHandler(async (req: Request, res: Response) => {
  const parentId = (req as any).parentId;
  if (!parentId) {
    throw new ValidationError("Unauthorized: Parent session not found.");
  }

  const payload = z
    .object({
      phone: z.string().optional().nullable(),
      email: z.string().email().optional().nullable(),
      photo: z.string().optional().nullable(),
    })
    .parse(req.body);

  const updated = await prisma.parent.update({
    where: { id: parentId },
    data: payload,
  });

  if (payload.email) {
    await prisma.user.update({
      where: { id: updated.userId },
      data: { email: payload.email },
    });
  }

  res.json({ success: true, data: updated });
});

/* ── GET /parents/mobile/devices ── */
export const getMobileParentDevices = asyncHandler(async (req: Request, res: Response) => {
  const parentId = (req as any).parentId;
  const currentToken = (req as any).token;
  if (!parentId) {
    throw new ValidationError("Unauthorized: Parent session not found.");
  }

  const sessions = getSessionsForParent(parentId);
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

/* ── POST /parents/mobile/devices/logout ── */
export const logoutMobileParentDevice = asyncHandler(async (req: Request, res: Response) => {
  const parentId = (req as any).parentId;
  if (!parentId) {
    throw new ValidationError("Unauthorized: Parent session not found.");
  }

  const { sessionId } = z
    .object({
      sessionId: z.string().min(1, "Session ID is required")
    })
    .parse(req.body);

  const success = revokeSession(sessionId, parentId);
  if (!success) {
    throw new NotFoundError("Device session not found or unauthorized.");
  }

  res.json({ success: true, message: "Device logged out successfully." });
});

/* ── POST /parents/mobile/devices/logout-all ── */
export const logoutAllOtherMobileDevices = asyncHandler(async (req: Request, res: Response) => {
  const parentId = (req as any).parentId;
  const currentToken = (req as any).token;
  if (!parentId) {
    throw new ValidationError("Unauthorized: Parent session not found.");
  }

  // Find current session ID
  const sessions = getSessionsForParent(parentId);
  const currentSession = sessions.find((s) => s.token === currentToken);

  revokeAllSessionsForParent(parentId, currentSession?.id);

  res.json({ success: true, message: "Logged out from all other devices successfully." });
});

/* ── POST /parents/mobile/change-password ── */
export const changeMobileParentPassword = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId; // The AppCredential ID attached by requireMobileAuth
  const parentId = (req as any).parentId;
  if (!credentialId || !parentId) {
    throw new ValidationError("Unauthorized: Session not found.");
  }

  const { newPassword } = z
    .object({
      newPassword: z.string().min(6, "New password must be at least 6 characters")
    })
    .parse(req.body);

  // 1. Fetch AppCredential
  const credential = await prisma.appCredential.findUnique({
    where: { id: credentialId }
  });

  if (!credential) {
    throw new NotFoundError("AppCredential");
  }

  // 2. Hash new password
  const newHash = crypto.createHash("sha256").update(newPassword).digest("hex");

  // 3. Update password hash and plainTextPw in database
  await prisma.appCredential.update({
    where: { id: credentialId },
    data: {
      passwordHash: newHash,
      plainTextPw: newPassword // Sync to parent credentials shown in admin dashboard
    }
  });

  // 4. Revoke all active sessions for this parent (force re-login on all devices)
  revokeAllSessionsForParent(parentId);

  res.json({ success: true, message: "Password updated successfully." });
});

/* ── GET /parents/mobile/social/status ── */
export const getParentSocialStatus = asyncHandler(async (req: Request, res: Response) => {
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

/* ── POST /parents/mobile/social/link ── */
export const linkParentSocialAccount = asyncHandler(async (req: Request, res: Response) => {
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

  // Check if this social account is already linked to another user
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

  // Update AppCredential
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

/* ── POST /parents/mobile/social/unlink ── */
export const unlinkParentSocialAccount = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId;
  if (!credentialId) {
    throw new ValidationError("Unauthorized: Session not found.");
  }

  const { provider } = z
    .object({
      provider: z.enum(["google", "apple"])
    })
    .parse(req.body);

  // Update AppCredential (set to null)
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


