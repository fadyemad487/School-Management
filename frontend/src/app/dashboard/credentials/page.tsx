"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { 
  Key, 
  ShieldCheck, 
  Download, 
  RefreshCw, 
  Search, 
  Eye, 
  EyeOff, 
  FileText,
  Printer,
  CheckCircle2,
  AlertCircle,
  Edit2,
  Check,
  X
} from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { useAuth } from "@/components/shared/AuthProvider";
import jsPDF from "jspdf";
import "jspdf-autotable";

export default function CredentialsPage() {
  const { user } = useAuth();
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [revealMap, setRevealMap] = useState<Record<string, boolean>>({});
  const [editingId, setEditingId] = useState<string | null>(null);
  const [tempPassword, setTempPassword] = useState("");

  const { data, isLoading, refetch, isRefetching } = useQuery({
    queryKey: ["credentials"],
    queryFn: async () => (await api.get("/credentials")).data.data
  });

  const generateMutation = useMutation({
    mutationFn: async (type: string) => {
      return await api.post("/credentials/generate", { type });
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["credentials"] })
  });

  const resetMutation = useMutation({
    mutationFn: async ({ id, password }: { id: string, password?: string }) => {
      return (await api.patch(`/credentials/${id}/reset-password`, { password })).data.data;
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ["credentials"] });
      alert(`✅ Password updated successfully!`);
      setEditingId(null);
    },
    onError: (err: any) => {
      console.error("Reset Error:", err);
      alert(`❌ Error resetting password: ${err.response?.data?.message || err.message}`);
    }
  });

  const toggleReveal = (id: string) => {
    setRevealMap(prev => ({ ...prev, [id]: !prev[id] }));
  };

  const filteredData = data?.filter((c: any) => {
    const s = search.toLowerCase();
    if (!s) return true;

    // 1. Direct matches (Login ID, Role, Entity Name)
    const entityName = (c.student?.nameAr || c.teacher?.nameAr || c.parent?.nameAr || c.driver?.nameAr || c.driver?.name || c.supervisor?.name || c.supervisor?.nameAr || "").toLowerCase();
    if (c.loginId?.toLowerCase().includes(s) || c.role.toLowerCase().includes(s) || entityName.includes(s)) return true;
    
    // 2. Student Code match (for student accounts)
    if (c.student?.studentCode?.toLowerCase().includes(s)) return true;

    // 3. Parent search by Linked Student Name or Code
    if (c.role === "PARENT" && c.parent) {
      const linkedStudents = [...(c.parent.fatherOf || []), ...(c.parent.motherOf || [])];
      return linkedStudents.some((stu: any) => 
        stu.nameAr?.toLowerCase().includes(s) || 
        stu.studentCode?.toLowerCase().includes(s)
      );
    }

    return false;
  });

  // --- Export Functions ---
  const exportTableCSV = () => {
    if (!data) return;
    const headers = ["User Name", "Login ID", "Password", "Role"];
    const rows = data.map((c: any) => {
      const name = c.student?.nameAr || c.teacher?.nameAr || c.parent?.nameAr || c.driver?.nameAr || c.driver?.name || c.supervisor?.name || c.supervisor?.nameAr || "—";
      return [name, c.loginId, c.plainTextPw, c.role];
    });
    const csvContent = [headers, ...rows].map(e => e.join(",")).join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `credentials_${new Date().toISOString()}.csv`);
    link.click();
  };

  const printSingleCard = (c: any) => {
    const name = c.student?.nameAr || c.teacher?.nameAr || c.parent?.nameAr || c.driver?.nameAr || c.driver?.name || c.supervisor?.name || c.supervisor?.nameAr || "—";
    
    const printWindow = window.open('', '', 'width=600,height=400');
    if (!printWindow) return alert("Please allow popups to print.");

    const htmlContent = `
      <html>
        <head>
          <title>Access Card - ${name}</title>
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; display: flex; justify-content: center; padding: 40px; margin: 0; background: #fff; }
            .card { border: 2px dashed #94a3b8; border-radius: 16px; width: 350px; padding: 24px; background: #fff; position: relative; }
            .header { color: #2563eb; font-weight: 800; font-size: 18px; margin-bottom: 16px; border-bottom: 2px solid #f1f5f9; padding-bottom: 12px; text-align: center; }
            .row { margin-bottom: 16px; text-align: left; direction: ltr; }
            .label { font-size: 11px; color: #64748b; font-weight: 800; letter-spacing: 1px; margin-bottom: 4px; }
            .value { font-size: 22px; font-weight: 900; font-family: monospace; color: #0f172a; background: #f8fafc; padding: 8px 12px; border-radius: 8px; border: 1px solid #e2e8f0; }
            .footer { margin-top: 24px; font-size: 13px; color: #475569; text-align: right; direction: rtl; line-height: 1.6; }
            .school-logo-placeholder { width: 40px; height: 40px; background: #eff6ff; border-radius: 10px; margin: 0 auto 10px auto; display: flex; align-items: center; justify-content: center; color: #3b82f6; font-weight: bold; }
            @media print {
              body { padding: 0; margin: 20px; }
              .card { border: 2px solid #000; break-inside: avoid; }
              .value { border: 1px solid #000; background: transparent; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
              @page { size: auto; margin: 0mm; }
            }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="school-logo-placeholder">Edu</div>
            <div class="header">${user?.school?.name || "School"} Mobile Access</div>
            
            <div class="row">
              <div class="label">LOGIN ID</div>
              <div class="value">${c.loginId}</div>
            </div>
            
            <div class="row">
              <div class="label">PASSWORD</div>
              <div class="value">${c.plainTextPw || "••••••••"}</div>
            </div>
            
            <div class="footer">
              <strong>اسم المستخدم:</strong> ${name}<br/>
              <strong>الصلاحية:</strong> ${c.role}<br/>
              <span style="font-size: 11px; color: #94a3b8; display: block; margin-top: 10px;">يرجى الاحتفاظ ببيانات الدخول في مكان آمن.</span>
            </div>
          </div>
          <script>
            setTimeout(() => {
              window.print();
              window.close();
            }, 500);
          </script>
        </body>
      </html>
    `;

    printWindow.document.write(htmlContent);
    printWindow.document.close();
  };

  return (
    <div className="credentials-module">
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: "40px" }}>
        <div>
          <h2 style={{ fontSize: "32px", fontWeight: 900, color: "var(--glass-text-primary)" }}>{t('dash_credentials')}</h2>
          <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>{t('cred_desc' as any)}</p>
        </div>
        <div style={{ display: "flex", gap: "10px", alignItems: "center" }}>
          <button className="btn outline sm-btn" onClick={exportTableCSV}>
            <Download size={16} /> {t('btn_export_csv' as any)}
          </button>
          <div style={{ width: "1px", height: "30px", background: "var(--glass-border)", margin: "0 4px" }} />
          <button 
            className="btn primary sm-btn" 
            onClick={() => refetch()}
            disabled={isRefetching}
            title="Refresh the table data"
          >
            <RefreshCw size={16} className={isRefetching ? "animate-spin" : ""} /> 
            {isRefetching ? (isAr ? "جاري التحديث..." : "Refreshing...") : (isAr ? "تحديث البيانات" : "Refresh Data")}
          </button>
        </div>
      </div>

      {/* Info Alert */}
      <div className="card-glass" style={{ marginBottom: "24px", borderColor: "rgba(59, 130, 246, 0.3)", background: "rgba(59, 130, 246, 0.05)", padding: "16px 24px", display: "flex", alignItems: "center", gap: "12px" }}>
        <ShieldCheck color="var(--primary-light)" size={20} />
        <span style={{ color: "var(--glass-text-secondary)", fontSize: "14px" }}>
          {t('cred_alert' as any)}
        </span>
      </div>

      {/* Search Row */}
      <div className="card-glass" style={{ padding: "16px 24px", marginBottom: "24px", display: "flex", gap: "20px", alignItems: "center" }}>
        <div style={{ position: "relative", flex: 1 }}>
          <Search size={18} style={{ position: "absolute", left: "14px", top: "50%", transform: "translateY(-50%)", color: "var(--glass-text-muted)" }} />
          <input 
            type="text" 
            placeholder={t('cred_search' as any)} 
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="glass-input"
            style={{ paddingLeft: "42px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)", borderRadius: "10px", width: "100%", padding: "12px 14px 12px 42px", outline: "none" }}
          />
        </div>
      </div>

      {/* Table */}
      <div className="premium-table-wrapper card-glass" style={{ padding: "0", overflow: "hidden" }}>
        <table className="premium-table">
          <thead>
            <tr>
              <th style={isAr ? { textAlign: "right" } : {}}>{t('dash_users')}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{t('cred_entity' as any)}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{t('cred_login_id' as any)}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{t('cred_password' as any)}</th>
              <th style={{ textAlign: "end" }}>{t('std_actions' as any)}</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr><td colSpan={5} style={{ textAlign: "center", padding: "60px" }}><div className="spinner-large" style={{ margin: "0 auto" }} /></td></tr>
            ) : filteredData?.length === 0 ? (
              <tr><td colSpan={5} style={{ textAlign: "center", padding: "60px", color: "var(--glass-text-muted)" }}>{t('cred_no_data' as any)}</td></tr>
            ) : filteredData?.map((cred: any) => {
              const entityName = cred.student?.nameAr || cred.teacher?.nameAr || cred.parent?.nameAr || cred.driver?.nameAr || cred.driver?.name || cred.supervisor?.name || cred.supervisor?.nameAr || "—";
              return (
                <tr key={cred.id}>
                  <td>
                    <div style={{ fontWeight: 700, color: "var(--glass-text-primary)" }}>{entityName}</div>
                  </td>
                  <td>
                    <span className="badge" style={{ 
                      background: cred.role === "STUDENT" ? "rgba(59, 130, 246, 0.1)" : cred.role === "TEACHER" ? "rgba(139, 92, 246, 0.1)" : "rgba(16, 185, 129, 0.1)",
                      color: cred.role === "STUDENT" ? "#3b82f6" : cred.role === "TEACHER" ? "#8b5cf6" : "#10b981"
                    }}>
                      {cred.role}
                    </span>
                  </td>
                  <td style={{ fontFamily: "monospace", fontWeight: 700, color: "var(--glass-text-primary)" }}>{cred.loginId}</td>
                  <td>
                    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                      {editingId === cred.id ? (
                        <input 
                          type="text" 
                          value={tempPassword} 
                          onChange={(e) => setTempPassword(e.target.value)}
                          style={{
                            background: "var(--glass-input-bg)",
                            border: "1px solid var(--primary-light)",
                            color: "var(--glass-text-primary)",
                            borderRadius: "6px",
                            padding: "4px 8px",
                            fontSize: "13px",
                            width: "120px"
                          }}
                          placeholder="Min 6 chars"
                        />
                      ) : (
                        <>
                          <div style={{ fontFamily: "monospace", color: revealMap[cred.id] ? "var(--primary-light)" : "var(--glass-text-muted)", letterSpacing: revealMap[cred.id] ? "normal" : "3px" }}>
                            {revealMap[cred.id] ? cred.plainTextPw : "••••••••"}
                          </div>
                          <button onClick={() => toggleReveal(cred.id)} style={{ background: "none", border: "none", color: "var(--glass-text-muted)", cursor: "pointer" }}>
                            {revealMap[cred.id] ? <EyeOff size={16} /> : <Eye size={16} />}
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                  <td style={{ textAlign: "end" }}>
                    <div style={{ display: "flex", gap: "8px", justifyContent: "flex-end" }}>
                      {editingId === cred.id ? (
                        <>
                          <button 
                            className="btn-icon success" 
                            onClick={() => {
                              if (tempPassword.length < 6) return alert("Password must be at least 6 characters");
                              resetMutation.mutate({ id: cred.id, password: tempPassword });
                            }}
                            disabled={resetMutation.isPending}
                          >
                            <Check size={16} />
                          </button>
                          <button className="btn-icon delete" onClick={() => setEditingId(null)}>
                            <X size={16} />
                          </button>
                        </>
                      ) : (
                        <>
                          <button className="btn-icon print" onClick={() => printSingleCard(cred)} title="Print Access Card">
                            <Printer size={16} />
                          </button>
                          <button 
                            className="btn-icon edit" 
                            onClick={() => {
                              setEditingId(cred.id);
                              setTempPassword(cred.plainTextPw || "");
                            }} 
                            title="Edit Password"
                          >
                            <Edit2 size={16} />
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <style jsx>{`
        .sm-btn {
          padding: 8px 16px !important;
          font-size: 13px !important;
          border-radius: 10px !important;
        }
        .btn-icon {
          width: 34px;
          height: 34px;
          border-radius: 8px;
          background: var(--glass-icon-bg);
          border: 1px solid var(--glass-border);
          color: var(--glass-text-secondary);
          display: inline-flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: 0.2s;
        }
        .btn-icon:hover {
          background: var(--primary);
          color: #fff;
          border-color: var(--primary);
        }
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        .animate-spin {
          animation: spin 1s linear infinite;
        }
      `}</style>
    </div>
  );
}
