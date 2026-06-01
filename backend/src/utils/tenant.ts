import type { Request } from "express";
import { ValidationError } from "./AppError";

/** Require schoolId — throws if missing */
export function requireSid(req: Request): string {
  if (!req.schoolId) throw new ValidationError("School context required");
  return req.schoolId;
}

