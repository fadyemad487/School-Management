import { Router } from "express";
import studentRoutes from "./modules/student.routes";
import teacherRoutes from "./modules/teacher.routes";
import classRoutes from "./modules/class.routes";
import attendanceRoutes from "./modules/attendance.routes";
import paymentRoutes from "./modules/payment.routes";
import announcementRoutes from "./modules/announcement.routes";
import dashboardRoutes from "./modules/dashboard.routes";
import authRoutes from "./modules/auth.routes";
import admissionRoutes from "./modules/admission.routes";
import academicRoutes from "./modules/academic.routes";
import credentialRoutes from "./modules/credential.routes";
import invoiceRoutes from "./modules/invoice.routes";
import transportRoutes from "./modules/transport.routes";
import settingsRoutes from "./modules/settings.routes";
import timetableRoutes from "./modules/timetable.routes";
import subjectRoutes from "./modules/subject.routes";
import homeworkRoutes from "./modules/homework.routes";
import examRoutes from "./modules/exam.routes";
import parentRoutes from "./modules/parent.routes";
import userRoutes from "./modules/user.routes";
import notificationRoutes from "./modules/notification.routes";
import reportsRoutes from "./modules/reports.routes";
import schoolRoutes from "./modules/school.routes";
import resultRoutes from "./modules/result.routes";
import zoomRoutes from "./modules/zoom.routes";
import chatRoutes from "./modules/chat.routes";

import feeStructureRoutes from "./modules/feeStructure.routes";
import archiveRoutes from "./modules/archive.routes";
import leaveRoutes from "./modules/leave.routes";
import scheduleRoutes from "./modules/schedule.routes";

import behaviorRoutes from "./modules/behavior.routes";
import dailyReportRoutes from "./modules/dailyReport.routes";
import studentTaskRoutes from "./modules/studentTask.routes";
import conversationRoutes from "./modules/conversation.routes";

const router = Router();

// Health check
router.get("/health", (_req, res) => {
  res.json({ success: true, message: "API is healthy" });
});

// Auth & Webhooks
router.use("/auth", authRoutes);

// Protected Dashboard Routes
router.use("/dashboard", dashboardRoutes);

// Admission & Academic Structure
router.use("/admissions", admissionRoutes);
router.use("/academic", academicRoutes);
router.use("/credentials", credentialRoutes);

// Protected Resource Routes
router.use("/students", studentRoutes);
router.use("/teachers", teacherRoutes);
router.use("/classes", classRoutes);
router.use("/attendance", attendanceRoutes);
router.use("/payments", paymentRoutes);
router.use("/invoices", invoiceRoutes);
router.use("/transport", transportRoutes);
router.use("/announcements", announcementRoutes);
router.use("/settings", settingsRoutes);
router.use("/timetable", timetableRoutes);
router.use("/subjects", subjectRoutes);
router.use("/homework", homeworkRoutes);
router.use("/exams", examRoutes);
router.use("/parents", parentRoutes);
router.use("/users", userRoutes);
router.use("/notifications", notificationRoutes);
router.use("/reports", reportsRoutes);
router.use("/school", schoolRoutes);
router.use("/results", resultRoutes);
router.use("/zoom", zoomRoutes);
router.use("/fee-structures", feeStructureRoutes);
router.use("/chat", chatRoutes);
router.use("/archives", archiveRoutes);
router.use("/leaves", leaveRoutes);
router.use("/schedules", scheduleRoutes);

router.use("/behavior", behaviorRoutes);
router.use("/daily-reports", dailyReportRoutes);
router.use("/student-tasks", studentTaskRoutes);
router.use("/conversations", conversationRoutes);

import aiRoutes from "./modules/ai.routes";
import mobileTransportRoutes from "./modules/mobile.transport.routes";

router.use("/ai", aiRoutes);
router.use("/mobile/transport", mobileTransportRoutes);

export default router;
