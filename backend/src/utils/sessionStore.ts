import fs from "fs";
import path from "path";

export interface DeviceSession {
  id: string;
  parentId?: string | null;
  teacherId?: string | null;
  credentialId: string;
  deviceName: string;
  location: string;
  ipAddress: string;
  token: string;
  isActive: boolean;
  createdAt: string;
  lastActiveAt: string;
}

const FILE_PATH = path.join(__dirname, "../../device_sessions.json");

// Ensure the file exists
function ensureFileExists() {
  if (!fs.existsSync(FILE_PATH)) {
    fs.writeFileSync(FILE_PATH, JSON.stringify([], null, 2), "utf8");
  }
}

export function getAllSessions(): DeviceSession[] {
  try {
    ensureFileExists();
    const data = fs.readFileSync(FILE_PATH, "utf8");
    return JSON.parse(data) || [];
  } catch (err) {
    console.error("Error reading device sessions:", err);
    return [];
  }
}

export function saveAllSessions(sessions: DeviceSession[]) {
  try {
    ensureFileExists();
    fs.writeFileSync(FILE_PATH, JSON.stringify(sessions, null, 2), "utf8");
  } catch (err) {
    console.error("Error writing device sessions:", err);
  }
}

export function addSession(session: Omit<DeviceSession, "createdAt" | "lastActiveAt">) {
  const sessions = getAllSessions();
  
  // To keep it clean, if there is an existing session for the exact same parent/teacher and device, we can remove or update it
  const filtered = sessions.filter(
    (s) => !(
      (session.parentId && s.parentId === session.parentId && s.deviceName === session.deviceName) ||
      (session.teacherId && s.teacherId === session.teacherId && s.deviceName === session.deviceName)
    )
  );

  const newSession: DeviceSession = {
    ...session,
    createdAt: new Date().toISOString(),
    lastActiveAt: new Date().toISOString(),
  };

  filtered.push(newSession);
  saveAllSessions(filtered);
  return newSession;
}

export function getSessionsForParent(parentId: string): DeviceSession[] {
  const sessions = getAllSessions();
  return sessions.filter((s) => s.parentId === parentId && s.isActive);
}

export function getSessionsForTeacher(teacherId: string): DeviceSession[] {
  const sessions = getAllSessions();
  return sessions.filter((s) => s.teacherId === teacherId && s.isActive);
}

export function revokeSession(sessionId: string, parentId: string): boolean {
  const sessions = getAllSessions();
  const index = sessions.findIndex((s) => s.id === sessionId && s.parentId === parentId);
  if (index !== -1) {
    sessions.splice(index, 1); // Delete session completely so they are logged out
    saveAllSessions(sessions);
    return true;
  }
  return false;
}

export function revokeSessionForTeacher(sessionId: string, teacherId: string): boolean {
  const sessions = getAllSessions();
  const index = sessions.findIndex((s) => s.id === sessionId && s.teacherId === teacherId);
  if (index !== -1) {
    sessions.splice(index, 1);
    saveAllSessions(sessions);
    return true;
  }
  return false;
}

export function revokeAllSessionsForParent(parentId: string, currentSessionId?: string) {
  const sessions = getAllSessions();
  const updated = sessions.filter((s) => {
    if (s.parentId === parentId) {
      if (currentSessionId && s.id === currentSessionId) {
        return true; // Keep current session active
      }
      return false; // Remove others
    }
    return true;
  });
  saveAllSessions(updated);
}

export function revokeAllSessionsForTeacher(teacherId: string, currentSessionId?: string) {
  const sessions = getAllSessions();
  const updated = sessions.filter((s) => {
    if (s.teacherId === teacherId) {
      if (currentSessionId && s.id === currentSessionId) {
        return true; // Keep current session active
      }
      return false; // Remove others
    }
    return true;
  });
  saveAllSessions(updated);
}

export function isSessionActive(token: string): boolean {
  const sessions = getAllSessions();
  const session = sessions.find((s) => s.token === token);
  return !!session && session.isActive;
}

export function getSessionByToken(token: string): DeviceSession | undefined {
  const sessions = getAllSessions();
  return sessions.find((s) => s.token === token);
}

export function updateSessionActivity(token: string) {
  const sessions = getAllSessions();
  const session = sessions.find((s) => s.token === token);
  if (session) {
    session.lastActiveAt = new Date().toISOString();
    saveAllSessions(sessions);
  }
}
