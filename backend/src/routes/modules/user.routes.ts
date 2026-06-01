import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { listUsers, updateUserRole } from "../../controllers/user.controller";

const router = Router();

router.get("/", requireAuth, tenantScope, listUsers);
router.patch("/:id/role", requireAuth, tenantScope, updateUserRole);

export default router;

