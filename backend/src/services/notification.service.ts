import { prisma } from "../config/prisma";
import { getIO } from "../config/websocket";
import { NotificationType, NotificationChannel } from "@prisma/client";

export class NotificationService {
  /**
   * Send an absence alert to the recipient (parent/student)
   */
  static async sendAbsenceAlert(
    schoolId: string,
    recipientUserId: string | null,
    studentName: string,
    date: Date,
    period?: number
  ) {
    const formattedDate = date.toLocaleDateString("ar-EG");
    const periodText = period ? ` (الحصة ${period})` : "";
    const title = "تنبيه غياب";
    const message = `تم تسجيل غياب الطالب ${studentName} بتاريخ ${formattedDate}${periodText}.`;

    // 1. Save to Database
    const notification = await prisma.notification.create({
      data: {
        schoolId,
        recipientId: recipientUserId,
        title,
        message,
        type: "ABSENCE",
        channel: "SYSTEM",
      },
    });

    // 2. Emit via WebSocket
    const io = getIO();
    if (recipientUserId) {
      io.to(`user:${recipientUserId}`).emit("notification:new", notification);
    }
    
    // Also notify the school admins/dashboard
    io.to(`school:${schoolId}`).emit("notification:system", notification);

    // 3. Placeholder for SMS/WhatsApp
    // TODO: Integrate with external SMS/WhatsApp gateway if settings.smsEnabled is true
    console.log(`[NotificationService] Absence alert queued for ${studentName} via System/WebSocket`);
    
    return notification;
  }
}
