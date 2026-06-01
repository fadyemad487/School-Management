"use client";

import { useState } from "react";
import { 
  User, 
  Briefcase, 
  FileText, 
  CheckCircle, 
  Upload, 
  ChevronRight, 
  ChevronLeft, 
  ShieldAlert,
  CreditCard,
  MapPin,
  Heart
} from "lucide-react";
import { useTranslation } from "@/lib/i18n";
import { supabase } from "@/lib/supabase";

const steps = [
  { id: 1, title: { ar: "البيانات الشخصية", en: "Personal Info" }, icon: User },
  { id: 2, title: { ar: "التوظيف والمستندات", en: "Employment & Docs" }, icon: Briefcase },
  { id: 3, title: { ar: "المراجعة والحفظ", en: "Review & Save" }, icon: CheckCircle },
];

const inputStyle = { 
  width: "100%", 
  padding: "12px", 
  background: "rgba(0,0,0,0.02)", 
  border: "1px solid var(--glass-border)", 
  borderRadius: "10px", 
  color: "var(--glass-text-primary)", 
  fontSize: "14px" 
};

const labelStyle = { 
  display: "block", 
  fontSize: "13px", 
  fontWeight: 600, 
  color: "var(--glass-text-secondary)", 
  marginBottom: "6px" 
};

