import { Router } from "express";
import { auth } from "../../middlewares/auth";
import {
  getArchives,
  restoreArchive
} from "../../controllers/archive.controller";

const router = Router();

router.use(auth);

router.get("/", getArchives);
router.post("/:id/restore", restoreArchive);

export default router;
