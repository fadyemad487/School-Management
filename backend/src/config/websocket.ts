import { Server as HttpServer } from "http";
import { Server, Socket } from "socket.io";
import { env } from "./env";
import { prisma } from "./prisma";

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

  io.on("connection", (socket: Socket) => {
    const schoolId = socket.handshake.query.schoolId as string | undefined;
    const userRole = socket.handshake.query.role as string | undefined;
    const userId = socket.handshake.query.userId as string | undefined;

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

      // Query database asynchronously to resolve real User.id and join its target room
      prisma.appCredential.findUnique({
        where: { id: userId },
        include: { teacher: true, parent: true, student: true }
      }).then((cred: any) => {
        if (cred) {
          let realUserId = cred.id;
          if (cred.teacher) realUserId = cred.teacher.userId;
          else if (cred.parent) realUserId = cred.parent.userId;
          else if (cred.student) realUserId = cred.student.userId;

          // Always join the real user room
          socket.join(`user:${realUserId}`);
          console.log(`[WS] Dynamic mapping: User joined real room: user:${realUserId}`);
        }
      }).catch((err: any) => {
        console.error("[WS] Dynamic mapping error:", err);
      });
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
