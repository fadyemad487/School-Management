import { Router } from "express";
import { Role } from "@prisma/client";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { roleGuard } from "../../middlewares/roleGuard";
import { getMySchool, updateMySchool } from "../../controllers/school.controller";

const router = Router();

const adminOnly = roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]);

router.get("/me", requireAuth, tenantScope, getMySchool);
router.patch("/me", requireAuth, tenantScope, adminOnly, updateMySchool);

export default router;

