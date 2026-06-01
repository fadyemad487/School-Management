"use client";

import React, { useState, useRef } from "react";
import { useQuery } from "@tanstack/react-query";
import {
   FileDown,
   Printer,
   Users,
   BookOpen,
   DollarSign,
   Calendar,
   TrendingUp,
   Eye,
   ShieldCheck,
   School,
   ArrowRight,
   UserCheck,
   LayoutGrid,
   Layers,
   FileBadge,
   CreditCard,
   Bell,
   CheckCircle2,
   ChevronRight,
   Activity,
   Zap,
   Globe,
   Award
} from "lucide-react";
import { api, extractApiError } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";
import { useAuth } from "@/components/shared/AuthProvider";

export default function ReportsPage() {
   const { user } = useAuth();
   const { t, isAr } = useTranslation();
   const [activeReport, setActiveReport] = useState<any>(null);
   const printRef = useRef<HTMLDivElement>(null);

   const schoolName = isAr ? (user?.school?.nameAr || user?.school?.name) : user?.school?.name;
   const displaySchoolName = schoolName || "EduControl";

   const { data: stats, isLoading: statsLoading } = useQuery({
      queryKey: ["reports-overview"],
      queryFn: async () => (await api.get("/reports/overview")).data.data,
   });

   const reportCategories = [
      { id: 'students', endpoint: '/students', icon: <Users />, color: '#3b82f6', titleAr: 'سجل الطلاب', titleEn: 'Students Registry' },
      { id: 'teachers', endpoint: '/teachers', icon: <UserCheck />, color: '#8b5cf6', titleAr: 'سجل المعلمين', titleEn: 'Teachers Registry' },
      { id: 'classes', endpoint: '/classes', icon: <LayoutGrid />, color: '#ec4899', titleAr: 'قائمة الفصول', titleEn: 'Classes List' },
      { id: 'grades', endpoint: '/academic/grades', icon: <Layers />, color: '#f59e0b', titleAr: 'المراحل والصفوف', titleEn: 'Grades & Stages' },
      { id: 'subjects', endpoint: '/subjects', icon: <BookOpen />, color: '#06b6d4', titleAr: 'المواد الدراسية', titleEn: 'Subjects List' },
      { id: 'invoices', endpoint: '/invoices', icon: <FileBadge />, color: '#10b981', titleAr: 'سجل الفواتير', titleEn: 'Invoices Report' },
      { id: 'payments', endpoint: '/payments', icon: <CreditCard />, color: '#f43f5e', titleAr: 'سجل المدفوعات', titleEn: 'Payments Logs' },
      { id: 'notifications', endpoint: '/notifications', icon: <Bell />, color: '#64748b', titleAr: 'سجل التنبيهات', titleEn: 'Notifications History' },
   ];

   const getStatIcon = (key: string) => {
      if (key.includes('student')) return <Users size={20} />;
      if (key.includes('teacher')) return <UserCheck size={20} />;
      if (key.includes('class')) return <LayoutGrid size={20} />;
      if (key.includes('payment') || key.includes('invoice')) return <DollarSign size={20} />;
      return <Activity size={20} />;
   };

   const getStatColor = (key: string) => {
      if (key.includes('student')) return '#3b82f6';
      if (key.includes('teacher')) return '#8b5cf6';
      if (key.includes('payment')) return '#10b981';
      return '#6366f1';
   };

   const { data: reportData, isLoading: reportLoading } = useQuery({
      queryKey: ["report-preview", activeReport?.endpoint],
      queryFn: async () => (await api.get(activeReport.endpoint)).data.data,
      enabled: !!activeReport,
   });

    const handlePrint = () => {
      const printContent = printRef.current;
      if (printContent) {
         const printWindow = window.open('', '_blank');
         if (printWindow) {
            printWindow.document.write(`
           <html>
             <head>
               <title>${isAr ? activeReport.titleAr : activeReport.titleEn}</title>
               <style>
                 @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700&family=Cairo:wght@400;700&display=swap');
                 body { font-family: 'Cairo', 'Inter', Tahoma, Arial, sans-serif; padding: 40px; color: #000; direction: ${isAr ? 'rtl' : 'ltr'}; }
                 .header { display: flex; justify-content: space-between; border-bottom: 2px solid #000; padding-bottom: 20px; margin-bottom: 30px; }
                 .header h1 { font-size: 24px; margin: 0; }
                 table { width: 100%; border-collapse: collapse; margin-top: 20px; }
                 th, td { border: 1px solid #ddd; padding: 10px; text-align: ${isAr ? 'right' : 'left'}; font-size: 13px; }
                 th { background: #f2f2f2; font-weight: bold; }
                 .footer { margin-top: 50px; text-align: center; font-size: 10px; color: #666; border-top: 1px solid #eee; padding-top: 10px; }
                 @media print {
                   body { padding: 0; }
                   .no-print { display: none; }
                 }
               </style>
             </head>
             <body>
                <div class="header">
                  <div>
                    <h1>${displaySchoolName}</h1>
                    <p>${isAr ? "تقرير رسمي معتمد" : "Official Certified Report"}</p>
                  </div>
                  <div style="text-align: ${isAr ? 'left' : 'right'}">
                    <p>${new Date().toLocaleDateString(isAr ? 'ar-EG' : 'en-US')}</p>
                    <p>${new Date().toLocaleTimeString(isAr ? 'ar-EG' : 'en-US')}</p>
                  </div>
                </div>
                <h2 style="text-align: center; margin-bottom: 30px; color: #333;">${isAr ? activeReport.titleAr : activeReport.titleEn}</h2>
                ${printContent.innerHTML}
                <div class="footer">
                  <p>Generated by EduControl Academic Management System</p>
                  <p>© ${new Date().getFullYear()} ${displaySchoolName}</p>
                </div>
               <script>
                 window.onload = () => {
                   setTimeout(() => {
                     window.print();
                     window.close();
                   }, 500);
                 };
               </script>
             </body>
           </html>
         `);
            printWindow.document.close();
         }
      }
   };

   return (
      <div className="reports-premium-hub" dir={isAr ? "rtl" : "ltr"}>
         <div className="hub-header">
            <div className="hub-title-box">
               <div className="title-icon"><Zap size={24} /></div>
               <div>
                  <h1 className="main-title">{isAr ? "مركز التحليلات والتقارير" : "Analytics & Reports Hub"}</h1>
                  <p className="main-sub">{isAr ? "نظرة شاملة على أداء المدرسة وتقارير فورية معتمدة." : "A complete overview of school performance and instant certified reports."}</p>
               </div>
            </div>
            <div className="live-status">
               <span className="pulse"></span>
               <span className="status-text">{isAr ? "البيانات مباشرة من النظام" : "Live System Data"}</span>
            </div>
         </div>

         {/* ULTRA PREMIUM STATS */}
         <div className="premium-stats-grid">
            {stats && Object.entries(stats).map(([k, v]) => (
               <div key={k} className="luxury-stat-card" style={{ "--accent-color": getStatColor(k) } as any}>
                  <div className="luxury-stat-inner">
                     <div className="l-stat-top">
                        <div className="l-stat-icon">{getStatIcon(k)}</div>
                        <div className="l-stat-trend"><TrendingUp size={14} /></div>
                     </div>
                     <div className="l-stat-body">
                        <div className="l-stat-val">{String(v)}</div>
                        <div className="l-stat-label">{k.replace('_', ' ').toUpperCase()}</div>
                     </div>
                     <div className="l-stat-bg-blob"></div>
                  </div>
               </div>
            ))}
            {statsLoading && [1, 2, 3, 4, 5, 6].map(i => <div key={i} className="luxury-stat-card skeleton" />)}
         </div>

         <div className="report-explorer">
            <div className="explorer-header">
               <h2 className="explorer-title">{isAr ? "سجلات المدرسة المعتمدة" : "Certified School Registries"}</h2>
               <div className="explorer-line"></div>
            </div>

            <div className="explorer-grid">
               {reportCategories.map((cat) => (
                  <div key={cat.id} className="explorer-card" onClick={() => setActiveReport(cat)}>
                     <div className="exp-icon-box" style={{ background: `${cat.color}15`, color: cat.color }}>
                        {cat.icon}
                     </div>
                     <div className="exp-info">
                        <h3 className="exp-name">{isAr ? cat.titleAr : cat.titleEn}</h3>
                        <div className="exp-meta">
                           <span>{isAr ? "توليد PDF" : "Generate PDF"}</span>
                           <ChevronRight size={14} />
                        </div>
                     </div>
                     <div className="exp-hover-glow" style={{ background: cat.color }}></div>
                  </div>
               ))}
            </div>
         </div>

         <div className="trust-footer card-glass">
            <Award size={32} color="#10b981" />
            <div className="trust-text">
               <h4>{isAr ? "دقة بيانات بنسبة 100%" : "100% Data Accuracy"}</h4>
               <p>{isAr ? "جميع التقارير تعكس الحالة الحقيقية والمباشرة للبيانات المسجلة في قاعدة بيانات المدرسة." : "All reports reflect the real and immediate status of data recorded in the school database."}</p>
            </div>
         </div>

         {/* MODAL */}
         <Modal
            isOpen={!!activeReport}
            onClose={() => setActiveReport(null)}
            title={activeReport ? (isAr ? activeReport.titleAr : activeReport.titleEn) : ""}
         >
            <div className="modal-preview-body">
               <div className="modal-toolbar">
                  <button className="btn-print-luxe" onClick={handlePrint}>
                     <Printer size={18} />
                     <span>{isAr ? "تحميل كـ PDF" : "Download as PDF"}</span>
                  </button>
               </div>

               <div className="modal-scrollable">
                  {reportLoading ? (
                     <div className="loading-container"><div className="loader-ring" /></div>
                  ) : (
                     <div ref={printRef} className="print-content-box">
                        <table className="report-table-luxe">
                           <thead>
                              <tr>
                                 {activeReport?.id === 'students' && (
                                    <><th>{isAr ? "اسم الطالب" : "Full Name"}</th><th>{isAr ? "الصف" : "Grade"}</th><th>{isAr ? "الكود" : "Code"}</th></>
                                 )}
                                 {activeReport?.id === 'teachers' && (
                                    <><th>{isAr ? "الاسم" : "Name"}</th><th>{isAr ? "المادة" : "Subject"}</th><th>{isAr ? "الحالة" : "Status"}</th></>
                                 )}
                                 {activeReport?.id === 'classes' && (
                                    <><th>{isAr ? "اسم الفصل" : "Class Name"}</th><th>{isAr ? "المرحلة" : "Grade"}</th><th>{isAr ? "السعة" : "Capacity"}</th></>
                                 )}
                                 {activeReport?.id === 'grades' && (
                                    <><th>{isAr ? "المرحلة" : "Grade"}</th><th>{isAr ? "الكود" : "Code"}</th></>
                                 )}
                                 {activeReport?.id === 'subjects' && (
                                    <><th>{isAr ? "المادة" : "Subject"}</th><th>{isAr ? "الصف" : "Grade"}</th></>
                                 )}
                                 {activeReport?.id === 'invoices' && (
                                    <><th>{isAr ? "الفاتورة" : "Inv #"}</th><th>{isAr ? "المبلغ" : "Amount"}</th><th>{isAr ? "الحالة" : "Status"}</th></>
                                 )}
                                 {activeReport?.id === 'payments' && (
                                    <><th>{isAr ? "رقم العملية" : "ID"}</th><th>{isAr ? "المبلغ" : "Amount"}</th><th>{isAr ? "التاريخ" : "Date"}</th></>
                                 )}
                                 {activeReport?.id === 'notifications' && (
                                    <><th>{isAr ? "العنوان" : "Title"}</th><th>{isAr ? "الجمهور" : "Target"}</th><th>{isAr ? "التاريخ" : "Date"}</th></>
                                 )}
                              </tr>
                           </thead>
                           <tbody>
                              {reportData?.map((item: any, idx: number) => (
                                 <tr key={idx}>
                                    {activeReport?.id === 'students' && (<><td>{item.user?.fullName}</td><td>{item.grade?.name || item.class?.grade?.name || item.gradeName || item.stage || item.class?.name || "---"}</td><td>{item.studentCode}</td></>)}
                                    {activeReport?.id === 'teachers' && (<><td>{item.user?.fullName}</td><td>{item.subject}</td><td>{item.status}</td></>)}
                                     {activeReport?.id === "classes" && (<><td>{item.name}</td><td>{item.grade?.name || item.gradeName || "General"}</td><td>{item.maxCapacity || item.capacity || "---"}</td></>)}
                                    {activeReport?.id === 'grades' && (<><td>{item.name}</td><td>{item.code}</td></>)}
                                     {activeReport?.id === "subjects" && (<><td>{item.name}</td><td>{item.grade?.name || item.gradeName || "General"}</td></>)}
                                     {activeReport?.id === "invoices" && (<><td>{item.student?.studentCode || item.id.slice(0, 8)}</td><td>{Number(item.totalAmount || item.amount).toLocaleString()} EGP</td><td>{item.status}</td></>)}
                                    {activeReport?.id === 'payments' && (<><td>{item.id.slice(0, 8)}</td><td>{item.amount}</td><td>{new Date(item.createdAt).toLocaleDateString()}</td></>)}
                                     {activeReport?.id === "notifications" && (<><td>{item.title}</td><td>{item.recipientId ? (isAr ? "مباشر" : "Direct") : (isAr ? "للجميع" : "Broadcast")}</td><td>{new Date(item.sentAt || item.createdAt).toLocaleDateString()}</td></>)}
                                 </tr>
                              ))}
                           </tbody>
                        </table>
                     </div>
                  )}
               </div>
            </div>
         </Modal>

         <style jsx>{`
        .reports-premium-hub { display: flex; flex-direction: column; gap: 48px; padding-bottom: 60px; }
        
        .hub-header { display: flex; justify-content: space-between; align-items: center; }
        .hub-title-box { display: flex; align-items: center; gap: 20px; }
        .title-icon { width: 56px; height: 56px; border-radius: 16px; background: var(--gradient-primary); color: #fff; display: flex; align-items: center; justify-content: center; box-shadow: 0 8px 24px rgba(59, 130, 246, 0.4); }
        .main-title { font-size: 34px; font-weight: 950; color: var(--glass-text-primary); letter-spacing: -0.03em; }
        .main-sub { font-size: 16px; color: var(--glass-text-secondary); margin-top: 4px; font-weight: 600; }
        
        .live-status { display: flex; align-items: center; gap: 10px; padding: 10px 20px; border-radius: 30px; background: rgba(16, 185, 129, 0.08); border: 1px solid rgba(16, 185, 129, 0.2); }
        .status-text { font-size: 12px; font-weight: 800; color: #10b981; text-transform: uppercase; letter-spacing: 0.05em; }
        .pulse { width: 8px; height: 8px; background: #10b981; border-radius: 50%; box-shadow: 0 0 0 rgba(16, 185, 129, 0.4); animation: pulse 2s infinite; }
        @keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7); } 70% { box-shadow: 0 0 0 10px rgba(16, 185, 129, 0); } 100% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); } }

        /* LUXURY STAT CARDS */
        .premium-stats-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 20px; }
        .luxury-stat-card { position: relative; border-radius: 24px; background: var(--glass-bg); border: 1px solid var(--glass-border); overflow: hidden; transition: 0.4s cubic-bezier(0.2, 0, 0, 1); cursor: default; }
        .luxury-stat-card:hover { transform: translateY(-8px) scale(1.02); border-color: var(--accent-color); box-shadow: 0 15px 30px rgba(0,0,0,0.1); }
        .luxury-stat-inner { padding: 24px; position: relative; z-index: 2; }
        .l-stat-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
        .l-stat-icon { width: 40px; height: 40px; border-radius: 12px; background: rgba(255,255,255,0.05); border: 1px solid var(--glass-border); display: flex; align-items: center; justify-content: center; color: var(--accent-color); }
        .l-stat-trend { color: #10b981; font-weight: 900; }
        .l-stat-val { font-size: 32px; font-weight: 950; color: var(--glass-text-primary); line-height: 1; letter-spacing: -0.04em; }
        .l-stat-label { font-size: 10px; font-weight: 800; color: var(--glass-text-muted); margin-top: 10px; letter-spacing: 0.1em; }
        .l-stat-bg-blob { position: absolute; bottom: -20px; right: -20px; width: 100px; height: 100px; background: var(--accent-color); filter: blur(50px); opacity: 0.15; transition: 0.4s; }
        .luxury-stat-card:hover .l-stat-bg-blob { opacity: 0.3; transform: scale(1.5); }

        .report-explorer { display: flex; flex-direction: column; gap: 32px; }
        .explorer-header { display: flex; align-items: center; gap: 24px; }
        .explorer-title { font-size: 24px; font-weight: 900; color: var(--glass-text-primary); white-space: nowrap; }
        .explorer-line { height: 1px; flex: 1; background: linear-gradient(90deg, var(--glass-border), transparent); }
        
        .explorer-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
        .explorer-card { 
          display: flex; 
          align-items: center; 
          gap: 20px; 
          padding: 24px; 
          border-radius: 24px; 
          background: var(--glass-bg); 
          border: 1px solid var(--glass-border); 
          cursor: pointer; 
          position: relative; 
          overflow: hidden;
          transition: 0.3s;
        }
        .explorer-card:hover { transform: translateX(8px); border-color: var(--primary-light); }
        .exp-icon-box { width: 56px; height: 56px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
        .exp-info { flex: 1; z-index: 2; }
        .exp-name { font-size: 17px; font-weight: 800; color: #ffffff !important; margin-bottom: 4px; }
        :global(.dashboard--light) .exp-name { color: #020617 !important; }
        .exp-meta { display: flex; align-items: center; gap: 6px; font-size: 12px; color: var(--primary-light); font-weight: 700; }
        .exp-hover-glow { position: absolute; top: 0; left: 0; width: 4px; height: 100%; opacity: 0; transition: 0.3s; }
        .explorer-card:hover .exp-hover-glow { opacity: 1; }

        .modal-preview-body { display: flex; flex-direction: column; gap: 24px; }
        .modal-toolbar { display: flex; justify-content: flex-end; }
        .btn-print-luxe { padding: 14px 32px; border-radius: 16px; background: var(--gradient-primary); color: #fff; font-weight: 800; cursor: pointer; border: none; display: flex; align-items: center; gap: 12px; }
        
        .print-content-box { background: #ffffff !important; padding: 40px; border-radius: 24px; color: #000000 !important; box-shadow: 0 20px 50px rgba(0,0,0,0.2); }
        .report-table-luxe { width: 100%; border-collapse: collapse; background: #ffffff !important; }
        .report-table-luxe th, .report-table-luxe td { padding: 18px; text-align: ${isAr ? 'right' : 'left'}; border-bottom: 1px solid #eeeeee !important; font-size: 14px; color: #000000 !important; }
        .report-table-luxe th { background: #f7f9fc !important; font-weight: 900; color: #000000 !important; }
        .report-table-luxe tr:hover { background: #fcfcfc !important; }

        .trust-footer { padding: 32px; display: flex; align-items: center; gap: 28px; border: 1px dashed var(--glass-border); background: rgba(16, 185, 129, 0.02); }
        .trust-text h4 { font-size: 20px; font-weight: 900; color: var(--glass-text-primary); margin-bottom: 6px; }
        .trust-text p { font-size: 15px; color: var(--glass-text-secondary); font-weight: 500; }

        .skeleton { background: linear-gradient(90deg, var(--glass-bg), rgba(255,255,255,0.05), var(--glass-bg)); background-size: 200% 100%; animation: loading 1.5s infinite; min-height: 180px; }
        @keyframes loading { from { background-position: 200% 0; } to { background-position: -200% 0; } }
      `}</style>
      </div>
   );
}
