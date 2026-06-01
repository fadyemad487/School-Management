"use client";

import React, { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { 
  FileText, 
  Plus, 
  CreditCard, 
  Filter, 
  Search, 
  CheckCircle, 
  Clock, 
  AlertCircle,
  MoreVertical,
  Printer,
  ChevronRight,
  Zap,
  ArrowLeft,
  ArrowRight,
  Trash2,
  Percent,
  Lock,
  Unlock,
  ShieldAlert
} from "lucide-react";
import Link from "next/link";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";

export default function InvoicesPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [isBulkModalOpen, setIsBulkModalOpen] = useState(false);
  const [isInvoiceModalOpen, setIsInvoiceModalOpen] = useState(false);
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [isDiscountModalOpen, setIsDiscountModalOpen] = useState(false);
  const [isDeadlineModalOpen, setIsDeadlineModalOpen] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState<any>(null);
  const [newDeadline, setNewDeadline] = useState("");
  
  const [bulkData, setBulkData] = useState({
    gradeId: "",
    amount: "",
    feeType: "TUITION",
    title: "مصروفات الفصل الدراسي الأول",
    dueDate: ""
  });

  const [invoiceData, setInvoiceData] = useState({
    studentId: "",
    amount: "",
    feeType: "TUITION",
    title: "",
    dueDate: ""
  });

  const [paymentData, setPaymentData] = useState({
    amount: "",
    notes: "",
    paymentType: "FULL" // or PARTIAL
  });

  const [discountData, setDiscountData] = useState({
    type: "PERCENTAGE", // or FIXED
    value: ""
  });

  const { data: invoices, isLoading } = useQuery({
    queryKey: ["invoices"],
    queryFn: async () => (await api.get("/invoices")).data.data
  });

  const { data: grades } = useQuery({ queryKey: ["grades"], queryFn: () => api.get("/academic/grades").then(res => res.data.data) });
  const { data: students } = useQuery({ queryKey: ["students"], queryFn: () => api.get("/students").then(res => res.data.data) });

  const bulkMutation = useMutation({
    mutationFn: async (data: any) => await api.post("/invoices/bulk", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
      setIsBulkModalOpen(false);
      alert(t('alert_bulk_success'));
    }
  });

  const invoiceMutation = useMutation({
    mutationFn: async (data: any) => await api.post("/invoices", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
      setIsInvoiceModalOpen(false);
      alert(t('alert_invoice_success'));
    }
  });

  const payMutation = useMutation({
    mutationFn: async (data: any) => await api.patch(`/invoices/${selectedInvoice.id}/pay`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
      setIsPaymentModalOpen(false);
      alert(t('alert_payment_success'));
    }
  });

  const discountMutation = useMutation({
    mutationFn: async (data: any) => await api.patch(`/invoices/${selectedInvoice.id}/discount`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
      setIsDiscountModalOpen(false);
      alert(isAr ? "تم تطبيق التخفيض بنجاح" : "Discount applied successfully");
    }
  });

  const toggleAccessMutation = useMutation({
    mutationFn: async ({ id, isActive }: { id: string, isActive: boolean }) => 
      await api.patch(`/invoices/${id}/toggle-access`, { isActive }),
    onMutate: async ({ id, isActive }) => {
      await queryClient.cancelQueries({ queryKey: ["invoices"] });
      const previousInvoices = queryClient.getQueryData(["invoices"]);
      // Optimistically update — cache is a plain array
      queryClient.setQueryData(["invoices"], (old: any) => {
        if (!Array.isArray(old)) return old;
        return old.map((inv: any) => {
          if (inv.id === id) {
            const updateCreds = (creds: any[]) => creds?.map((c: any) => ({ ...c, isActive })) || [];
            return {
              ...inv,
              student: {
                ...inv.student,
                credentials: updateCreds(inv.student?.credentials),
                father: inv.student?.father ? { ...inv.student.father, credentials: updateCreds(inv.student.father.credentials) } : null,
                mother: inv.student?.mother ? { ...inv.student.mother, credentials: updateCreds(inv.student.mother.credentials) } : null,
                guardian: inv.student?.guardian ? { ...inv.student.guardian, credentials: updateCreds(inv.student.guardian.credentials) } : null,
              }
            };
          }
          return inv;
        });
      });
      return { previousInvoices };
    },
    onError: (err: any, variables, context) => {
      // Rollback on error
      if (context?.previousInvoices) {
        queryClient.setQueryData(["invoices"], context.previousInvoices);
      }
      alert(isAr ? "فشل تحديث الحالة" : "Failed to update status");
    },
    onSettled: () => {
      // Always refetch after error or success to sync with server
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
    }
  });

  const deadlineMutation = useMutation({
    mutationFn: async ({ id, dueDate }: { id: string, dueDate: string }) => 
      await api.patch(`/invoices/${id}/deadline`, { dueDate }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
      setIsDeadlineModalOpen(false);
      alert(isAr ? "تم تحديث تاريخ الاستحقاق" : "Deadline updated successfully");
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => await api.delete(`/invoices/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
    }
  });

  const handlePrint = (inv: any) => {
    // Basic print - in a real app we'd open a template
    const printContent = `
      <div dir="${isAr ? 'rtl' : 'ltr'}" style="padding: 40px; font-family: sans-serif;">
        <h1 style="text-align: center;">${isAr ? 'فاتورة مدرسية' : 'School Invoice'}</h1>
        <hr/>
        <p><strong>${isAr ? 'اسم الطالب:' : 'Student Name:'}</strong> ${inv.student?.user?.fullName}</p>
        <p><strong>${isAr ? 'كود الطالب:' : 'Student ID:'}</strong> ${inv.student?.studentCode}</p>
        <p><strong>${isAr ? 'المرحلة:' : 'Grade:'}</strong> ${isAr ? (inv.student?.grade?.nameAr || inv.student?.grade?.nameEn) : (inv.student?.grade?.nameEn || inv.student?.grade?.nameAr)}</p>
        <p><strong>${isAr ? 'نوع الرسوم:' : 'Fee Type:'}</strong> ${inv.feeType}</p>
        <p><strong>${isAr ? 'المبلغ الإجمالي:' : 'Total Amount:'}</strong> EGP ${Number(inv.totalAmount).toLocaleString()}</p>
        ${Number(inv.discount) > 0 ? `<p><strong>${isAr ? 'التخفيض:' : 'Discount:'}</strong> EGP ${Number(inv.discount).toLocaleString()}</p>` : ''}
        <p><strong>${isAr ? 'المبلغ المدفوع:' : 'Paid Amount:'}</strong> EGP ${Number(inv.paid || 0).toLocaleString()}</p>
        <p><strong>${isAr ? 'المبلغ المتبقي:' : 'Remaining:'}</strong> EGP ${Number(inv.remaining).toLocaleString()}</p>
        <p><strong>${isAr ? 'الحالة:' : 'Status:'}</strong> ${inv.status}</p>
        <p><strong>${isAr ? 'التاريخ:' : 'Date:'}</strong> ${new Date(inv.createdAt).toLocaleDateString()}</p>
        <br/>
        <div style="margin-top: 40px; text-align: left;">
          <p>_________________________</p>
          <p>${isAr ? 'توقيع الحسابات' : 'Accountant Signature'}</p>
        </div>
      </div>
    `;
    const win = window.open('', '_blank');
    win?.document.write(printContent);
    win?.document.close();
    win?.print();
  };

  const filteredInvoices = useMemo(() => {
    if (!invoices) return [];
    return invoices.filter((inv: any) => 
      inv.student?.user?.fullName.toLowerCase().includes(search.toLowerCase()) ||
      inv.notes?.toLowerCase().includes(search.toLowerCase())
    );
  }, [invoices, search]);

  return (
    <div className="invoices-module">
      {/* Header */}
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "40px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
          <Link href="/dashboard/payments" style={{ 
            width: "40px", 
            height: "40px", 
            borderRadius: "12px", 
            background: "rgba(255, 255, 255, 0.05)", 
            border: "1px solid var(--glass-border)", 
            display: "flex", 
            alignItems: "center", 
            justifyContent: "center",
            color: "var(--glass-text-primary)",
            transition: "0.2s"
          }}>
            {isAr ? <ArrowRight size={20} /> : <ArrowLeft size={20} />}
          </Link>
          <div>
            <h2 style={{ fontSize: "32px", fontWeight: 900, color: "var(--glass-text-primary)" }}>{isAr ? "إدارة الفواتير" : "Invoice Management"}</h2>
            <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>{isAr ? "إصدار ومتابعة المطالبات المالية للطلاب" : "Manage student financial obligations and billing"}</p>
          </div>
        </div>
        <div style={{ display: "flex", gap: "12px" }}>
          <button className="btn outline" onClick={() => setIsBulkModalOpen(true)}>
            <Zap size={18} /> {t('btn_generate_bulk')}
          </button>
          <button className="btn primary" onClick={() => setIsInvoiceModalOpen(true)}>
            <Plus size={18} /> {t('btn_add_invoice')}
          </button>
        </div>
      </div>

      {/* Stats Quick View */}
      <div className="module-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: "24px", marginBottom: "32px" }}>
        <div className="luxury-stat-card" style={{ "--accent-color": "var(--primary)" } as any}>
          <div className="l-stat-bg-blob"></div>
          <div className="luxury-stat-inner">
            <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "14px", fontWeight: 600 }}>{isAr ? "إجمالي المستحقات" : "Total Receivable"}</h4>
            <div className="value" style={{ fontSize: "32px", fontWeight: 800, marginTop: "8px", color: "var(--primary)" }}>
              EGP {invoices?.reduce((acc: number, curr: any) => acc + Number(curr.remaining || 0), 0).toLocaleString()}
            </div>
          </div>
        </div>
        <div className="luxury-stat-card" style={{ "--accent-color": "#f59e0b" } as any}>
          <div className="l-stat-bg-blob"></div>
          <div className="luxury-stat-inner">
            <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "14px", fontWeight: 600 }}>{isAr ? "فواتير غير مدفوعة" : "Unpaid Invoices"}</h4>
            <div className="value" style={{ fontSize: "32px", fontWeight: 800, marginTop: "8px", color: "#f59e0b" }}>
              {invoices?.filter((i: any) => i.status === "UNPAID").length} {isAr ? "فاتورة" : "Invoices"}
            </div>
          </div>
        </div>
        <div className="luxury-stat-card" style={{ "--accent-color": "#10b981" } as any}>
          <div className="l-stat-bg-blob"></div>
          <div className="luxury-stat-inner">
            <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "14px", fontWeight: 600 }}>{isAr ? "المحصل اليوم" : "Collected Today"}</h4>
            <div className="value" style={{ fontSize: "32px", fontWeight: 800, marginTop: "8px", color: "#10b981" }}>
              EGP {invoices?.filter((i: any) => new Date(i.updatedAt).toDateString() === new Date().toDateString()).reduce((acc: number, curr: any) => acc + Number(curr.paid || 0), 0).toLocaleString()}
            </div>
          </div>
        </div>
      </div>

      {/* Table Container */}
      <div className="premium-table-wrapper card-glass" style={{ padding: "0", overflow: "hidden" }}>
        <div style={{ padding: "20px", borderBottom: "1px solid var(--glass-border)", display: "flex", gap: "16px" }}>
          <div style={{ position: "relative", flex: 1 }}>
            <Search size={18} style={{ position: "absolute", left: isAr ? "auto" : "12px", right: isAr ? "12px" : "auto", top: "50%", transform: "translateY(-50%)", color: "var(--glass-text-muted)" }} />
            <input 
              type="text" 
              placeholder={isAr ? "ابحث باسم الطالب..." : "Search invoices..."}
              className="glass-input" 
              style={{ paddingLeft: isAr ? "12px" : "40px", paddingRight: isAr ? "40px" : "12px", height: "42px", width: "100%", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)", borderRadius: "10px", outline: "none" }}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        <table className="premium-table" dir={isAr ? "rtl" : "ltr"}>
          <thead>
            <tr>
              <th>{isAr ? "كود الطالب" : "ID"}</th>
              <th>{isAr ? "الطالب" : "Student"}</th>
              <th>{isAr ? "المرحلة" : "Grade"}</th>
              <th>{isAr ? "النوع" : "Fee Type"}</th>
              <th>{isAr ? "المبلغ" : "Amount"}</th>
              <th>{isAr ? "التخفيض" : "Disc."}</th>
              <th>{isAr ? "الحالة والوقت" : "Status & Time"}</th>
              <th>{isAr ? "دخول الطالب" : "Account Access"}</th>
              <th style={{ textAlign: isAr ? "left" : "right" }}>{isAr ? "إجراءات" : "Actions"}</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr><td colSpan={9} style={{ textAlign: "center", padding: "40px" }}><div className="spinner-large" style={{margin:"0 auto"}} /></td></tr>
            ) : filteredInvoices?.length === 0 ? (
              <tr><td colSpan={9} style={{ textAlign: "center", padding: "40px", color: "var(--glass-text-muted)" }}>{isAr ? "لا توجد فواتير" : "No invoices found."}</td></tr>
            ) : filteredInvoices?.map((inv: any) => (
              <tr key={inv.id}>
                <td style={{ fontFamily: "monospace", fontSize: "12px", color: "var(--glass-text-muted)" }}>{inv.student?.studentCode || "—"}</td>
                <td>
                  <div style={{ fontWeight: 700, color: "var(--glass-text-primary)" }}>{inv.student?.user?.fullName}</div>
                </td>
                <td>{isAr ? (inv.student?.grade?.nameAr || inv.student?.grade?.nameEn) : (inv.student?.grade?.nameEn || inv.student?.grade?.nameAr)}</td>
                <td>{inv.feeType}</td>
                <td style={{ fontWeight: 800, color: "var(--glass-text-primary)" }}>EGP {Number(inv.totalAmount).toLocaleString()}</td>
                <td style={{ color: Number(inv.discount) > 0 ? "#10b981" : "var(--glass-text-muted)" }}>{Number(inv.discount) > 0 ? `EGP ${Number(inv.discount).toLocaleString()}` : "—"}</td>
                <td>
                  <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
                    <StatusBadge status={inv.status} isAr={isAr} />
                    {inv.dueDate && (
                      <div style={{ fontSize: "10px", color: (inv.status !== 'PAID' && new Date(inv.dueDate) < new Date()) ? "#f87171" : "var(--glass-text-muted)", fontWeight: 700, display: "flex", alignItems: "center", gap: "4px" }}>
                        <Clock size={10} /> {new Date(inv.dueDate).toLocaleDateString()}
                        {(inv.status !== 'PAID' && new Date(inv.dueDate) < new Date()) && <ShieldAlert size={10} />}
                      </div>
                    )}
                  </div>
                </td>
                <td>
                  {(() => {
                    // Collect ALL credentials: student + father + mother + guardian
                    const allCreds = [
                      ...(inv.student?.credentials || []),
                      ...(inv.student?.father?.credentials || []),
                      ...(inv.student?.mother?.credentials || []),
                      ...(inv.student?.guardian?.credentials || [])
                    ];
                    const isActive = allCreds.length === 0 || allCreds.every((c: any) => c.isActive !== false);
                    return (
                      <button 
                        onClick={() => toggleAccessMutation.mutate({ id: inv.id, isActive: !isActive })}
                        disabled={toggleAccessMutation.isPending}
                        style={{ 
                          background: isActive ? "rgba(16, 185, 129, 0.1)" : "rgba(239, 68, 68, 0.1)",
                          color: isActive ? "#10b981" : "#ef4444",
                          border: "none",
                          padding: "6px 12px",
                          borderRadius: "8px",
                          fontSize: "11px",
                          fontWeight: 800,
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          gap: "6px",
                          width: "100px",
                          justifyContent: "center",
                          transition: "0.2s"
                        }}
                      >
                        {isActive ? <Unlock size={12} /> : <Lock size={12} />}
                        {isActive ? (isAr ? "مفعل" : "ACTIVE") : (isAr ? "غير مفعل" : "INACTIVE")}
                      </button>
                    );
                  })()}
                </td>
                <td style={{ textAlign: isAr ? "left" : "right" }}>
                  <div style={{ display: "flex", justifyContent: isAr ? "flex-start" : "flex-end", gap: "8px", alignItems: "center" }}>
                    <button className="btn-icon" onClick={() => handlePrint(inv)} title={isAr ? "طباعة" : "Print"}><Printer size={16} /></button>
                    {inv.status !== "PAID" && (
                      <button className="btn-icon" onClick={() => { setSelectedInvoice(inv); setNewDeadline(inv.dueDate?.split('T')[0] || ""); setIsDeadlineModalOpen(true); }} title={isAr ? "تعديل التاريخ" : "Edit Deadline"}><Clock size={16} /></button>
                    )}
                    {inv.status !== "PAID" && (
                      <button className="btn-icon" style={{ color: "#3b82f6" }} onClick={() => { setSelectedInvoice(inv); setIsDiscountModalOpen(true); }} title={isAr ? "تخفيض" : "Discount"}><Percent size={16} /></button>
                    )}
                    <button 
                      className="btn-icon" 
                      style={{ color: "#f87171" }} 
                      onClick={() => { if(confirm(isAr ? 'هل أنت متأكد من حذف هذه الفاتورة نهائياً؟' : 'Are you sure you want to delete this invoice?')) deleteMutation.mutate(inv.id); }}
                      title={isAr ? "حذف" : "Delete"}
                    >
                      <Trash2 size={16} />
                    </button>
                    {inv.status !== "PAID" && (
                      <button className="btn primary" style={{ padding: "6px 12px", fontSize: "12px", borderRadius: "8px" }} onClick={() => { setSelectedInvoice(inv); setPaymentData({...paymentData, paymentType: "FULL", amount: ""}); setIsPaymentModalOpen(true); }}><CreditCard size={14} /> {isAr ? "دفع" : "Pay"}</button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Bulk Generation Modal */}
      <Modal
        isOpen={isBulkModalOpen}
        onClose={() => setIsBulkModalOpen(false)}
        title={t('modal_bulk_title')}
        footer={
          <>
            <button className="btn" onClick={() => setIsBulkModalOpen(false)}>{t('btn_cancel')}</button>
            <button className="btn primary" onClick={() => bulkMutation.mutate(bulkData)} disabled={bulkMutation.isPending}>{bulkMutation.isPending ? t('btn_generating') : t('btn_start_bulk')}</button>
          </>
        }
      >
        <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{t('field_grade')}</label>
            <select style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} value={bulkData.gradeId} onChange={e => setBulkData({...bulkData, gradeId: e.target.value})}><option value="">{t('select_grade')}</option>{grades?.map((g: any) => <option key={g.id} value={g.id} style={{color:'#000'}}>{isAr ? (g.nameAr || g.nameEn) : (g.nameEn || g.nameAr)}</option>)}</select>
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{t('field_fee_type')}</label>
            <select style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} value={bulkData.feeType} onChange={e => setBulkData({...bulkData, feeType: e.target.value})}><option value="TUITION">Tuition</option><option value="BUS">Bus</option><option value="UNIFORM">Uniform</option><option value="BOOKS">Books</option></select>
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{t('field_amount')} (EGP)</label>
            <input type="number" style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} value={bulkData.amount} onChange={e => setBulkData({...bulkData, amount: e.target.value})} />
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{isAr ? "تاريخ الاستحقاق" : "Due Date"}</label>
            <input type="date" style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} value={bulkData.dueDate} onChange={e => setBulkData({...bulkData, dueDate: e.target.value})} />
          </div>
        </div>
      </Modal>

      {/* New Invoice Modal */}
      <Modal
        isOpen={isInvoiceModalOpen}
        onClose={() => setIsInvoiceModalOpen(false)}
        title={t('modal_invoice_title')}
        footer={
          <>
            <button className="btn" onClick={() => setIsInvoiceModalOpen(false)}>{t('btn_cancel')}</button>
            <button className="btn primary" onClick={() => invoiceMutation.mutate(invoiceData)} disabled={invoiceMutation.isPending}>{invoiceMutation.isPending ? t('btn_creating') : t('btn_create_invoice')}</button>
          </>
        }
      >
        <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{t('field_student')}</label>
            <select style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} value={invoiceData.studentId} onChange={e => setInvoiceData({...invoiceData, studentId: e.target.value})}><option value="">{t('select_student')}</option>{students?.map((s: any) => <option key={s.id} value={s.id} style={{color:'#000'}}>{s.user?.fullName}</option>)}</select>
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{t('field_fee_type')}</label>
            <select style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} value={invoiceData.feeType} onChange={e => setInvoiceData({...invoiceData, feeType: e.target.value})}><option value="TUITION">Tuition</option><option value="BUS">Bus</option><option value="UNIFORM">Uniform</option><option value="BOOKS">Books</option></select>
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{t('field_amount')} (EGP)</label>
            <input type="number" style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} value={invoiceData.amount} onChange={e => setInvoiceData({...invoiceData, amount: e.target.value})} />
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{isAr ? "تاريخ الاستحقاق" : "Due Date"}</label>
            <input type="date" style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} value={invoiceData.dueDate} onChange={e => setInvoiceData({...invoiceData, dueDate: e.target.value})} />
          </div>
        </div>
      </Modal>

      {/* Discount Modal */}
      <Modal
        isOpen={isDiscountModalOpen}
        onClose={() => setIsDiscountModalOpen(false)}
        title={isAr ? "تطبيق تخفيض" : "Apply Discount"}
        footer={
          <>
            <button className="btn" onClick={() => setIsDiscountModalOpen(false)}>{t('btn_cancel')}</button>
            <button 
              className="btn primary" 
              onClick={() => discountMutation.mutate(discountData.type === 'PERCENTAGE' ? { discountPercentage: discountData.value } : { discountAmount: discountData.value })} 
              disabled={discountMutation.isPending}
            >
              {discountMutation.isPending ? (isAr ? "جاري التطبيق..." : "Applying...") : (isAr ? "حفظ" : "Apply")}
            </button>
          </>
        }
      >
        {selectedInvoice && (
          <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
             <div style={{ padding: "16px", background: "rgba(59, 130, 246, 0.05)", borderRadius: "12px", border: "1px solid rgba(59, 130, 246, 0.1)" }}>
              <div style={{ fontSize: "13px", color: "var(--glass-text-secondary)" }}>{isAr ? "تطبيق تخفيض للطالب:" : "Discount for student:"}</div>
              <div style={{ fontSize: "18px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{selectedInvoice.student?.user?.fullName}</div>
              <div style={{ fontSize: "14px", marginTop: "8px" }}>{isAr ? "المبلغ الأصلي:" : "Original Amount:"} <strong>EGP {Number(selectedInvoice.totalAmount).toLocaleString()}</strong></div>
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{isAr ? "نوع التخفيض" : "Discount Type"}</label>
              <select 
                style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} 
                value={discountData.type} 
                onChange={e => setDiscountData({...discountData, type: e.target.value})}
              >
                <option value="PERCENTAGE">{isAr ? "نسبة مئوية (%)" : "Percentage (%)"}</option>
                <option value="FIXED">{isAr ? "مبلغ ثابت (EGP)" : "Fixed Amount (EGP)"}</option>
              </select>
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>
                {discountData.type === 'PERCENTAGE' ? (isAr ? "النسبة المئوية (%)" : "Percentage (%)") : (isAr ? "المبلغ (EGP)" : "Amount (EGP)")}
              </label>
              <input 
                type="number" 
                style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} 
                value={discountData.value} 
                onChange={e => setDiscountData({...discountData, value: e.target.value})}
                placeholder={discountData.type === 'PERCENTAGE' ? "10" : "500"}
              />
            </div>
          </div>
        )}
      </Modal>

      {/* Payment Recording Modal */}
      <Modal
        isOpen={isPaymentModalOpen}
        onClose={() => setIsPaymentModalOpen(false)}
        title={isAr ? "تسجيل مدفوعات" : "Record Payment"}
        footer={
          <>
            <button className="btn" onClick={() => setIsPaymentModalOpen(false)}>{t('btn_cancel')}</button>
            <button className="btn primary" onClick={() => payMutation.mutate({ ...paymentData, amount: paymentData.paymentType === "FULL" ? selectedInvoice.remaining : paymentData.amount })} disabled={payMutation.isPending}>{payMutation.isPending ? (isAr ? "جاري التسجيل..." : "Recording...") : (isAr ? "تأكيد الدفع" : "Confirm Payment")}</button>
          </>
        }
      >
        {selectedInvoice && (
          <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
            <div style={{ padding: "16px", background: "rgba(59, 130, 246, 0.05)", borderRadius: "12px", border: "1px solid rgba(59, 130, 246, 0.1)" }}>
              <div style={{ fontSize: "13px", color: "var(--glass-text-secondary)" }}>{isAr ? "سداد فاتورة الطالب:" : "Paying for student:"}</div>
              <div style={{ fontSize: "18px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{selectedInvoice.student?.user?.fullName}</div>
              <div style={{ fontSize: "20px", fontWeight: 900, color: "var(--primary-light)", marginTop: "8px" }}>EGP {Number(selectedInvoice.remaining).toLocaleString()}</div>
              {Number(selectedInvoice.discount) > 0 && (
                <div style={{ fontSize: "12px", color: "#10b981", marginTop: "4px" }}>
                  {isAr ? "* تم تطبيق تخفيض بقيمة:" : "* Discount applied:"} EGP {Number(selectedInvoice.discount).toLocaleString()}
                </div>
              )}
            </div>

            <div>
              <label style={{ display: "block", marginBottom: "12px", fontSize: "14px", fontWeight: 600 }}>{isAr ? "نوع الدفع" : "Payment Type"}</label>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px" }}>
                <button 
                  className={`btn ${paymentData.paymentType === 'FULL' ? 'primary' : 'outline'}`} 
                  onClick={() => setPaymentData({...paymentData, paymentType: 'FULL', amount: ""})}
                  style={{ height: "45px", fontSize: "14px" }}
                >
                  {isAr ? "دفع كامل" : "Full Payment"}
                </button>
                <button 
                  className={`btn ${paymentData.paymentType === 'PARTIAL' ? 'primary' : 'outline'}`} 
                  onClick={() => setPaymentData({...paymentData, paymentType: 'PARTIAL'})}
                  style={{ height: "45px", fontSize: "14px" }}
                >
                  {isAr ? "دفع جزئي" : "Partial Payment"}
                </button>
              </div>
            </div>

            {paymentData.paymentType === "PARTIAL" && (
              <div>
                <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600 }}>{isAr ? "المبلغ المراد دفعه" : "Amount to Pay"}</label>
                <input 
                  type="number" 
                  style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} 
                  placeholder={selectedInvoice.remaining} 
                  value={paymentData.amount} 
                  onChange={e => setPaymentData({...paymentData, amount: e.target.value})} 
                />
              </div>
            )}
          </div>
        )}
      </Modal>

      {/* Deadline Adjustment Modal */}
      <Modal
        isOpen={isDeadlineModalOpen}
        onClose={() => setIsDeadlineModalOpen(false)}
        title={isAr ? "تعديل تاريخ الاستحقاق" : "Adjust Deadline"}
        footer={
          <>
            <button className="btn" onClick={() => setIsDeadlineModalOpen(false)}>{t('btn_cancel')}</button>
            <button className="btn primary" onClick={() => deadlineMutation.mutate({ id: selectedInvoice.id, dueDate: newDeadline })} disabled={deadlineMutation.isPending}>{deadlineMutation.isPending ? (isAr ? "جاري التعديل..." : "Adjusting...") : (isAr ? "تحديث" : "Update")}</button>
          </>
        }
      >
        {selectedInvoice && (
          <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
            <p style={{ fontSize: "14px", color: "var(--glass-text-secondary)" }}>{isAr ? "حدد تاريخ الاستحقاق الجديد لهذه الفاتورة:" : "Set a new deadline for this invoice:"}</p>
            <input 
              type="date" 
              style={{ width: "100%", padding: "12px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }} 
              value={newDeadline}
              onChange={e => setNewDeadline(e.target.value)}
            />
          </div>
        )}
      </Modal>

      <style jsx>{`
        .btn-icon { width: 32px; height: 32px; border-radius: 8px; background: var(--glass-icon-bg); border: 1px solid var(--glass-border); color: var(--glass-text-secondary); display: inline-flex; align-items: center; justify-content: center; cursor: pointer; transition: 0.2s; }
        .btn-icon:hover { background: var(--primary); color: #fff; border-color: var(--primary); }
      `}</style>
    </div>
  );
}

const StatusBadge = ({ status, isAr }: { status: string, isAr: boolean }) => {
  const styles: any = {
    UNPAID: { bg: "rgba(248, 113, 113, 0.1)", color: "#f87171", icon: <AlertCircle size={12} />, text: isAr ? "غير مدفوع" : "UNPAID" },
    PARTIAL: { bg: "rgba(245, 158, 11, 0.1)", color: "#f59e0b", icon: <Clock size={12} />, text: isAr ? "مدفوع جزئياً" : "PARTIAL" },
    PAID: { bg: "rgba(52, 211, 153, 0.1)", color: "#34d399", icon: <CheckCircle size={12} />, text: isAr ? "مدفوع" : "PAID" },
  };
  const s = styles[status] || styles.UNPAID;
  return (
    <span className="badge" style={{ background: s.bg, color: s.color, display: "inline-flex", alignItems: "center", gap: "6px", padding: '4px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 600 }}>
      {s.icon} {s.text}
    </span>
  );
};
