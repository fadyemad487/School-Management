import { Router } from "express";
import * as leaveController from "../../controllers/leave.controller";
import { auth } from "../../middlewares/auth";

const router = Router();

router.use(auth);

router.get("/", leaveController.getLeaveRequests);
router.post("/", leaveController.createLeaveRequest);
router.patch("/:id/status", leaveController.updateLeaveStatus);

export default router;
