import { Router } from "express";
import { auth } from "../../middlewares/auth";
import { tenantScope } from "../../middlewares/tenantScope";
import { roleGuard } from "../../middlewares/roleGuard";
import { Role } from "@prisma/client";
import {
  getInvoices,
  createInvoice,
  createBulkInvoices,
  payInvoice,
  deleteInvoice,
  applyDiscount,
  toggleInvoiceAccess,
  updateInvoiceDeadline
} from "../../controllers/invoice.controller";

const router = Router();

router.use(auth, tenantScope);

router.get("/", getInvoices);
router.post("/", roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), createInvoice);
router.post("/bulk", roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), createBulkInvoices);
router.patch("/:id/pay", roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), payInvoice);
router.patch("/:id/discount", roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), applyDiscount);
router.patch("/:id/toggle-access", roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), toggleInvoiceAccess);
router.patch("/:id/deadline", roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), updateInvoiceDeadline);
router.delete("/:id", roleGuard([Role.ADMIN, Role.SCHOOL_ADMIN, Role.SUPER_ADMIN]), deleteInvoice);

export default router;
