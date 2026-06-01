import type { Request, Response } from "express";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { requireSid } from "../utils/tenant";

export const getReportsOverview = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);

  const [
    students,
    teachers,
    classes,
    grades,
    subjects,
    invoices,
    payments,
    notifications,
  ] = await Promise.all([
    prisma.student.count({ where: { schoolId } }),
    prisma.teacher.count({ where: { schoolId } }),
    prisma.schoolClass.count({ where: { schoolId } }),
    prisma.grade.count({ where: { schoolId } }),
    prisma.subject.count({ where: { schoolId } }),
    prisma.invoice.count({ where: { schoolId } }),
    prisma.payment.count({ where: { schoolId } }),
    prisma.notification.count({ where: { schoolId } }),
  ]);

  res.json({
    success: true,
    data: {
      students,
      teachers,
      classes,
      grades,
      subjects,
      invoices,
      payments,
      notifications,
    },
  });
});

