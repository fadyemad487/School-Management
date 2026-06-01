import { Router } from "express";
import * as chatController from "../../controllers/chat.controller";
import { auth } from "../../middlewares/auth";

const router = Router();

// All chat routes require authentication
router.use(auth);

router.get("/conversations", chatController.getConversations);
router.get("/messages/:conversationId", chatController.getMessages);
router.get("/contacts", chatController.getContacts);
router.post("/send", chatController.sendMessage);

export default router;
