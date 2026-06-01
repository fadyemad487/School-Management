import type { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";
import { isSessionActive, updateSessionActivity } from "../utils/sessionStore";

export interface MobileRequestUser {
  id: string; // AppCredential.id
  loginId: string;
  role: "STUDENT" | "TEACHER" | "PARENT" | "DRIVER";
  schoolId: string;
  parentId?: string | null;
  studentId?: string | null;
  teacherId?: string | null;
  driverId?: string | null;
}

export function requireMobileAuth(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith("Bearer ") ? authHeader.split(" ")[1] : null;

  if (!token) {
    res.status(401).json({ success: false, message: "Authentication token missing" });
    return;
  }

  try {
    const decoded = jwt.verify(token, env.supabaseJwtSecret) as MobileRequestUser;
    
    // Check if the device session is active in our session store (for PARENT and TEACHER)
    if ((decoded.role === "PARENT" && decoded.parentId) || (decoded.role === "TEACHER" && decoded.teacherId)) {
      if (!isSessionActive(token)) {
        res.status(401).json({ success: false, message: "Unauthorized: Session has been terminated or revoked" });
        return;
      }
      // Update last active timestamp
      updateSessionActivity(token);
    }
    
    // Attach to request for dashboard/tenant compatibility
    req.user = {
      id: decoded.id,
      email: decoded.loginId,
      role: decoded.role as any,
      schoolId: decoded.schoolId,
      supabaseId: decoded.id // Placeholder to satisfy TypeScript strict user definition
    };
    req.userId = decoded.id;
    req.schoolId = decoded.schoolId;

    // Attach specific entity links
    (req as any).parentId = decoded.parentId;
    (req as any).studentId = decoded.studentId;
    (req as any).teacherId = decoded.teacherId;
    (req as any).driverId = decoded.driverId;
    (req as any).token = token; // Keep token in request for device identification

    next();
  } catch (err) {
    console.error("Mobile Auth Error:", err);
    res.status(401).json({ success: false, message: "Unauthorized: Invalid or expired token" });
  }
}
