import { prisma } from "../config/prisma";

/**
 * Smart overdue invoice checker.
 * Only locks accounts if ALL unpaid invoices for a student are overdue.
 * If the student has any unpaid invoice with a future due date, the account stays active.
 */
export async function checkOverdueInvoices() {
  const now = new Date();
  console.log(`[CRON] Checking overdue invoices at ${now.toISOString()}...`);

  try {
    // Find all unpaid invoices with a due date
    const unpaidInvoices = await prisma.invoice.findMany({
      where: {
        status: { not: "PAID" },
        dueDate: { not: null }
      },
      include: {
        student: {
          include: {
            father: true,
            mother: true,
            guardian: true
          }
        }
      }
    });

    if (unpaidInvoices.length === 0) {
      console.log(`[CRON] No unpaid invoices with due dates found.`);
      return;
    }

    // Group invoices by studentId
    const byStudent = new Map<string, typeof unpaidInvoices>();
    for (const inv of unpaidInvoices) {
      const list = byStudent.get(inv.studentId) || [];
      list.push(inv);
      byStudent.set(inv.studentId, list);
    }

    let lockedStudents = 0;
    let lockedParents = 0;

    for (const [studentId, invoices] of byStudent) {
      // Check: does this student have ANY unpaid invoice with a FUTURE due date?
      const hasFutureDueDate = invoices.some(
        inv => inv.dueDate && new Date(inv.dueDate) > now
      );

      // Only lock if ALL due dates have passed (no future grace period)
      if (hasFutureDueDate) continue;

      // All invoices are overdue — lock credentials
      const student = invoices[0].student;

      const studentResult = await prisma.appCredential.updateMany({
        where: { studentId, isActive: true },
        data: { isActive: false }
      });
      lockedStudents += studentResult.count;

      const parentIds = [
        student.father?.id,
        student.mother?.id,
        student.guardian?.id
      ].filter(Boolean) as string[];

      if (parentIds.length > 0) {
        const parentResult = await prisma.appCredential.updateMany({
          where: { parentId: { in: parentIds }, isActive: true },
          data: { isActive: false }
        });
        lockedParents += parentResult.count;
      }
    }

    console.log(`[CRON] Done. Locked ${lockedStudents} student accounts and ${lockedParents} parent accounts.`);
  } catch (error) {
    console.error("[CRON] Error checking overdue invoices:", error);
  }
}

/**
 * Start the overdue invoice checker.
 * Runs immediately on startup, then every hour.
 */
export function startOverdueChecker() {
  // Run immediately on startup
  checkOverdueInvoices();

  // Then run every hour (3600000 ms)
  const INTERVAL_MS = 60 * 60 * 1000; // 1 hour
  setInterval(checkOverdueInvoices, INTERVAL_MS);
  console.log(`[CRON] Overdue invoice checker started. Interval: every 1 hour.`);
}
