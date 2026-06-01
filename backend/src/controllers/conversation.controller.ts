import type { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { NotFoundError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";
import { createNotification } from "./notification.controller";

export const getConversations = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const userId = (req as any).userId;
  const userRole = req.user?.role;

  console.log('🔍 [getConversations] User ID:', userId, 'Role:', userRole, 'School ID:', schoolId);

  let conversations;
  let currentEntityId: string | null = null;

  if (userRole === "PARENT") {
    const parentId = (req as any).parentId;
    if (!parentId) {
      console.log('❌ [getConversations] No parentId found for PARENT');
      return res.json({ success: true, data: [] });
    }
    currentEntityId = parentId;

    conversations = await prisma.conversation.findMany({
      where: {
        schoolId,
        OR: [{ participant1Id: parentId }, { participant2Id: parentId }],
      },
      include: {
        messages: {
          orderBy: { createdAt: "desc" },
          take: 1,
        },
      },
      orderBy: { lastMessageAt: "desc" },
    });
  } else if (userRole === "TEACHER") {
    const teacherId = (req as any).teacherId;
    if (!teacherId) {
      console.log('❌ [getConversations] No teacherId found for TEACHER');
      return res.json({ success: true, data: [] });
    }
    currentEntityId = teacherId;

    conversations = await prisma.conversation.findMany({
      where: {
        schoolId,
        OR: [{ participant1Id: teacherId }, { participant2Id: teacherId }],
      },
      include: {
        messages: {
          orderBy: { createdAt: "desc" },
          take: 1,
        },
      },
      orderBy: { lastMessageAt: "desc" },
    });
  } else {
    conversations = await prisma.conversation.findMany({
      where: { schoolId },
      include: {
        messages: {
          orderBy: { createdAt: "desc" },
          take: 1,
        },
      },
      orderBy: { lastMessageAt: "desc" },
    });
  }

  // Enrich conversations with participant details
  const enrichedConversations = await Promise.all(
    conversations.map(async (conv) => {
      const otherParticipantId =
        currentEntityId && conv.participant1Id === currentEntityId ? conv.participant2Id : conv.participant1Id;

      // Try to find the other participant in different tables
      const parent = await prisma.parent.findUnique({
        where: { id: otherParticipantId },
        include: { user: true },
      });

      const teacher = await prisma.teacher.findUnique({
        where: { id: otherParticipantId },
        include: { user: true },
      });

      // Also check if it's a school admin (User with SCHOOL_ADMIN role)
      const user = await prisma.user.findUnique({
        where: { id: otherParticipantId },
        include: { school: true },
      });

      let participantName = "Unknown";
      let participantType = "UNKNOWN";
      let participantImage = null;

      if (parent) {
        participantName = parent.user.fullName;
        participantType = "PARENT";
        participantImage = parent.photo;
      } else if (teacher) {
        participantName = teacher.user.fullName;
        participantType = "TEACHER";
        participantImage = teacher.photo;
      } else if (user && (user.role === "SCHOOL_ADMIN" || user.role === "ADMIN")) {
        // For school admins, use school name and logo
        participantName = user.school?.name || user.fullName || "إدارة المدرسة";
        participantType = user.role;
        participantImage = user.school?.logo;
      }

      // Count unread messages
      const unreadCount = await prisma.message.count({
        where: {
          conversationId: conv.id,
          senderId: { not: currentEntityId || userId },
          readAt: null,
        },
      });

      return {
        ...conv,
        participantName,
        participantType,
        participantImage,
        unreadCount,
      };
    })
  );

  console.log('✅ [getConversations] Total conversations:', enrichedConversations.length);
  res.json({ success: true, data: enrichedConversations });
});

export const getMessages = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const conversationId = req.params.id as string;
  const userId = (req as any).userId;
  const userRole = req.user?.role;

  const conversation = await prisma.conversation.findFirst({
    where: { id: conversationId, schoolId },
  });

  if (!conversation) throw new NotFoundError("Conversation");

  // Get current user's entity ID based on role
  let currentEntityId = userId;

  if (userRole === "PARENT") {
    const parentId = (req as any).parentId;
    if (!parentId) {
      console.log('❌ [getMessages] No parentId found for PARENT');
      return res.status(400).json({ success: false, message: "Parent not found" });
    }
    currentEntityId = parentId;
  } else if (userRole === "TEACHER") {
    const teacherId = (req as any).teacherId;
    if (!teacherId) {
      console.log('❌ [getMessages] No teacherId found for TEACHER');
      return res.status(400).json({ success: false, message: "Teacher not found" });
    }
    currentEntityId = teacherId;
  }

  // Mark messages as read
  await prisma.message.updateMany({
    where: {
      conversationId,
      senderId: { not: currentEntityId },
      readAt: null,
    },
    data: { readAt: new Date() },
  });

  const messages = await prisma.message.findMany({
    where: { conversationId },
    orderBy: { createdAt: "asc" },
  });

  res.json({ success: true, data: messages });
});

