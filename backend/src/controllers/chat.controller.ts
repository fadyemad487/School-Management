import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { z } from "zod";
import { getIO } from "../config/websocket";
import { ValidationError, NotFoundError } from "../utils/AppError";

const sid = (req: Request) => {
  if (!req.schoolId) throw new ValidationError("School context required");
  return req.schoolId as string;
};

const uid = (req: Request) => {
  if (!req.userId) throw new ValidationError("User context required");
  return req.userId as string;
};

// Helper to get entity ID based on user role
const getEntityId = async (userId: string, userRole?: string) => {
  let entityId = userId;

  if (userRole === "PARENT") {
    const parent = await prisma.parent.findFirst({
      where: { userId },
    });
    if (parent) entityId = parent.id;
  } else if (userRole === "TEACHER") {
    const teacher = await prisma.teacher.findFirst({
      where: { userId },
    });
    if (teacher) entityId = teacher.id;
  } else if (userRole === "SUPER_ADMIN") {
    // For super admin, use user ID directly
    entityId = userId;
  }

  return entityId;
};

// Helper to get user ID from entity ID
const getUserIdFromEntityId = async (entityId: string) => {
  // Try parent
  const parent = await prisma.parent.findUnique({
    where: { id: entityId },
    select: { userId: true },
  });
  if (parent) return parent.userId;

  // Try teacher
  const teacher = await prisma.teacher.findUnique({
    where: { id: entityId },
    select: { userId: true },
  });
  if (teacher) return teacher.userId;

  // Default to entityId (for direct user-to-user chats)
  return entityId;
};

/** GET /api/chat/conversations - List all chats for current user */
export const getConversations = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = sid(req);
  const userId = uid(req);
  const userRole = (req as any).user?.role || req.user?.role;

  // Get entity ID based on role
  const entityId = await getEntityId(userId, userRole);

  const conversations = await prisma.conversation.findMany({
    where: {
      schoolId,
      OR: [
        { participant1Id: entityId },
        { participant2Id: entityId }
      ]
    },
    orderBy: { lastMessageAt: "desc" },
    include: {
      messages: {
        orderBy: { createdAt: "desc" },
        take: 1
      }
    }
  });

  // Hydrate with user details
  const hydrated = await Promise.all(conversations.map(async (conv) => {
    const otherId = conv.participant1Id === entityId ? conv.participant2Id : conv.participant1Id;
    
    // Get user ID from entity ID
    const otherUserId = await getUserIdFromEntityId(otherId);
    
    const otherUser = await prisma.user.findUnique({
      where: { id: otherUserId },
      select: { id: true, fullName: true, email: true, role: true }
    });
    return {
      ...conv,
      otherUser,
      lastMessage: conv.messages[0] || null
    };
  }));

  res.json({ success: true, data: hydrated });
});

/** GET /api/chat/messages/:conversationId - Get messages for a chat */
export const getMessages = asyncHandler(async (req: Request, res: Response) => {
  const conversationId = req.params.conversationId as string;
  const userId = uid(req);
  const userRole = (req as any).user?.role || req.user?.role;

  // Get entity ID based on role
  const entityId = await getEntityId(userId, userRole);

  const conv = await prisma.conversation.findUnique({
    where: { id: conversationId }
  });

  if (!conv || (conv.participant1Id !== entityId && conv.participant2Id !== entityId)) {
    throw new NotFoundError("Conversation not found");
  }

  const messages = await prisma.message.findMany({
    where: { conversationId },
    orderBy: { createdAt: "asc" }
  });

  // Mark as read
  await prisma.message.updateMany({
    where: {
      conversationId,
      senderId: { not: entityId },
      readAt: null
    },
    data: { readAt: new Date() }
  });

  res.json({ success: true, data: messages });
});

/** POST /api/chat/send - Send a message */
export const sendMessage = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = sid(req);
  const userId = uid(req);
  const userRole = (req as any).user?.role || req.user?.role;
  
  const { receiverId, content, conversationId: existingId } = z.object({
    receiverId: z.string().min(1).optional(),
    conversationId: z.string().min(1).optional(),
    content: z.string().min(1)
  }).parse(req.body);

  // Get entity ID based on role
  const senderEntityId = await getEntityId(userId, userRole);

  let convId = existingId;

  if (!convId && receiverId) {
    // receiverId from frontend is entity ID, need to verify
    const receiverEntityId = receiverId;
    
    if (senderEntityId === receiverEntityId) throw new ValidationError("Cannot chat with yourself");
    
    // Sort IDs to ensure unique pair identification
    const participants = [senderEntityId, receiverEntityId].sort();
    const p1 = participants[0];
    const p2 = participants[1];

    const conv = await prisma.conversation.upsert({
      where: { 
        participant1Id_participant2Id: { 
          participant1Id: p1, 
          participant2Id: p2 
        } 
      },
      update: { lastMessageAt: new Date() },
      create: {
        schoolId,
        participant1Id: p1,
        participant2Id: p2,
        lastMessageAt: new Date()
      }
    });
    convId = conv.id;
  }

  if (!convId) throw new ValidationError("Conversation target missing");

  const msg = await prisma.message.create({
    data: {
      conversationId: convId,
      senderId: senderEntityId,
      content
    }
  });

  // Update conversation lastMessageAt
  await prisma.conversation.update({
    where: { id: convId },
    data: { lastMessageAt: new Date() }
  });

  // Emit to receiver
  const conv = await prisma.conversation.findUnique({ where: { id: convId } });
  const otherEntityId = conv!.participant1Id === senderEntityId ? conv!.participant2Id : conv!.participant1Id;
  
  // Convert entity ID to user ID for WebSocket emit
  const otherUserId = await getUserIdFromEntityId(otherEntityId);
  
  const io = getIO();
  io.to(`user:${otherUserId}`).emit("chat:message", msg);
  io.to(`user:${userId}`).emit("chat:message", msg);

  res.status(201).json({ success: true, data: msg });
});

/** GET /api/chat/contacts - Search users to start a chat */
export const getContacts = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = sid(req);
  const userId = uid(req);
  const query = z.string().optional().parse(req.query.q) || "";

  // Search for parents and teachers
  const parents = await prisma.parent.findMany({
    where: {
      schoolId,
      OR: [
        { user: { fullName: { contains: query, mode: "insensitive" } } },
        { user: { email: { contains: query, mode: "insensitive" } } }
      ]
    },
    take: 20,
    include: { user: { select: { id: true, fullName: true, role: true, email: true } } }
  });

  const teachers = await prisma.teacher.findMany({
    where: {
      schoolId,
      OR: [
        { user: { fullName: { contains: query, mode: "insensitive" } } },
        { user: { email: { contains: query, mode: "insensitive" } } }
      ]
    },
    take: 20,
    include: { user: { select: { id: true, fullName: true, role: true, email: true } } }
  });

  // Convert to format expected by frontend
  const contacts = [
    ...parents.map(p => ({ ...p.user, id: p.id, entityId: p.id })),
    ...teachers.map(t => ({ ...t.user, id: t.id, entityId: t.id }))
  ];

  res.json({ success: true, data: contacts });
});
