import type { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { ConflictError, NotFoundError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";
import { supabaseAdmin } from "../config/supabase";

export const getMySchool = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const school = await prisma.school.findUnique({
    where: { id: schoolId },
    select: {
      id: true,
      code: true,
      name: true,
      email: true,
      phone: true,
      address: true,
      logo: true,
      stamp: true,
      website: true,
      principalName: true,
      updatedAt: true,
    },
  });

  if (!school) throw new NotFoundError("School");
  res.json({ success: true, data: school });
});

export const updateMySchool = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const currentUser = req.user!;

  const payload = z
    .object({
      name: z.string().min(2).optional(),
      email: z.string().email().optional().nullable(),
      logo: z.string().url().optional().nullable(),
    })
    .parse(req.body);

  if (payload.name) {
    const existingName = await prisma.school.findFirst({
      where: { name: payload.name, NOT: { id: schoolId } },
      select: { id: true },
    });
    if (existingName) throw new ConflictError("This Institution Name is already registered.", "name");
  }

  // Handle Email Update with Uniqueness Check and Auth Sync
  if (payload.email !== undefined) {
    const newEmail = payload.email ?? null;
    
    if (newEmail && newEmail !== currentUser.email) {
      // 1. Check if email exists in School table (other than this school)
      const existingSchoolEmail = await prisma.school.findFirst({
        where: { email: newEmail, NOT: { id: schoolId } },
        select: { id: true },
      });
      if (existingSchoolEmail) throw new ConflictError("A school with this email is already registered.", "email");

      // 2. Check if email exists in User table (other than the current user)
      const existingUserEmail = await prisma.user.findFirst({
        where: { email: newEmail, NOT: { id: currentUser.id } },
        select: { id: true },
      });
      if (existingUserEmail) throw new ConflictError("A user with this email is already registered.", "email");

      // 3. Update Supabase Auth email (Syncing Login Identity)
      const { error: authUpdateError } = await supabaseAdmin.auth.admin.updateUserById(
        currentUser.supabaseId,
        { email: newEmail, email_confirm: true }
      );
      if (authUpdateError) {
        throw new ConflictError(`Failed to update authentication: ${authUpdateError.message}`, "email");
      }

      // 4. Update local User record to match new email
      await prisma.user.update({
        where: { id: currentUser.id },
        data: { email: newEmail }
      });
    }
  }

  const school = await prisma.school.update({
    where: { id: schoolId },
    data: {
      name: payload.name,
      email: payload.email === undefined ? undefined : payload.email,
      logo: payload.logo === undefined ? undefined : payload.logo,
    },
    select: {
      id: true,
      code: true,
      name: true,
      email: true,
      logo: true,
      updatedAt: true,
    },
  });

  getIO().to(`school:${schoolId}`).emit("school:updated", school);
  res.json({ success: true, data: school });
});

