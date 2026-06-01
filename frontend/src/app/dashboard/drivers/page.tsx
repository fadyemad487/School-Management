"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { 
  Users, 
  Plus, 
  Search, 
  MoreVertical, 
  Trash2, 
  Edit, 
  Eye, 
  Phone, 
  ShieldCheck, 
  CreditCard,
  MapPin,
  Clock,
  Briefcase,
  FileText,
  Calendar,
  DollarSign,
  User,
  Mail,
  Smartphone,
  Award,
  Heart,
  UserCheck
} from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";
import DriverWizard from "@/components/dashboard/DriverWizard";


const DetailItem = ({ icon, label, value, color }: { icon?: any, label: string, value: any, color?: string }) => (
  <div className="detail-item-box">
     <div className="detail-label">
        {icon}
        <span>{label}</span>
     </div>
     <p className="detail-value" style={color ? { color } : {}}>{value || "---"}</p>
  </div>
);

export default function DriversPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [isWizardOpen, setIsWizardOpen] = useState(false);
  const [isViewOpen, setIsViewOpen] = useState(false);
  const [selectedDriver, setSelectedDriver] = useState<any>(null);
  const [searchQuery, setSearchQuery] = useState("");

  const { data: drivers, isLoading } = useQuery({
    queryKey: ["drivers"],
    queryFn: async () => (await api.get("/transport/drivers")).data.data
  });

  const createMutation = useMutation({
    mutationFn: async (data: any) => api.post("/transport/drivers", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["drivers"] });
      queryClient.invalidateQueries({ queryKey: ["credentials"] });
      setIsWizardOpen(false);
      setSelectedDriver(null);
    }
  });

  const updateMutation = useMutation({
    mutationFn: async (data: any) => api.put(`/transport/drivers/${selectedDriver.id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["drivers"] });
      queryClient.invalidateQueries({ queryKey: ["credentials"] });
      setIsWizardOpen(false);
      setSelectedDriver(null);
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/transport/drivers/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["drivers"] });
      queryClient.invalidateQueries({ queryKey: ["credentials"] });
    }
  });

  const filteredDrivers = drivers?.filter((d: any) => 
    d.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    d.code?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="drivers-module" dir={isAr ? "rtl" : "ltr"}>
      {/* Header Section */}
      <div className="module-header">
        <div>
          <h2 className="title">{isAr ? "إدارة السائقين" : "Driver Management"}</h2>
          <p className="subtitle">{isAr ? "إدارة طاقم السائقين، رخص القيادة، ومواعيد التجديد" : "Manage driving staff, license validity, and renewal schedules."}</p>
        </div>
        <button className="btn-add-driver" onClick={() => { setSelectedDriver(null); setIsWizardOpen(true); }}>
          <Plus size={18} />
          <span>{isAr ? "إضافة سواق جديد" : "Add New Driver"}</span>
        </button>
      </div>

      {/* Stats Bar */}
      <div className="stats-bar">
         <div className="stat-item card-glass">
            <Users size={20} color="#3b82f6" />
            <div>
               <div className="stat-val">{drivers?.length || 0}</div>
               <div className="stat-lbl">{isAr ? "إجمالي السائقين" : "Total Drivers"}</div>
            </div>
         </div>
         <div className="stat-item card-glass">
            <ShieldCheck size={20} color="#10b981" />
            <div>
               <div className="stat-val">{drivers?.filter((d:any) => d.bus).length || 0}</div>
               <div className="stat-lbl">{isAr ? "سائقين نشطين" : "Active on Routes"}</div>
            </div>
         </div>
         <div className="stat-item card-glass">
            <Clock size={20} color="#f59e0b" />
            <div>
               <div className="stat-val">0</div>
               <div className="stat-lbl">{isAr ? "رخص قاربت على الانتهاء" : "Expiring Licenses"}</div>
            </div>
         </div>
      </div>

      {/* List Section */}
      <div className="list-container card-glass">
        <div className="list-header">
          <div className="search-box">
            <Search size={18} />
            <input 
              placeholder={isAr ? "ابحث بالاسم أو الكود..." : "Search by name or code..."} 
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
            />
          </div>
        </div>

        <div className="drivers-grid">
          {isLoading ? (
            <div className="loading-state">
               <div className="spinner-large" />
            </div>
          ) : filteredDrivers?.length === 0 ? (
            <div className="empty-state">
               <Users size={48} opacity={0.2} />
               <p>{isAr ? "لا يوجد سائقين مطابقين للبحث" : "No drivers found."}</p>
            </div>
          ) : filteredDrivers?.map((driver: any) => (
            <div key={driver.id} className="driver-card luxury-stat-card">
               <div className="glow-blob"></div>
               <div className="card-content">
                 <div className="driver-card-header">
                    <div className="driver-avatar">
                       {driver.personalPhoto ? <img src={driver.personalPhoto} alt="" /> : <Users size={24} />}
                       <div className="status-dot" data-active={driver.status === 'ACTIVE'} />
                    </div>
                    <div className="driver-actions">
                       <button className="icon-btn view" onClick={() => { setSelectedDriver(driver); setIsViewOpen(true); }} title={isAr ? "عرض الملف" : "View Profile"}><Eye size={16} /></button>
                       <button className="icon-btn edit" onClick={() => { setSelectedDriver(driver); setIsWizardOpen(true); }} title={isAr ? "تعديل" : "Edit"}><Edit size={16} /></button>
                       <button className="icon-btn delete" onClick={() => confirm(isAr ? "هل أنت متأكد من حذف السائق؟" : "Are you sure?") && deleteMutation.mutate(driver.id)} title={isAr ? "حذف" : "Delete"}><Trash2 size={16} /></button>
                    </div>
                 </div>

                 <div className="driver-card-body">
                    <div className="driver-name">{driver.name}</div>
                    <div className="driver-id">ID: {driver.code || driver.id.slice(0,8)}</div>
                    
                    <div className="info-tags">
                       <div className="tag"><Phone size={12} /> {driver.phone || "---"}</div>
                       <div className="tag"><CreditCard size={12} /> {driver.licenseType}</div>
                       <div className="tag"><Briefcase size={12} /> {driver.bus ? `Bus #${driver.bus.number}` : (isAr ? "بدون باص" : "Idle")}</div>
                    </div>
                 </div>

                 <div className="driver-card-footer">
                    <div className="license-expiry">
                       <Clock size={12} />
                       <span>Exp: {driver.licenseExpiry ? new Date(driver.licenseExpiry).toLocaleDateString() : "---"}</span>
                    </div>
                 </div>
               </div>
            </div>
          ))}
        </div>
      </div>

      {/* Wizard Modal */}
      <Modal
        isOpen={isWizardOpen}
        onClose={() => setIsWizardOpen(false)}
        title={selectedDriver && !isWizardOpen ? (isAr ? "ملف السائق" : "Driver Profile") : selectedDriver ? (isAr ? "تعديل بيانات السائق" : "Edit Driver") : (isAr ? "إضافة سائق جديد" : "Add Driver")}
        width="800px"
      >
        <DriverWizard 
          onSave={(data) => selectedDriver ? updateMutation.mutate(data) : createMutation.mutate(data)}
          onCancel={() => setIsWizardOpen(false)}
          isPending={createMutation.isPending || updateMutation.isPending}
          initialData={selectedDriver}
        />
      </Modal>

      {/* View Details Modal */}
      <Modal
        isOpen={isViewOpen}
        onClose={() => setIsViewOpen(false)}
        title={isAr ? "ملف السائق المحترف" : "Professional Driver Profile"}
        width="850px"
      >
        {selectedDriver && (
          <div className="driver-profile-premium">
             <div className="profile-hero">
                <div className="hero-avatar">
                   {selectedDriver.personalPhoto ? <img src={selectedDriver.personalPhoto} alt="" /> : <Users size={40} />}
                </div>
                <div className="hero-info">
                   <h3>{isAr ? selectedDriver.nameAr || selectedDriver.name : selectedDriver.nameEn || selectedDriver.name}</h3>
                   <div className="hero-badges">
                      <span className="code-badge">ID: {selectedDriver.code}</span>
                      <span className={`status-badge ${selectedDriver.status === "ACTIVE" ? "active" : ""}`}>
                        {selectedDriver.status === "ACTIVE" ? (isAr ? "نشط" : "Active") : (isAr ? "غير نشط" : "Inactive")}
                      </span>
                   </div>
                </div>
             </div>

             <div className="profile-grid-container">
                {/* ── Personal Details ── */}
                <div className="profile-card">
                   <h4 className="card-section-title"><User size={18} /> {isAr ? "البيانات الشخصية" : "Personal Details"}</h4>
                   <div className="details-subgrid">
                      <DetailItem icon={<CreditCard size={14} />} label={isAr ? "الرقم القومي" : "National ID"} value={selectedDriver.nationalId} />
                      <DetailItem icon={<Phone size={14} />} label={isAr ? "الهاتف" : "Phone"} value={selectedDriver.phone} />
                      <DetailItem icon={<Smartphone size={14} />} label={isAr ? "واتساب" : "WhatsApp"} value={selectedDriver.whatsapp} />
                      <DetailItem icon={<Mail size={14} />} label={isAr ? "البريد" : "Email"} value={selectedDriver.email} />
                      <DetailItem icon={<Calendar size={14} />} label={isAr ? "تاريخ الميلاد" : "Date of Birth"} value={selectedDriver.dob ? new Date(selectedDriver.dob).toLocaleDateString() : null} />
                      <DetailItem icon={<Heart size={14} />} label={isAr ? "الحالة الاجتماعية" : "Marital Status"} value={selectedDriver.maritalStatus} />
                      <div className="full-width">
                        <DetailItem icon={<MapPin size={14} />} label={isAr ? "العنوان" : "Address"} value={selectedDriver.address} />
                      </div>
                   </div>
                </div>

                {/* ── License Details ── */}
                <div className="profile-card">
                   <h4 className="card-section-title"><Award size={18} /> {isAr ? "بيانات الرخصة" : "License Details"}</h4>
                   <div className="details-subgrid">
                      <DetailItem label={isAr ? "نوع الرخصة" : "License Type"} value={selectedDriver.licenseType} />
                      <DetailItem label={isAr ? "رقم الرخصة" : "License No."} value={selectedDriver.licenseNumber} />
                      <DetailItem label={isAr ? "تاريخ الانتهاء" : "Expiry Date"} value={selectedDriver.licenseExpiry ? new Date(selectedDriver.licenseExpiry).toLocaleDateString() : null} color="#f59e0b" />
                      <DetailItem label={isAr ? "جهة الإصدار" : "Authority"} value={selectedDriver.licenseAuthority} />
                   </div>
                </div>

                {/* ── Professional Details ── */}
                <div className="profile-card">
                   <h4 className="card-section-title"><Briefcase size={18} /> {isAr ? "البيانات المهنية" : "Professional Details"}</h4>
                   <div className="details-subgrid">
                      <DetailItem icon={<Clock size={14} />} label={isAr ? "تاريخ التعيين" : "Appointment"} value={selectedDriver.appointmentDate ? new Date(selectedDriver.appointmentDate).toLocaleDateString() : null} />
                      <DetailItem icon={<DollarSign size={14} />} label={isAr ? "الراتب" : "Salary"} value={selectedDriver.salary ? `${selectedDriver.salary} EGP` : null} />
                      <DetailItem label={isAr ? "ساعات العمل" : "Work Hours"} value={selectedDriver.workingHours} />
                      <DetailItem icon={<MapPin size={14} />} label={isAr ? "خط السير" : "Route"} value={selectedDriver.assignedRoute} />
                   </div>
                </div>

                {/* ── App Login Credentials ── */}
                <div className="profile-card" style={{ border: "1px solid rgba(59, 130, 246, 0.3)", background: "rgba(59, 130, 246, 0.02)" }}>
                   <h4 className="card-section-title" style={{ color: "#3b82f6" }}><ShieldCheck size={18} /> {isAr ? "بيانات دخول التطبيق" : "App Login Credentials"}</h4>
                   <div className="details-subgrid">
                      <DetailItem 
                        label="Login ID" 
                        value={selectedDriver.credentials?.[0]?.loginId} 
                        color="#3b82f6"
                      />
                      <DetailItem 
                        label="Password" 
                        value={selectedDriver.credentials?.[0]?.plainTextPw} 
                        color="#3b82f6"
                      />
                      <div className="full-width" style={{ marginTop: "10px" }}>
                         <p style={{ fontSize: "11px", color: "var(--glass-text-muted)", fontStyle: "italic" }}>
                           {isAr ? "* استخدم هذه البيانات لتسجيل دخول السائق في تطبيق الهاتف المحمول." : "* Use these credentials for the driver to log in to the mobile application."}
                         </p>
                      </div>
                   </div>
                </div>

                {/* ── Documents ── */}
                <div className="profile-card full-width">
                   <h4 className="card-section-title"><FileText size={18} /> {isAr ? "المستندات المرفقة" : "Attached Documents"}</h4>
                   <div className="profile-docs-grid">
                      {[
                        { id: "idCopyFront", label: isAr ? "بطاقة (أمامي)" : "ID Front", value: selectedDriver.idCopyFront },
                        { id: "idCopyBack", label: isAr ? "بطاقة (خلفي)" : "ID Back", value: selectedDriver.idCopyBack },
                        { id: "licenseCopy", label: isAr ? "صورة الرخصة" : "License", value: selectedDriver.licenseCopy },
                        { id: "criminalRecord", label: isAr ? "الفيش والتشبيه" : "Criminal Record", value: selectedDriver.criminalRecord },
                        { id: "medicalCert", label: isAr ? "الشهادة الطبية" : "Medical Cert", value: selectedDriver.medicalCert },
                        { id: "militaryCert", label: isAr ? "شهادة التجنيد" : "Military Cert", value: selectedDriver.militaryCert },
                      ].map(doc => doc.value ? (
                        <a key={doc.id} href={doc.value} target="_blank" rel="noreferrer" className="premium-doc-card">
                           <div className="doc-icon"><FileText size={20} /></div>
                           <div className="doc-info">
                              <span className="doc-label">{doc.label}</span>
                              <span className="doc-view">{isAr ? "عرض الملف" : "View File"}</span>
                           </div>
                        </a>
                      ) : null)}
                      {![selectedDriver.idCopyFront, selectedDriver.idCopyBack, selectedDriver.licenseCopy, selectedDriver.criminalRecord, selectedDriver.medicalCert, selectedDriver.militaryCert].some(v => v) && (
                        <div className="no-docs-placeholder">
                           <FileText size={32} />
                           <p>{isAr ? "لم يتم رفع أي مستندات رسمية" : "No official documents uploaded"}</p>
                        </div>
                      )}
                   </div>
                </div>
             </div>

             <div className="profile-actions-footer">
                <button className="btn-cancel" onClick={() => setIsViewOpen(false)}>{isAr ? "إغلاق" : "Close"}</button>
                <div className="main-actions">
                   <button className="btn-edit" onClick={() => { setIsViewOpen(false); setIsWizardOpen(true); }}>
                      <Edit size={16} /> {isAr ? "تعديل البيانات" : "Edit Profile"}
                   </button>
                </div>
             </div>
          </div>
        )}
      </Modal>

      <style jsx>{`
        .drivers-module { display: flex; flex-direction: column; gap: 32px; }
        .module-header { display: flex; justify-content: space-between; align-items: center; }
        .title { font-size: 32px; font-weight: 800; color: var(--glass-text-primary); letter-spacing: -0.5px; }
        .subtitle { color: var(--glass-text-secondary); margin-top: 4px; }
        
        .btn-add-driver {
          background: var(--gradient-primary); color: #fff; border: none; padding: 14px 28px; border-radius: 14px; font-weight: 800; display: flex; align-items: center; gap: 10px; cursor: pointer; box-shadow: 0 8px 20px rgba(59, 130, 246, 0.3); transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); font-size: 14px;
        }
        .btn-add-driver:hover { transform: translateY(-3px) scale(1.02); box-shadow: 0 12px 24px rgba(59, 130, 246, 0.4); }

        .stats-bar { display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; }
        .stat-item { padding: 20px; display: flex; gap: 16px; align-items: center; }
        .stat-val { font-size: 24px; font-weight: 800; color: var(--glass-text-primary); }
        .stat-lbl { font-size: 13px; color: var(--glass-text-muted); font-weight: 600; }

        .list-container { padding: 24px; }
        .list-header { display: flex; justify-content: space-between; margin-bottom: 24px; }
        .search-box { position: relative; width: 300px; display: flex; align-items: center; gap: 10px; background: rgba(0,0,0,0.02); border: 1px solid var(--glass-border); padding: 8px 16px; border-radius: 10px; }
        .search-box input { background: transparent; border: none; color: var(--glass-text-primary); outline: none; width: 100%; font-size: 14px; }

        .drivers-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 24px; }
        
        .luxury-stat-card {
          position: relative;
          background: var(--glass-bg);
          backdrop-filter: blur(20px);
          border: 1px solid var(--glass-border);
          border-radius: 24px;
          padding: 20px;
          overflow: hidden;
          transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
          z-index: 1;
        }

        .luxury-stat-card:hover {
          transform: translateY(-8px) scale(1.02);
          border-color: var(--primary-light);
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
        }

        .glow-blob {
          position: absolute;
          width: 130px;
          height: 130px;
          background: var(--gradient-primary);
          filter: blur(55px);
          opacity: 0.12;
          border-radius: 50%;
          top: -40px;
          inset-inline-end: -40px;
          z-index: 0;
          transition: 0.6s;
        }

        .luxury-stat-card:hover .glow-blob {
          opacity: 0.28;
          transform: scale(1.6) translate(-10%, 10%);
        }

        .card-content {
          position: relative;
          z-index: 2;
        }

        .driver-card { min-height: 200px; display: flex; flex-direction: column; }
        :global(.dashboard--light) .luxury-stat-card { background: rgba(255, 255, 255, 0.8); }
        
        .driver-card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 16px; }
        .driver-avatar { width: 50px; height: 50px; border-radius: 14px; background: rgba(255,255,255,0.05); border: 1px solid var(--glass-border); display: flex; align-items: center; justify-content: center; position: relative; color: var(--glass-text-secondary); }
        .driver-avatar img { width: 100%; height: 100%; border-radius: 14px; object-fit: cover; }
        .status-dot { position: absolute; bottom: -2px; right: -2px; width: 12px; height: 12px; border-radius: 50%; border: 2px solid var(--glass-bg); background: #94a3b8; }
        .status-dot[data-active="true"] { background: #10b981; }

        .driver-actions { display: flex; gap: 8px; }
        .icon-btn { width: 32px; height: 32px; border-radius: 8px; border: 1px solid var(--glass-border); background: transparent; color: var(--glass-text-muted); cursor: pointer; display: flex; align-items: center; justify-content: center; transition: 0.2s; }
        .icon-btn:hover { background: rgba(255,255,255,0.05); color: var(--glass-text-primary); }
        .icon-btn.delete:hover { color: #ef4444; border-color: rgba(239, 68, 68, 0.2); }
        .icon-btn.edit:hover { color: #3b82f6; border-color: rgba(59, 130, 246, 0.2); }

        .driver-name { font-size: 18px; font-weight: 800; color: var(--glass-text-primary); margin-bottom: 4px; }
        .driver-id { font-size: 12px; font-weight: 700; color: var(--glass-text-muted); margin-bottom: 16px; }

        .info-tags { display: flex; flex-wrap: wrap; gap: 8px; }
        .tag { display: flex; align-items: center; gap: 6px; padding: 4px 10px; border-radius: 6px; background: rgba(0,0,0,0.02); color: var(--glass-text-secondary); font-size: 11px; font-weight: 700; }

        .driver-card-footer { margin-top: 20px; padding-top: 16px; border-top: 1px solid var(--glass-border); }
        .license-expiry { display: flex; align-items: center; gap: 6px; font-size: 11px; font-weight: 700; color: #f59e0b; }

        /* Profile View Styles */
        .driver-profile-view { display: flex; flex-direction: column; gap: 24px; }
        .profile-header { display: flex; gap: 20px; align-items: center; }
        .profile-avatar { width: 80px; height: 80px; border-radius: 20px; background: rgba(255,255,255,0.05); display: flex; align-items: center; justify-content: center; overflow: hidden; border: 1px solid var(--glass-border); color: var(--glass-text-secondary); }
        .profile-avatar img { width: 100%; height: 100%; object-fit: cover; }
        .profile-header h3 { font-size: 24px; font-weight: 800; color: var(--glass-text-primary); margin: 0; }
        .code-badge { display: inline-block; padding: 4px 10px; border-radius: 6px; background: var(--gradient-primary); color: #fff; font-size: 12px; font-weight: 800; margin-top: 4px; }
        
        .profile-details-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .detail-box label { display: block; font-size: 11px; font-weight: 800; color: var(--glass-text-muted); text-transform: uppercase; margin-bottom: 4px; }
        .detail-box p { font-size: 15px; font-weight: 700; color: var(--glass-text-primary); margin: 0; }
        
        .profile-actions-row { display: flex; justify-content: space-between; margin-top: 32px; padding-top: 24px; border-top: 1px solid var(--glass-border); }
        .btn-secondary-outline { background: transparent; border: 1px solid var(--glass-border); padding: 10px 20px; border-radius: 12px; color: var(--glass-text-muted); cursor: pointer; font-weight: 700; }
        .btn-primary-edit { background: var(--gradient-primary); color: #fff; border: none; padding: 12px 24px; border-radius: 12px; font-weight: 800; cursor: pointer; display: flex; align-items: center; gap: 8px; box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3); }

        .loading-state, .empty-state { grid-column: 1 / -1; padding: 80px 0; text-align: center; }
        .spinner-large { width: 40px; height: 40px; border: 4px solid rgba(255,255,255,0.1); border-top-color: var(--primary-light); border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto; }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* Premium Driver Profile View */
        .driver-profile-premium { display: flex; flex-direction: column; gap: 32px; padding: 10px 0; }
        .profile-hero { display: flex; gap: 24px; align-items: center; padding-bottom: 24px; border-bottom: 1px solid var(--glass-border); }
        .hero-avatar { width: 90px; height: 90px; border-radius: 24px; background: var(--glass-icon-bg); display: flex; align-items: center; justify-content: center; border: 2px solid var(--glass-border); overflow: hidden; color: var(--glass-text-secondary); box-shadow: 0 8px 16px rgba(0,0,0,0.1); }
        .hero-avatar img { width: 100%; height: 100%; object-fit: cover; }
        .hero-info h3 { font-size: 26px; font-weight: 800; color: var(--glass-text-primary); margin: 0 0 8px 0; letter-spacing: -0.5px; }
        .hero-badges { display: flex; gap: 10px; align-items: center; }
        .code-badge { padding: 4px 12px; border-radius: 8px; background: var(--gradient-primary); color: #fff; font-size: 13px; font-weight: 800; box-shadow: 0 4px 10px rgba(59, 130, 246, 0.2); }
        .status-badge { padding: 4px 12px; border-radius: 8px; background: rgba(148, 163, 184, 0.1); color: #94a3b8; font-size: 13px; font-weight: 800; border: 1px solid rgba(148, 163, 184, 0.2); }
        .status-badge.active { background: rgba(16, 185, 129, 0.1); color: #10b981; border-color: rgba(16, 185, 129, 0.2); }

        .profile-grid-container { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
        .profile-card { background: rgba(0,0,0,0.02); border: 1px solid var(--glass-border); border-radius: 20px; padding: 20px; display: flex; flex-direction: column; gap: 20px; }
        .profile-card.full-width { grid-column: 1 / -1; }
        .card-section-title { font-size: 15px; font-weight: 800; color: var(--primary-light); display: flex; align-items: center; gap: 10px; margin: 0; padding-bottom: 12px; border-bottom: 1px solid var(--glass-border); text-transform: uppercase; letter-spacing: 0.5px; }
        
        .details-subgrid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .details-subgrid .full-width { grid-column: 1 / -1; }
        
        .detail-item-box { display: flex; flex-direction: column; gap: 4px; }
        .detail-label { display: flex; align-items: center; gap: 6px; font-size: 11px; font-weight: 700; color: var(--glass-text-muted); text-transform: uppercase; }
        .detail-value { font-size: 15px; font-weight: 700; color: var(--glass-text-primary); margin: 0; }

        .profile-docs-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 16px; }
        .premium-doc-card { display: flex; align-items: center; gap: 16px; padding: 14px; border-radius: 14px; background: var(--glass-bg); border: 1px solid var(--glass-border); text-decoration: none; transition: all 0.3s ease; }
        .premium-doc-card:hover { transform: translateY(-3px); border-color: var(--primary-light); box-shadow: 0 8px 20px rgba(59, 130, 246, 0.1); }
        .doc-icon { width: 40px; height: 40px; border-radius: 10px; background: rgba(59, 130, 246, 0.1); color: var(--primary-light); display: flex; align-items: center; justify-content: center; }
        .doc-info { display: flex; flex-direction: column; }
        .doc-label { font-size: 13px; font-weight: 800; color: var(--glass-text-primary); }
        .doc-view { font-size: 11px; font-weight: 700; color: var(--glass-text-muted); }

        .no-docs-placeholder { grid-column: 1 / -1; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 40px; color: var(--glass-text-muted); opacity: 0.5; }
        .no-docs-placeholder p { font-size: 14px; font-weight: 700; margin-top: 12px; }

        .profile-actions-footer { margin-top: 32px; padding-top: 24px; border-top: 1px solid var(--glass-border); display: flex; justify-content: space-between; align-items: center; }
        .btn-cancel { background: transparent; border: 1px solid var(--glass-border); padding: 12px 24px; border-radius: 14px; color: var(--glass-text-muted); cursor: pointer; font-weight: 700; transition: 0.2s; }
        .btn-cancel:hover { background: rgba(255,255,255,0.05); color: var(--glass-text-primary); }
        .btn-edit { background: var(--gradient-primary); color: #fff; border: none; padding: 12px 28px; border-radius: 14px; font-weight: 800; cursor: pointer; display: flex; align-items: center; gap: 10px; box-shadow: 0 8px 20px rgba(59, 130, 246, 0.3); transition: 0.3s; }
        .btn-edit:hover { transform: translateY(-3px); box-shadow: 0 12px 24px rgba(59, 130, 246, 0.4); }
      `}</style>
    </div>
  );
}
