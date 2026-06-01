import { Request, Response } from "express";
import { FeeType, PaymentMethod, InvoiceStatus } from "@prisma/client";
import { prisma } from "../config/prisma";
import { z } from "zod";
import { asyncHandler } from "../utils/asyncHandler";
import { ValidationError, NotFoundError } from "../utils/AppError";
import { requireSid } from "../utils/tenant";

/** GET /api/invoices — List all invoices for the school */
export const getInvoices = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { status, studentId, gradeId } = req.query;

  const where: any = { schoolId: schoolId as string };
  if (status && typeof status === "string") where.status = status;
  if (studentId && typeof studentId === "string") where.studentId = studentId;
  if (gradeId && typeof gradeId === "string") where.student = { gradeId };

  const data = await prisma.invoice.findMany({
    where,
    include: {
      student: { 
        include: { 
          user: true, 
          grade: true,
          credentials: true,
          father: { include: { credentials: true } },
          mother: { include: { credentials: true } },
          guardian: { include: { credentials: true } }
        } 
      },
      payments: true
    },
    orderBy: { createdAt: "desc" }
  });

  res.json({ success: true, data });
});

/** POST /api/invoices — Create a single invoice */
export const createInvoice = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const payload = z.object({
    studentId: z.string(),
    feeType: z.nativeEnum(FeeType),
    amount: z.coerce.number().positive(), // mapped to totalAmount
    title: z.string().optional(),
    dueDate: z.string().optional(),
    notes: z.string().optional(),
  }).parse(req.body);

  const mergedNotes =
    payload.title && payload.notes ? `${payload.title}\n${payload.notes}` : (payload.title ?? payload.notes);

  const data = await prisma.invoice.create({
    data: {
      schoolId: schoolId as string,
      studentId: payload.studentId,
      feeType: payload.feeType,
      totalAmount: payload.amount,
      remaining: payload.amount,
      notes: mergedNotes,
      dueDate: payload.dueDate ? new Date(payload.dueDate) : undefined,
    }
  });

  // If due date is in the future, re-enable credentials (new payment arrangement)
  if (payload.dueDate && new Date(payload.dueDate) > new Date()) {
    const student = await prisma.student.findUnique({
      where: { id: payload.studentId },
      include: { father: true, mother: true, guardian: true }
    });
    if (student) {
      await prisma.appCredential.updateMany({
        where: { studentId: student.id },
        data: { isActive: true }
      });
      const parentIds = [student.father?.id, student.mother?.id, student.guardian?.id].filter(Boolean) as string[];
      if (parentIds.length > 0) {
        await prisma.appCredential.updateMany({
          where: { parentId: { in: parentIds } },
          data: { isActive: true }
        });
      }
    }
  }

  res.status(201).json({ success: true, data });
});

/** POST /api/invoices/bulk — Generate invoices for a whole grade */
export const createBulkInvoices = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const { gradeId, feeType, amount, title, dueDate, notes } = z.object({
    gradeId: z.string(),
    feeType: z.nativeEnum(FeeType),
    amount: z.coerce.number().positive(),
    title: z.string().optional(),
    dueDate: z.string().optional(),
    notes: z.string().optional(),
  }).parse(req.body);

  const mergedNotes = title && notes ? `${title}\n${notes}` : (title ?? notes);

  // Find all students in this grade for this school
  const students = await prisma.student.findMany({
    where: { schoolId: schoolId as string, gradeId }
  });

  if (students.length === 0) {
    throw new ValidationError("No students found in the selected grade.");
  }

  // Create invoices for each student
  const invoices = await Promise.all(
    students.map(student => 
      prisma.invoice.create({
        data: {
          schoolId: schoolId as string,
          studentId: student.id,
          feeType,
          totalAmount: amount,
          remaining: amount,
          notes: mergedNotes,
          dueDate: dueDate ? new Date(dueDate) : undefined,
        }
      })
    )
  );

  res.status(201).json({ success: true, count: invoices.length });
});

/** PATCH /api/invoices/:id/pay — Record a payment against an invoice */
export const payInvoice = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  const { amount, method, notes } = z.object({
    amount: z.coerce.number().positive(),
    method: z.nativeEnum(PaymentMethod).optional(),
    notes: z.string().optional(),
  }).parse(req.body);

  const invoice = await prisma.invoice.findFirst({
    where: { id: id as string, schoolId: schoolId as string }
  });

  if (!invoice) throw new NotFoundError("Invoice not found");

  // Create payment record
  const payment = await prisma.payment.create({
    data: {
      schoolId: schoolId as string,
      studentId: invoice.studentId,
      invoiceId: invoice.id,
      amount,
      feeType: invoice.feeType,
      paymentMethod: method ?? PaymentMethod.CASH,
      status: "PAID",
      notes,
      paidAt: new Date(),
    }
  });

  // Calculate total paid
  const allPayments = await prisma.payment.findMany({ where: { invoiceId: invoice.id, status: "PAID" } });
  const totalPaid = allPayments.reduce((acc, curr) => acc + Number(curr.amount), 0);

  const originalTotal = Number(invoice.totalAmount);
  const discount = Number(invoice.discount);
  const netRequired = originalTotal - discount;
  const newRemaining = Math.max(0, netRequired - totalPaid);

  // Update invoice status
  let newStatus: InvoiceStatus = "UNPAID";
  if (totalPaid >= netRequired && netRequired > 0) newStatus = "PAID";
  else if (totalPaid > 0) newStatus = "PARTIAL";
  else if (netRequired === 0) newStatus = "PAID";

  await prisma.invoice.update({
    where: { id: invoice.id },
    data: {
      status: newStatus,
      paid: totalPaid,
      remaining: newRemaining,
    }
  });

  // Auto re-enable credentials when invoice is fully paid
  if (newStatus === "PAID") {
    const fullInvoice = await prisma.invoice.findFirst({
      where: { id: invoice.id },
      include: { student: { include: { father: true, mother: true, guardian: true } } }
    });

    if (fullInvoice) {
      // Re-enable student credentials
      await prisma.appCredential.updateMany({
        where: { studentId: fullInvoice.studentId },
        data: { isActive: true }
      });

      // Re-enable parent credentials
      const parentIds = [
        fullInvoice.student.father?.id,
        fullInvoice.student.mother?.id,
        fullInvoice.student.guardian?.id
      ].filter(Boolean) as string[];

      if (parentIds.length > 0) {
        await prisma.appCredential.updateMany({
          where: { parentId: { in: parentIds } },
          data: { isActive: true }
        });
      }

      console.log(`[AUTO] Credentials re-enabled for student ${fullInvoice.studentId} after full payment.`);
    }
  }

  res.json({ success: true, payment, invoiceStatus: newStatus });
});

