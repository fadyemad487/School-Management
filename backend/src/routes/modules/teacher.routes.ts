import { Router } from "express";
import { 
  getTeachers, 
  createTeacher, 
  updateTeacher, 
  deleteTeacher,
  getTeacherAssignments,
  assignTeacher,
  unassignTeacher,
  getMobileTeacherDashboard,
  getMobileTeacherReports,
  getMobileTeacherClasses,
  updateMobileTeacherProfile,
  changeMobileTeacherPassword,
  getMobileTeacherDevices,
  logoutMobileTeacherDevice,
  logoutAllOtherTeacherDevices,
  getTeacherSocialStatus,
  linkTeacherSocialAccount,
  unlinkTeacherSocialAccount
} from "../../controllers/teacher.controller";
import { requireAuth } from "../../middlewares/auth";
import { requireMobileAuth } from "../../middlewares/mobileAuth";
import { tenantScope } from "../../middlewares/tenantScope";
import { roleGuard } from "../../middlewares/roleGuard";
import { Role } from "@prisma/client";

const router = Router();

// Mobile teacher endpoints
router.get("/mobile/dashboard", requireMobileAuth, getMobileTeacherDashboard);
router.get("/mobile/reports", requireMobileAuth, getMobileTeacherReports);
router.get("/mobile/classes", requireMobileAuth, getMobileTeacherClasses);
router.put("/mobile/profile", requireMobileAuth, updateMobileTeacherProfile);
router.post("/mobile/change-password", requireMobileAuth, changeMobileTeacherPassword);
router.get("/mobile/devices", requireMobileAuth, getMobileTeacherDevices);
router.post("/mobile/devices/logout", requireMobileAuth, logoutMobileTeacherDevice);
router.post("/mobile/devices/logout-all", requireMobileAuth, logoutAllOtherTeacherDevices);
router.get("/mobile/social/status", requireMobileAuth, getTeacherSocialStatus);
router.post("/mobile/social/link", requireMobileAuth, linkTeacherSocialAccount);
router.post("/mobile/social/unlink", requireMobileAuth, unlinkTeacherSocialAccount);

// Web dashboard teacher endpoints
router.get("/", requireAuth, tenantScope, getTeachers);
router.post("/", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SUPER_ADMIN]), createTeacher);
router.put("/:id", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SUPER_ADMIN]), updateTeacher);
router.delete("/:id", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SUPER_ADMIN]), deleteTeacher);

// Teacher assignment (class ↔ subject) management
router.get("/:id/assignments", requireAuth, tenantScope, getTeacherAssignments);
router.post("/:id/assignments", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SUPER_ADMIN]), assignTeacher);
router.delete("/:id/assignments/:assignmentId", requireAuth, tenantScope, roleGuard([Role.ADMIN, Role.SUPER_ADMIN]), unassignTeacher);

export default router;
