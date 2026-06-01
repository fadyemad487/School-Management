import { Router } from "express";
import { 
  getStudents, 
  createStudent, 
  updateStudent, 
  deleteStudent, 
  getStudentById,
  getMobileStudentGameState,
  updateMobileStudentGameState,
  studentMobileAiChat
} from "../../controllers/student.controller";
import { requireAuth } from "../../middlewares/auth";
import { requireMobileAuth } from "../../middlewares/mobileAuth";
import { tenantScope } from "../../middlewares/tenantScope";
import { roleGuard } from "../../middlewares/roleGuard";
import { Role } from "@prisma/client";

const router = Router();

// Mobile client persistent gamification endpoints
router.get("/mobile/game-state", requireMobileAuth, getMobileStudentGameState);
router.post("/mobile/game-state", requireMobileAuth, updateMobileStudentGameState);
router.post("/mobile/ai-chat", requireMobileAuth, studentMobileAiChat);

// Dashboard administrative routes
router.get("/", requireAuth, tenantScope, getStudents);
router.post("/", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), createStudent);
router.get("/:id", requireAuth, tenantScope, getStudentById);
router.put("/:id", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), updateStudent);
router.delete("/:id", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), deleteStudent);

export default router;
