import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { 
  listSchoolResults, 
  uploadSchoolResult, 
  deleteSchoolResult 
} from "../../controllers/result.controller";

const router = Router();

router.use(requireAuth);
router.use(tenantScope);

router.get("/", listSchoolResults);
router.post("/", uploadSchoolResult);
router.delete("/:id", deleteSchoolResult);

export default router;
