"use client";

import { useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { X, Mail, Phone, MapPin, Briefcase, Award, Calendar, FileText, ExternalLink, User, ShieldCheck, Eye, EyeOff, Copy } from "lucide-react";
import { useTranslation } from "@/lib/i18n";
import { api } from "@/lib/api";

export default function TeacherProfileModal({ teacher, onClose }: { teacher: any; onClose: () => void }) {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [loading, setLoading] = useState(false);
  const [revealPassword, setRevealPassword] = useState(false);
  const [localCredentials, setLocalCredentials] = useState<any>(teacher.credentials?.[0] || null);

  const generateCredentials = async () => {
    setLoading(true);
    try {
      const res = await api.post("/credentials/generate", {
        role: "TEACHER",
        entityId: teacher.id
      });
      const newCred = res.data?.data?.[0];
      if (newCred) {
        setLocalCredentials({
          id: newCred.id,
          loginId: newCred.loginId,
          plainTextPw: newCred.password,
        });
        queryClient.invalidateQueries({ queryKey: ["teachers"] });
      }
    } catch (err: any) {
      alert(err.response?.data?.message || "Failed to generate credentials");
    } finally {
      setLoading(false);
    }
  };

  if (!teacher) return null;

  const sectionStyle = { marginBottom: "32px" };
  const titleStyle = { fontSize: "16px", fontWeight: 800, color: "var(--glass-text-primary)", marginBottom: "16px", display: "flex", alignItems: "center", gap: "8px", borderBottom: "1px solid var(--glass-border)", paddingBottom: "8px" };
  const gridStyle = { display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: "20px" };
  const itemStyle = { display: "flex", flexDirection: "column" as const, gap: "4px" };
  const labelStyle = { fontSize: "12px", color: "var(--glass-text-muted)", fontWeight: 600 };
  const valueStyle = { fontSize: "14px", color: "var(--glass-text-primary)", fontWeight: 700 };

  return (
    <div style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(15, 23, 42, 0.4)", backdropFilter: "blur(8px)", zIndex: 2000, display: "flex", alignItems: "center", justifyContent: "center", padding: "20px" }} onClick={onClose}>
      <div className="card-glass active" style={{ width: "100%", maxWidth: "900px", maxHeight: "90vh", overflowY: "auto", padding: "40px", position: "relative" }} onClick={e => e.stopPropagation()}>
        
        <button onClick={onClose} style={{ position: "absolute", top: "24px", insetInlineEnd: "24px", background: "rgba(255,255,255,0.05)", border: "1px solid var(--glass-border)", color: "var(--glass-text-secondary)", cursor: "pointer", width: "40px", height: "40px", borderRadius: "12px", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <X size={20} />
        </button>

        {/* Header */}
        <div style={{ display: "flex", alignItems: "center", gap: "24px", marginBottom: "40px" }}>
          {teacher.personalPhoto ? (
            <img src={teacher.personalPhoto} style={{ width: "100px", height: "100px", borderRadius: "24px", objectFit: "cover", border: "4px solid var(--glass-border)" }} />
          ) : (
            <div style={{ width: "100px", height: "100px", borderRadius: "24px", background: "var(--gradient-primary)", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "32px", fontWeight: 800 }}>
              {teacher.user?.fullName?.[0] || "T"}
            </div>
          )}
          <div>
            <h2 style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{teacher.user?.fullName}</h2>
            <div style={{ display: "flex", gap: "12px", marginTop: "8px" }}>
              <span className="badge" style={{ background: "rgba(59, 130, 246, 0.1)", color: "#3b82f6" }}>{t(`data_${teacher.jobTitle?.toUpperCase()}` as any) || teacher.jobTitle || (isAr ? "مدرس" : "Teacher")}</span>
              <span className="badge" style={{ background: "rgba(16, 185, 129, 0.1)", color: "#10b981" }}>{t(`data_${teacher.stage?.toUpperCase()}` as any) || teacher.stage}</span>
              <span className="badge" style={{ background: "rgba(255, 255, 255, 0.05)", color: "var(--glass-text-secondary)" }}>ID: {teacher.code || "—"}</span>
            </div>
          </div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: "40px" }}>
          <div>
            {/* Basic Info */}
            <section style={sectionStyle}>
              <h3 style={titleStyle}><User size={18} /> {isAr ? "البيانات الأساسية" : "Basic Information"}</h3>
              <div style={gridStyle}>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "الاسم بالعربي" : "Name (Ar)"}</span><span style={valueStyle}>{teacher.nameAr || "—"}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "الاسم بالإنجليزي" : "Name (En)"}</span><span style={valueStyle}>{teacher.nameEn || "—"}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "تاريخ الميلاد" : "DOB"}</span><span style={valueStyle}>{teacher.dob ? new Date(teacher.dob).toLocaleDateString() : "—"}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "النوع" : "Gender"}</span><span style={valueStyle}>{teacher.gender}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "الموبايل" : "Phone"}</span><span style={valueStyle}>{teacher.phone || "—"}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "العنوان" : "Address"}</span><span style={valueStyle}>{teacher.address || "—"}</span></div>
              </div>
            </section>

            {/* Job & Qualifications */}
            <section style={sectionStyle}>
              <h3 style={titleStyle}><Briefcase size={18} /> {isAr ? "البيانات الوظيفية والمؤهلات" : "Professional & Qualifications"}</h3>
              <div style={gridStyle}>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "المادة" : "Subject"}</span><span style={valueStyle}>{t(`data_${teacher.subject?.toUpperCase()}` as any) || teacher.subject || "—"}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "المؤهل" : "Qualification"}</span><span style={valueStyle}>{teacher.qualification || "—"}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "التخصص" : "Specialization"}</span><span style={valueStyle}>{teacher.specialization || "—"}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "سنة التخرج" : "Graduation Year"}</span><span style={valueStyle}>{teacher.graduationYear || "—"}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "التقدير" : "Grade"}</span><span style={valueStyle}>{teacher.graduationGrade || "—"}</span></div>
                <div style={itemStyle}><span style={labelStyle}>{isAr ? "تاريخ التعيين" : "Hire Date"}</span><span style={valueStyle}>{teacher.appointmentDate ? new Date(teacher.appointmentDate).toLocaleDateString() : "—"}</span></div>
              </div>
            </section>
          </div>

          <div>
            {/* Documents */}
            <section style={sectionStyle}>
              <h3 style={titleStyle}><FileText size={18} /> {isAr ? "المستندات" : "Documents"}</h3>
              <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                {[
                  { id: "idCopy", label: isAr ? "صورة البطاقة" : "ID Copy" },
                  { id: "graduationCert", label: isAr ? "شهادة التخرج" : "Graduation Cert" },
                  { id: "militaryService", label: isAr ? "الخدمة العسكرية" : "Military Service" },
                  { id: "criminalRecord", label: isAr ? "الفيش والتشبيه" : "Criminal Record" },
                  { id: "experienceCerts", label: isAr ? "شهادات الخبرة" : "Experience Certs" },
                ].map(doc => (
                  <div key={doc.id} style={{ padding: "12px", background: "rgba(255,255,255,0.03)", borderRadius: "12px", border: "1px solid var(--glass-border)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <span style={{ fontSize: "13px", color: "var(--glass-text-secondary)" }}>{doc.label}</span>
                    {teacher[doc.id] ? (
                      <a href={teacher[doc.id]} target="_blank" rel="noreferrer" style={{ color: "var(--primary-light)", display: "flex", alignItems: "center", gap: "4px", fontSize: "12px", fontWeight: 700, textDecoration: "none" }}>
                        View <ExternalLink size={14} />
                      </a>
                    ) : (
                      <span style={{ fontSize: "11px", color: "var(--glass-text-muted)" }}>Missing</span>
                    )}
                  </div>
                ))}
              </div>
            </section>

            {/* Mobile App Access */}
            <section style={sectionStyle}>
              <h3 style={titleStyle}><ShieldCheck size={18} /> {isAr ? "دخول تطبيق الجوال" : "Mobile App Access"}</h3>
              {loading ? (
                <div style={{ display: "flex", justifyContent: "center", padding: "20px" }}>
                  <div className="spinner-small" style={{ border: "2px solid rgba(255,255,255,0.1)", borderTop: "2px solid var(--primary-light)", borderRadius: "50%", width: "20px", height: "20px", animation: "spin 1s linear infinite" }} />
                </div>
              ) : localCredentials ? (
                <div style={{ padding: "16px", background: "rgba(255,255,255,0.03)", borderRadius: "16px", border: "1px solid var(--glass-border)", display: "flex", flexDirection: "column", gap: "12px" }}>
                  <div>
                    <span style={labelStyle}>Login ID</span>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: "4px" }}>
                      <span style={{ ...valueStyle, fontFamily: "monospace", fontSize: "15px" }}>{localCredentials.loginId}</span>
                      <button 
                        onClick={() => {
                          navigator.clipboard.writeText(localCredentials.loginId);
                          alert(isAr ? "تم نسخ اسم الدخول!" : "Login ID copied!");
                        }}
                        style={{ background: "none", border: "none", color: "var(--primary-light)", cursor: "pointer", display: "flex", alignItems: "center" }}
                        title={isAr ? "نسخ" : "Copy"}
                      >
                        <Copy size={16} />
                      </button>
                    </div>
                  </div>
                  <div>
                    <span style={labelStyle}>{isAr ? "كلمة المرور" : "Password"}</span>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: "4px" }}>
                      <span style={{ ...valueStyle, fontFamily: "monospace", fontSize: "15px", letterSpacing: revealPassword ? "normal" : "3px", color: revealPassword ? "var(--primary-light)" : "var(--glass-text-muted)" }}>
                        {revealPassword ? localCredentials.plainTextPw : "••••••••"}
                      </span>
                      <div style={{ display: "flex", gap: "8px" }}>
                        <button 
                          onClick={() => setRevealPassword(!revealPassword)}
                          style={{ background: "none", border: "none", color: "var(--glass-text-secondary)", cursor: "pointer" }}
                        >
                          {revealPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                        {localCredentials.plainTextPw && (
                          <button 
                            onClick={() => {
                              navigator.clipboard.writeText(localCredentials.plainTextPw);
                              alert(isAr ? "تم نسخ كلمة المرور!" : "Password copied!");
                            }}
                            style={{ background: "none", border: "none", color: "var(--primary-light)", cursor: "pointer" }}
                            title={isAr ? "نسخ" : "Copy"}
                          >
                            <Copy size={16} />
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                  <div style={{ fontSize: "11px", color: "var(--glass-text-muted)", marginTop: "4px", borderTop: "1px dashed var(--glass-border)", paddingTop: "8px" }}>
                    {isAr ? "* استخدم هذه البيانات لتسجيل دخول المعلم في تطبيق الجوال." : "* Use these credentials for the teacher to log in to the mobile application."}
                  </div>
                </div>
              ) : (
                <div style={{ padding: "16px", background: "rgba(239, 68, 68, 0.05)", borderRadius: "16px", border: "1px dashed rgba(239, 68, 68, 0.2)", display: "flex", flexDirection: "column", gap: "12px", alignItems: "center", textAlign: "center" }}>
                  <span style={{ fontSize: "13px", color: "var(--glass-text-secondary)" }}>
                    {isAr ? "لا توجد بيانات دخول للتطبيق لهذا المعلم حالياً." : "No app credentials generated for this teacher."}
                  </span>
                  <button 
                    className="btn primary" 
                    onClick={generateCredentials}
                    style={{ fontSize: "12px", padding: "8px 16px", borderRadius: "8px", width: "100%", background: "var(--gradient-primary)", border: "none", color: "#fff", cursor: "pointer", fontWeight: 700 }}
                  >
                    {isAr ? "إنشاء بيانات الدخول" : "Generate Credentials"}
                  </button>
                </div>
              )}
            </section>

            {/* Financial Summary */}
            <section style={sectionStyle}>
              <h3 style={titleStyle}><Award size={18} /> {isAr ? "البيانات المالية" : "Financial"}</h3>
              <div style={{ padding: "16px", background: "var(--gradient-primary)", borderRadius: "16px", color: "#fff" }}>
                <div style={{ fontSize: "12px", opacity: 0.8 }}>{isAr ? "المرتب الحالي" : "Current Salary"}</div>
                <div style={{ fontSize: "24px", fontWeight: 800 }}>{teacher.salary ? `${teacher.salary} EGP` : "—"}</div>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}