export default function SupervisorWizard({ 
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
        dob: formatDate(initialData.dob),
        appointmentDate: formatDate(initialData.appointmentDate),
      };
    }
    return {
      // Basic
      name: "", nameAr: "", nameEn: "", nationalId: "", dob: "", phone: "", whatsapp: "", email: "", address: "", gender: "FEMALE",
      // Employment
      qualification: "", appointmentDate: "",
      // Docs
      idCopyFront: "", idCopyBack: "", personalPhoto: ""
    };
  });

  const [uploading, setUploading] = useState<string | null>(null);

  const handleFileUpload = async (field: string, file: File) => {
    try {
      setUploading(field);
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random()}.${fileExt}`;
      const filePath = `supervisors/${field}/${fileName}`;

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
      return formData.name && formData.phone && (!formData.nationalId || formData.nationalId.length === 14);
    }
    if (currentStep === 2) {
      return true; // Optional docs
    }
    return true;
  };

  const next = () => {
    if (canNext()) {
      setCurrentStep(s => Math.min(s + 1, 3));
    }
  };
  const prev = () => setCurrentStep(s => Math.max(s - 1, 1));

  return (
    <div className="wizard-container" dir={isAr ? "rtl" : "ltr"}>
      {/* Progress Header */}
      <div className="wizard-progress">
        <div className="progress-line" />
        <div className="progress-fill" style={{ width: `${((currentStep - 1) / 2) * 100}%` }} />
        
        {steps.map(step => (
          <div key={step.id} className={`step-node ${currentStep >= step.id ? 'active' : ''}`}>
            <div className="step-icon">
              <step.icon size={20} />
            </div>
            <span className="step-label">
              {isAr ? step.title.ar : step.title.en}
            </span>
          </div>
        ))}
      </div>

      {/* STEP 1: PERSONAL INFO */}
      {currentStep === 1 && (
        <div className="step-content">
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "الاسم الافتراضي / بالإنجليزية *" : "Default / English Name *"}</label>
              <input type="text" style={inputStyle} value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} placeholder="Siham Mahmoud..." />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "الاسم بالكامل (عربي)" : "Arabic Full Name"}</label>
              <input type="text" style={inputStyle} value={formData.nameAr || ""} onChange={e => setFormData({...formData, nameAr: e.target.value})} placeholder="سهام محمود..." />
            </div>
          </div>
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "الرقم القومي (14 رقم)" : "National ID (14 Digits)"}</label>
              <input 
                 type="text" 
                 style={inputStyle} 
                 value={formData.nationalId || ""} 
                 onChange={e => setFormData({...formData, nationalId: e.target.value.replace(/\D/g, '')})} 
                 placeholder="14 Digits" 
                 maxLength={14}
               />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "تاريخ الميلاد" : "Date of Birth"}</label>
              <input type="date" style={inputStyle} value={formData.dob || ""} onChange={e => setFormData({...formData, dob: e.target.value})} />
            </div>
          </div>
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "رقم الموبايل *" : "Mobile Number *"}</label>
              <input type="text" style={inputStyle} value={formData.phone || ""} onChange={e => setFormData({...formData, phone: e.target.value})} placeholder="01xxxxxxxxx" />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "رقم الواتساب" : "WhatsApp Number"}</label>
              <input type="text" style={inputStyle} value={formData.whatsapp || ""} onChange={e => setFormData({...formData, whatsapp: e.target.value})} placeholder="01xxxxxxxxx" />
            </div>
          </div>
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "البريد الإلكتروني (اختياري)" : "Email Address (Optional)"}</label>
              <input type="email" style={inputStyle} value={formData.email || ""} onChange={e => setFormData({...formData, email: e.target.value})} placeholder="supervisor@educontrol.me" />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "النوع" : "Gender"}</label>
              <select style={inputStyle} value={formData.gender || "FEMALE"} onChange={e => setFormData({...formData, gender: e.target.value})}>
                <option value="FEMALE">{isAr ? "أنثى (مشرفة)" : "Female (Supervisor)"}</option>
                <option value="MALE">{isAr ? "ذكر (مشرف)" : "Male (Supervisor)"}</option>
              </select>
            </div>
          </div>
          <div>
            <label style={labelStyle}>{isAr ? "العنوان بالتفصيل" : "Full Address"}</label>
            <input type="text" style={inputStyle} value={formData.address || ""} onChange={e => setFormData({...formData, address: e.target.value})} placeholder="شارع الجمهوريه، الفيوم..." />
          </div>
        </div>
      )}

      {/* STEP 2: EMPLOYMENT & DOCS */}
      {currentStep === 2 && (
        <div className="step-content">
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "المؤهل الدراسي" : "Qualification"}</label>
              <input type="text" style={inputStyle} value={formData.qualification || ""} onChange={e => setFormData({...formData, qualification: e.target.value})} placeholder="بكالوريوس تربية..." />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "تاريخ التعيين" : "Hire Date"}</label>
              <input type="date" style={inputStyle} value={formData.appointmentDate || ""} onChange={e => setFormData({...formData, appointmentDate: e.target.value})} />
            </div>
          </div>

          <div style={{ marginTop: "32px", display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
             {[
               { id: "personalPhoto", label: isAr ? "الصورة الشخصية" : "Personal Photo", required: false },
               { id: "idCopyFront", label: isAr ? "صورة البطاقة (أمامي)" : "ID Card (Front)", required: false },
               { id: "idCopyBack", label: isAr ? "صورة البطاقة (خلفي)" : "ID Card (Back)", required: false },
             ].map(doc => (
               <div key={doc.id} className="doc-upload-box">
                  <div className="doc-label">
                    {doc.label}
                  </div>
                  {formData[doc.id] ? (
                    <div className="doc-status success"><CheckCircle size={14} /> Ready</div>
                  ) : (
                    <label className="upload-label">
                      {uploading === doc.id ? <div className="spinner-small" /> : <Upload size={14} />}
                      <span>{isAr ? "رفع" : "Upload"}</span>
                      <input type="file" hidden onChange={e => e.target.files?.[0] && handleFileUpload(doc.id, e.target.files[0])} />
                    </label>
                  )}
               </div>
             ))}
          </div>
        </div>
      )}

      {/* STEP 3: REVIEW */}
      {currentStep === 3 && (
        <div className="step-content review-step">
           <div className="review-header">
              <div className="review-avatar">
                <User size={32} />
              </div>
              <div>
                <h3>{formData.nameAr || formData.name}</h3>
                <p>{formData.phone}</p>
              </div>
           </div>
           
           <div className="review-grid">
              <div className="review-item">
                <Heart size={16} />
                <div>
                   <label>{isAr ? "النوع" : "Gender"}</label>
                   <span>{formData.gender === "FEMALE" ? (isAr ? "أنثى" : "Female") : (isAr ? "ذكر" : "Male")}</span>
                </div>
              </div>
              <div className="review-item">
                <MapPin size={16} />
                <div>
                   <label>{isAr ? "العنوان" : "Address"}</label>
                   <span>{formData.address || "---"}</span>
                </div>
              </div>
              <div className="review-item">
                <Briefcase size={16} />
                <div>
                   <label>{isAr ? "المؤهل الدراسي" : "Qualification"}</label>
                   <span>{formData.qualification || "---"}</span>
                </div>
              </div>
           </div>

            <div className="final-notice card-glass">
               <p>{isAr ? "سيتم إنشاء حساب دخول تلقائي للمشرفة على تطبيق الهاتف برقم كود النظام." : "An app login account will be automatically created using system generated code."}</p>
            </div>
        </div>
      )}

      {/* ACTIONS */}
      <div className="wizard-actions">
        <button className="btn-cancel" onClick={onCancel}>{isAr ? "إلغاء" : "Cancel"}</button>
        <div style={{ display: "flex", gap: "12px" }}>
          {currentStep > 1 && (
            <button className="btn-prev" onClick={prev}>
              <ChevronLeft size={18} /> {isAr ? "السابق" : "Back"}
            </button>
          )}
          {currentStep < 3 ? (
            <button 
              className="btn-next" 
              onClick={next} 
              disabled={!canNext()}
            >
              {isAr ? "التالي" : "Next"} <ChevronRight size={18} />
            </button>
          ) : (
            <button 
              className="btn-submit" 
              onClick={() => onSave(formData)} 
              disabled={isPending}
            >
              {isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "حفظ ملف المشرفة" : "Save Supervisor")}
            </button>
          )}
        </div>
      </div>

      <style jsx>{`
        .wizard-container { width: 100%; margin: 0 auto; }
        .wizard-progress { display: flex; justify-content: space-between; margin-bottom: 48px; position: relative; padding: 0 40px; }
        .progress-line { position: absolute; top: 22px; left: 0; right: 0; height: 2px; background: var(--glass-border); z-index: 0; }
        .progress-fill { 
          position: absolute; 
          top: 22px; 
          height: 2px; 
          background: var(--gradient-primary); 
          z-index: 0; 
          transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
          ${isAr ? 'right: 0;' : 'left: 0;'}
        }
        .step-node { z-index: 1; text-align: center; width: 120px; position: relative; }
        .step-icon { width: 44px; height: 44px; border-radius: 14px; margin: 0 auto 12px; background: var(--glass-bg); border: 2px solid var(--glass-border); color: var(--glass-text-muted); display: flex; align-items: center; justify-content: center; transition: all 0.3s ease; position: relative; z-index: 2; }
        .step-node.active .step-icon { background: var(--gradient-primary); border-color: transparent; color: #fff; box-shadow: 0 8px 20px rgba(59, 130, 246, 0.4); transform: scale(1.1); }
        .step-label { font-size: 11px; font-weight: 800; color: var(--glass-text-muted); text-transform: uppercase; letter-spacing: 0.5px; }
        .step-node.active .step-label { color: var(--glass-text-primary); }

        .step-content { display: flex; flex-direction: column; gap: 24px; animation: fadeIn 0.4s cubic-bezier(0.4, 0, 0.2, 1); }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; }
        
        .doc-upload-box { background: rgba(0,0,0,0.03); border: 2px dashed var(--glass-border); border-radius: 16px; padding: 20px; display: flex; justify-content: space-between; align-items: center; transition: 0.3s; }
        .doc-upload-box:hover { border-color: var(--primary-light); background: rgba(0,0,0,0.05); }
        .doc-label { font-size: 14px; font-weight: 700; color: var(--glass-text-secondary); }
        .upload-label { cursor: pointer; display: flex; align-items: center; gap: 8px; background: var(--gradient-primary); color: #fff; padding: 8px 16px; border-radius: 10px; font-size: 13px; font-weight: 700; transition: 0.3s; }
        .upload-label:hover { transform: scale(1.05); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3); }
        .doc-status.success { color: #10b981; font-size: 13px; font-weight: 800; display: flex; align-items: center; gap: 6px; }

        .review-header { display: flex; gap: 24px; align-items: center; margin-bottom: 32px; padding: 24px; border-radius: 20px; background: rgba(0,0,0,0.02); }
        .review-avatar { width: 72px; height: 72px; border-radius: 22px; background: var(--gradient-primary); color: #fff; display: flex; align-items: center; justify-content: center; box-shadow: 0 8px 20px rgba(59, 130, 246, 0.3); }
        .review-header h3 { font-size: 22px; font-weight: 800; color: var(--glass-text-primary); letter-spacing: -0.5px; }
        .review-header p { font-size: 15px; color: var(--glass-text-muted); }

        .review-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 24px; padding: 0 24px; }
        .review-item { display: flex; gap: 16px; align-items: flex-start; }
        .review-item label { display: block; font-size: 11px; font-weight: 800; color: var(--glass-text-muted); text-transform: uppercase; margin-bottom: 4px; letter-spacing: 0.5px; }
        .review-item span { font-size: 15px; font-weight: 700; color: var(--glass-text-primary); }

        .final-notice { margin-top: 40px; padding: 20px; text-align: center; font-size: 14px; color: var(--glass-text-secondary); background: rgba(59, 130, 246, 0.05); border-radius: 16px; border: 1px solid rgba(59, 130, 246, 0.1); }

        .wizard-actions { display: flex; justify-content: space-between; margin-top: 48px; padding-top: 32px; border-top: 1px solid var(--glass-border); }
        .btn-cancel { background: transparent; border: 1px solid var(--glass-border); padding: 12px 24px; border-radius: 14px; color: var(--glass-text-muted); cursor: pointer; font-weight: 700; transition: 0.3s; }
        .btn-cancel:hover { background: rgba(0,0,0,0.05); color: var(--glass-text-primary); }
        .btn-next, .btn-submit { background: var(--gradient-primary); border: none; padding: 14px 28px; border-radius: 14px; color: #fff; font-weight: 800; cursor: pointer; display: flex; align-items: center; gap: 10px; transition: 0.3s; box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3); }
        .btn-next:hover, .btn-submit:hover { transform: translateY(-2px); box-shadow: 0 6px 16px rgba(59, 130, 246, 0.4); }
        .btn-prev { background: transparent; border: 1px solid var(--glass-border); padding: 12px 24px; border-radius: 14px; color: var(--glass-text-primary); cursor: pointer; display: flex; align-items: center; gap: 10px; font-weight: 700; transition: 0.3s; }
        .btn-prev:hover { background: rgba(0,0,0,0.05); }
        .btn-next:disabled { opacity: 0.5; cursor: not-allowed; transform: none !important; box-shadow: none !important; }

        .spinner-small { width: 16px; height: 16px; border: 2px solid rgba(255,255,255,0.3); border-top-color: #fff; border-radius: 50%; animation: spin 0.8s linear infinite; }
        @keyframes spin { to { transform: rotate(360deg); } }
      `}</style>
    </div>
  );
}
