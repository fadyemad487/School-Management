import { Request, Response } from "express";
import jwt from "jsonwebtoken";
import { prisma } from "../config/prisma";
import { supabaseAdmin } from "../config/supabase";
import { env } from "../config/env";
import { Role } from "@prisma/client";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { getIO } from "../config/websocket";
import crypto from "crypto";
import axios from "axios";
import { addSession, revokeAllSessionsForParent, revokeAllSessionsForTeacher } from "../utils/sessionStore";
import {
  AuthenticationError,
  ConflictError,
  ValidationError,
  NotFoundError
} from "../utils/AppError";

/* ── Validation Schemas ── */

const loginSchema = z.object({
  email: z.string().email("Please enter a valid email address."),
  password: z.string().min(6, "Password must be at least 6 characters.")
});

const registerSchema = z.object({
  name: z.string().min(2, "School name must be at least 2 characters."),
  email: z.string().email("Please enter a valid email address."),
  password: z.string().min(6, "Password must be at least 6 characters."),
  schoolId: z.string().min(3, "School ID must be at least 3 characters.")
});

/* ── POST /auth/login ── */
export const login = asyncHandler(async (req: Request, res: Response) => {
  const { email, password } = loginSchema.parse(req.body);

  // Step 1: Check if email exists in our database
  const existingUser = await prisma.user.findUnique({ 
    where: { email },
    include: {
      student: { include: { credentials: { select: { isActive: true } } } },
      parent: { include: { credentials: { select: { isActive: true } } } }
    }
  });

  if (!existingUser) {
    throw new AuthenticationError(
      "The email address you entered isn't connected to an account.",
      "EMAIL_NOT_FOUND",
      "email"
    );
  }

  // Step 1.5: Check if account is active (for students and parents)
  const studentCred = existingUser.student?.credentials?.[0];
  const parentCred = existingUser.parent?.credentials?.[0];

  if ((studentCred && !studentCred.isActive) || (parentCred && !parentCred.isActive)) {
    throw new AuthenticationError(
      "Your account has been disabled. Please contact administration regarding your dues.",
      "ACCOUNT_DISABLED",
      "email"
    );
  }

  // Step 2: Try Supabase auth — if password is wrong, Supabase returns error
  const { data, error: signInError } = await supabaseAdmin.auth.signInWithPassword({
    email,
    password
  });

  if (signInError) {
    // Supabase returns "Invalid login credentials" for wrong password
    // We make it field-specific
    throw new AuthenticationError(
      "The password you've entered is incorrect.",
      "WRONG_PASSWORD",
      "password"
    );
  }

  // Step 3: Emit live logout signal to other active sessions
  getIO().to(`user:${existingUser.id}`).emit("SESSION_TERMINATED", {
    message: "New login detected. You have been logged out."
  });

  // Step 4: Update currentSessionId in our database for single-session enforcement
  const decoded = jwt.decode(data.session?.access_token || "") as any;
  const sessionId = decoded?.session_id;

  await prisma.user.update({
    where: { id: existingUser.id },
    data: { currentSessionId: (sessionId as string) || null }
  });

  // Step 4: Return user data + session
  res.json({
    success: true,
    data: {
      user: {
        id: existingUser.id,
        email: existingUser.email,
        fullName: existingUser.fullName,
        role: existingUser.role,
        schoolId: existingUser.schoolId
      },
      session: data.session
    }
  });
});

