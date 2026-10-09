import type { NextFunction, Request, Response } from "express";
import { supabaseAdmin } from "../config/supabase";
import { prisma } from "../config/prisma";
import { env } from "../config/env";
import jwt from "jsonwebtoken";
import { logger } from "../utils/logger";

export async function requireAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith("Bearer ") ? authHeader.split(" ")[1] : null;

  if (!token) {
    res.status(401).json({ success: false, message: "Missing token" });
    return;
  }

  try {
    try {
      // 1. Try to verify the token as a custom AppCredential JWT token first
      const decoded = jwt.verify(token, env.supabaseJwtSecret) as any;
      if (decoded && decoded.id) {
        req.user = {
          id: decoded.id,
          supabaseId: "", // Custom credentials users do not have a Supabase native record
          email: decoded.loginId || "",
          role: decoded.role,
          schoolId: decoded.schoolId || null
        };
        req.userId = decoded.id;
        if (decoded.schoolId) req.schoolId = decoded.schoolId;
        
        // Attach role-specific IDs
        if (decoded.teacherId) (req as any).teacherId = decoded.teacherId;
        if (decoded.parentId) (req as any).parentId = decoded.parentId;
        if (decoded.studentId) (req as any).studentId = decoded.studentId;
        if (decoded.driverId) (req as any).driverId = decoded.driverId;
        if (decoded.supervisorId) (req as any).supervisorId = decoded.supervisorId;
        
        next();
        return;
      }
    } catch (jwtErr) {
      // Not a valid custom JWT, fall through to Supabase token verification
    }

    // 2. Fallback to Supabase User Token
    const { data: { user: authUser }, error: authError } = await supabaseAdmin.auth.getUser(token);

    if (authError || !authUser) {
      logger.authEvent("failed", undefined, req.ip);
      logger.error("Supabase Auth Error", authError);
      res.status(401).json({ success: false, message: "Unauthorized: Invalid or expired token" });
      return;
    }

    // Collect all candidate emails from authUser, identities, and metadata
    const candidateEmails = Array.from(
      new Set(
        [
          authUser.email,
          ...(authUser.identities?.map((id: any) => id.identity_data?.email) || []),
          authUser.user_metadata?.email
        ]
          .filter(Boolean)
          .map((e: string) => e.toLowerCase())
      )
    );

    if (candidateEmails.length === 0) {
      res.status(401).json({ success: false, message: "Invalid token: Email missing" });
      return;
    }

    const dbUser = await prisma.user.findFirst({ 
      where: { 
        email: { in: candidateEmails, mode: "insensitive" }
      },
      include: {
        teacher: true,
        parent: true,
        student: true,
        driver: true,
        supervisor: true,
      }
    });
    
    if (!dbUser) {
      res.status(401).json({ success: false, message: "User not found in local database. Please sync your account." });
      return;
    }

    // A matching email alone is not proof that this is the same Supabase
    // account. Once known, the stable Supabase user ID is the authority.
    if (dbUser.supabaseId && dbUser.supabaseId !== authUser.id) {
      // Clean up orphaned temporary OAuth account from Supabase Auth immediately
      try {
        await supabaseAdmin.auth.admin.deleteUser(authUser.id);
        logger.info(`[AUTH] Cleaned up orphaned OAuth user ${authUser.id} (${authUser.email})`);
      } catch (cleanupErr) {
        logger.error("[AUTH] Error cleaning up orphaned OAuth user", cleanupErr as Error);
      }

      res.status(401).json({
        success: false,
        code: "OAUTH_ACCOUNT_NOT_LINKED",
        message: "This social account is not linked to your EduControl account. Sign in with email and password, then link it again from Settings."
      });
      return;
    }

    // Existing accounts created before supabaseId was introduced are bound the
    // first time their already-authorized session reaches the API.
    if (!dbUser.supabaseId) {
      await prisma.user.update({
        where: { id: dbUser.id },
        data: { supabaseId: authUser.id }
      });
      dbUser.supabaseId = authUser.id;
    }

    const signInProvider = typeof authUser.app_metadata?.provider === "string"
      ? authUser.app_metadata.provider.toLowerCase()
      : "";
    const isExternalProvider = ["google", "facebook", "apple"].includes(signInProvider);

    // Matching an OAuth email must never bypass an account that was explicitly
    // unlinked in Settings. The block is stored with the EduControl user, not
    // only on a Supabase identity, so it also covers a newly-created OAuth user
    // with the same email address.
    if (
      isExternalProvider &&
      dbUser.disabledOAuthProviders.includes(signInProvider) &&
      dbUser.supabaseId !== authUser.id
    ) {
      // Clean up orphaned temporary OAuth account from Supabase Auth immediately
      try {
        await supabaseAdmin.auth.admin.deleteUser(authUser.id);
        logger.info(`[AUTH] Cleaned up unlinked OAuth user ${authUser.id} (${authUser.email})`);
      } catch (cleanupErr) {
        logger.error("[AUTH] Error cleaning up unlinked OAuth user", cleanupErr as Error);
      }

      res.status(401).json({
        success: false,
        code: "OAUTH_PROVIDER_UNLINKED",
        message: "This sign-in provider is no longer linked to your EduControl account. Sign in with email and password, then link it again from Settings."
      });
      return;
    }

    req.user = {
      id: dbUser.id,
      supabaseId: authUser.id,
      email: dbUser.email,
      role: dbUser.role,
      schoolId: dbUser.schoolId
    };
    req.userId = dbUser.id;
    if (dbUser.schoolId) {
      req.schoolId = dbUser.schoolId;
    }

    // Attach role-specific IDs from database relations
    if (dbUser.teacher) (req as any).teacherId = dbUser.teacher.id;
    if (dbUser.parent) (req as any).parentId = dbUser.parent.id;
    if (dbUser.student) (req as any).studentId = dbUser.student.id;
    if (dbUser.driver) (req as any).driverId = dbUser.driver.id;
    if (dbUser.supervisor) (req as any).supervisorId = dbUser.supervisor.id;

    next();
  } catch (err) {
    logger.error("Authentication middleware error", err as Error, { ip: req.ip });
    res.status(401).json({ success: false, message: "Unauthorized: System authentication error" });
  }
}

// Alias for convenience
export const auth = requireAuth;
