"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useParams, useRouter } from "next/navigation";
import {
  User, Users, FileText, CheckCircle2, XCircle, Clock, RefreshCw,
  UserPlus, Pencil
} from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation, type TranslationKey } from "@/lib/i18n";
import { BackButton } from "@/components/ui/BackButton";

export default function AdmissionDetailsPage() {
  const { id } = useParams();
  const { t, isAr } = useTranslation();
  const router = useRouter();
  const queryClient = useQueryClient();
  const [editingSection, setEditingSection] = useState<string | null>(null);
  const [editData, setEditData] = useState<any>({});

  const { data: app, isLoading } = useQuery({
    queryKey: ["admission", id],
    queryFn: async () => (await api.get(`/admissions/${id}`)).data.data
  });

  const statusMutation = useMutation({
    mutationFn: async (status: string) => api.patch(`/admissions/${id}/status`, { status }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["admission", id] })
  });

  const updateMutation = useMutation({
    mutationFn: async (data: any) => api.put(`/admissions/${id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admission", id] });
      queryClient.invalidateQueries({ queryKey: ["admissions"] });
      setEditingSection(null);
    },
    onError: (err: any) => alert(err.response?.data?.message || t('stat_no_data'))
  });

  const convertMutation = useMutation({
    mutationFn: async () => api.post(`/admissions/${id}/convert`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admission", id] });
      queryClient.invalidateQueries({ queryKey: ["students"] });
      router.push("/dashboard/students");
    },
    onError: (err: any) => {
      const msg = err.response?.data?.message || "Failed to convert admission";
      alert(msg);
    }
  });

  const startEdit = (section: string) => {
    if (section === "child") {
      setEditData({ 
        childNameAr: app.childNameAr, 
        childNameEn: app.childNameEn, 
        childNationalId: app.childNationalId, 
        childAddress: app.childAddress,
        childBloodType: app.childBloodType,
        childGender: app.childGender
      });
    } else if (section === "family") {
      setEditData({ fatherName: app.father?.fullName, fatherPhone: app.father?.phone, fatherOccupation: app.father?.occupation, motherName: app.mother?.fullName, motherPhone: app.mother?.phone, motherOccupation: app.mother?.occupation });
    }
    setEditingSection(section);
  };

  const saveEdit = () => {
    if (editingSection === "child") {
      updateMutation.mutate({ 
        childNameAr: editData.childNameAr, 
        childNameEn: editData.childNameEn, 
        childNationalId: editData.childNationalId, 
        childAddress: editData.childAddress,
        childBloodType: editData.childBloodType,
        childGender: editData.childGender
      });
    } else if (editingSection === "family") {
      updateMutation.mutate({ father: { fullName: editData.fatherName, phone: editData.fatherPhone, occupation: editData.fatherOccupation }, mother: { fullName: editData.motherName, phone: editData.motherPhone, occupation: editData.motherOccupation } });
    }
  };

  if (isLoading) return <div style={{ padding: "80px", textAlign: "center" }}><div className="spinner-large" style={{ margin: "0 auto" }} /></div>;
  if (!app) return <div style={{ padding: "80px", textAlign: "center" }}>Application not found.</div>;

  const ef = (label: string, field: string) => (
    <div style={{ marginBottom: "12px" }}>
      <div style={{ fontSize: "12px", color: "var(--dash-muted-strong)", marginBottom: "4px" }}>{label}</div>
      <input className="glass-input" value={editData[field] || ""} onChange={(e) => setEditData((prev: any) => ({ ...prev, [field]: e.target.value }))} style={{ padding: "8px 12px", fontSize: "14px" }} />
    </div>
  );

  const getStatusInfo = (status: string) => {
    const map: any = {
      NEW: { label: t('status_new'), color: "#f59e0b", icon: <Clock size={16} /> },
      UNDER_REVIEW: { label: t('status_under_review'), color: "#3b82f6", icon: <RefreshCw size={16} /> },
      FINAL_ACCEPTED: { label: t('status_final_accepted'), color: "#34d399", icon: <CheckCircle2 size={16} /> },
      REJECTED: { label: t('status_rejected'), color: "#f87171", icon: <XCircle size={16} /> },
      CONVERTED: { label: t('status_converted'), color: "#10b981", icon: <CheckCircle2 size={16} /> },
      DOCUMENTS_INCOMPLETE: { label: t('status_doc_incomplete'), color: "#ef4444", icon: <XCircle size={16} /> },
      PENDING_DECISION: { label: t('status_pending_decision'), color: "#8b5cf6", icon: <Clock size={16} /> },
      PRELIMINARY_ACCEPTED: { label: t('status_preliminary_accepted'), color: "#60a5fa", icon: <CheckCircle2 size={16} /> },
    };
    return map[status] || { label: status, color: "var(--dash-muted-strong)", icon: <Clock size={16} /> };
  };

  return (
    <div className="admission-details">
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "40px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "20px" }}>
          <BackButton />
          <div>
            <h2 style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)" }}>
              {isAr ? "تفاصيل طلب: " : "Admission Details: "} 
              {isAr ? app.childNameAr : (app.childNameEn || app.childNameAr)}
            </h2>
            <div style={{ display: "flex", gap: "10px", marginTop: "4px", fontSize: "14px", color: "var(--dash-muted-strong)" }}>
              <span>{t('adm_label_id')}: {app.applicationNo}</span><span>•</span>
              <span>{t('adm_label_date')}: {new Date(app.createdAt).toLocaleDateString()}</span>
            </div>
          </div>
        </div>
        <div style={{ display: "flex", gap: "12px" }}>
          {app.status === "FINAL_ACCEPTED" && !app.convertedStudentId && (
            <button className="btn primary" onClick={() => convertMutation.mutate()} disabled={convertMutation.isPending}>
              <UserPlus size={18} /> {convertMutation.isPending ? t('adm_btn_converting') : t('adm_btn_convert')}
            </button>
          )}
          {app.convertedStudentId && (
            <div style={{ background: "rgba(52,211,153,0.1)", color: "#34d399", padding: "10px 20px", borderRadius: "12px", border: "1px solid rgba(52,211,153,0.2)", fontSize: "14px", fontWeight: 700, display: "flex", alignItems: "center", gap: "8px" }}>
              <CheckCircle2 size={18} /> {t('status_converted')}
            </div>
          )}
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: "32px" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: "32px" }}>

          {/* ── Child Card ── */}
          <div className="card-glass">
            <h3 className="card-title" style={{ justifyContent: "space-between" }}>
              <span style={{ display: "flex", alignItems: "center", gap: "12px" }}><User size={18} /> {t('adm_section_basic')}</span>
              <button className="edit-section-btn" onClick={() => startEdit("child")}><Pencil size={14} /></button>
            </h3>
            {editingSection === "child" ? (
              <div className="info-grid">
                {ef(t('adm_label_name_ar'), "childNameAr")}
                {ef(t('adm_label_name_en'), "childNameEn")}
                {ef(t('adm_label_national_id'), "childNationalId")}
                {ef(t('adm_label_blood_type'), "childBloodType")}
                <div style={{ marginBottom: "12px" }}>
                  <div style={{ fontSize: "12px", color: "var(--dash-muted-strong)", marginBottom: "4px" }}>{t('adm_label_gender')}</div>
                  <select 
                    className="glass-input" 
                    value={editData.childGender || "MALE"} 
                    onChange={(e) => setEditData((prev: any) => ({ ...prev, childGender: e.target.value }))}
                    style={{ padding: "8px 12px", fontSize: "14px", height: "39px", width: "100%", background: "var(--glass-bg)", color: "var(--glass-text-primary)", border: "1px solid var(--glass-border)", borderRadius: "8px" }}
                  >
                    <option value="MALE" style={{ background: "#1a1f2c", color: "#fff" }}>{t('adm_label_gender_m')}</option>
                    <option value="FEMALE" style={{ background: "#1a1f2c", color: "#fff" }}>{t('adm_label_gender_f')}</option>
                  </select>
                </div>
                {ef(t('adm_label_address'), "childAddress")}
                <div style={{ gridColumn: "1 / -1", display: "flex", gap: "8px", marginTop: "8px" }}>
                  <button className="btn primary" onClick={saveEdit} disabled={updateMutation.isPending} style={{ padding: "8px 20px", fontSize: "13px" }}>{updateMutation.isPending ? t('btn_submitting') : t('adm_btn_save')}</button>
                  <button className="btn outline" onClick={() => setEditingSection(null)} style={{ padding: "8px 20px", fontSize: "13px" }}>{t('adm_btn_cancel')}</button>
                </div>
              </div>
            ) : (
              <div className="info-grid">
                <InfoItem label={t('adm_label_name_ar')} value={app.childNameAr} />
                <InfoItem label={t('adm_label_name_en')} value={app.childNameEn} />
                <InfoItem label={t('adm_label_national_id')} value={app.childNationalId} />
                <InfoItem label={t('adm_label_dob')} value={new Date(app.childDob).toLocaleDateString()} />
                <InfoItem label={t('adm_label_gender')} value={app.childGender === "MALE" ? t('adm_label_gender_m') : t('adm_label_gender_f')} />
                <InfoItem label={t('adm_label_nationality')} value={app.childNationality} />
                <InfoItem label={t('adm_label_religion')} value={app.childReligion === "MUSLIM" ? t('adm_opt_muslim') : t('adm_opt_christian')} />
                <InfoItem label={t('adm_label_blood_type')} value={app.childBloodType} />
                <div style={{ gridColumn: "1 / -1" }}><InfoItem label={t('adm_label_address')} value={app.childAddress} /></div>
              </div>
            )}
          </div>

          {/* ── Parents Card ── */}
          <div className="card-glass">
            <h3 className="card-title" style={{ justifyContent: "space-between" }}>
              <span style={{ display: "flex", alignItems: "center", gap: "12px" }}><Users size={18} /> {t('adm_section_parents')}</span>
              <button className="edit-section-btn" onClick={() => startEdit("family")}><Pencil size={14} /></button>
            </h3>
            {editingSection === "family" ? (
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "32px" }}>
                <div>
                  <h4 style={{ fontSize: "16px", marginBottom: "16px", color: "var(--primary-light)" }}>{t('adm_section_parents_father')}</h4>
                  {ef(t('adm_label_father_name'), "fatherName")}
                  {ef(t('adm_label_father_phone'), "fatherPhone")}
                  {ef(t('adm_label_father_job'), "fatherOccupation")}
                </div>
                <div>
                  <h4 style={{ fontSize: "16px", marginBottom: "16px", color: "var(--primary-light)" }}>{t('adm_section_parents_mother')}</h4>
                  {ef(t('adm_label_mother_name'), "motherName")}
                  {ef(t('adm_label_mother_phone'), "motherPhone")}
                  {ef(t('adm_label_mother_job'), "motherOccupation")}
                </div>
                <div style={{ gridColumn: "1 / -1", display: "flex", gap: "8px" }}>
                  <button className="btn primary" onClick={saveEdit} disabled={updateMutation.isPending} style={{ padding: "8px 20px", fontSize: "13px" }}>{updateMutation.isPending ? t('btn_submitting') : t('adm_btn_save')}</button>
                  <button className="btn outline" onClick={() => setEditingSection(null)} style={{ padding: "8px 20px", fontSize: "13px" }}>{t('adm_btn_cancel')}</button>
                </div>
              </div>
            ) : (
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "32px" }}>
                <div>
                  <h4 style={{ fontSize: "16px", marginBottom: "16px", color: "var(--primary-light)" }}>{t('adm_section_parents_father')}</h4>
                  <InfoStack label={t('adm_label_father_name')} value={app.father?.fullName} />
                  <InfoStack label={t('adm_label_phone')} value={app.father?.phone} />
                  <InfoStack label={t('adm_label_job')} value={app.father?.occupation} />
                </div>
                <div>
                  <h4 style={{ fontSize: "16px", marginBottom: "16px", color: "var(--primary-light)" }}>{t('adm_section_parents_mother')}</h4>
                  <InfoStack label={t('adm_label_mother_name')} value={app.mother?.fullName} />
                  <InfoStack label={t('adm_label_phone')} value={app.mother?.phone} />
                  <InfoStack label={t('adm_label_job')} value={app.mother?.occupation} />
                </div>
              </div>
            )}
          </div>

          {/* ── Documents Card ── */}
          <div className="card-glass">
            <h3 className="card-title"><span style={{ display: "flex", alignItems: "center", gap: "12px" }}><FileText size={18} /> {t('adm_label_docs')}</span></h3>
            {(!app.documents || app.documents.length === 0) && !app.childPhoto ? (
              <p style={{ color: "var(--dash-muted-strong)", textAlign: "center", padding: "40px 0" }}>{t('adm_msg_no_docs')}</p>
            ) : (
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))", gap: "16px" }}>
                {app.childPhoto && (
                  <a href={app.childPhoto} target="_blank" rel="noreferrer" style={{ display: "flex", flexDirection: "column", gap: "8px", padding: "16px", background: "var(--glass-icon-bg)", border: "1px solid var(--glass-border)", borderRadius: "12px", textDecoration: "none", color: "var(--glass-text-primary)" }}>
                    <div style={{ width: "100%", height: "100px", borderRadius: "8px", background: "var(--glass-bg)", overflow: "hidden" }}>
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={app.childPhoto} alt="Student" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                    </div>
                    <span style={{ fontSize: "14px", fontWeight: 700, textAlign: "center" }}>{t('adm_doc_photo')}</span>
                  </a>
                )}
                {app.documents?.map((doc: any, i: number) => (
                  <a key={i} href={doc.fileUrl} target="_blank" rel="noreferrer" style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: "12px", padding: "20px 16px", background: "var(--glass-icon-bg)", border: "1px solid var(--glass-border)", borderRadius: "12px", textDecoration: "none", color: "var(--glass-text-primary)", transition: "0.2s" }}>
                    <FileText size={32} color="var(--primary-light)" />
                    <span style={{ fontSize: "13px", fontWeight: 700, textAlign: "center" }}>
                      {doc.documentType === "FATHER_NATIONAL_ID_FRONT" ? (isAr ? "بطاقة الأب (أمامي)" : "Father ID (Front)") :
                       doc.documentType === "FATHER_NATIONAL_ID_BACK" ? (isAr ? "بطاقة الأب (خلفي)" : "Father ID (Back)") :
                       doc.documentType === "MOTHER_NATIONAL_ID_FRONT" ? (isAr ? "بطاقة الأم (أمامي)" : "Mother ID (Front)") :
                       doc.documentType === "MOTHER_NATIONAL_ID_BACK" ? (isAr ? "بطاقة الأم (خلفي)" : "Mother ID (Back)") :
                       doc.documentType === "BIRTH_CERTIFICATE" ? t('adm_doc_birth') : doc.documentType}
                    </span>
                  </a>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* ── Sidebar ── */}
        <div style={{ display: "flex", flexDirection: "column", gap: "32px" }}>
          <div className="card-glass">
            <h3 className="card-title">{t('adm_label_status')}</h3>
            <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
              <StatusBtn active={app.status === "NEW"} onClick={() => statusMutation.mutate("NEW")} {...getStatusInfo("NEW")} />
              <StatusBtn active={app.status === "UNDER_REVIEW"} onClick={() => statusMutation.mutate("UNDER_REVIEW")} {...getStatusInfo("UNDER_REVIEW")} />
              <StatusBtn active={app.status === "FINAL_ACCEPTED"} onClick={() => statusMutation.mutate("FINAL_ACCEPTED")} {...getStatusInfo("FINAL_ACCEPTED")} />
              <StatusBtn active={app.status === "REJECTED"} onClick={() => statusMutation.mutate("REJECTED")} {...getStatusInfo("REJECTED")} />
            </div>
          </div>
          <div className="card-glass">
            <h3 className="card-title">{t('adm_label_reg_data')}</h3>
            <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
              <InfoStack label={t('adm_label_academic_year')} value={app.academicYear?.name} />
              <InfoStack label={t('adm_label_target_grade')} value={app.grade?.name} />
              <InfoStack label={t('adm_label_prev_school_val')} value={app.previousSchool || "—"} />
            </div>
          </div>
        </div>
      </div>

      <style jsx>{`
        .card-title { font-size: 18px; font-weight: 800; margin-bottom: 24px; display: flex; align-items: center; gap: 12px; color: var(--glass-text-primary); }
        .info-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 20px; }
        .edit-section-btn { width: 32px; height: 32px; border-radius: 8px; background: rgba(59,130,246,0.1); border: 1px solid rgba(59,130,246,0.2); color: var(--primary-light); display: flex; align-items: center; justify-content: center; cursor: pointer; transition: 0.2s; }
        .edit-section-btn:hover { background: rgba(59,130,246,0.2); transform: translateY(-1px); }
      `}</style>
    </div>
  );
}

const InfoItem = ({ label, value }: { label: string; value: any }) => (
  <div style={{ marginBottom: "12px" }}>
    <div style={{ fontSize: "12px", color: "var(--dash-muted-strong)", textTransform: "uppercase", letterSpacing: "1px", marginBottom: "4px" }}>{label}</div>
    <div style={{ fontSize: "15px", fontWeight: 600, color: "var(--glass-text-primary)" }}>{value || "—"}</div>
  </div>
);

const InfoStack = ({ label, value }: { label: string; value: any }) => (
  <div style={{ marginBottom: "16px" }}>
    <div style={{ fontSize: "13px", color: "var(--dash-muted-strong)", marginBottom: "4px" }}>{label}</div>
    <div style={{ fontSize: "16px", fontWeight: 700, color: "var(--glass-text-primary)" }}>{value || "—"}</div>
  </div>
);

const StatusBtn = ({ active, onClick, icon, label, color }: any) => (
  <button onClick={onClick} style={{ width: "100%", padding: "14px", borderRadius: "12px", border: active ? `2px solid ${color}` : "1px solid var(--glass-border)", background: active ? `${color}15` : "var(--glass-icon-bg)", color: active ? color : "var(--dash-muted-strong)", fontWeight: 700, display: "flex", alignItems: "center", gap: "10px", cursor: "pointer", transition: "0.2s" }}>
    {icon} {label}
  </button>
);
