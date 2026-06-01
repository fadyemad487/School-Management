import { Router } from "express";
import { chatWithAI, getAIChatHistory, getAIChatSessions, deleteAIChatSession, checkAIPasswordStatus, setAIPassword, verifyAIPassword } from "../../controllers/ai.controller";
import { requireAuth } from "../../middlewares/auth";

const router = Router();

// Secure the AI endpoints so only logged-in staff can use them
router.get("/sessions", requireAuth, getAIChatSessions);
router.delete("/sessions/:sessionId", requireAuth, deleteAIChatSession);
router.get("/history", requireAuth, getAIChatHistory);
router.get("/password-status", requireAuth, checkAIPasswordStatus);
router.post("/set-password", requireAuth, setAIPassword);
router.post("/verify-password", requireAuth, verifyAIPassword);
router.post("/chat", requireAuth, chatWithAI);

export default router;
