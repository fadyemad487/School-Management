import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";
import axios from "axios";

/** Require schoolId — throws if missing */
function requireSid(req: Request): string {
  if (!req.schoolId) throw new ValidationError("School context required");
  return req.schoolId;
}

/**
 * Zoom Server-to-Server OAuth
 * Returns an access token for the school's Zoom account
 */
async function getZoomAccessToken(settings: any) {
  if (!settings.zoomAccountId || !settings.zoomClientId || !settings.zoomClientSecret) {
    throw new ValidationError("Zoom API credentials not configured correctly in settings.");
  }

  const auth = Buffer.from(`${settings.zoomClientId}:${settings.zoomClientSecret}`).toString("base64");
  
  try {
    const response = await axios.post(
      `https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${settings.zoomAccountId}`,
      {},
      {
        headers: {
          Authorization: `Basic ${auth}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    );
    return response.data.access_token;
  } catch (error: any) {
    console.error("Zoom OAuth Error:", error.response?.data || error.message);
    throw new ValidationError("Failed to authenticate with Zoom. Check your API credentials.");
  }
}

/**
 * POST /api/zoom/meetings
 * Create a new Zoom meeting
 */
export const createZoomMeeting = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { topic, startTime, duration, agenda, targetType, targetIds, type = 2 } = req.body;

  const settings = await prisma.schoolSettings.findUnique({
    where: { schoolId },
  });

  if (!settings || !settings.zoomEnabled) {
    throw new ValidationError("Zoom integration is not enabled for this school.");
  }

  const token = await getZoomAccessToken(settings);

  try {
    const response = await axios.post(
      "https://api.zoom.us/v2/users/me/meetings",
      {
        topic: topic || "School Meeting",
        type: type, // 2 for scheduled
        start_time: startTime, // ISO format
        duration: duration || 40,
        agenda: agenda || "EduControl Generated Meeting",
        settings: {
          host_video: true,
          participant_video: true,
          join_before_host: true,
          mute_upon_entry: true,
          waiting_room: true,
        },
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      }
    );

    // --- SEND NOTIFICATIONS TO TARGET AUDIENCE ---
    const meetingData = response.data;
    
    // Logic to notify based on targetType
    if (targetType) {
      let targetUserIds: string[] = [];

      if (targetType === "all_parents") {
        const parents = await prisma.user.findMany({
          where: { schoolId, role: "PARENT" },
          select: { id: true }
        });
        targetUserIds = parents.map(p => p.id);
      } else if (targetType === "all_teachers") {
        const teachers = await prisma.user.findMany({
          where: { schoolId, role: "TEACHER" },
          select: { id: true }
        });
        targetUserIds = teachers.map(t => t.id);
      } else if (targetType === "specific" && Array.isArray(targetIds)) {
        targetUserIds = targetIds;
      }

      if (targetUserIds.length > 0) {
        await prisma.notification.createMany({
          data: targetUserIds.map((id: string) => ({
            schoolId,
            recipientId: id,
            title: "New Zoom Meeting | اجتماع زووم جديد",
            message: `Meeting: ${topic}. Join here: ${meetingData.join_url}`,
          }))
        });
      }
    }

    res.status(201).json({ success: true, data: meetingData });
  } catch (error: any) {
    console.error("Zoom Create Meeting Error:", error.response?.data || error.message);
    throw new ValidationError("Failed to create Zoom meeting. " + (error.response?.data?.message || ""));
  }
});

/**
 * GET /api/zoom/meetings
 * List all Zoom meetings for the account
 */
export const listZoomMeetings = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const settings = await prisma.schoolSettings.findUnique({
    where: { schoolId },
  });

  if (!settings || !settings.zoomEnabled) {
    throw new ValidationError("Zoom integration is not enabled for this school.");
  }

  const token = await getZoomAccessToken(settings);

  try {
    const response = await axios.get(
      "https://api.zoom.us/v2/users/me/meetings?type=upcoming",
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      }
    );

    res.status(200).json({ success: true, data: response.data.meetings });
  } catch (error: any) {
    console.error("Zoom List Meetings Error:", error.response?.data || error.message);
    throw new ValidationError("Failed to fetch Zoom meetings. Check your API credentials.");
  }
});

/**
 * DELETE /api/zoom/meetings/:meetingId
 * Delete a Zoom meeting
 */
export const deleteZoomMeeting = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { meetingId } = req.params;

  const settings = await prisma.schoolSettings.findUnique({
    where: { schoolId },
  });

  if (!settings || !settings.zoomEnabled) {
    throw new ValidationError("Zoom integration is not enabled for this school.");
  }

  const token = await getZoomAccessToken(settings);

  try {
    await axios.delete(
      `https://api.zoom.us/v2/meetings/${meetingId}`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      }
    );

    res.status(200).json({ success: true, message: "Meeting deleted successfully" });
  } catch (error: any) {
    console.error("Zoom Delete Meeting Error Details:", error.response?.data || error.message);
    const zoomMsg = error.response?.data?.message || "";
    throw new ValidationError(`Failed to delete Zoom meeting. ${zoomMsg}`);
  }
});


