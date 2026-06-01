import { Router } from "express";
import { getFeeStructures, createFeeStructure, deleteFeeStructure } from "../../controllers/feeStructure.controller";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";

const router = Router();

router.use(requireAuth, tenantScope);

router.get("/", getFeeStructures);
router.post("/", createFeeStructure);
router.delete("/:id", deleteFeeStructure);

export default router;
