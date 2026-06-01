import { Router } from "express";
import { auth } from "../../middlewares/auth";
import { createStudentTask, getStudentTasks, markTaskCompleted, deleteStudentTask } from "../../controllers/studentTask.controller";

const router = Router();

router.use(auth);

router.post("/", createStudentTask);
router.get("/", getStudentTasks);
router.post("/:id/complete", markTaskCompleted);
router.delete("/:id", deleteStudentTask);

export default router;