/* ── POST /auth/register ── */
export const register = asyncHandler(async (req: Request, res: Response) => {
  const { name, email, password, schoolId } = registerSchema.parse(req.body);

  // Step 1: Check if School ID (code) already exists
  const existingSchool = await prisma.school.findUnique({
    where: { code: schoolId }
  });
  if (existingSchool) {
    throw new ConflictError(
      "This School ID is already registered. Each school must have a unique ID.",
      "schoolId"
    );
  }

  // Step 2: Check if School Name already exists
  const existingName = await prisma.school.findUnique({
    where: { name }
  });
  if (existingName) {
    throw new ConflictError(
      "This Institution Name is already registered.",
      "name"
    );
  }

  // Step 3: Check if email already exists (User email)
  const existingUser = await prisma.user.findUnique({ where: { email } });
  if (existingUser) {
    throw new ConflictError(
      "An account with this email already exists.",
      "email"
    );
  }

  // Step 4: Check if School email already exists (if different from user email)
  const existingSchoolEmail = await prisma.school.findUnique({ where: { email } });
  if (existingSchoolEmail) {
    throw new ConflictError(
      "A school with this email is already registered.",
      "email"
    );
  }

  // Step 3: Create Supabase auth user
  const { error: signUpError } = await supabaseAdmin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: name,
      school_id: schoolId
    }
  });

  if (signUpError) {
    throw new ValidationError(signUpError.message);
  }

  // Step 4: Determine role (SUPER_ADMIN if email matches)
  const role = email.toLowerCase() === env.superAdminEmail.toLowerCase()
    ? Role.SUPER_ADMIN
    : Role.ADMIN;

  // Step 5: Create School + User in a transaction
  const result = await prisma.$transaction(async (tx) => {
    const school = await tx.school.create({
      data: {
        code: schoolId,
        name: name,
        email: email
      }
    });

    const user = await tx.user.create({
      data: {
        email,
        fullName: name,
        role,
        schoolId: role === Role.SUPER_ADMIN ? null : school.id
      }
    });

    return { school, user };
  });

  // Step 6: Sign in the user to get a session
  const { data: sessionData, error: signInError } = await supabaseAdmin.auth.signInWithPassword({
    email,
    password
  });

  if (signInError) {
    throw new AuthenticationError("Failed to initialize session after registration.");
  }

  // Step 7: Update currentSessionId for the user (Now that transaction is committed)
  const accessToken = sessionData?.session?.access_token;
  const decoded = accessToken ? jwt.decode(accessToken) as any : null;
  const sessionId = decoded?.session_id;

  await prisma.user.update({
    where: { id: result.user.id },
    data: { currentSessionId: (sessionId as string) || null }
  });

  // Step 8: Emit live signals
  getIO().to(`user:${result.user.id}`).emit("SESSION_TERMINATED", {
    message: "Session re-initialized."
  });

  res.status(201).json({
    success: true,
    data: {
      user: {
        id: result.user.id,
        email: result.user.email,
        fullName: result.user.fullName,
        role: result.user.role,
        schoolId: result.user.schoolId
      },
      school: {
        id: result.school.id,
        code: result.school.code,
        name: result.school.name
      },
      session: sessionData?.session || null
    }
  });
});

/* ── GET /auth/check-school-id/:code ── */
export const checkSchoolId = asyncHandler(async (req: Request, res: Response) => {
  const { code } = req.params;

  if (!code || (code as string).length < 3) {
    throw new ValidationError("School ID must be at least 3 characters.", "schoolId");
  }

  const existing = await prisma.school.findUnique({
    where: { code: code as string }
  });

  res.json({
    success: true,
    data: {
      available: !existing,
      code
    }
  });
});

/* ── GET /auth/check-school-name/:name ── */
export const checkSchoolName = asyncHandler(async (req: Request, res: Response) => {
  const { name } = req.params;

  if (!name || (name as string).length < 2) {
    throw new ValidationError("School name must be at least 2 characters.", "name");
  }

  const existing = await prisma.school.findUnique({
    where: { name: name as string }
  });

  res.json({
    success: true,
    data: {
      available: !existing,
      name
    }
  });
});

/* ── GET /auth/check-school-email/:email ── */
export const checkSchoolEmail = asyncHandler(async (req: Request, res: Response) => {
  const { email } = req.params;

  if (!email || !(email as string).includes("@")) {
    throw new ValidationError("Invalid email address.", "email");
  }

  // Check both User and School tables
  const [userExisting, schoolExisting] = await Promise.all([
    prisma.user.findUnique({ where: { email: email as string } }),
    prisma.school.findUnique({ where: { email: email as string } })
  ]);

  res.json({
    success: true,
    data: {
      available: !userExisting && !schoolExisting,
      email
    }
  });
});

/* ── GET /auth/me ── */
export const getMe = asyncHandler(async (req: Request, res: Response) => {
  const user = req.user;
  if (!user) {
    throw new AuthenticationError("Not authenticated.", "NOT_AUTHENTICATED");
  }

  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
    include: {
      school: {
        select: {
          id: true,
          code: true,
          name: true,
          email: true,
          phone: true
        }
      }
    }
  });

  if (!dbUser) {
    throw new NotFoundError("User");
  }

  // If SUPER_ADMIN, also return school count
  let schoolCount: number | undefined;
  if (dbUser.role === Role.SUPER_ADMIN) {
    schoolCount = await prisma.school.count();
  }

  res.json({
    success: true,
    data: {
      id: dbUser.id,
      email: dbUser.email,
      fullName: dbUser.fullName,
      role: dbUser.role,
      school: dbUser.school,
      ...(schoolCount !== undefined && { totalSchools: schoolCount })
    }
  });
});

