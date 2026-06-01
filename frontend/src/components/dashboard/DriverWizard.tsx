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
  MapPin
} from "lucide-react";
import { useTranslation } from "@/lib/i18n";
import { supabase } from "@/lib/supabase";

const steps = [
  { id: 1, title: { ar: "البيانات الشخصية", en: "Personal Info" }, icon: User },
  { id: 2, title: { ar: "بيانات الرخصة", en: "License Details" }, icon: CreditCard },
  { id: 3, title: { ar: "التوظيف والمستندات", en: "Employment & Docs" }, icon: Briefcase },
  { id: 4, title: { ar: "المراجعة والحفظ", en: "Review & Save" }, icon: CheckCircle },
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

export default function DriverWizard({ 
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
        licenseIssueDate: formatDate(initialData.licenseIssueDate),
        licenseExpiry: formatDate(initialData.licenseExpiry),
        appointmentDate: formatDate(initialData.appointmentDate),
        salary: initialData.salary ? Number(initialData.salary) : "",
      };
    }
    return {
      // Basic
      name: "", nationalId: "", dob: "", phone: "", address: "", maritalStatus: "SINGLE",
      // License
      licenseType: "DEGREE_3", licenseNumber: "", licenseIssueDate: "", licenseExpiry: "", licenseAuthority: "",
      // Employment
      contractType: "FULL_TIME", appointmentDate: "", salary: "", workingHours: "8", assignedRoute: "",
      // Docs
      idCopyFront: "", idCopyBack: "", idCopy: "", licenseCopy: "", criminalRecord: "", medicalCert: "", militaryCert: "", photo: ""
    };
  });

  const [uploading, setUploading] = useState<string | null>(null);

  const handleFileUpload = async (field: string, file: File) => {
    try {
      setUploading(field);
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random()}.${fileExt}`;
      const filePath = `drivers/${field}/${fileName}`;

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
      return formData.name && formData.nationalId?.length === 14 && formData.phone;
    }
    if (currentStep === 2) {
      return formData.licenseNumber && formData.licenseType && formData.licenseExpiry;
    }
    if (currentStep === 3) {
      return formData.idCopyFront && formData.idCopyBack && formData.licenseCopy && formData.criminalRecord;
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
      <div className="wizard-progress">
        <div className="progress-line" />
        <div className="progress-fill" style={{ width: `${((currentStep - 1) / 3) * 100}%` }} />
        
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
          <div className="form-row">
            <div className="form-col">
              <label style={labelStyle}>{isAr ? "الاسم بالكامل *" : "Full Name *"}</label>
              <input type="text" style={inputStyle} value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} placeholder="أحمد محمد علي..." />
            </div>
          </div>
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "الرقم القومي *" : "National ID *"}</label>
              <input 
                 type="text" 
                 style={inputStyle} 
                 value={formData.nationalId} 
                 onChange={e => setFormData({...formData, nationalId: e.target.value.replace(/\D/g, '')})} 
                 placeholder="14 Digits" 
                 maxLength={14}
               />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "تاريخ الميلاد" : "Date of Birth"}</label>
              <input type="date" style={inputStyle} value={formData.dob} onChange={e => setFormData({...formData, dob: e.target.value})} />
            </div>
          </div>
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "رقم الموبايل *" : "Mobile Number *"}</label>
              <input type="text" style={inputStyle} value={formData.phone} onChange={e => setFormData({...formData, phone: e.target.value})} />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "الحالة الاجتماعية" : "Marital Status"}</label>
              <select style={inputStyle} value={formData.maritalStatus} onChange={e => setFormData({...formData, maritalStatus: e.target.value})}>
                <option value="SINGLE">{isAr ? "أعزب" : "Single"}</option>
                <option value="MARRIED">{isAr ? "متزوج" : "Married"}</option>
                <option value="DIVORCED">{isAr ? "مطلق" : "Divorced"}</option>
              </select>
            </div>
          </div>
          <div>
            <label style={labelStyle}>{isAr ? "العنوان بالتفصيل" : "Full Address"}</label>
            <input type="text" style={inputStyle} value={formData.address} onChange={e => setFormData({...formData, address: e.target.value})} />
          </div>
        </div>
      )}

      {/* STEP 2: LICENSE INFO */}
      {currentStep === 2 && (
        <div className="step-content">
          <div className="license-alert card-glass">
            <ShieldAlert color="#f59e0b" size={24} />
            <div>
              <h5>{isAr ? "تنبيه صلاحية الرخصة" : "License Expiry Alert"}</h5>
              <p>{isAr ? "تأكد من إدخال تاريخ انتهاء الرخصة بدقة لتلقي تنبيهات التجديد." : "Ensure accurate expiry date to receive renewal notifications."}</p>
            </div>
          </div>

          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "نوع الرخصة *" : "License Type *"}</label>
              <select style={inputStyle} value={formData.licenseType} onChange={e => setFormData({...formData, licenseType: e.target.value})}>
                <option value="DEGREE_1">{isAr ? "درجة أولى" : "1st Degree"}</option>
                <option value="DEGREE_2">{isAr ? "درجة ثانية" : "2nd Degree"}</option>
                <option value="DEGREE_3">{isAr ? "درجة ثالثة" : "3rd Degree"}</option>
                <option value="PRIVATE">{isAr ? "خاصة" : "Private"}</option>
              </select>
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "رقم الرخصة *" : "License Number *"}</label>
              <input type="text" style={inputStyle} value={formData.licenseNumber} onChange={e => setFormData({...formData, licenseNumber: e.target.value})} />
            </div>
          </div>
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "تاريخ الإصدار" : "Issue Date"}</label>
              <input type="date" style={inputStyle} value={formData.licenseIssueDate} onChange={e => setFormData({...formData, licenseIssueDate: e.target.value})} />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "تاريخ الانتهاء *" : "Expiry Date *"}</label>
              <input type="date" style={inputStyle} value={formData.licenseExpiry} onChange={e => setFormData({...formData, licenseExpiry: e.target.value})} />
            </div>
          </div>
          <div>
            <label style={labelStyle}>{isAr ? "جهة الإصدار" : "Issuing Authority"}</label>
            <input type="text" style={inputStyle} value={formData.licenseAuthority} onChange={e => setFormData({...formData, licenseAuthority: e.target.value})} placeholder="مرور القاهرة..." />
          </div>
        </div>
      )}

      {/* STEP 3: EMPLOYMENT & DOCS */}
      {currentStep === 3 && (
        <div className="step-content">
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "نوع التعاقد" : "Contract Type"}</label>
              <select style={inputStyle} value={formData.contractType} onChange={e => setFormData({...formData, contractType: e.target.value})}>
                <option value="FULL_TIME">{isAr ? "دوام كامل" : "Full Time"}</option>
                <option value="PART_TIME">{isAr ? "دوام جزئي" : "Part Time"}</option>
              </select>
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "تاريخ التعيين" : "Hire Date"}</label>
              <input type="date" style={inputStyle} value={formData.appointmentDate} onChange={e => setFormData({...formData, appointmentDate: e.target.value})} />
            </div>
          </div>
          <div className="form-grid">
            <div>
              <label style={labelStyle}>{isAr ? "المرتب الشهري" : "Monthly Salary"}</label>
              <input type="number" style={inputStyle} value={formData.salary} onChange={e => setFormData({...formData, salary: e.target.value})} />
            </div>
            <div>
              <label style={labelStyle}>{isAr ? "ساعات العمل" : "Work Hours"}</label>
              <input type="text" style={inputStyle} value={formData.workingHours} onChange={e => setFormData({...formData, workingHours: e.target.value})} />
            </div>
          </div>

          <div style={{ marginTop: "32px", display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
             {[
               { id: "idCopyFront", label: isAr ? "صورة البطاقة (أمامي) *" : "ID Card (Front) *", required: true },
               { id: "idCopyBack", label: isAr ? "صورة البطاقة (خلفي) *" : "ID Card (Back) *", required: true },
               { id: "licenseCopy", label: isAr ? "صورة الرخصة *" : "License Copy *", required: true },
               { id: "criminalRecord", label: isAr ? "فيش وتشبيه *" : "Criminal Record *", required: true },
               { id: "medicalCert", label: isAr ? "شهادة طبية" : "Medical Cert", required: false },
             ].map(doc => (
               <div key={doc.id} className="doc-upload-box" style={doc.required && !formData[doc.id] ? { borderColor: "rgba(239, 68, 68, 0.3)" } : {}}>
                  <div className="doc-label" style={doc.required ? { color: "var(--glass-text-primary)" } : {}}>
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

      {/* STEP 4: REVIEW */}
      {currentStep === 4 && (
        <div className="step-content review-step">
           <div className="review-header">
              <div className="review-avatar">
                <User size={32} />
              </div>
              <div>
                <h3>{formData.name}</h3>
                <p>{formData.nationalId}</p>
              </div>
           </div>
           
           <div className="review-grid">
              <div className="review-item">
                <CreditCard size={16} />
                <div>
                   <label>{isAr ? "الرخصة" : "License"}</label>
                   <span>{formData.licenseType} - #{formData.licenseNumber}</span>
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
                   <label>{isAr ? "التعاقد" : "Contract"}</label>
                   <span>{formData.contractType} - {formData.salary} EGP</span>
                </div>
              </div>
           </div>

            <div className="final-notice card-glass">
               <p>{isAr ? "سيتم إنشاء حساب دخول تلقائي للسائق باستخدام كود النظام (System ID)." : "A login account will be automatically created using the System ID (Code)."}</p>
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
          {currentStep < 4 ? (
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
              {isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "حفظ ملف السائق" : "Save Driver")}
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

        .form-row { width: 100%; }
        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; }
        
        .license-alert { padding: 20px; display: flex; gap: 16px; border-radius: 16px; border-left: 4px solid #f59e0b; background: rgba(245, 158, 11, 0.05); }
        .license-alert h5 { color: #f59e0b; font-weight: 800; margin-bottom: 4px; font-size: 14px; }
        .license-alert p { font-size: 12px; color: var(--glass-text-muted); line-height: 1.6; }

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
