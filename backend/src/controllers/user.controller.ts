import type { Request, Response } from "express";
import { Role } from "@prisma/client";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { ForbiddenError, NotFoundError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";

export const listUsers = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { q } = req.query;
  const query = typeof q === "string" ? q.trim() : "";

  const where: any = { schoolId };
  if (query) {
    where.OR = [
      { email: { contains: query, mode: "insensitive" } },
      { fullName: { contains: query, mode: "insensitive" } },
    ];
  }

  const data = await prisma.user.findMany({
    where,
    select: {
      id: true,
      email: true,
      fullName: true,
      role: true,
      schoolId: true,
      createdAt: true,
      updatedAt: true,
    },
    orderBy: { createdAt: "desc" },
  });

  res.json({ success: true, data });
});

export const updateUserRole = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const actorRole = req.user?.role ?? Role.STUDENT;
  if (!["SUPER_ADMIN", "SCHOOL_ADMIN", "ADMIN"].includes(actorRole)) {
    throw new ForbiddenError("Only admins can update user roles.");
  }

  const id = req.params.id as string;
  const payload = z.object({ role: z.nativeEnum(Role) }).parse(req.body);

  const existing = await prisma.user.findFirst({ where: { id: id as string, schoolId } });
  if (!existing) throw new NotFoundError("User");

  const data = await prisma.user.update({
    where: { id: id as string },
    data: { role: payload.role },
    select: { id: true, email: true, fullName: true, role: true, schoolId: true, updatedAt: true },
  });

  res.json({ success: true, data });
});