/* ── POST /auth/webhook (legacy — kept for backward compat) ── */
export const handleWebhook = asyncHandler(async (req: Request, res: Response) => {
  const { email, fullName, schoolId, role } = req.body;

  if (!email || !schoolId) {
    throw new ValidationError("Email and School ID are required.");
  }

  // Ensure school exists
  let school = await prisma.school.findUnique({ where: { code: schoolId as string } });
  if (!school) {
    school = await prisma.school.create({
      data: { code: schoolId as string, name: schoolId as string }
    });
  }

  // Determine role
  const userRole = (email as string).toLowerCase() === env.superAdminEmail.toLowerCase()
    ? Role.SUPER_ADMIN
    : (role as Role) || Role.ADMIN;

  // Upsert user
  const user = await prisma.user.upsert({
    where: { email: email as string },
    update: { fullName, schoolId: userRole === Role.SUPER_ADMIN ? null : school.id, role: userRole },
    create: { email: email as string, fullName, schoolId: userRole === Role.SUPER_ADMIN ? null : school.id, role: userRole }
  });

  res.json({ success: true, data: user });
});

const mobileLoginSchema = z.object({
  loginId: z.string().min(1, "Login ID or Email is required"),
  password: z.string().min(6, "Password must be at least 6 characters")
});

