import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";
import { requireMobileAuth } from "../../middlewares/mobileAuth";
import { tenantScope } from "../../middlewares/tenantScope";
import {
  createExam,
  deleteExam,
  listExams,
  updateExam,
  saveExamResults,
  getExamResults,
  getStudentResults,
} from "../../controllers/exam.controller";

const router = Router();

router.get("/", requireAuth, tenantScope, listExams);
router.post("/", requireAuth, tenantScope, createExam);
router.patch("/:id", requireAuth, tenantScope, updateExam);
router.delete("/:id", requireAuth, tenantScope, deleteExam);

// Exam results routes (web dashboard)
router.post("/:id/results", requireAuth, tenantScope, saveExamResults);
router.get("/:id/results", requireAuth, tenantScope, getExamResults);
router.get("/student/:studentId", requireAuth, tenantScope, getStudentResults);

// Mobile teacher endpoints
router.post("/mobile/:id/results", requireMobileAuth, saveExamResults);
router.get("/mobile/:id/results", requireMobileAuth, getExamResults);
router.get("/mobile/student/:studentId", requireMobileAuth, getStudentResults);

export default router;

