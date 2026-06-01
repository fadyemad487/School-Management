import { Router } from "express";
import * as scheduleController from "../../controllers/schedule.controller";
import { auth } from "../../middlewares/auth";

const router = Router();

router.use(auth);

router.get("/", scheduleController.getEvents);
router.post("/", scheduleController.createEvent);
router.delete("/:id", scheduleController.deleteEvent);

export default router;
