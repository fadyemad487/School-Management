import { Router } from "express";
import { login, register, checkSchoolId, checkSchoolName, checkSchoolEmail, getMe, handleWebhook, mobileLogin, mobileSocialLogin, changeMobilePassword } from "../../controllers/auth.controller";
import { requireAuth } from "../../middlewares/auth";
import { requireMobileAuth } from "../../middlewares/mobileAuth";

const router = Router();

// Public routes
router.post("/login", login);
router.post("/mobile/login", mobileLogin);
router.post("/mobile/social-login", mobileSocialLogin);
router.post("/register", register);
router.get("/check-school-id/:code", checkSchoolId);
router.get("/check-school-name/:name", checkSchoolName);
router.get("/check-school-email/:email", checkSchoolEmail);
router.post("/webhook", handleWebhook);

// Protected routes
router.get("/me", requireAuth, getMe);
router.post("/mobile/change-password", requireMobileAuth, changeMobilePassword);

export default router;
