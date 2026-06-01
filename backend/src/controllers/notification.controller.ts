import type { Request, Response } from "express";
import { NotificationChannel, NotificationType, PaymentMethod, type Role } from "@prisma/client";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { ForbiddenError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";

async function getRealUserId(req: Request): Promise<string | null> {
  const role = req.user?.role;
  const id = req.user?.id; // AppCredential.id or User.id

  if (!id) return null;

  // If role is admin/superadmin, req.user.id is already the User.id
  if (["SUPER_ADMIN", "SCHOOL_ADMIN", "ADMIN"].includes(role ?? "")) {
    return id;
  }

  // Resolve custom AppCredential to real User.id
  const cred = await prisma.appCredential.findUnique({
    where: { id },
    include: { teacher: true, parent: true, student: true }
  });

  if (cred) {
    if (cred.teacher) return cred.teacher.userId;
    if (cred.parent) return cred.parent.userId;
    if (cred.student) return cred.student.userId;
  }

  return id;
}

export const listNotifications = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { onlyMine, unread } = req.query;
  const role = req.user?.role ?? "STUDENT";
  const realUserId = await getRealUserId(req);

  const where: any = { schoolId };

  if (!["SUPER_ADMIN", "SCHOOL_ADMIN", "ADMIN"].includes(role)) {
    // Non-admins can only see general school notifications or their own targeted notifications
    where.OR = [
      { recipientId: realUserId },
      { recipientId: null }
    ];
  } else {
    if (onlyMine === "1" || onlyMine === "true") {
      where.recipientId = realUserId;
    }
  }

  if (unread === "1" || unread === "true") {
    where.readAt = null;
  }

  const data = await prisma.notification.findMany({
    where,
    orderBy: { sentAt: "desc" },
    take: 200,
  });

  res.json({ success: true, data });
});

export const markNotificationRead = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const id = req.params.id as string;
  const realUserId = await getRealUserId(req);

  const notification = await prisma.notification.findFirst({ where: { id: id as string, schoolId } });
  if (!notification) return res.json({ success: true });

  // Only recipient can mark their own, admins can mark system notifications
  if (notification.recipientId && notification.recipientId !== realUserId) {
    throw new ForbiddenError();
  }

  await prisma.notification.update({
    where: { id: id as string },
    data: { readAt: new Date() },
  });

  res.json({ success: true });
});

export const sendManualNotification = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const role = (req.user?.role ?? "STUDENT") as Role;
  if (!["SUPER_ADMIN", "SCHOOL_ADMIN", "ADMIN"].includes(role)) {
    throw new ForbiddenError("Only admins can send notifications.");
  }

  const payload = z
    .object({
      recipientId: z.string().optional().nullable(),
      title: z.string().min(2),
      message: z.string().min(2),
      type: z.nativeEnum(NotificationType).optional(),
      channel: z.nativeEnum(NotificationChannel).optional(),
    })
    .parse(req.body);

  const hasRecipient = !!(payload.recipientId && payload.recipientId.trim() !== "");

  const notification = await prisma.notification.create({
    data: {
      schoolId,
      recipientId: hasRecipient ? payload.recipientId : null,
      title: payload.title,
      message: payload.message,
      type: payload.type ?? NotificationType.GENERAL,
      channel: payload.channel ?? NotificationChannel.SYSTEM,
    },
  });

  const io = getIO();
  if (hasRecipient) {
    io.to(`user:${payload.recipientId}`).emit("notification:new", notification);
  } else {
    io.to(`school:${schoolId}`).emit("notification:system", notification);
  }

  res.status(201).json({ success: true, data: notification });
});

export const deleteNotification = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const role = (req.user?.role ?? "STUDENT") as Role;
  const id = req.params.id as string;

  const notification = await prisma.notification.findFirst({ where: { id, schoolId } });
  if (!notification) {
    return res.status(404).json({ success: false, message: "Notification not found" });
  }

  // Only admins can delete notifications
  if (!["SUPER_ADMIN", "SCHOOL_ADMIN", "ADMIN"].includes(role)) {
    throw new ForbiddenError("Only admins can delete notifications.");
  }

  await prisma.notification.delete({ where: { id } });

  res.json({ success: true });
});

export async function createNotification(params: {
  schoolId: string;
  recipientId: string | null | undefined;
  title: string;
  message: string;
  type?: NotificationType;
  channel?: NotificationChannel;
}) {
  const notification = await prisma.notification.create({
    data: {
      schoolId: params.schoolId,
      recipientId: params.recipientId || null,
      title: params.title,
      message: params.message,
      type: params.type ?? NotificationType.GENERAL,
      channel: params.channel ?? NotificationChannel.SYSTEM,
    },
  });

  const io = getIO();
  if (params.recipientId) {
    io.to(`user:${params.recipientId}`).emit("notification:new", notification);
  } else {
    io.to(`school:${params.schoolId}`).emit("notification:system", notification);
  }

  return notification;
}
