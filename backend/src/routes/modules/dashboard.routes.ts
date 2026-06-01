import { Router } from "express";
import { getOverview } from "../../controllers/dashboard.controller";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";

const router = Router();

router.get("/overview", requireAuth, tenantScope, getOverview);

export default router;
