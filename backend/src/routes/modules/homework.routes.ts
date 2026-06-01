import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { createHomework, deleteHomework, getHomeworkSubmissions, listHomework, submitHomework, updateHomework } from "../../controllers/homework.controller";

const router = Router();

router.get("/", requireAuth, tenantScope, listHomework);
router.post("/", requireAuth, tenantScope, createHomework);
router.post("/:id/submit", requireAuth, tenantScope, submitHomework);
router.get("/:id/submissions", requireAuth, tenantScope, getHomeworkSubmissions);
router.patch("/:id", requireAuth, tenantScope, updateHomework);
router.delete("/:id", requireAuth, tenantScope, deleteHomework);

export default router;
