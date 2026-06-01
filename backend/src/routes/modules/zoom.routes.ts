import { Router } from "express";
import { auth } from "../../middlewares/auth";
import { createZoomMeeting, listZoomMeetings, deleteZoomMeeting } from "../../controllers/zoom.controller";

const router = Router();

router.use(auth);

router.post("/meetings", createZoomMeeting);
router.get("/meetings", listZoomMeetings);
router.delete("/meetings/:meetingId", deleteZoomMeeting);

export default router;
