import { Router } from "express";
import { Role } from "@prisma/client";
import { auth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { roleGuard } from "../../middlewares/roleGuard";
import {
  generateCredentials,
  bulkGenerateCredentials,
  getCredentials,
  toggleCredential,
  resetCredentialPassword,
  deleteCredential,
} from "../../controllers/credential.controller";

const router = Router();

// Only administrators are allowed to view, generate, or manage credentials
router.use(auth, tenantScope, roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]));

router.get("/", getCredentials);
router.post("/generate", generateCredentials);
router.post("/bulk-generate", bulkGenerateCredentials);
router.patch("/:id/toggle", toggleCredential);
router.patch("/:id/reset-password", resetCredentialPassword);
router.delete("/:id", deleteCredential);

export default router;
