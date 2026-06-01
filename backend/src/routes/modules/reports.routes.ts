import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { getReportsOverview } from "../../controllers/reports.controller";

const router = Router();

router.get("/overview", requireAuth, tenantScope, getReportsOverview);

export default router;