export const sendMessage = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const conversationId = req.params.id as string;
  const userId = (req as any).userId;
  const userRole = req.user?.role;

  console.log('🔍 [sendMessage] User ID:', userId, 'Role:', userRole, 'Conversation ID:', conversationId);

  const payload = z
    .object({
      content: z.string().min(1),
    })
    .parse(req.body);

  // Get current user's entity ID based on role
  let senderEntityId = userId;

  if (userRole === "PARENT") {
    const parentId = (req as any).parentId;
    if (!parentId) {
      console.log('❌ [sendMessage] No parentId found for PARENT');
      return res.status(400).json({ success: false, message: "Parent not found" });
    }
    senderEntityId = parentId;
  } else if (userRole === "TEACHER") {
    const teacherId = (req as any).teacherId;
    if (!teacherId) {
      console.log('❌ [sendMessage] No teacherId found for TEACHER');
      return res.status(400).json({ success: false, message: "Teacher not found" });
    }
    senderEntityId = teacherId;
  }

  const conversation = await prisma.conversation.findFirst({
    where: { id: conversationId, schoolId },
  });

  if (!conversation) throw new NotFoundError("Conversation");

  const message = await prisma.message.create({
    data: {
      conversationId,
      senderId: senderEntityId,
      content: payload.content,
    },
  });

  // Update conversation's lastMessageAt
  await prisma.conversation.update({
    where: { id: conversationId },
    data: { lastMessageAt: new Date() },
  });

  // Emit WebSocket event
  const recipientId =
    conversation.participant1Id === senderEntityId
      ? conversation.participant2Id
      : conversation.participant1Id;

  console.log('🔍 [sendMessage] Recipient ID:', recipientId, 'Sender Entity ID:', senderEntityId);

  // Find recipient's User ID for WebSocket emit
  let recipientUserId = null;

  const parent = await prisma.parent.findUnique({
    where: { id: recipientId },
  });

  const teacher = await prisma.teacher.findUnique({
    where: { id: recipientId },
  });

  if (parent) {
    recipientUserId = parent.userId;
  } else if (teacher) {
    recipientUserId = teacher.userId;
  }

  if (recipientUserId) {
    getIO().to(`user:${recipientUserId}`).emit("message:new", message);
  }
  getIO().to(`school:${schoolId}`).emit("conversation:updated", conversationId);

  // Send notification
  const sender = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (sender && recipientUserId) {
    await createNotification({
      schoolId,
      recipientId: recipientUserId,
      title: "💬 رسالة جديدة",
      message: `${sender.fullName}: ${payload.content.substring(0, 50)}...`,
      type: "GENERAL",
      channel: "SYSTEM",
    });
  }

  res.status(201).json({ success: true, data: message });
});

export const createConversation = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const userId = (req as any).userId;
  const userRole = req.user?.role;

  console.log('🔍 [createConversation] User ID:', userId, 'Role:', userRole, 'School ID:', schoolId);

  const payload = z
    .object({
      recipientId: z.string().min(1),
      recipientType: z.enum(["PARENT", "TEACHER", "SCHOOL_ADMIN"]),
    })
    .parse(req.body);

  // Get current user's entity ID based on role
  let currentUserId = userId;

  if (userRole === "PARENT") {
    const parentId = (req as any).parentId;
    if (!parentId) {
      console.log('❌ [createConversation] No parentId found for PARENT');
      return res.status(400).json({ success: false, message: "Parent not found" });
    }
    currentUserId = parentId;
  } else if (userRole === "TEACHER") {
    const teacherId = (req as any).teacherId;
    if (!teacherId) {
      console.log('❌ [createConversation] No teacherId found for TEACHER');
      return res.status(400).json({ success: false, message: "Teacher not found" });
    }
    currentUserId = teacherId;
  }

  console.log('🔍 [createConversation] Current User ID:', currentUserId, 'Recipient:', payload.recipientId);

  // Check if conversation already exists
  const existingConversation = await prisma.conversation.findFirst({
    where: {
      schoolId,
      OR: [
        { participant1Id: currentUserId, participant2Id: payload.recipientId },
        { participant1Id: payload.recipientId, participant2Id: currentUserId },
      ],
    },
  });

  if (existingConversation) {
    console.log('✅ [createConversation] Conversation already exists');
    return res.json({ success: true, data: existingConversation });
  }

  // Create new conversation
  const conversation = await prisma.conversation.create({
    data: {
      schoolId,
      participant1Id: currentUserId,
      participant2Id: payload.recipientId,
    },
  });

  console.log('✅ [createConversation] New conversation created:', conversation.id);
  res.status(201).json({ success: true, data: conversation });
});

