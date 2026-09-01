import { Router } from "express";
import { Role } from "@prisma/client";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { roleGuard } from "../../middlewares/roleGuard";
import { listUsers, updateUserRole } from "../../controllers/user.controller";

const router = Router();

const adminOnly = roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]);

router.get("/", requireAuth, tenantScope, adminOnly, listUsers);
router.patch("/:id/role", requireAuth, tenantScope, adminOnly, updateUserRole);

export default router;

