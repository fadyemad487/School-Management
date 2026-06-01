"use client";

import { useState } from "react";
import { Plus, X, User, Briefcase, FileText, CheckCircle, Upload, ChevronRight, ChevronLeft } from "lucide-react";
import { useTranslation } from "@/lib/i18n";
import { supabase } from "@/lib/supabase";

const steps = [
  { id: 1, title: { ar: "البيانات الأساسية", en: "Basic Info" }, icon: User },
  { id: 2, title: { ar: "البيانات الوظيفية", en: "Job & Qualifications" }, icon: Briefcase },
  { id: 3, title: { ar: "المستندات", en: "Documents" }, icon: FileText },
  { id: 4, title: { ar: "ربط المدرسة", en: "School Mapping" }, icon: CheckCircle },
];

const inputStyle = { width: "100%", padding: "12px", background: "rgba(0,0,0,0.02)", border: "1px solid var(--glass-border)", borderRadius: "10px", color: "var(--glass-text-primary)", fontSize: "14px" };
const labelStyle = { display: "block", fontSize: "13px", fontWeight: 600, color: "var(--glass-text-secondary)", marginBottom: "6px" };

export default function TeacherWizard({ 
  onSave, 
  onCancel, 
  isPending, 
  initialData 
}: { 
  onSave: (data: any) => void; 
  onCancel: () => void; 
  isPending: boolean;
  initialData?: any;
}) {
  const { isAr } = useTranslation();
  const [currentStep, setCurrentStep] = useState(1);
  
  const formatDate = (date: any) => {
    if (!date) return "";
    const d = new Date(date);
    return d.toISOString().split('T')[0];
  };

  const [formData, setFormData] = useState<any>(() => {
    if (initialData) {
      return {
        ...initialData,
        fullName: initialData.user?.fullName || initialData.fullName || "",
        email: initialData.user?.email || initialData.email || "",
        dob: formatDate(initialData.dob),
        appointmentDate: formatDate(initialData.appointmentDate),
      };
    }
    return {
      // Basic
      fullName: "", nameEn: "", nationalId: "", dob: "", gender: "MALE", email: "", phone: "", address: "",
      // Job
      jobTitle: "TEACHER", subject: "", stage: "PRIMARY", appointmentDate: "", contractType: "FULL_TIME", salary: "",
      // Quals
      qualification: "", specialization: "", graduationYear: "", graduationGrade: "", experienceYears: "",
      // Docs
      idCopy: "", graduationCert: "", militaryService: "", criminalRecord: "", personalPhoto: "", experienceCerts: ""
    };
  });

  const [uploading, setUploading] = useState<string | null>(null);

  const handleFileUpload = async (field: string, file: File) => {
    try {
      setUploading(field);
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random()}.${fileExt}`;
      const filePath = `teachers/${field}/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('documents')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from('documents')
        .getPublicUrl(filePath);

      setFormData({ ...formData, [field]: publicUrl });
    } catch (error: any) {
      alert("Error uploading file: " + error.message);
    } finally {
      setUploading(null);
    }
  };

  const canNext = () => {
    if (currentStep === 1) {
      return formData.fullName && formData.nationalId && formData.dob && formData.gender && formData.phone && formData.address;
    }
    if (currentStep === 2) {
      return formData.jobTitle && formData.subject && formData.stage && formData.appointmentDate && formData.qualification && formData.specialization && formData.graduationYear;
    }
    if (currentStep === 3) {
      // Mandatory documents
      return formData.idCopy && formData.graduationCert && formData.criminalRecord && formData.personalPhoto;
    }
    return true;
  };

  const next = () => {
    if (canNext()) {
      setCurrentStep(s => Math.min(s + 1, 4));
    }
  };
  const prev = () => setCurrentStep(s => Math.max(s - 1, 1));

  return (
    <div className="wizard-container" dir={isAr ? "rtl" : "ltr"}>
      {/* Progress Header */}
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "40px", position: "relative" }}>
        <div style={{ position: "absolute", top: "20px", left: "0", right: "0", height: "2px", background: "var(--glass-border)", zIndex: 0 }} />
        <div style={{ position: "absolute", top: "20px", left: isAr ? "auto" : "0", right: isAr ? "0" : "auto", height: "2px", background: "var(--gradient-primary)", width: `${((currentStep - 1) / 3) * 100}%`, zIndex: 0, transition: "0.3s" }} />
        
        {steps.map(step => (
          <div key={step.id} style={{ zIndex: 1, textAlign: "center", width: "80px" }}>
            <div style={{ 
              width: "40px", height: "40px", borderRadius: "12px", margin: "0 auto 8px",
              background: currentStep >= step.id ? "var(--gradient-primary)" : "var(--glass-bg)",
              border: `2px solid ${currentStep >= step.id ? "transparent" : "var(--glass-border)"}`,
              color: currentStep >= step.id ? "#fff" : "var(--glass-text-muted)",
              display: "flex", alignItems: "center", justifyContent: "center", transition: "0.3s"
            }}>
              <step.icon size={20} />
            </div>
            <span style={{ fontSize: "11px", fontWeight: 700, color: currentStep >= step.id ? "var(--glass-text-primary)" : "var(--glass-text-muted)" }}>
              {isAr ? step.title.ar : step.title.en}
            </span>
          </div>
        ))}
      </div>

      {/* STEP 1: BASIC INFO */}
      {currentStep === 1 && (
        <div style={{ display: "grid", gap: "20px" }}>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
            <div>
              <label style={labelStyle}>{isAr ? "الاسم بالكامل (عربي) *" : "Full Name (Arabic) *"}</label>
              <input type="text" style={inputStyle} value={formData.fullName} onChange={e => setFormData({...formData, fullName: e.target.value})} required />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "الاسم بالكامل (إنجليزي)" : "Full Name (English)"}</label>
              <input type="text" style={inputStyle} value={formData.nameEn} onChange={e => setFormData({...formData, nameEn: e.target.value})} />
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
            <div>
              <label style={labelStyle}>{isAr ? "الرقم القومي *" : "National ID *"}</label>
              <input type="text" style={inputStyle} value={formData.nationalId} onChange={e => setFormData({...formData, nationalId: e.target.value})} />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "تاريخ الميلاد *" : "Date of Birth *"}</label>
              <input type="date" style={inputStyle} value={formData.dob} onChange={e => setFormData({...formData, dob: e.target.value})} />
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
            <div>
              <label style={labelStyle}>{isAr ? "النوع *" : "Gender *"}</label>
              <select style={inputStyle} value={formData.gender} onChange={e => setFormData({...formData, gender: e.target.value})}>
                <option value="MALE">{isAr ? "ذكر" : "Male"}</option>
                <option value="FEMALE">{isAr ? "أنثى" : "Female"}</option>
              </select>
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "رقم الموبايل *" : "Phone Number *"}</label>
              <input type="text" style={inputStyle} value={formData.phone} onChange={e => setFormData({...formData, phone: e.target.value})} />
            </div>
          </div>
          <div>
            <label style={labelStyle}>{isAr ? "البريد الإلكتروني" : "Email Address"}</label>
            <input type="email" style={inputStyle} value={formData.email} onChange={e => setFormData({...formData, email: e.target.value})} />
          </div>
          <div>
            <label style={labelStyle}>{isAr ? "العنوان *" : "Address *"}</label>
            <input type="text" style={inputStyle} value={formData.address} onChange={e => setFormData({...formData, address: e.target.value})} />
          </div>
        </div>
      )}

      {/* STEP 2: JOB & QUALS */}
      {currentStep === 2 && (
        <div style={{ display: "grid", gap: "20px" }}>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
            <div>
              <label style={labelStyle}>{isAr ? "الوظيفة *" : "Job Title *"}</label>
              <select style={inputStyle} value={formData.jobTitle} onChange={e => setFormData({...formData, jobTitle: e.target.value})}>
                <option value="TEACHER">{isAr ? "مدرس" : "Teacher"}</option>
                <option value="SPECIALIST">{isAr ? "أخصائي" : "Specialist"}</option>
                <option value="SUPERVISOR">{isAr ? "مشرف" : "Supervisor"}</option>
              </select>
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "المادة *" : "Subject *"}</label>
              <input type="text" style={inputStyle} value={formData.subject} onChange={e => setFormData({...formData, subject: e.target.value})} placeholder="e.g. Arabic, Math" />
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
            <div>
              <label style={labelStyle}>{isAr ? "المرحلة *" : "Stage *"}</label>
              <select style={inputStyle} value={formData.stage} onChange={e => setFormData({...formData, stage: e.target.value})}>
                <option value="PRIMARY">{isAr ? "ابتدائي" : "Primary"}</option>
                <option value="PREPARATORY">{isAr ? "إعدادي" : "Preparatory"}</option>
                <option value="SECONDARY">{isAr ? "ثانوي" : "Secondary"}</option>
              </select>
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "تاريخ التعيين *" : "Hire Date *"}</label>
              <input type="date" style={inputStyle} value={formData.appointmentDate} onChange={e => setFormData({...formData, appointmentDate: e.target.value})} />
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
            <div>
              <label style={labelStyle}>{isAr ? "المؤهل الدراسي *" : "Qualification *"}</label>
              <input type="text" style={inputStyle} value={formData.qualification} onChange={e => setFormData({...formData, qualification: e.target.value})} />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "التخصص *" : "Specialization *"}</label>
              <input type="text" style={inputStyle} value={formData.specialization} onChange={e => setFormData({...formData, specialization: e.target.value})} />
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "16px" }}>
             <div>
              <label style={labelStyle}>{isAr ? "سنة التخرج *" : "Graduation Year *"}</label>
              <input type="text" style={inputStyle} value={formData.graduationYear} onChange={e => setFormData({...formData, graduationYear: e.target.value})} />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "التقدير" : "Grade"}</label>
              <input type="text" style={inputStyle} value={formData.graduationGrade} onChange={e => setFormData({...formData, graduationGrade: e.target.value})} />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "المرتب" : "Salary"}</label>
              <input type="number" style={inputStyle} value={formData.salary} onChange={e => setFormData({...formData, salary: e.target.value})} />
            </div>
          </div>
        </div>
      )}

      {/* STEP 3: DOCUMENTS */}
      {currentStep === 3 && (
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "24px" }}>
          {[
            { id: "idCopy", label: isAr ? "صورة البطاقة" : "ID Card Copy" },
            { id: "graduationCert", label: isAr ? "شهادة التخرج" : "Graduation Certificate" },
            { id: "militaryService", label: isAr ? "شهادة الخدمة العسكرية" : "Military Service" },
            { id: "criminalRecord", label: isAr ? "فيش وتشبيه" : "Criminal Record" },
            { id: "personalPhoto", label: isAr ? "صورة شخصية" : "Personal Photo" },
            { id: "experienceCerts", label: isAr ? "شهادات خبرة" : "Experience Certs" },
          ].map(doc => (
            <div key={doc.id} style={{ background: "rgba(0,0,0,0.02)", border: "2px dashed var(--glass-border)", borderRadius: "16px", padding: "20px", textAlign: "center" }}>
              <div style={{ color: "var(--glass-text-secondary)", fontWeight: 600, marginBottom: "12px", fontSize: "14px" }}>{doc.label}</div>
              {formData[doc.id] ? (
                <div style={{ color: "#10b981", fontSize: "12px", fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center", gap: "4px" }}>
                  <CheckCircle size={14} /> Uploaded
                </div>
              ) : (
                <label style={{ cursor: "pointer", display: "inline-block" }}>
                  <div style={{ background: "var(--gradient-primary)", color: "#fff", padding: "8px 16px", borderRadius: "8px", fontSize: "12px", display: "flex", alignItems: "center", gap: "8px" }}>
                    {uploading === doc.id ? <div className="spinner-small" /> : <Upload size={14} />}
                    {isAr ? "رفع الملف" : "Upload"}
                  </div>
                  <input type="file" hidden onChange={e => e.target.files?.[0] && handleFileUpload(doc.id, e.target.files[0])} />
                </label>
              )}
            </div>
          ))}
        </div>
      )}

      {/* STEP 4: MAPPING */}
      {currentStep === 4 && (
        <div style={{ textAlign: "center", padding: "20px" }}>
          <div style={{ width: "80px", height: "80px", borderRadius: "24px", background: "rgba(16, 185, 129, 0.1)", color: "#10b981", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 24px" }}>
            <CheckCircle size={40} />
          </div>
          <h3 style={{ fontSize: "20px", fontWeight: 800, color: "var(--glass-text-primary)", marginBottom: "12px" }}>
            {isAr ? "جاهز للحفظ" : "Ready to Save"}
          </h3>
          <p style={{ color: "var(--glass-text-secondary)", maxWidth: "400px", margin: "0 auto 32px" }}>
            {isAr ? "تم إكمال جميع البيانات الأساسية والمستندات. يمكنك الآن حفظ ملف المدرس." : "All basic data and documents have been completed. You can now save the teacher profile."}
          </p>
          <div className="card-glass" style={{ padding: "20px", textAlign: "right", background: "rgba(0,0,0,0.02)" }}>
             <div style={{ fontSize: "14px", fontWeight: 700, marginBottom: "8px" }}>{isAr ? "ملخص:" : "Summary:"}</div>
             <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px", fontSize: "13px" }}>
               <div><strong>{isAr ? "الاسم:" : "Name:"}</strong> {formData.fullName}</div>
               <div><strong>{isAr ? "المادة:" : "Subject:"}</strong> {formData.subject}</div>
               <div><strong>{isAr ? "المرحلة:" : "Stage:"}</strong> {formData.stage}</div>
               <div><strong>{isAr ? "المرتب:" : "Salary:"}</strong> {formData.salary} EGP</div>
             </div>
          </div>
        </div>
      )}

      {/* ACTIONS */}
      <div style={{ display: "flex", justifyContent: "space-between", marginTop: "40px", borderTop: "1px solid var(--glass-border)", paddingTop: "24px" }}>
        <button className="btn outline" onClick={onCancel} style={{ borderRadius: "12px" }}>{isAr ? "إلغاء" : "Cancel"}</button>
        <div style={{ display: "flex", gap: "12px" }}>
          {currentStep > 1 && (
            <button className="btn outline" onClick={prev} style={{ borderRadius: "12px" }}>
              <ChevronLeft size={18} /> {isAr ? "السابق" : "Back"}
            </button>
          )}
          {currentStep < 4 ? (
            <button 
              className="btn primary" 
              onClick={next} 
              disabled={!canNext()}
              style={{ 
                borderRadius: "12px", 
                opacity: canNext() ? 1 : 0.5, 
                cursor: canNext() ? "pointer" : "not-allowed" 
              }}
            >
              {isAr ? "التالي" : "Next"} <ChevronRight size={18} />
            </button>
          ) : (
            <button 
              className="btn primary" 
              onClick={() => onSave(formData)} 
              disabled={isPending} 
              style={{ borderRadius: "12px", minWidth: "140px" }}
            >
              {isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "حفظ المدرس" : "Save Teacher")}
            </button>
          )}
        </div>
      </div>

      <style jsx>{`
        .wizard-container {
          max-width: 800px;
          margin: 0 auto;
        }
        .spinner-small {
          width: 14px;
          height: 14px;
          border: 2px solid rgba(255,255,255,0.3);
          border-top-color: #fff;
          border-radius: 50%;
          animation: spin 0.8s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
      `}</style>
    </div>
  );
}
