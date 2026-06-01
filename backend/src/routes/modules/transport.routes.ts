import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import {
  getBuses,
  upsertBus,
  toggleTrip,
  getRoutes,
  createRoute,
  deleteBus,
  deleteRoute,
  getTransportStudents,
  assignStudentsToBus
} from "../../controllers/transport.controller";
import {
  getDrivers,
  createDriver,
  updateDriver,
  deleteDriver
} from "../../controllers/driver.controller";
import {
  getSupervisors,
  createSupervisor,
  updateSupervisor,
  deleteSupervisor
} from "../../controllers/supervisor.controller";
const router = Router();

router.use(requireAuth, tenantScope);

router.get("/buses", getBuses);
router.post("/buses", upsertBus);
router.post("/buses/:id/trip", toggleTrip);
router.post("/buses/:id/students", assignStudentsToBus);

router.get("/students", getTransportStudents);

router.get("/routes", getRoutes);
router.post("/routes", createRoute);
router.delete("/buses/:id", deleteBus);
router.delete("/routes/:id", deleteRoute);

router.get("/drivers", getDrivers);
router.post("/drivers", createDriver);
router.put("/drivers/:id", updateDriver);
router.delete("/drivers/:id", deleteDriver);

router.get("/supervisors", getSupervisors);
router.post("/supervisors", createSupervisor);
router.put("/supervisors/:id", updateSupervisor);
router.delete("/supervisors/:id", deleteSupervisor);

export default router;
