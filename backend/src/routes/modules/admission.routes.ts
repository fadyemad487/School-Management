import { Router } from "express";
import { auth } from "../../middlewares/auth";
import {
  getApplications,
  getApplication,
  createApplication,
  updateApplication,
  changeApplicationStatus,
  convertToStudent,
  addContactLog,
  deleteApplication,
  getAdmissionStats,
} from "../../controllers/admission.controller";

const router = Router();

router.use(auth);

router.get("/", getApplications);
router.get("/stats", getAdmissionStats);
router.get("/:id", getApplication);
router.post("/", createApplication);
router.put("/:id", updateApplication);
router.patch("/:id/status", changeApplicationStatus);
router.post("/:id/convert", convertToStudent);
router.post("/:id/contact", addContactLog);
router.delete("/:id", deleteApplication);

export default router;
