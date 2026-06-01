"use client";

import React, { useState } from "react";
import { useForm } from "react-hook-form";
import {
  User,
  Users,
  MapPin,
  BookOpen,
  Upload,
  CheckCircle2,
  ChevronRight,
  ChevronLeft,
  Calendar,
  Phone,
  Briefcase,
  UploadCloud
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { useRouter } from "next/navigation";
import { useTranslation, type TranslationKey } from "@/lib/i18n";

const STEPS: { id: string; title: TranslationKey; icon: any }[] = [
  { id: "child", title: "adm_step_student", icon: User },
  { id: "parents", title: "adm_step_family", icon: Users },
  { id: "academic", title: "adm_step_academic", icon: BookOpen },
  { id: "documents", title: "adm_step_docs", icon: Upload }
];

export const AdmissionWizard = () => {
  const { t, isAr } = useTranslation();
  const [currentStep, setCurrentStep] = useState(0);
  const [fatherIdFront, setFatherIdFront] = React.useState<string | null>(null);
  const [fatherIdBack, setFatherIdBack] = React.useState<string | null>(null);
  const [motherIdFront, setMotherIdFront] = React.useState<string | null>(null);
  const [motherIdBack, setMotherIdBack] = React.useState<string | null>(null);
  const [birthCertDoc, setBirthCertDoc] = React.useState<string | null>(null);
  const [childPhotoDoc, setChildPhotoDoc] = React.useState<string | null>(null);
  const [isUploading, setIsUploading] = React.useState(false);
  const router = useRouter();
  const queryClient = useQueryClient();

  const { register, handleSubmit, watch, setValue, trigger, formState: { errors } } = useForm({
    defaultValues: {
      childNameAr: "",
      childNameEn: "",
      childNationalId: "",
      childDob: "",
      childGender: "MALE",
      childNationality: "مصري",
      childReligion: "MUSLIM",
      childAddress: "",
      fatherName: "",
      fatherNationalId: "",
      fatherPhone: "",
      fatherOccupation: "",
      motherName: "",
      motherNationalId: "",
      motherPhone: "",
      motherOccupation: "",
      gradeId: "",
      academicYearId: "",
      previousSchool: "",
    }
  });

  const { data: grades } = useQuery({ queryKey: ["grades"], queryFn: () => api.get("/academic/grades").then(res => res.data.data) });
  const { data: years } = useQuery({ queryKey: ["academic-years"], queryFn: () => api.get("/academic/years").then(res => res.data.data) });

  React.useEffect(() => {
    if (years && years.length > 0) {
      const currentYear = new Date().getFullYear();
      const match = years.find((y: any) => y.name.includes(currentYear.toString()));
      if (match && !watch("academicYearId")) setValue("academicYearId", match.id);
    }
  }, [years, setValue, watch]);

  const mutation = useMutation({
    mutationFn: (data: any) => api.post("/admissions", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admissions"] });
      router.push("/dashboard/admissions");
    }
  });

  const handleNextStep = async () => {
    let isValid = false;
    if (currentStep === 0) isValid = await trigger(["childNameAr", "childNationalId", "childDob", "childAddress"]);
    else if (currentStep === 1) {
      isValid = await trigger(["fatherName", "fatherNationalId", "fatherPhone", "fatherOccupation", "motherName", "motherNationalId", "motherPhone", "motherOccupation"]);
      if (isValid && (!fatherIdFront || !fatherIdBack || !motherIdFront || !motherIdBack)) {
        alert(isAr ? "يرجى رفع صور البطاقات الشخصية (وش وظهر) للأب والأم قبل المتابعة" : "Please upload Father and Mother ID (Front & Back) before proceeding.");
        isValid = false;
      }
    }
    else if (currentStep === 2) isValid = await trigger(["academicYearId", "gradeId"]);
    else isValid = true;

    if (isValid) setCurrentStep(s => Math.min(s + 1, STEPS.length - 1));
  };

  const prevStep = () => setCurrentStep(s => Math.max(s - 1, 0));

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>, type: string) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIsUploading(true);
    try {
      const ext = file.name.split('.').pop();
      const filename = `${type}_${Date.now()}.${ext}`;
      const { data, error } = await supabase.storage.from("documents").upload(`admissions/${filename}`, file);
      if (error) throw error;
      const { data: urlData } = supabase.storage.from("documents").getPublicUrl(data.path);
      const url = urlData.publicUrl;
      if (type === "father_front") setFatherIdFront(url);
      else if (type === "father_back") setFatherIdBack(url);
      else if (type === "mother_front") setMotherIdFront(url);
      else if (type === "mother_back") setMotherIdBack(url);
      else if (type === "birth") setBirthCertDoc(url);
      else if (type === "photo") setChildPhotoDoc(url);
    } catch (error: any) {
      console.error(error);
      alert(isAr ? "فشل رفع الملف. تأكد من إعدادات Supabase Storage" : "Failed to upload file.");
    } finally {
      setIsUploading(false);
    }
  };

  const onSubmit = (data: any) => {
    const payload = {
      ...data,
      childDob: new Date(data.childDob).toISOString(),
      father: { fullName: data.fatherName, nationalId: data.fatherNationalId, phone: data.fatherPhone, occupation: data.fatherOccupation },
      mother: { fullName: data.motherName, nationalId: data.motherNationalId, phone: data.motherPhone, occupation: data.motherOccupation },
      documents: [] as any[]
    };
    if (fatherIdFront) payload.documents.push({ documentType: "FATHER_NATIONAL_ID_FRONT", fileUrl: fatherIdFront, received: true, validityStatus: "RECEIVED" });
    if (fatherIdBack) payload.documents.push({ documentType: "FATHER_NATIONAL_ID_BACK", fileUrl: fatherIdBack, received: true, validityStatus: "RECEIVED" });
    if (motherIdFront) payload.documents.push({ documentType: "MOTHER_NATIONAL_ID_FRONT", fileUrl: motherIdFront, received: true, validityStatus: "RECEIVED" });
    if (motherIdBack) payload.documents.push({ documentType: "MOTHER_NATIONAL_ID_BACK", fileUrl: motherIdBack, received: true, validityStatus: "RECEIVED" });
    if (birthCertDoc) payload.documents.push({ documentType: "BIRTH_CERTIFICATE", fileUrl: birthCertDoc, received: true, validityStatus: "RECEIVED" });
    if (childPhotoDoc) payload.childPhoto = childPhotoDoc;
    mutation.mutate(payload);
  };

  const primaryGrades = grades?.filter((g: any) => g.order >= 1 && g.order <= 6).sort((a: any, b: any) => a.order - b.order) || [];

  const UploadBox = ({ label, state, uploadType }: { label: string; state: string | null; uploadType: string }) => (
    <div style={{ background: "rgba(255,255,255,0.02)", border: `1px dashed ${state ? "#34d399" : "var(--glass-border)"}`, borderRadius: "12px", padding: "16px 12px", textAlign: "center" }}>
      <UploadCloud size={24} color={state ? "#34d399" : "var(--primary-light)"} style={{ margin: "0 auto 8px" }} />
      <div style={{ fontSize: "12px", fontWeight: 600, color: "var(--glass-text-primary)", marginBottom: "8px" }}>{label}</div>
      {state ? (
        <span className="badge" style={{ background: "rgba(52,211,153,0.1)", color: "#34d399", fontSize: "11px", padding: "4px 8px" }}>{isAr ? "مكتمل ✓" : "Done ✓"}</span>
      ) : (
        <label style={{ display: "inline-block", background: "var(--gradient-primary)", color: "#fff", padding: "6px 12px", borderRadius: "8px", fontSize: "11px", cursor: "pointer", fontWeight: 600 }}>
          {isAr ? "اختر صورة (JPG/PNG)" : "Select Image (JPG/PNG)"}
          <input type="file" accept="image/*,.pdf" style={{ display: "none" }} onChange={(e) => handleFileUpload(e, uploadType)} disabled={isUploading} />
        </label>
      )}
    </div>
  );

  return (
    <div className="wizard-container card-glass" style={{ maxWidth: "1000px", margin: "0 auto", padding: "0", overflow: "hidden" }}>
      {/* Progress Header */}
      <div style={{ display: "flex", borderBottom: "1px solid var(--glass-border)", background: "var(--glass-bg)" }}>
        {STEPS.map((step, idx) => {
          const Icon = step.icon;
          const isActive = idx === currentStep;
          const isCompleted = idx < currentStep;
          return (
            <div key={step.id} style={{ flex: 1, padding: "20px", display: "flex", alignItems: "center", justifyContent: "center", gap: "12px", borderBottom: isActive ? "3px solid var(--primary-light)" : "3px solid transparent", transition: "0.3s" }}>
              <div style={{ width: "32px", height: "32px", borderRadius: "50%", background: isActive ? "var(--gradient-primary)" : isCompleted ? "#34d399" : "var(--dash-chart-grid)", display: "flex", alignItems: "center", justifyContent: "center", color: (isActive || isCompleted) ? "var(--text-primary)" : "var(--dash-muted-strong)" }}>
                {isCompleted ? <CheckCircle2 size={18} /> : <Icon size={18} />}
              </div>
              <span style={{ fontWeight: 600, fontSize: "14px", color: isActive ? "var(--glass-text-primary)" : "var(--glass-text-secondary)" }}>{t(step.title)}</span>
            </div>
          );
        })}
      </div>

      {/* Form Content */}
      <form onSubmit={(e) => e.preventDefault()} style={{ padding: "48px" }}>
        {currentStep === 0 && (
          <div className="animate-fadeInRight">
            <h3 className="section-title" style={{ color: "var(--text-primary)" }}>{t('adm_section_basic')}</h3>
            <div className="form-grid">
              <div className="field">
                <label className="glass-label">{t('adm_label_name_ar')}</label>
                <input {...register("childNameAr", { required: isAr ? "الاسم مطلوب" : "Required" })} className="glass-input" placeholder={t('adm_ph_name_ar')} />
                {errors.childNameAr && <span className="error-text">{errors.childNameAr.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_name_en')}</label>
                <input {...register("childNameEn")} className="glass-input" placeholder={t('adm_ph_name_en')} />
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_dob')}</label>
                <input type="date" {...register("childDob", { required: isAr ? "التاريخ مطلوب" : "Required" })} className="glass-input" />
                {errors.childDob && <span className="error-text">{errors.childDob.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_national_id')}</label>
                <input {...register("childNationalId", { required: isAr ? "الرقم القومي مطلوب" : "National ID required", pattern: { value: /^\d{14}$/, message: isAr ? "يجب أن يتكون من 14 رقم بالضبط" : "Must be exactly 14 digits" } })} className="glass-input" placeholder={t('adm_ph_national_id')} />
                {errors.childNationalId && <span className="error-text">{errors.childNationalId.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_religion')}</label>
                <select {...register("childReligion")} className="glass-input">
                  <option value="MUSLIM">{t('adm_opt_muslim')}</option>
                  <option value="CHRISTIAN">{t('adm_opt_christian')}</option>
                  <option value="OTHER">{t('adm_opt_other')}</option>
                </select>
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_gender')}</label>
                <select {...register("childGender")} className="glass-input">
                  <option value="MALE">{t('adm_label_gender_m')}</option>
                  <option value="FEMALE">{t('adm_label_gender_f')}</option>
                </select>
              </div>
              <div className="field" style={{ gridColumn: "1 / -1" }}>
                <label className="glass-label">{t('adm_label_address')}</label>
                <input {...register("childAddress", { required: isAr ? "العنوان بالتفصيل مطلوب" : "Detailed Address required" })} className="glass-input" placeholder={t('adm_ph_address')} />
                {errors.childAddress && <span className="error-text">{errors.childAddress.message as string}</span>}
              </div>
            </div>
          </div>
        )}

        {currentStep === 1 && (
          <div className="animate-fadeInRight">
            <h3 className="section-title" style={{ color: "var(--text-primary)" }}>{t('adm_section_parents')}</h3>
            <div className="form-grid">
              <div style={{ gridColumn: "1 / -1" }}><h4 style={{ color: "var(--text-primary)" }}>{t('adm_section_parents_father')}</h4></div>
              <div className="field">
                <label className="glass-label">{t('adm_label_father_name')}</label>
                <input {...register("fatherName", { required: isAr ? "الاسم مطلوب" : "Required" })} className="glass-input" />
                {errors.fatherName && <span className="error-text">{errors.fatherName.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{isAr ? "الرقم القومي" : "National ID"}</label>
                <input {...register("fatherNationalId", { required: isAr ? "الرقم القومي مطلوب" : "National ID required", pattern: { value: /^\d{14}$/, message: isAr ? "يجب أن يتكون من 14 رقم بالضبط" : "Must be exactly 14 digits" } })} className="glass-input" />
                {errors.fatherNationalId && <span className="error-text">{errors.fatherNationalId.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_father_phone')}</label>
                <input {...register("fatherPhone", { required: isAr ? "رقم الموبايل مطلوب" : "Phone number required" })} className="glass-input" />
                {errors.fatherPhone && <span className="error-text">{errors.fatherPhone.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_father_job')}</label>
                <input {...register("fatherOccupation", { required: isAr ? "الوظيفة مطلوبة" : "Occupation required" })} className="glass-input" />
                {errors.fatherOccupation && <span className="error-text">{errors.fatherOccupation.message as string}</span>}
              </div>

              <div style={{ gridColumn: "1 / -1", marginTop: "20px" }}><h4 style={{ color: "var(--text-primary)" }}>{t('adm_section_parents_mother')}</h4></div>
              <div className="field">
                <label className="glass-label">{t('adm_label_mother_name')}</label>
                <input {...register("motherName", { required: isAr ? "الاسم مطلوب" : "Required" })} className="glass-input" />
                {errors.motherName && <span className="error-text">{errors.motherName.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{isAr ? "الرقم القومي" : "National ID"}</label>
                <input {...register("motherNationalId", { required: isAr ? "الرقم القومي مطلوب" : "National ID required", pattern: { value: /^\d{14}$/, message: isAr ? "يجب أن يتكون من 14 رقم بالضبط" : "Must be exactly 14 digits" } })} className="glass-input" />
                {errors.motherNationalId && <span className="error-text">{errors.motherNationalId.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_mother_phone')}</label>
                <input {...register("motherPhone", { required: isAr ? "رقم الموبايل مطلوب" : "Phone number required" })} className="glass-input" />
                {errors.motherPhone && <span className="error-text">{errors.motherPhone.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_mother_job')}</label>
                <input {...register("motherOccupation", { required: isAr ? "الوظيفة مطلوبة" : "Occupation required" })} className="glass-input" />
                {errors.motherOccupation && <span className="error-text">{errors.motherOccupation.message as string}</span>}
              </div>

              {/* ID DOCUMENTS - Front & Back */}
              <div style={{ gridColumn: "1 / -1", marginTop: "20px", borderTop: "1px solid var(--glass-border)", paddingTop: "20px" }}>
                <h4 style={{ color: "var(--text-primary)", marginBottom: "16px" }}>{isAr ? "المستندات المطلوبة (صورة البطاقة الشخصية)" : "Required Documents (National ID Scan)"}</h4>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px", marginBottom: "16px" }}>
                  <UploadBox label={isAr ? "بطاقة الأب — وجه أمامي (Front)" : "Father's ID — Front"} state={fatherIdFront} uploadType="father_front" />
                  <UploadBox label={isAr ? "بطاقة الأب — وجه خلفي (Back)" : "Father's ID — Back"} state={fatherIdBack} uploadType="father_back" />
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
                  <UploadBox label={isAr ? "بطاقة الأم — وجه أمامي (Front)" : "Mother's ID — Front"} state={motherIdFront} uploadType="mother_front" />
                  <UploadBox label={isAr ? "بطاقة الأم — وجه خلفي (Back)" : "Mother's ID — Back"} state={motherIdBack} uploadType="mother_back" />
                </div>
              </div>
            </div>
          </div>
        )}

        {currentStep === 2 && (
          <div className="animate-fadeInRight">
            <h3 className="section-title" style={{ color: "var(--text-primary)" }}>{t('adm_section_grade')}</h3>
            <div className="form-grid">
              <div className="field">
                <label className="glass-label">{t('adm_label_year')}</label>
                <select {...register("academicYearId", { required: isAr ? "إجباري" : "Required" })} className="glass-input">
                  <option value="">{t('adm_ph_year')}</option>
                  {years?.map((y: any) => <option key={y.id} value={y.id}>{y.name}</option>)}
                </select>
                {errors.academicYearId && <span className="error-text">{errors.academicYearId.message as string}</span>}
              </div>
              <div className="field">
                <label className="glass-label">{t('adm_label_grade')}</label>
                <select {...register("gradeId", { required: isAr ? "إجباري" : "Required" })} className="glass-input">
                  <option value="">{t('adm_ph_grade')}</option>
                  {primaryGrades.map((g: any) => <option key={g.id} value={g.id}>{isAr ? g.name : g.nameEn}</option>)}
                </select>
                {errors.gradeId && <span className="error-text">{errors.gradeId.message as string}</span>}
              </div>
              <div className="field" style={{ gridColumn: "1 / -1" }}>
                <label className="glass-label">{t('adm_label_prev_school')}</label>
                <input {...register("previousSchool")} className="glass-input" />
              </div>
            </div>
          </div>
        )}

        {currentStep === 3 && (
          <div className="animate-fadeInRight" style={{ textAlign: "center" }}>
            <h3 className="section-title">{t('adm_section_upload')}</h3>
            <div className="doc-upload-grid">
              <div className="doc-upload-card">
                <UploadCloud size={32} color={birthCertDoc ? "#34d399" : "var(--primary-light)"} />
                <span>{t('adm_doc_birth')}</span>
                {birthCertDoc ? (
                  <span className="badge" style={{ background: "rgba(52,211,153,0.1)", color: "#34d399", fontSize: "12px", padding: "4px 8px" }}>{isAr ? "تم الرفع ✓" : "Uploaded ✓"}</span>
                ) : (
                  <label className="btn outline sm" style={{ cursor: "pointer", display: "inline-block", margin: 0 }}>
                    {t('adm_btn_choose')}
                    <input type="file" accept="image/*,.pdf" style={{ display: "none" }} onChange={(e) => handleFileUpload(e, "birth")} disabled={isUploading} />
                  </label>
                )}
              </div>
              <div className="doc-upload-card">
                <User size={32} color={childPhotoDoc ? "#34d399" : "var(--primary-light)"} />
                <span>{t('adm_doc_photo')}</span>
                {childPhotoDoc ? (
                  <span className="badge" style={{ background: "rgba(52,211,153,0.1)", color: "#34d399", fontSize: "12px", padding: "4px 8px" }}>{isAr ? "تم الرفع ✓" : "Uploaded ✓"}</span>
                ) : (
                  <label className="btn outline sm" style={{ cursor: "pointer", display: "inline-block", margin: 0 }}>
                    {t('adm_btn_choose')}
                    <input type="file" accept="image/*" style={{ display: "none" }} onChange={(e) => handleFileUpload(e, "photo")} disabled={isUploading} />
                  </label>
                )}
              </div>
              <div className="doc-upload-card" style={{ opacity: 0.5 }}>
                <CheckCircle2 size={32} color="#34d399" />
                <span>{t('adm_doc_national_id')}</span>
                <span style={{ fontSize: "12px", color: "var(--glass-text-muted)" }}>{isAr ? "تم الرفع في خطوة الأسرة" : "Uploaded in Family step"}</span>
              </div>
            </div>

            {mutation.isError && (
              <div style={{ marginTop: "24px", padding: "16px", background: "rgba(239,68,68,0.1)", border: "1px solid rgba(239,68,68,0.2)", borderRadius: "12px", color: "#ef4444", fontWeight: 600 }}>
                {isAr ? "خطأ في البيانات: " : "Validation Error: "} {(mutation.error as any)?.response?.data?.message || mutation.error.message}
              </div>
            )}

            <div style={{ marginTop: "40px", padding: "24px", background: "rgba(52,211,153,0.05)", borderRadius: "12px", border: "1px solid rgba(52,211,153,0.1)" }}>
              <p style={{ color: "#34d399", fontWeight: 600 }}>{t('adm_notice_declaration')}</p>
            </div>
          </div>
        )}

        {/* Action Buttons - SEPARATED to prevent auto-submit */}
        <div style={{ display: "flex", justifyContent: "space-between", marginTop: "60px", paddingTop: "32px", borderTop: "1px solid var(--glass-border)" }}>
          <button type="button" onClick={prevStep} disabled={currentStep === 0} className="btn outline" style={{ opacity: currentStep === 0 ? 0 : 1, transition: "0.3s" }}>
            {isAr ? <ChevronRight size={20} /> : <ChevronLeft size={20} />} {isAr ? 'السابق' : 'Previous'}
          </button>

          {currentStep < STEPS.length - 1 ? (
            <button type="button" onClick={handleNextStep} className="btn primary">
              {isAr ? 'التالي' : 'Next'} {isAr ? <ChevronLeft size={20} /> : <ChevronRight size={20} />}
            </button>
          ) : (
            <button type="button" className="btn primary" disabled={mutation.isPending} onClick={handleSubmit(onSubmit)}>
              {mutation.isPending ? t('btn_submitting') : t('btn_submit_app')}
            </button>
          )}
        </div>
      </form>

      <style jsx>{`
        .error-text { color: #ef4444; font-size: 12px; margin-top: 6px; display: block; }
        .section-title { font-size: 24px; font-weight: 800; margin-bottom: 32px; color: var(--glass-text-primary); }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
        .field label { display: block; margin-bottom: 8px; font-size: 14px; font-weight: 600; color: var(--glass-text-secondary); }
        .doc-upload-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
        .doc-upload-card { padding: 32px; background: var(--glass-bg); border: 2px dashed var(--glass-border); border-radius: 16px; display: flex; flex-direction: column; align-items: center; gap: 12px; transition: 0.3s; }
        .doc-upload-card:hover { border-color: var(--primary-light); background: rgba(59,130,246,0.05); }
        .doc-upload-card span { font-size: 13px; font-weight: 600; }
        @keyframes fadeInRight { from { opacity: 0; transform: translateX(20px); } to { opacity: 1; transform: translateX(0); } }
        .animate-fadeInRight { animation: fadeInRight 0.4s ease-out; }
      `}</style>
    </div>
  );
};
