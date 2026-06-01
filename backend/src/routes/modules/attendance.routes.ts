import { Router } from "express";
import { getAttendance, createAttendance, markBulkAttendance } from "../../controllers/attendance.controller";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";

const router = Router();

router.get("/", requireAuth, tenantScope, getAttendance);
router.post("/", requireAuth, tenantScope, createAttendance);
router.post("/bulk", requireAuth, tenantScope, markBulkAttendance);

export default router;
