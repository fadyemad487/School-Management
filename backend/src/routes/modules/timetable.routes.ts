import { Router } from "express";
import { getTimetable, upsertTimetableSlot, deleteTimetableSlot, autoGenerateTimetable } from "../../controllers/timetable.controller";
import { requireAuth } from "../../middlewares/auth";
import { requireMobileAuth } from "../../middlewares/mobileAuth";
import { tenantScope } from "../../middlewares/tenantScope";
import { prisma } from "../../config/prisma";

const router = Router();

// Mobile teacher schedule — teacher sees their own timetable
router.get("/mobile/my-schedule", requireMobileAuth, async (req, res) => {
  const teacherId = (req as any).teacherId;
  const schoolId = req.schoolId;
  if (!teacherId) return res.status(401).json({ success: false, message: "Unauthorized" });

  const data = await prisma.timetable.findMany({
    where: { schoolId: schoolId!, teacherId },
    include: {
      subject: true,
      class: true,
    },
    orderBy: [{ day: "asc" }, { periodNumber: "asc" }],
  });

  res.json({ success: true, data });
});

router.get("/", requireAuth, tenantScope, getTimetable);
router.post("/auto-generate", requireAuth, tenantScope, autoGenerateTimetable);
router.post("/", requireAuth, tenantScope, upsertTimetableSlot);
router.delete("/:id", requireAuth, tenantScope, deleteTimetableSlot);

export default router;
