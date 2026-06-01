import { Router } from "express";
import { getAnnouncements, createAnnouncement, deleteAnnouncement } from "../../controllers/announcement.controller";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { roleGuard } from "../../middlewares/roleGuard";
import { Role } from "@prisma/client";

const router = Router();

router.get("/", requireAuth, tenantScope, getAnnouncements);
router.post("/", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SUPER_ADMIN, Role.TEACHER]), createAnnouncement);
router.delete("/:id", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SUPER_ADMIN]), deleteAnnouncement);

export default router;
