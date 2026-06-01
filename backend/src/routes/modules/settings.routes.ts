import { Router } from "express";
import { getSettings, updateSettings } from "../../controllers/settings.controller";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";

const router = Router();

router.get("/", requireAuth, tenantScope, getSettings);
router.patch("/", requireAuth, tenantScope, updateSettings);

export default router;
