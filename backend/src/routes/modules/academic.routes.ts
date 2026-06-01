import { Router } from "express";
import { auth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import {
  getAcademicYears,
  createAcademicYear,
  updateAcademicYear,
  deleteAcademicYear,
  getGrades,
  createGrade,
  updateGrade,
  deleteGrade,
  seedDefaultGrades,
} from "../../controllers/academic.controller";

const router = Router();

router.use(auth);
router.use(tenantScope);

// Academic Years
router.get("/years", getAcademicYears);
router.post("/years", createAcademicYear);
router.put("/years/:id", updateAcademicYear);
router.delete("/years/:id", deleteAcademicYear);

// Grades
router.get("/grades", getGrades);
router.post("/grades", createGrade);
router.post("/grades/seed", seedDefaultGrades);
router.put("/grades/:id", updateGrade);
router.delete("/grades/:id", deleteGrade);

export default router;
