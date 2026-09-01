import { Router } from "express";
import { login, register, checkSchoolId, checkSchoolName, checkSchoolEmail, getMe, handleWebhook, mobileLogin, mobileSocialLogin, changeMobilePassword } from "../../controllers/auth.controller";
import { requireAuth } from "../../middlewares/auth";
import { requireMobileAuth } from "../../middlewares/mobileAuth";
import { createRateLimiter } from "../../middlewares/rateLimit";

const router = Router();

// Public routes
const loginLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: "Too many sign-in attempts. Please try again in a few minutes."
});
const registrationLimiter = createRateLimiter({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: "Too many registration attempts. Please try again later."
});

router.post("/login", loginLimiter, login);
router.post("/mobile/login", loginLimiter, mobileLogin);
router.post("/mobile/social-login", loginLimiter, mobileSocialLogin);
router.post("/register", registrationLimiter, register);
router.get("/check-school-id/:code", checkSchoolId);
router.get("/check-school-name/:name", checkSchoolName);
router.get("/check-school-email/:email", checkSchoolEmail);
router.post("/webhook", handleWebhook);

// Protected routes
router.get("/me", requireAuth, getMe);
router.post("/mobile/change-password", requireMobileAuth, changeMobilePassword);

export default router;
