import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";
import {
  getDriverDashboard,
  getSupervisorDashboard,
  markDriverBusAttendance,
  markBusAttendance,
  updateSupervisorProfile,
  updateDriverProfile,
  updateDriverLocation
} from "../../controllers/mobile.transport.controller";

const router = Router();

router.use(requireAuth);

router.get("/driver/dashboard", getDriverDashboard);
router.put("/driver/profile", updateDriverProfile);
router.post("/driver/location", updateDriverLocation);
router.post("/driver/attendance", markDriverBusAttendance);
router.get("/supervisor/dashboard", getSupervisorDashboard);
router.post("/supervisor/attendance", markBusAttendance);
router.put("/supervisor/profile", updateSupervisorProfile);

export default router;
