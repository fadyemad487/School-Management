import { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { Role } from "@prisma/client";

/** Dashboard stats & charts aggregated from multiple tables */
// Cache object to store overview data per school
const overviewCache = new Map<string, { data: any; timestamp: number }>();
const CACHE_TTL = 60 * 1000; // 1 minute

export const getOverview = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = req.schoolId;
  const userId = req.userId;
  
  const cacheKey = `${schoolId}-${userId}`;
  const now = Date.now();

  // Check cache first
  if (schoolId && overviewCache.has(cacheKey)) {
    const cached = overviewCache.get(cacheKey)!;
    if (now - cached.timestamp < CACHE_TTL) {
      console.log("DEBUG: Serving overview from cache for schoolId:", schoolId);
      res.json({ success: true, data: cached.data, _cached: true });
      return;
    }
  }

  console.log("DEBUG: getOverview fetching from DB for schoolId:", schoolId);

  try {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);
    
    const lastMonth = new Date();
    lastMonth.setMonth(lastMonth.getMonth() - 1);

    const where: any = schoolId ? { schoolId } : {};

    // 1. Basic Stats with catch blocks
    const [
      students,
      activeStudents,
      newStudentsThisMonth,
      newStudentsLastMonth,
      teachers,
      activeTeachers,
      newTeachersThisMonth,
      newTeachersLastMonth,
      drivers,
      activeDrivers,
      newDriversThisMonth,
      newDriversLastMonth,
      subjects,
      activeSubjects,
      classes,
      paymentsAgg,
      schools,
      // NEW CONCURRENT QUERIES
      attStudPresent, attStudAbsent, attStudLate, attStudEmerg,
      attTeachPresent, attTeachAbsent, attTeachLate, attTeachEmerg,
      attDrivePresent, attDriveAbsent, attDriveLate, attDriveEmerg,
      pendingLeavesList,
      upcomingEventsList,
      totalEarningsVal,
      totalExpensesVal,
      totalFinesVal,
      unpaidCount,
      unpaidRecent,
      perfHigh,
      perfMedium,
      perfLow
    ] = await Promise.all([
      prisma.student.count({ where }).catch(() => 0),
      prisma.student.count({ where: { ...where, status: "ACTIVE" } }).catch(() => 0),
      prisma.student.count({ where: { ...where, createdAt: { gte: todayStart } } }).catch(() => 0),
      prisma.student.count({ where: { ...where, createdAt: { gte: lastMonth, lt: todayStart } } }).catch(() => 0),
      
      prisma.teacher.count({ where }).catch(() => 0),
      prisma.teacher.count({ where: { ...where, status: "ACTIVE" } }).catch(() => 0),
      prisma.teacher.count({ where: { ...where, createdAt: { gte: todayStart } } }).catch(() => 0),
      prisma.teacher.count({ where: { ...where, createdAt: { gte: lastMonth, lt: todayStart } } }).catch(() => 0),

      prisma.driver.count({ where }).catch(() => 0),
      prisma.driver.count({ where: { ...where, status: "ACTIVE" } }).catch(() => 0),
      prisma.driver.count({ where: { ...where, createdAt: { gte: todayStart } } }).catch(() => 0),
      prisma.driver.count({ where: { ...where, createdAt: { gte: lastMonth, lt: todayStart } } }).catch(() => 0),

      prisma.subject.count({ where }).catch(() => 0),
      prisma.subject.count({ where: { ...where, teacherSubjects: { some: {} } } }).catch(() => 0),
      prisma.schoolClass.count({ where }).catch(() => 0),
      prisma.payment.aggregate({ where, _sum: { amount: true } }).catch(() => ({ _sum: { amount: 0 } })),
      schoolId ? Promise.resolve(0) : prisma.school.count().catch(() => 0),

      // Attendance Student
      prisma.attendance.count({ where: { ...where, type: "STUDENT", status: "PRESENT", date: { gte: todayStart } } }).catch(() => 0),
      prisma.attendance.count({ where: { ...where, type: "STUDENT", status: "ABSENT", date: { gte: todayStart } } }).catch(() => 0),
      prisma.attendance.count({ where: { ...where, type: "STUDENT", status: "LATE", date: { gte: todayStart } } }).catch(() => 0),
      prisma.attendance.count({ where: { ...where, type: "STUDENT", status: "EMERGENCY", date: { gte: todayStart } } }).catch(() => 0),
      // Attendance Teacher
      prisma.attendance.count({ where: { ...where, type: "TEACHER", status: "PRESENT", date: { gte: todayStart } } }).catch(() => 0),
      prisma.attendance.count({ where: { ...where, type: "TEACHER", status: "ABSENT", date: { gte: todayStart } } }).catch(() => 0),
      prisma.attendance.count({ where: { ...where, type: "TEACHER", status: "LATE", date: { gte: todayStart } } }).catch(() => 0),
      prisma.attendance.count({ where: { ...where, type: "TEACHER", status: "EMERGENCY", date: { gte: todayStart } } }).catch(() => 0),
      // Attendance Driver
      prisma.attendance.count({ where: { ...where, type: "DRIVER", status: "PRESENT", date: { gte: todayStart } } }).catch(() => 0),
      prisma.attendance.count({ where: { ...where, type: "DRIVER", status: "ABSENT", date: { gte: todayStart } } }).catch(() => 0),
      prisma.attendance.count({ where: { ...where, type: "DRIVER", status: "LATE", date: { gte: todayStart } } }).catch(() => 0),
      prisma.attendance.count({ where: { ...where, type: "DRIVER", status: "EMERGENCY", date: { gte: todayStart } } }).catch(() => 0),

      // Other lists
      prisma.leaveRequest.findMany({ where: { ...where, status: "PENDING" }, include: { student: { include: { user: true } }, teacher: { include: { user: true } } }, take: 10, orderBy: { applyDate: "desc" } }).catch(() => []),
      prisma.calendarEvent.findMany({ where: { ...where }, take: 3, orderBy: [{ year: "asc" }, { month: "asc" }, { day: "asc" }] }).catch(() => []),
      
      // Finance totals
      prisma.payment.aggregate({ where: { ...where, status: "PAID" }, _sum: { amount: true } }).then(r => Number(r._sum.amount || 0)).catch(() => 0),
      prisma.expense.aggregate({ where: { ...where }, _sum: { amount: true } }).then(r => Number(r._sum.amount || 0)).catch(() => 0),
      prisma.payment.aggregate({ where: { ...where, status: "PAID", feeType: "FINE" }, _sum: { amount: true } }).then(r => Number(r._sum.amount || 0)).catch(() => 0),
      
      // Invoices
      prisma.invoice.count({ where: { ...where, status: { in: ["UNPAID", "PARTIAL"] } } }).catch(() => 0),
      prisma.invoice.findMany({ where: { ...where, status: { in: ["UNPAID", "PARTIAL"] } }, take: 4, distinct: ['studentId'], select: { student: { select: { id: true, photo: true, user: { select: { fullName: true } } } } } }).catch(() => []),
      
      // Performance
      prisma.invoice.count({ where: { ...where, status: "PAID" } }).catch(() => 0),
      prisma.invoice.count({ where: { ...where, status: "PARTIAL" } }).catch(() => 0),
      prisma.invoice.count({ where: { ...where, status: "UNPAID" } }).catch(() => 0),
    ]);

    const calculateChange = (current: number, previous: number) => {
      if (previous === 0) return current > 0 ? 100 : 0;
      return Math.round(((current - previous) / previous) * 100);
    };

    const studentChange = calculateChange(newStudentsThisMonth, newStudentsLastMonth);
    const teacherChange = calculateChange(newTeachersThisMonth, newTeachersLastMonth);
    const driverChange = calculateChange(newDriversThisMonth, newDriversLastMonth);
    const subjectChange = 0;

    // 2. Charts & Lists
    const [attendanceToday, attendance30d, classesList, paymentsRecent, announcements, notifications] = await Promise.all([
      prisma.attendance.findMany({ where: { ...where, date: { gte: todayStart, lte: todayEnd } } }).catch(() => []),
      prisma.attendance.findMany({ where: { ...where, date: { gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } } }).catch(() => []),
      prisma.schoolClass.findMany({ where, select: { id: true, name: true, section: true, maxCapacity: true, roomNumber: true, floor: true, _count: { select: { students: true } } } }).catch(() => []),
      prisma.payment.findMany({ where, take: 200, orderBy: { createdAt: "desc" } }).catch(() => []),
      prisma.announcement.findMany({ where, take: 5, orderBy: { createdAt: "desc" } }).catch(() => []),
      prisma.notification.findMany({ 
        where: { ...where, OR: [{ recipientId: userId }, { recipientId: null }] },
        take: 5,
        orderBy: { sentAt: "desc" } 
      }).catch(() => []),
    ]);

    // 3. Process data
    const totalAttendance = attendanceToday.length;
    const presentCount = attendanceToday.filter((a: any) => a.status === "PRESENT").length;
    const attendanceRateToday = totalAttendance === 0 ? 0 : Math.round((presentCount / totalAttendance) * 100);

    const revenueByMonth = new Map<string, number>();
    for (const p of (paymentsRecent as any[])) {
      const paymentDate = p.paidAt || p.createdAt;
      if (!paymentDate) continue;
      const d = new Date(paymentDate);
      const key = `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
      revenueByMonth.set(key, (revenueByMonth.get(key) ?? 0) + Number(p.amount));
    }
    const monthlyRevenue = Array.from(revenueByMonth.entries())
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => a.month.localeCompare(b.month));

    const byClass = new Map<string, { present: number; total: number }>();
    for (const row of (attendance30d as any[])) {
      if (!row.classId) continue;
      const cid = row.classId;
      if (!byClass.has(cid)) byClass.set(cid, { present: 0, total: 0 });
      const c = byClass.get(cid)!;
      c.total += 1;
      if (row.status === "PRESENT") c.present += 1;
    }

    // 4. Fees Collection Trend (Dynamic Period)
    const period = (req.query.period as string) || 'last6months';
    const feesCollectionTrend: any[] = [];
    
    if (period === 'today') {
      // Last 24 hours in 4-hour blocks
      for (let i = 5; i >= 0; i--) {
        const d = new Date();
        d.setHours(d.getHours() - (i * 4), 0, 0, 0);
        const key = d.toISOString();
        const name = d.toLocaleTimeString('en-US', { hour: 'numeric', hour12: true });
        feesCollectionTrend.push({ key, name, total: 0, collected: 0, start: new Date(d), end: new Date(d.getTime() + 4 * 60 * 60 * 1000) });
      }
    } else if (period === 'week') {
      // Last 7 days
      for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        d.setHours(0,0,0,0);
        const key = d.toISOString().split('T')[0];
        const name = d.toLocaleDateString('en-US', { weekday: 'short' });
        feesCollectionTrend.push({ key, name, total: 0, collected: 0, start: new Date(d), end: new Date(d.getTime() + 24 * 60 * 60 * 1000) });
      }
    } else if (period === 'month') {
      // Last 4 weeks
      for (let i = 3; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - (i * 7));
        d.setHours(0,0,0,0);
        const key = `week-${i}`;
        const name = i === 0 ? 'This Week' : `${i}w ago`;
        feesCollectionTrend.push({ key, name, total: 0, collected: 0, start: new Date(d.getTime() - 7 * 24 * 60 * 60 * 1000), end: new Date(d.getTime()) });
      }
    } else {
      // Last 6 Months (Default)
      for (let i = 5; i >= 0; i--) {
        const d = new Date();
        d.setMonth(d.getMonth() - i);
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
        const name = d.toLocaleDateString('en-US', { month: 'short' });
        const start = new Date(d.getFullYear(), d.getMonth(), 1);
        const end = new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59);
        feesCollectionTrend.push({ key, name, total: 0, collected: 0, start, end });
      }
    }

    const invoicesRecent = await prisma.invoice.findMany({
      where: {
        ...where,
        createdAt: { gte: feesCollectionTrend[0].start }
      },
      orderBy: { createdAt: "asc" },
    }).catch(() => []);

    for (const inv of (invoicesRecent as any[])) {
      const invDate = new Date(inv.createdAt);
      const entry = feesCollectionTrend.find(t => invDate >= t.start && invDate <= t.end);
      if (entry) {
        entry.total += Number(inv.totalAmount || 0);
        entry.collected += Number(inv.paid || 0);
      }
    }
    
    const classSuccessVsFail = (classesList as any[]).map((c) => {
      const agg = byClass.get(c.id) ?? { present: 0, total: 0 };
      const passRate = agg.total === 0 ? 0 : Math.round((agg.present / agg.total) * 1000) / 10;
      const failRate = Math.max(0, Math.round((100 - passRate) * 10) / 10);
      return { classId: c.id, label: `${c.name} ${c.section}`.trim(), passRate, failRate, samples: agg.total };
    });

    const pendingPayments = await prisma.payment.aggregate({
      where: { ...where, status: "PENDING" },
      _count: { id: true },
      _sum: { amount: true }
    }).catch(() => ({ _count: { id: 0 }, _sum: { amount: 0 } }));

    const homeworkSentToday = await prisma.homework.count({
      where: { ...where, sentDate: { gte: todayStart, lte: todayEnd } }
    }).catch(() => 0);

    const activeBuses = await prisma.bus.count({
      where: { ...where, status: "ACTIVE" }
    }).catch(() => 0);

    const resData = {
      totalStudents: students,
      activeStudents,
      inactiveStudents: students - activeStudents,
      studentChange,
      totalTeachers: teachers,
      activeTeachers,
      inactiveTeachers: teachers - activeTeachers,
      teacherChange,
      totalDrivers: drivers,
      activeDrivers,
      inactiveDrivers: drivers - activeDrivers,
      driverChange,
      totalSubjects: subjects,
      activeSubjects,
      inactiveSubjects: subjects - activeSubjects,
      subjectChange,
      totalClasses: classes,
      totalRevenue: Number(paymentsAgg?._sum?.amount ?? 0),
      totalSchools: schools,
      attendanceRateToday,
      attendanceStats: {
        students: {
          present: attStudPresent,
          absent: attStudAbsent,
          late: attStudLate,
          emergency: attStudEmerg,
        },
        teachers: {
          present: attTeachPresent,
          absent: attTeachAbsent,
          late: attTeachLate,
          emergency: attTeachEmerg,
        },
        drivers: {
          present: attDrivePresent,
          absent: attDriveAbsent,
          late: attDriveLate,
          emergency: attDriveEmerg,
        },
      },
      absentStudentsToday: totalAttendance - presentCount,
      pendingFeesCount: pendingPayments._count.id,
      pendingFeesAmount: Number(pendingPayments._sum.amount ?? 0),
      homeworkSentToday,
      activeBuses,
      monthlyRevenue,
      feesCollectionTrend,
      classSuccessVsFail,
      latestNotifications: (notifications as any[]).map(n => ({
        id: n.id, 
        type: (n.type || "GENERAL").toLowerCase(), 
        title: n.title, 
        message: n.message, 
        createdAt: n.sentAt ? new Date(n.sentAt).toISOString() : new Date().toISOString()
      })),
      latestAnnouncements: (announcements as any[]).map(a => ({
        id: a.id, 
        title: a.title, 
        audience: a.audience, 
        excerpt: (a.body || "").substring(0, 100), 
        createdAt: a.createdAt ? new Date(a.createdAt).toISOString() : new Date().toISOString()
      })),
      academicClasses: (classesList as any[]).slice(0, 5).map(c => ({
        id: c.id,
        name: c.name,
        section: c.section,
        capacity: c.maxCapacity,
        studentsCount: c._count?.students || 0,
        room: c.roomNumber,
        floor: c.floor
      })),
      pendingLeaves: pendingLeavesList,
      upcomingEvents: upcomingEventsList,
      totalEarnings: totalEarningsVal,
      totalExpenses: totalExpensesVal,
      totalFines: totalFinesVal,
      unpaidStudents: {
        count: unpaidCount,
        recent: unpaidRecent
      },
      platformPerformance: {
        high: perfHigh,
        medium: perfMedium,
        low: perfLow,
      }
    };

    // Save to cache before returning
    if (schoolId) {
      overviewCache.set(cacheKey, { data: resData, timestamp: Date.now() });
    }

    res.json({
      success: true,
      data: resData,
    });
  } catch (err: any) {
    console.error("FATAL OVERVIEW ERROR:", err);
    res.status(500).json({ success: false, message: "Internal server error during dashboard aggregation", error: err.message });
  }
});

/** Utility to clear dashboard cache for a school (call when data changes) */
export const clearDashboardCache = (schoolId?: string) => {
  if (!schoolId) {
    overviewCache.clear();
    return;
  }
  for (const key of Array.from(overviewCache.keys())) {
    if (key.startsWith(schoolId)) {
      overviewCache.delete(key);
    }
  }
};