/** DELETE /api/invoices/:id — Delete an invoice */
export const deleteInvoice = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);

  const invoice = await prisma.invoice.findFirst({
    where: { id: id as string, schoolId: schoolId as string }
  });

  if (!invoice) throw new NotFoundError("Invoice not found");

  await prisma.invoice.delete({
    where: { id: invoice.id }
  });

  res.json({ success: true, message: "Invoice deleted successfully" });
});

/** PATCH /api/invoices/:id/discount — Apply a discount to an invoice */
export const applyDiscount = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  const { discountAmount, discountPercentage } = z.object({
    discountAmount: z.coerce.number().min(0).optional(),
    discountPercentage: z.coerce.number().min(0).max(100).optional(),
  }).parse(req.body);

  const invoice = await prisma.invoice.findFirst({
    where: { id: id as string, schoolId: schoolId as string }
  });

  if (!invoice) throw new NotFoundError("Invoice not found");

  let finalDiscount = Number(invoice.discount);
  
  if (discountPercentage !== undefined) {
    finalDiscount = (Number(invoice.totalAmount) * discountPercentage) / 100;
  } else if (discountAmount !== undefined) {
    finalDiscount = discountAmount;
  }

  const totalPaid = Number(invoice.paid);
  const originalTotal = Number(invoice.totalAmount);
  const newRemaining = Math.max(0, originalTotal - finalDiscount - totalPaid);
  
  let newStatus: InvoiceStatus = "UNPAID";
  const netRequired = originalTotal - finalDiscount;
  
  if (totalPaid >= netRequired && netRequired > 0) newStatus = "PAID";
  else if (totalPaid > 0) newStatus = "PARTIAL";
  else if (netRequired === 0) newStatus = "PAID"; // Fully discounted

  const updated = await prisma.invoice.update({
    where: { id: invoice.id },
    data: {
      discount: finalDiscount,
      remaining: newRemaining,
      status: newStatus
    }
  });

  res.json({ success: true, data: updated });
});

/** PATCH /api/invoices/:id/toggle-access — Enable/Disable student & parent credentials */
export const toggleInvoiceAccess = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  const { isActive } = z.object({
    isActive: z.boolean()
  }).parse(req.body);

  const invoice = await prisma.invoice.findFirst({
    where: { id: id as string, schoolId: schoolId as string },
    include: { student: { include: { father: true, mother: true, guardian: true } } }
  });

  if (!invoice) throw new NotFoundError("Invoice not found");

  // Update Student Credentials
  const studentResult = await prisma.appCredential.updateMany({
    where: { studentId: invoice.studentId },
    data: { isActive }
  });

  // Update Parent Credentials (all linked types)
  const parentIds = [
    invoice.student.father?.id,
    invoice.student.mother?.id,
    invoice.student.guardian?.id
  ].filter(Boolean) as string[];

  let parentResult = { count: 0 };
  if (parentIds.length > 0) {
    parentResult = await prisma.appCredential.updateMany({
      where: { parentId: { in: parentIds } },
      data: { isActive }
    });
  }

  console.log(`Updated Access: ${isActive}. Students: ${studentResult.count}, Parents: ${parentResult.count}`);

  res.json({ 
    success: true, 
    message: `Account access ${isActive ? 'enabled' : 'disabled'} for student and linked parents.`,
    updatedCount: studentResult.count + parentResult.count
  });
});

/** PATCH /api/invoices/:id/deadline — Update invoice due date */
export const updateInvoiceDeadline = asyncHandler(async (req: Request, res: Response) => {
  const id = req.params.id as string;
  const schoolId = requireSid(req);
  const { dueDate } = z.object({
    dueDate: z.string()
  }).parse(req.body);

  const invoice = await prisma.invoice.findFirst({
    where: { id, schoolId }
  });

  if (!invoice) throw new NotFoundError("Invoice not found");
  if (invoice.status === "PAID") {
    throw new ValidationError("Cannot update deadline for a paid invoice");
  }

  const updated = await prisma.invoice.update({
    where: { id },
    data: { dueDate: new Date(dueDate) }
  });

  res.json({ success: true, data: updated });
});


