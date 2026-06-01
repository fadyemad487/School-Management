import { Router } from "express";
import { auth } from "../../middlewares/auth";
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

router.use(auth);

router.get("/", getInvoices);
router.post("/", createInvoice);
router.post("/bulk", createBulkInvoices);
router.patch("/:id/pay", payInvoice);
router.patch("/:id/discount", applyDiscount);
router.patch("/:id/toggle-access", toggleInvoiceAccess);
router.patch("/:id/deadline", updateInvoiceDeadline);
router.delete("/:id", deleteInvoice);

export default router;
