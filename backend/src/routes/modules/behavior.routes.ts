import { Router } from "express";
import { auth } from "../../middlewares/auth";
import { createBehaviorReport, getBehaviorReports, getParentBehaviorReports, getTeacherBehaviorReports } from "../../controllers/behavior.controller";

const router = Router();

router.use(auth);

router.post("/", createBehaviorReport);
router.get("/", getBehaviorReports);
router.get("/parent", getParentBehaviorReports);
router.get("/teacher", getTeacherBehaviorReports);

export default router;
