import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";
import { requireMobileAuth } from "../../middlewares/mobileAuth";
import { tenantScope } from "../../middlewares/tenantScope";
import { 
  attachParentToStudent, 
  listParents, 
  updateParent, 
  getMobileParentDashboard, 
  updateMobileParentProfile,
  getMobileParentDevices,
  logoutMobileParentDevice,
  logoutAllOtherMobileDevices,
  changeMobileParentPassword,
  getParentSocialStatus,
  linkParentSocialAccount,
  unlinkParentSocialAccount
} from "../../controllers/parent.controller";

const router = Router();

router.get("/", requireAuth, tenantScope, listParents);
router.get("/mobile/dashboard", requireMobileAuth, getMobileParentDashboard);
router.put("/mobile/profile", requireMobileAuth, updateMobileParentProfile);

// Password Change route
router.post("/mobile/change-password", requireMobileAuth, changeMobileParentPassword);

// Device Sessions routes
router.get("/mobile/devices", requireMobileAuth, getMobileParentDevices);
router.post("/mobile/devices/logout", requireMobileAuth, logoutMobileParentDevice);
router.post("/mobile/devices/logout-all", requireMobileAuth, logoutAllOtherMobileDevices);

// Social linking routes
router.get("/mobile/social/status", requireMobileAuth, getParentSocialStatus);
router.post("/mobile/social/link", requireMobileAuth, linkParentSocialAccount);
router.post("/mobile/social/unlink", requireMobileAuth, unlinkParentSocialAccount);

router.patch("/:id", requireAuth, tenantScope, updateParent);
router.post("/students/:studentId/attach", requireAuth, tenantScope, attachParentToStudent);

export default router;
