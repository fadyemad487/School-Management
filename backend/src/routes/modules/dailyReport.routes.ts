import { Router } from "express";
import { auth } from "../../middlewares/auth";
import { createDailyReport, getDailyReports } from "../../controllers/dailyReport.controller";

const router = Router();

router.use(auth);

router.post("/", createDailyReport);
router.get("/", getDailyReports);

export default router;
