"use client";

import React, { useState, useMemo } from "react";
import { createPortal } from "react-dom";
import Link from "next/link";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Plus, Search, Download, Filter,
  CreditCard, Wallet, ArrowUpRight, ArrowDownRight,
  MoreHorizontal, FileText, User, Calendar,
  DollarSign, CheckCircle, Clock, AlertTriangle, X, Printer, Landmark, Trash2, Settings2
} from "lucide-react";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from "recharts";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { DashboardOverview } from "@/types/overview";
import styles from "./PaymentsPage.module.css";

type Tab = "history" | "settings";

export default function PaymentsPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<Tab>("history");
  const [search, setSearch] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isRuleModalOpen, setIsRuleModalOpen] = useState(false);

  // New Payment Form State
  const initialPaymentData = {
    studentId: "", amount: "", feeType: "TUITION", paymentMethod: "CASH", status: "PAID", notes: "", installment: "1", academicYear: "2024/2025"
  };
  const [formData, setFormData] = useState(initialPaymentData);

  // Fee Structure Form State
  const initialRuleData = {
    name: "", amount: "", feeType: "TUITION", gradeId: "", studentId: "", academicYearId: ""
  };
  const [ruleData, setRuleData] = useState(initialRuleData);

  // 1. Fetch real payments
  const { data: paymentsData, isLoading: paymentsLoading } = useQuery({
    queryKey: ["payments"],
    queryFn: async () => (await api.get("/payments")).data.data,
    staleTime: 0,
    refetchOnMount: "always",
  });

  // 2. Fetch Fee Structures
  const { data: rulesData } = useQuery({
    queryKey: ["fee-structures"],
    queryFn: async () => (await api.get("/fee-structures")).data.data,
  });

  // 3. Fetch Students & Grades for dropdowns
  const { data: studentsData } = useQuery({
    queryKey: ["students"],
    queryFn: async () => (await api.get("/students")).data.data,
  });
  const { data: gradesData } = useQuery({
    queryKey: ["grades"],
    queryFn: async () => (await api.get("/academic/grades")).data.data,
  });

  // 4. Fetch overview
  const { data: ov } = useQuery({
    queryKey: ["overview"],
    queryFn: async () => (await api.get<{ data: DashboardOverview }>("/dashboard/overview")).data.data,
  });

  // Mutations
  const createPaymentMutation = useMutation({
    mutationFn: async (payload: any) => (await api.post("/payments", payload)).data,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["payments"] });
      queryClient.invalidateQueries({ queryKey: ["overview"] });
      setIsModalOpen(false);
      setFormData(initialPaymentData);
    }
  });

  const createRuleMutation = useMutation({
    mutationFn: async (payload: any) => (await api.post("/fee-structures", payload)).data,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["fee-structures"] });
      setIsRuleModalOpen(false);
      setRuleData(initialRuleData);
    }
  });

  const deleteRuleMutation = useMutation({
    mutationFn: async (id: string) => (await api.delete(`/fee-structures/${id}`)).data,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["fee-structures"] }),
  });

  const payments = useMemo(() => (Array.isArray(paymentsData) ? paymentsData : []), [paymentsData]);
  const rules = useMemo(() => (Array.isArray(rulesData) ? rulesData : []), [rulesData]);
  const students = useMemo(() => (Array.isArray(studentsData) ? studentsData : []), [studentsData]);
  const grades = useMemo(() => (Array.isArray(gradesData) ? gradesData : []), [gradesData]);

  const filteredPayments = useMemo(() => {
    if (!search) return payments;
    return payments.filter((p: any) => p.student?.user?.fullName?.toLowerCase().includes(search.toLowerCase()));
  }, [payments, search]);

  const stats = [
    { label: isAr ? "إجمالي التحصيل" : "Total Collected", value: `EGP ${ov?.totalRevenue?.toLocaleString() ?? "0"}`, icon: CheckCircle, accent: "#10b981" },
    { label: isAr ? "رسوم معلقة" : "Pending Fees", value: `EGP ${ov?.pendingFeesAmount?.toLocaleString() ?? "0"}`, icon: Clock, accent: "#f59e0b" },
    { label: isAr ? "فواتير صادرة" : "Invoices Issued", value: ov?.pendingFeesCount ?? "0", icon: FileText, accent: "#3b82f6" },
    { label: isAr ? "نسبة التحصيل" : "Collection Rate", value: "84%", icon: ArrowUpRight, accent: "#8b5cf6" }
  ];

  const handleExport = () => {
    if (filteredPayments.length === 0) return;

    const headers = [
      isAr ? "الطالب" : "Student",
      isAr ? "النوع" : "Type",
      isAr ? "المبلغ" : "Amount",
      isAr ? "التاريخ" : "Date",
      isAr ? "الحالة" : "Status"
    ];

    const rows = filteredPayments.map((p: any) => [
      p.student?.user?.fullName || "",
      p.feeType || "",
      p.amount || 0,
      new Date(p.createdAt).toLocaleDateString(),
      p.status || ""
    ]);

    const csvContent = [
      headers.join(","),
      ...rows.map(row => row.join(","))
    ].join("\n");

    const blob = new Blob(["\ufeff" + csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `payments_export_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const [selectedPayment, setSelectedPayment] = useState<any>(null);

  const handlePrint = () => {
    window.print();
  };

  const ReceiptContent = ({ payment }: { payment: any }) => (
    <div className={styles.receiptPreview}>
      <div className={styles.receiptHeader}>
        <div style={{ display: "flex", justifyContent: "center", marginBottom: "15px" }}>
          <div style={{ background: "linear-gradient(135deg, #3b82f6, #8b5cf6)", padding: "12px", borderRadius: "12px" }}>
            <Landmark size={32} color="#fff" />
          </div>
        </div>
        <h1 className="receipt-title">EduControl</h1>
        <p style={{ color: "#64748b", fontSize: "14px" }}>Official Payment Receipt</p>
      </div>

      <div className={styles.receiptMetaPrint}>
        <div className={styles.metaGroupPrint}>
          <label>{isAr ? "رقم العملية" : "TRANSACTION ID"}</label>
          <div>#{payment.id?.slice(-8).toUpperCase()}</div>
        </div>
        <div className={styles.metaGroupPrint} style={{ textAlign: isAr ? "left" : "right" }}>
          <label>{isAr ? "التاريخ" : "DATE"}</label>
          <div>{new Date(payment.createdAt).toLocaleDateString()}</div>
        </div>
      </div>

      <div style={{ marginBottom: "30px" }}>
        <div className={styles.metaGroupPrint}>
          <label>{isAr ? "استلمنا من السيد/ة" : "RECEIVED FROM"}</label>
          <div style={{ fontSize: "18px" }}>{payment.student?.user?.fullName}</div>
        </div>
      </div>

      <table className={styles.receiptTablePrint}>
        <thead>
          <tr>
            <th>{isAr ? "الوصف" : "DESCRIPTION"}</th>
            <th style={{ textAlign: "right" }}>{isAr ? "المبلغ" : "AMOUNT"}</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{payment.feeType} Fees</td>
            <td style={{ textAlign: "right", fontWeight: 700 }}>EGP {payment.amount?.toLocaleString()}</td>
          </tr>
        </tbody>
      </table>

      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
        <div>
          <div className={styles.stampPrint}>PAID</div>
        </div>
        <div style={{ textAlign: "right" }}>
          <p style={{ color: "#64748b", fontSize: "12px", marginBottom: "5px" }}>TOTAL AMOUNT</p>
          <div style={{ fontSize: "28px", fontWeight: 900, color: "#0f172a" }}>EGP {payment.amount?.toLocaleString()}</div>
        </div>
      </div>

      <div className={styles.receiptFooterPrint}>
        <p>Thank you for your payment. This is a computer-generated receipt.</p>
      </div>
    </div>
  );

  return (
    <div className={styles.container}>
      {/* RECEIPT MODAL */}
      {selectedPayment && (
        <div className={styles.modalOverlay} onClick={() => setSelectedPayment(null)}>
          <div className={styles.modalContent} style={{ maxWidth: "500px" }} onClick={e => e.stopPropagation()}>
            <div className={styles.modalHeader}>
              <h2>{isAr ? "إيصال دفع" : "Payment Receipt"}</h2>
              <button onClick={() => setSelectedPayment(null)} style={{ background: 'none', border: 'none' }}><X size={24} /></button>
            </div>

            <ReceiptContent payment={selectedPayment} />

            <div style={{ marginTop: "30px", display: "flex", gap: "12px" }}>
              <button className={styles.btnSecondary} style={{ flex: 1 }} onClick={() => setSelectedPayment(null)}>{isAr ? "إغلاق" : "Close"}</button>
              <button className={styles.btnPrimary} style={{ flex: 1 }} onClick={handlePrint}><Printer size={18} /> {isAr ? "طباعة" : "Print"}</button>
            </div>
          </div>
        </div>
      )}

      {/* PRINT PORTAL - Hidden on screen, shown on print */}
      {selectedPayment && typeof document !== "undefined" && createPortal(
        <div className={styles.printOnlyContainer}>
          <ReceiptContent payment={selectedPayment} />
        </div>,
        document.body
      )}
      <header className={styles.header}>
        <div>
          <h1>{isAr ? "المالية والمدفوعات" : "Finance & Payments"}</h1>
          <p>{isAr ? "إدارة الرسوم الدراسية والفواتير وسجل التحصيل" : "Manage student fees, invoices, and collection history"}</p>
        </div>
        <div className={styles.actions}>
          <Link href="/dashboard/payments/invoices" className={styles.btnSecondary}><FileText size={18} /> {isAr ? "إدارة الفواتير" : "Manage Invoices"}</Link>
          <button className={styles.btnPrimary} onClick={() => { setFormData(initialPaymentData); setIsModalOpen(true); }}><Plus size={18} /> {isAr ? "دفع جديد" : "New Payment"}</button>
        </div>
      </header>

      <div className={styles.statsGrid}>
        {stats.map((s, i) => (
          <div
            key={i}
            className="luxury-stat-card"
            style={{ "--accent-color": s.accent } as any}
          >
            <div className="l-stat-bg-blob"></div>
            <div className="luxury-stat-inner">
              <div className={styles.statTop}>
                <div className={styles.statIconWrap} style={{ background: `${s.accent}15`, color: s.accent }}>
                  <s.icon size={24} />
                </div>
              </div>
              <div>
                <div className={styles.statValue}>{s.value}</div>
                <div className={styles.statLabel}>{s.label}</div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className={styles.tabs}>
        <button className={`${styles.tab} ${activeTab === 'history' ? styles.tabActive : ''}`} onClick={() => setActiveTab('history')}>
          {isAr ? "سجل المدفوعات" : "Payment History"}
        </button>
        <button className={`${styles.tab} ${activeTab === 'settings' ? styles.tabActive : ''}`} onClick={() => setActiveTab('settings')}>
          {isAr ? "إعدادات الرسوم" : "Fee Settings"}
        </button>
      </div>

      {activeTab === 'history' ? (
        <>
          <div className={styles.contentGrid}>
            <div className={styles.card}>
              <div className={styles.cardHeader}><h3 className={styles.cardTitle}>{isAr ? "نمو الإيرادات" : "Revenue Growth"}</h3></div>
              <div style={{ height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={ov?.monthlyRevenue || []}>
                    <defs><linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} /><stop offset="95%" stopColor="#3b82f6" stopOpacity={0} /></linearGradient></defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" /><XAxis dataKey="month" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#64748b' }} /><YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#64748b' }} /><Tooltip contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }} /><Area type="monotone" dataKey="amount" stroke="#3b82f6" strokeWidth={3} fillOpacity={1} fill="url(#colorValue)" />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className={styles.card}>
              <div className={styles.cardHeader}><h3 className={styles.cardTitle}>{isAr ? "توزيع الرسوم" : "Fees by Type"}</h3></div>
              <div style={{ height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={[{ name: isAr ? 'مصروفات' : 'Tuition', value: 400 }, { name: isAr ? 'باص' : 'Bus', value: 300 }, { name: isAr ? 'زي' : 'Uniform', value: 200 }, { name: isAr ? 'كتب' : 'Books', value: 100 }]} cx="50%" cy="50%" innerRadius={60} outerRadius={80} paddingAngle={5} dataKey="value">
                      {[{ color: '#3b82f6' }, { color: '#10b981' }, { color: '#f59e0b' }, { color: '#8b5cf6' }].map((entry, index) => <Cell key={index} fill={entry.color} />)}
                    </Pie>
                    <Tooltip contentStyle={{ borderRadius: '12px', border: 'none' }} />
                    <Legend align={isAr ? "right" : "left"} verticalAlign="bottom" iconType="circle" formatter={(v) => <span style={{ paddingLeft: isAr ? 0 : 10, paddingRight: isAr ? 10 : 0 }}>{v}</span>} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>

          <section className={styles.tableSection}>
            <div className={styles.tableHeader}>
              <div className={styles.searchBox}><Search className={styles.searchIcon} size={18} /><input type="text" placeholder={isAr ? "البحث باسم الطالب..." : "Search..."} value={search} onChange={e => setSearch(e.target.value)} /></div>
              <button className={styles.btnSecondary} onClick={handleExport}><Download size={16} /> {isAr ? "تصدير" : "Export"}</button>
            </div>
            <div className={styles.tableContainer}>
              <table className={styles.table}>
                <thead><tr><th>{isAr ? "الطالب" : "Student"}</th><th>{isAr ? "النوع" : "Type"}</th><th>{isAr ? "المبلغ" : "Amount"}</th><th>{isAr ? "التاريخ" : "Date"}</th><th>{isAr ? "الحالة" : "Status"}</th><th>{isAr ? "وصل" : "Receipt"}</th></tr></thead>
                <tbody>
                  {filteredPayments.map((p: any) => (
                    <tr key={p.id}>
                      <td>
                        <div className={styles.studentInfo}>
                          <div className={styles.avatar}>
                            {p.student?.photo ? (
                              <img src={p.student.photo} alt={p.student?.user?.fullName} className={styles.avatarImg} />
                            ) : (
                              p.student?.user?.fullName?.charAt(0)
                            )}
                          </div>
                          <div>
                            <div style={{ fontWeight: 600 }}>{p.student?.user?.fullName}</div>
                          </div>
                        </div>
                      </td>
                      <td>{p.feeType}</td><td>EGP {p.amount?.toLocaleString()}</td><td>{new Date(p.createdAt).toLocaleDateString()}</td>
                      <td><span className={`${styles.status} ${p.status === 'PAID' ? styles.paid : styles.pending}`}>{p.status}</span></td>
                      <td><button onClick={() => setSelectedPayment(p)} style={{ background: 'none', border: 'none', color: '#3b82f6', cursor: 'pointer' }}><Printer size={18} /></button></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </>
      ) : (
        <section className={styles.card}>
          <div className={styles.cardHeader}>
            <div><h3 className={styles.cardTitle}>{isAr ? "هيكل الرسوم الدراسية" : "Fee Structure Rules"}</h3><p style={{ fontSize: 13, color: '#64748b' }}>{isAr ? "حدد المصروفات الأساسية لكل مرحلة أو خصومات خاصة لطلاب معينين" : "Define base fees per grade or custom discounts for specific students"}</p></div>
            <button className={styles.btnPrimary} onClick={() => { setRuleData(initialRuleData); setIsRuleModalOpen(true); }}><Plus size={16} /> {isAr ? "إضافة قاعدة رسوم" : "Add Fee Rule"}</button>
          </div>

          <div className={styles.ruleList}>
            {rules.length === 0 && <div style={{ textAlign: 'center', padding: 40, color: '#94a3b8' }}>{isAr ? "لا توجد قواعد مسجلة" : "No fee rules defined yet."}</div>}
            {rules.map((rule: any) => (
              <div key={rule.id} className={styles.ruleItem}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                  <div className={styles.statIconWrap} style={{ background: 'rgba(59,130,246,0.1)', color: '#3b82f6' }}><DollarSign size={20} /></div>
                  <div>
                    <div style={{ fontWeight: 700 }}>{rule.name}</div>
                    <div style={{ fontSize: 12, color: '#64748b' }}>
                      {rule.student ? (
                        <span style={{ color: '#ef4444' }}>Target: {rule.student.user.fullName} (Custom)</span>
                      ) : rule.grade ? (
                        <span>Target: {rule.grade.nameEn || rule.grade.nameAr}</span>
                      ) : (
                        <span>Target: Global / All School</span>
                      )}
                      {" • "} {rule.feeType}
                    </div>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
                  <div style={{ fontWeight: 800, fontSize: 18 }}>EGP {Number(rule.amount).toLocaleString()}</div>
                  <button onClick={() => deleteRuleMutation.mutate(rule.id)} style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer' }}><Trash2 size={18} /></button>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* NEW RULE MODAL */}
      {isRuleModalOpen && (
        <div className={styles.modalOverlay} onClick={() => setIsRuleModalOpen(false)}>
          <div className={styles.modalContent} onClick={e => e.stopPropagation()}>
            <div className={styles.modalHeader}><h2>{isAr ? "إضافة قاعدة رسوم جديدة" : "Add Fee Rule"}</h2><button onClick={() => setIsRuleModalOpen(false)} style={{ background: 'none', border: 'none' }}><X size={24} /></button></div>
            <form onSubmit={(e) => { e.preventDefault(); createRuleMutation.mutate(ruleData); }}>
              <div className={styles.formGrid}>
                <div className={styles.formGroup}><label>Rule Name (e.g. Tuition Grade 1)</label><input required value={ruleData.name} onChange={e => setRuleData({ ...ruleData, name: e.target.value })} /></div>
                <div className={styles.formGroup}><label>Amount (EGP)</label><input type="number" required value={ruleData.amount} onChange={e => setRuleData({ ...ruleData, amount: e.target.value })} /></div>
                <div className={styles.formGroup}>
                  <label>{isAr ? "النوع" : "Type"}</label>
                  <select value={ruleData.feeType} onChange={e => setRuleData({ ...ruleData, feeType: e.target.value })}>
                    <option value="TUITION">{isAr ? "مصروفات دراسية" : "Tuition"}</option>
                    <option value="BUS">{isAr ? "باص" : "Bus"}</option>
                    <option value="UNIFORM">{isAr ? "زي مدرسي" : "Uniform"}</option>
                    <option value="BOOKS">{isAr ? "كتب" : "Books"}</option>
                    <option value="OTHER">{isAr ? "أخرى" : "Other"}</option>
                  </select>
                </div>
                <div className={styles.formGroup}>
                  <label>{isAr ? "تخصيص لمرحلة (اختياري)" : "Assign to Grade (Optional)"}</label>
                  <select value={ruleData.gradeId} onChange={e => setRuleData({ ...ruleData, gradeId: e.target.value, studentId: "" })}>
                    <option value="">{isAr ? "عام / للكل" : "Global / All"}</option>
                    {grades.map((g: any) => <option key={g.id} value={g.id}>{isAr ? (g.nameAr || g.nameEn) : (g.nameEn || g.nameAr)}</option>)}
                  </select>
                </div>
              </div>
              <div className={styles.formGroup} style={{ marginTop: 20 }}>
                <label>{isAr ? "أو تخصيص لطالب محدد (مصاريف خاصة)" : "OR Assign to Specific Student (Custom Fee)"}</label>
                <select value={ruleData.studentId} onChange={e => setRuleData({ ...ruleData, studentId: e.target.value, gradeId: "" })}>
                  <option value="">{isAr ? "لا يوجد (استخدم المرحلة/عام)" : "None (Use Grade/Global)"}</option>
                  {students.map((s: any) => <option key={s.id} value={s.id}>{s.user?.fullName}</option>)}
                </select>
              </div>
              <button type="submit" className={styles.btnPrimary} style={{ width: '100%', marginTop: 32, justifyContent: 'center' }} disabled={createRuleMutation.isPending}>
                {createRuleMutation.isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "حفظ القاعدة" : "Save Rule")}
              </button>
            </form>
          </div>
        </div>
      )}

      {/* NEW PAYMENT MODAL */}
      {isModalOpen && (
        <div className={styles.modalOverlay} onClick={() => setIsModalOpen(false)}>
          <div className={styles.modalContent} onClick={e => e.stopPropagation()}>
            <div className={styles.modalHeader}><h2>{isAr ? "تسجيل عملية دفع" : "New Payment"}</h2><button onClick={() => setIsModalOpen(false)} style={{ background: 'none', border: 'none' }}><X size={24} /></button></div>
            <form onSubmit={(e) => { e.preventDefault(); createPaymentMutation.mutate(formData); }}>
              <div className={styles.formGrid}>
                <div className={styles.formGroup}>
                  <label>{isAr ? "الطالب" : "Student"}</label>
                  <select required value={formData.studentId} onChange={e => setFormData({ ...formData, studentId: e.target.value })}>
                    <option value="">{isAr ? "اختر..." : "Select..."}</option>
                    {students.map((s: any) => <option key={s.id} value={s.id}>{s.user?.fullName}</option>)}
                  </select>
                </div>
                <div className={styles.formGroup}>
                  <label>{isAr ? "المبلغ" : "Amount"}</label>
                  <input type="number" required value={formData.amount} onChange={e => setFormData({ ...formData, amount: e.target.value })} />
                </div>
                <div className={styles.formGroup}>
                  <label>{isAr ? "نوع الرسوم" : "Fee Type"}</label>
                  <select value={formData.feeType} onChange={e => setFormData({ ...formData, feeType: e.target.value })}>
                    <option value="TUITION">{isAr ? "مصروفات دراسية" : "Tuition"}</option>
                    <option value="BUS">{isAr ? "باص" : "Bus"}</option>
                    <option value="UNIFORM">{isAr ? "زي مدرسي" : "Uniform"}</option>
                    <option value="BOOKS">{isAr ? "كتب" : "Books"}</option>
                  </select>
                </div>
              </div>
              <button type="submit" className={styles.btnPrimary} style={{ width: '100%', marginTop: 32, justifyContent: 'center' }} disabled={createPaymentMutation.isPending}>
                {createPaymentMutation.isPending ? (isAr ? "جاري المعالجة..." : "Processing...") : (isAr ? "تأكيد الدفع" : "Confirm Payment")}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
