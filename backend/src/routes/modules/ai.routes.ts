import { Router } from "express";
import { Role } from "@prisma/client";
import { chatWithAI, getAIChatHistory, getAIChatSessions, deleteAIChatSession, checkAIPasswordStatus, setAIPassword, verifyAIPassword } from "../../controllers/ai.controller";
import { requireAuth } from "../../middlewares/auth";
import { roleGuard } from "../../middlewares/roleGuard";

const router = Router();

// The assistant can change school records, so it is strictly an administrator tool.
router.use(requireAuth, roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]));

router.get("/sessions", getAIChatSessions);
router.delete("/sessions/:sessionId", deleteAIChatSession);
router.get("/history", getAIChatHistory);
router.get("/password-status", checkAIPasswordStatus);
router.post("/set-password", setAIPassword);
router.post("/verify-password", verifyAIPassword);
router.post("/chat", chatWithAI);

export default router;