/* ── POST /auth/mobile/login ── */
export const mobileLogin = asyncHandler(async (req: Request, res: Response) => {
  const { loginId, password } = mobileLoginSchema.parse(req.body);

  // 1. Search for matching AppCredential
  const credential = await prisma.appCredential.findFirst({
    where: {
      OR: [
        { loginId: loginId },
        { loginEmail: loginId }
      ]
    },
    include: {
      school: {
        select: {
          id: true,
          code: true,
          name: true,
          email: true,
          phone: true
        }
      },
      parent: {
        select: {
          id: true,
          userId: true,
          nameAr: true,
          phone: true,
          whatsapp: true,
          photo: true
        }
      },
      student: {
        select: {
          id: true,
          userId: true,
          nameAr: true,
          studentCode: true,
          rollNumber: true,
          points: true,
          game1Lvl: true,
          game2Lvl: true,
          game3Lvl: true,
          game4Lvl: true,
          game5Lvl: true,
          photo: true
        }
      },
      teacher: {
        select: {
          id: true,
          userId: true,
          nameAr: true,
          photo: true,
          personalPhoto: true
        }
      },
      driver: {
        select: {
          id: true,
          nameAr: true,
          phone: true,
          photo: true
        }
      },
      supervisor: {
        select: {
          id: true,
          nameAr: true,
          phone: true
        }
      }
    }
  });

  if (!credential) {
    throw new AuthenticationError(
      "The Login ID or Password you entered is incorrect.",
      "INVALID_CREDENTIALS",
      "loginId"
    );
  }

  // 2. Check if account is active
  if (!credential.isActive) {
    throw new AuthenticationError(
      "Your account has been disabled. Please contact administration regarding your dues.",
      "ACCOUNT_DISABLED",
      "loginId"
    );
  }

  // 3. Verify password (SHA-256)
  const passwordHash = crypto.createHash("sha256").update(password).digest("hex");
  if (passwordHash !== credential.passwordHash) {
    throw new AuthenticationError(
      "The password you've entered is incorrect.",
      "WRONG_PASSWORD",
      "password"
    );
  }

  // 4. Generate JWT Token signed with supabaseJwtSecret
  const token = jwt.sign(
    {
      id: credential.id,
      loginId: credential.loginId,
      role: credential.role,
      schoolId: credential.schoolId,
      parentId: credential.parentId,
      studentId: credential.studentId,
      teacherId: credential.teacherId,
      driverId: credential.driverId,
      supervisorId: credential.supervisorId
    },
    env.supabaseJwtSecret,
    { expiresIn: "30d" }
  );

  // 5. Update lastLoginAt
  await prisma.appCredential.update({
    where: { id: credential.id },
    data: { lastLoginAt: new Date() }
  });

  // 5.5. If PARENT or TEACHER, record the device session in our session store
  if ((credential.role === "PARENT" && credential.parentId) || (credential.role === "TEACHER" && credential.teacherId)) {
    const rawUserAgent = req.headers["user-agent"] || "";
    let deviceName = (req.headers["x-device-name"] as string) || "";
    if (!deviceName) {
      if (rawUserAgent.includes("iPhone")) {
        deviceName = "iPhone";
      } else if (rawUserAgent.includes("Android")) {
        deviceName = "Android Device";
      } else if (rawUserAgent.includes("iPad")) {
        deviceName = "iPad";
      } else if (rawUserAgent.includes("Macintosh")) {
        deviceName = "MacBook / iMac";
      } else {
        deviceName = "Mobile Device";
      }
    }

    const ipAddress = (req.headers["x-forwarded-for"] as string) || req.ip || "127.0.0.1";
    let location = "الفيوم، مصر"; // Standard hometown default for simulator/localhost testing

    // Retrieve physical location dynamically if it is a public IP
    try {
      const cleanIp = ipAddress.split(",")[0].trim();
      if (
        cleanIp !== "127.0.0.1" &&
        cleanIp !== "::1" &&
        !cleanIp.startsWith("192.168.") &&
        !cleanIp.startsWith("10.") &&
        !cleanIp.startsWith("172.16.")
      ) {
        const geoRes = await axios.get(`http://ip-api.com/json/${cleanIp}?lang=ar`);
        if (geoRes.data && geoRes.data.status === "success") {
          const city = geoRes.data.city || "";
          const country = geoRes.data.country || "";
          if (city && country) {
            location = `${city}، ${country}`;
          }
        }
      }
    } catch (_) {
      // Fallback to default
    }

    addSession({
      id: crypto.randomUUID(),
      parentId: credential.parentId || null,
      teacherId: credential.teacherId || null,
      credentialId: credential.id,
      deviceName,
      location,
      ipAddress,
      token,
      isActive: true
    });
  }

  // 6. Return user profile + school branding data
  let realUserId = credential.id;
  if (credential.teacher) realUserId = credential.teacher.userId;
  else if (credential.parent) realUserId = credential.parent.userId;
  else if (credential.student) realUserId = credential.student.userId;

  res.json({
    success: true,
    data: {
      token,
      user: {
        id: realUserId,
        loginId: credential.loginId,
        loginEmail: credential.loginEmail,
        role: credential.role,
        fullName: credential.parent?.nameAr || credential.student?.nameAr || credential.teacher?.nameAr || credential.driver?.nameAr || credential.supervisor?.nameAr || "User",
        parentId: credential.parentId,
        studentId: credential.studentId,
        points: credential.student?.points ?? 0,
        game1Lvl: credential.student?.game1Lvl ?? 1,
        game2Lvl: credential.student?.game2Lvl ?? 1,
        game3Lvl: credential.student?.game3Lvl ?? 1,
        game4Lvl: credential.student?.game4Lvl ?? 1,
        game5Lvl: credential.student?.game5Lvl ?? 1,
        teacherId: credential.teacherId,
        driverId: credential.driverId,
        supervisorId: credential.supervisorId,
        photo: credential.parent?.photo || credential.student?.photo || credential.teacher?.personalPhoto || credential.teacher?.photo || credential.driver?.photo || null
      },
      school: credential.school
    }
  });
});

