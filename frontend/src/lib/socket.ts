import { io, Socket } from "socket.io-client";

const SOCKET_URL = process.env.NEXT_PUBLIC_API_URL?.replace("/api", "") || "http://localhost:5001";

let socket: Socket | null = null;

/**
 * Connect to the WebSocket server and join the school's room.
 * Each school gets its own room for data isolation.
 */
export function connectSocket(schoolId: string | null, role: string, userId: string | null = null): Socket {
  if (socket?.connected) {
    return socket;
  }

  socket = io(SOCKET_URL, {
    transports: ["websocket", "polling"],
    query: {
      schoolId: schoolId || "",
      role,
      userId: userId || ""
    },
    autoConnect: true
  });

  socket.on("connect", () => {
    console.log("[WS] Connected:", socket?.id);
  });

  socket.on("disconnect", () => {
    console.log("[WS] Disconnected");
  });

  return socket;
}

/**
 * Get the current socket instance.
 */
export function getSocket(): Socket | null {
  return socket;
}

/**
 * Disconnect and clean up the socket.
 */
export function disconnectSocket(): void {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
}
