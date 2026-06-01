import { Role } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

export function roleGuard(roles: Role[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user?.role || !roles.includes(req.user.role)) {
      res.status(403).json({ success: false, message: "Forbidden" });
      return;
    }
    next();
  };
}