/* ── POST /auth/mobile/social-login ── */
export const mobileSocialLogin = asyncHandler(async (req: Request, res: Response) => {
  const { provider, socialId, email } = z
    .object({
      provider: z.enum(["google", "apple"]),
      socialId: z.string().min(1, "Social ID is required"),
      email: z.string().email("Please enter a valid email address.").optional().nullable()
    })
    .parse(req.body);

  // 1. Search for matching AppCredential
  const credential = await prisma.appCredential.findFirst({
    where: {
      OR: [
        { googleId: provider === "google" ? socialId : undefined },
        { appleId: provider === "apple" ? socialId : undefined }
      ]
    },
    include: {
      school: true,
      parent: true,
      teacher: true,
      student: true,
      driver: true,
      supervisor: true
    }
  });

  if (!credential) {
    throw new AuthenticationError(
      "هذا الحساب غير مربوط بأي حساب مستخدم. يرجى تسجيل الدخول أولاً باستخدام معرّف المدرسة وربط حسابك من الإعدادات.",
      "SOCIAL_ACCOUNT_NOT_LINKED",
      "social"
    );
  }

  if (!credential.isActive) {
    throw new AuthenticationError(
      "Your account has been locked or suspended by the administrator.",
      "ACCOUNT_LOCKED",
      "social"
    );
  }

  // 2. Generate JWT Token signed with supabaseJwtSecret
  const token = jwt.sign(
    {
      id: credential.id,
      loginId: credential.loginId,
      role: credential.role,
      schoolId: credential.schoolId,
      parentId: credential.parentId,
      studentId: credential.studentId,
      teacherId: credential.teacherId,
      driverId: credential.driverId,
      supervisorId: credential.supervisorId
    },
    env.supabaseJwtSecret,
    { expiresIn: "30d" }
  );

  // 3. Update lastLoginAt
  await prisma.appCredential.update({
    where: { id: credential.id },
    data: { lastLoginAt: new Date() }
  });

  // 4. Record device session in session store if Parent or Teacher
  if ((credential.role === "PARENT" && credential.parentId) || (credential.role === "TEACHER" && credential.teacherId)) {
    const rawUserAgent = req.headers["user-agent"] || "";
    let deviceName = (req.headers["x-device-name"] as string) || "";
    if (!deviceName) {
      if (rawUserAgent.includes("iPhone")) {
        deviceName = "iPhone";
      } else if (rawUserAgent.includes("Android")) {
        deviceName = "Android Device";
      } else {
        deviceName = "Mobile Device";
      }
    }

    const ipAddress = (req.headers["x-forwarded-for"] as string) || req.ip || "127.0.0.1";
    let location = "الفيوم، مصر";

    try {
      const cleanIp = ipAddress.split(",")[0].trim();
      if (
        cleanIp !== "127.0.0.1" &&
        cleanIp !== "::1" &&
        !cleanIp.startsWith("192.168.") &&
        !cleanIp.startsWith("10.") &&
        !cleanIp.startsWith("172.16.")
      ) {
        const geoRes = await axios.get(`http://ip-api.com/json/${cleanIp}?lang=ar`);
        if (geoRes.data && geoRes.data.status === "success") {
          const city = geoRes.data.city || "";
          const country = geoRes.data.country || "";
          if (city && country) {
            location = `${city}، ${country}`;
          }
        }
      }
    } catch (_) {}

    addSession({
      id: crypto.randomUUID(),
      parentId: credential.parentId || null,
      teacherId: credential.teacherId || null,
      credentialId: credential.id,
      deviceName,
      location,
      ipAddress,
      token,
      isActive: true
    });
  }

  let realUserId = credential.id;
  if (credential.teacher) realUserId = credential.teacher.userId;
  else if (credential.parent) realUserId = credential.parent.userId;
  else if (credential.student) realUserId = credential.student.userId;

  res.json({
    success: true,
    data: {
      token,
      user: {
        id: realUserId,
        loginId: credential.loginId,
        loginEmail: credential.loginEmail,
        role: credential.role,
        fullName: credential.parent?.nameAr || credential.student?.nameAr || credential.teacher?.nameAr || credential.driver?.nameAr || credential.supervisor?.nameAr || "User",
        parentId: credential.parentId,
        studentId: credential.studentId,
        teacherId: credential.teacherId,
        driverId: credential.driverId,
        supervisorId: credential.supervisorId,
        photo: credential.parent?.photo || credential.student?.photo || credential.teacher?.personalPhoto || credential.teacher?.photo || credential.driver?.photo || null
      },
      school: credential.school
    }
  });
});

/* ── POST /auth/mobile/change-password ── */
export const changeMobilePassword = asyncHandler(async (req: Request, res: Response) => {
  const credentialId = req.userId; // The AppCredential ID attached by requireMobileAuth
  if (!credentialId) {
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
      plainTextPw: newPassword
    }
  });

  // 4. If parent or teacher, revoke sessions
  if (credential.parentId) {
    revokeAllSessionsForParent(credential.parentId);
  } else if (credential.teacherId) {
    revokeAllSessionsForTeacher(credential.teacherId);
  }

  res.json({ success: true, message: "Password updated successfully." });
});

