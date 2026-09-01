import { Router } from "express";
import { Role } from "@prisma/client";
import { getSettings, updateSettings } from "../../controllers/settings.controller";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { roleGuard } from "../../middlewares/roleGuard";

const router = Router();

const adminOnly = roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]);

router.get("/", requireAuth, tenantScope, getSettings);
router.patch("/", requireAuth, tenantScope, adminOnly, updateSettings);

export default router;