export const getAvailableContacts = asyncHandler(async (req: Request, res: Response) => {
  console.log('🚨 [getAvailableContacts] CALLED!');
  console.log('Request body:', req.body);
  console.log('Request query:', req.query);
  
  const schoolId = requireSid(req);
  const userId = (req as any).userId;
  const userRole = req.user?.role;

  console.log('🔍 [getAvailableContacts] User ID:', userId, 'Role:', userRole, 'School ID:', schoolId);

  let contacts = [];

  // Add school administration as fixed contact for everyone
  try {
    const schoolAdmin = await prisma.user.findFirst({
      where: {
        schoolId,
        role: 'SCHOOL_ADMIN',
      },
      include: {
        school: true,
      },
    });

    if (schoolAdmin) {
      contacts.push({
        id: schoolAdmin.id,
        user: {
          fullName: schoolAdmin.school?.name || 'إدارة المدرسة',
          email: schoolAdmin.email,
          photo: schoolAdmin.school?.logo,
        },
        type: 'SCHOOL_ADMIN',
        photo: schoolAdmin.school?.logo,
      });
      console.log('🏫 [getAvailableContacts] School admin added:', schoolAdmin.email, 'with logo:', schoolAdmin.school?.logo);
    } else {
      console.log('⚠️ [getAvailableContacts] No school admin found for school:', schoolId);
    }
  } catch (error) {
    console.error('❌ [getAvailableContacts] Error fetching school admin:', error);
  }

  if (userRole === "PARENT") {
    // Get parent's students and their teachers
    const parentId = (req as any).parentId;
    
    if (!parentId) {
      console.log('❌ [getAvailableContacts] No parentId found for PARENT role');
      console.log('✅ [getAvailableContacts] Total contacts returned:', contacts.length);
      return res.json({ success: true, data: contacts });
    }

    const parent = await prisma.parent.findUnique({
      where: { id: parentId },
    });

    console.log('👨‍👩‍👧‍👦 [getAvailableContacts] Parent found:', parent ? parent.id : 'NOT FOUND');

    if (parent) {
      const students = await prisma.student.findMany({
        where: { 
          OR: [
            { fatherId: parent.id },
            { motherId: parent.id },
            { guardianId: parent.id },
          ]
        },
        include: {
          class: {
            include: {
              teacher: {
                include: { user: true },
              },
              teacherSubjects: {
                include: {
                  teacher: {
                    include: { user: true },
                  },
                },
              },
            },
          },
        },
      });

      console.log('👨‍🎓 [getAvailableContacts] Students found:', students.length);
      students.forEach((student: any) => {
        console.log(`  - Student: ${student.id}, Class: ${student.class?.name || 'NO CLASS'}`);
        if (student.class) {
          console.log(`    Class Teacher: ${student.class.teacher?.user?.fullName || 'NONE'}`);
          console.log(`    Subject Teachers: ${student.class.teacherSubjects?.length || 0}`);
        }
      });

      const teachersMap = new Map();
      students.forEach((student: any) => {
        if (student.class) {
          // Add class teacher (supervisor)
          if (student.class.teacher) {
            teachersMap.set(student.class.teacher.id, student.class.teacher);
          }
          
          // Add subject teachers
          if (student.class.teacherSubjects) {
            student.class.teacherSubjects.forEach((ts: any) => {
              if (ts.teacher) {
                teachersMap.set(ts.teacher.id, ts.teacher);
              }
            });
          }
        }
      });

      const teacherContacts = Array.from(teachersMap.values());
      contacts = [...contacts, ...teacherContacts];
      console.log('👨‍🏫 [getAvailableContacts] Final teachers count:', teacherContacts.length);
    }
  } else if (userRole === "TEACHER") {
    // Get teacher's classes and their students' parents
    const teacherId = (req as any).teacherId;
    
    if (!teacherId) {
      console.log('❌ [getAvailableContacts] No teacherId found for TEACHER role');
      console.log('✅ [getAvailableContacts] Total contacts returned:', contacts.length);
      return res.json({ success: true, data: contacts });
    }

    const teacher = await prisma.teacher.findUnique({
      where: { id: teacherId },
      include: {
        teacherSubjects: {
          include: {
            class: {
              include: {
                students: {
                  include: {
                    father: {
                      include: { user: true },
                    },
                    mother: {
                      include: { user: true },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });

    console.log('👨‍🏫 [getAvailableContacts] Teacher found:', teacher ? teacher.id : 'NOT FOUND');

    if (teacher) {
      const parentsMap = new Map();
      
      // Get parents from teacher's classes
      teacher.teacherSubjects.forEach((ts: any) => {
        if (ts.class && ts.class.students) {
          ts.class.students.forEach((student: any) => {
            if (student.father && student.father.user) {
              parentsMap.set(student.father.id, { ...student.father, type: "FATHER" });
            }
            if (student.mother && student.mother.user) {
              parentsMap.set(student.mother.id, { ...student.mother, type: "MOTHER" });
            }
          });
        }
      });

      const parentContacts = Array.from(parentsMap.values());
      contacts = [...contacts, ...parentContacts];
      console.log('👨‍👩‍👧‍👦 [getAvailableContacts] Final parents count:', parentContacts.length);
    }
  } else {
    console.log('❌ [getAvailableContacts] Unknown user role:', userRole);
  }

  console.log('✅ [getAvailableContacts] Total contacts returned:', contacts.length);
  res.json({ success: true, data: contacts });
});
