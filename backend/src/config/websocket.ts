import { Server as HttpServer } from "http";
import { Server, Socket } from "socket.io";
import { env } from "./env";
import { prisma } from "./prisma";
import { supabaseAdmin } from "./supabase";
import jwt from "jsonwebtoken";

let io: Server;

/**
 * Initialize Socket.IO server with school-based room isolation.
 * Each authenticated school connects and is placed in a room
 * named `school:<schoolId>` so real-time events only reach
 * users of the same school.
 */
export function initWebSocket(httpServer: HttpServer): Server {
  io = new Server(httpServer, {
    cors: {
      origin: env.allowedOrigins,
      methods: ["GET", "POST"],
      credentials: true
    },
    transports: ["websocket", "polling"]
  });

  io.use(async (socket, next) => {
    const token = socket.handshake.auth?.token;
    if (typeof token !== "string" || !token) {
      next(new Error("Authentication required"));
      return;
    }

    try {
      // Browser dashboard sessions are Supabase JWTs. Custom mobile credential
      // JWTs are also supported without trusting any client-provided identity.
      try {
        const custom = jwt.verify(token, env.supabaseJwtSecret) as {
          id: string; role: string; schoolId?: string;
        };
        const credential = await prisma.appCredential.findUnique({
          where: { id: custom.id },
          include: { teacher: true, parent: true, student: true },
        });
        if (!credential || !credential.isActive) throw new Error("Inactive credential");
        const userId = credential.teacher?.userId ?? credential.parent?.userId ?? credential.student?.userId ?? credential.id;
        socket.data.auth = { schoolId: credential.schoolId, role: credential.role, userId };
        next();
        return;
      } catch {
        // Not a custom credential token; continue with Supabase verification.
      }

      const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
      if (error || !user?.email) throw new Error("Invalid token");
      const dbUser = await prisma.user.findUnique({ where: { email: user.email } });
      if (!dbUser) throw new Error("User not found");
      socket.data.auth = { schoolId: dbUser.schoolId, role: dbUser.role, userId: dbUser.id };
      next();
    } catch {
      next(new Error("Unauthorized"));
    }
  });

  io.on("connection", (socket: Socket) => {
    const auth = socket.data.auth as { schoolId: string | null; role: string; userId: string };
    const schoolId = auth.schoolId;
    const userRole = auth.role;
    const userId = auth.userId;

    if (userRole === "SUPER_ADMIN") {
      // SUPER_ADMIN joins a special room to receive all events
      socket.join("super_admin");
      console.log(`[WS] SUPER_ADMIN connected: ${socket.id}`);
    } else if (schoolId) {
      // Regular users join their school's room
      socket.join(`school:${schoolId}`);
      console.log(`[WS] School ${schoolId} connected: ${socket.id}`);
    }

    if (userId) {
      // Join default credential room for session tracking/logout
      socket.join(`user:${userId}`);
      console.log(`[WS] User credential room joined: user:${userId}`);

    }

    socket.on("disconnect", () => {
      console.log(`[WS] Disconnected: ${socket.id}`);
    });
  });

  return io;
}

/**
 * Get the Socket.IO server instance.
 * Use this in controllers to emit events.
 */
export function getIO(): Server {
  if (!io) {
    // Return a no-op proxy if WebSocket is not initialized yet
    // This prevents crashes during testing or when WS is not needed
    return {
      to: () => ({
        emit: () => {}
      })
    } as any;
  }
  return io;
}
