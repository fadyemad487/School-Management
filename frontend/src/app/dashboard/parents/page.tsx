"use client";

import React, { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { api, extractApiError } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";
import { 
  Users, 
  Search, 
  ChevronRight, 
  Heart,
  Baby,
  Briefcase,
  Smartphone,
  Mail,
  ShieldCheck,
  Hash,
  MapPin,
  User,
  Info,
  ExternalLink,
  Contact,
  Fingerprint
} from "lucide-react";

export default function ParentsPage() {
  const router = useRouter();
  const { t, isAr } = useTranslation();
  const [q, setQ] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [selectedFamily, setSelectedFamily] = useState<any>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["parents", q],
    queryFn: async () => {
      try {
        const res = await api.get("/parents", { params: q ? { q } : undefined });
        setError(null);
        return res.data.data;
      } catch (e) {
        setError(extractApiError(e).message);
        return [];
      }
    },
  });

  const parents = useMemo(() => (Array.isArray(data) ? data : []), [data]);

  const families = useMemo(() => {
    const familyMap = new Map<string, { father?: any, mother?: any, students: any[] }>();
    parents.forEach((p: any) => {
      const myStudents = [...(p.fatherOf || []), ...(p.motherOf || []), ...(p.guardianOf || [])];
      if (myStudents.length === 0) {
        familyMap.set(`p-${p.id}`, { [p.relationship === "أب" ? "father" : "mother"]: p, students: [] });
        return;
      }
      const familyKey = myStudents[0].id;
      if (!familyMap.has(familyKey)) {
        familyMap.set(familyKey, { students: myStudents, father: undefined, mother: undefined });
      }
      const family = familyMap.get(familyKey)!;
      if (p.relationship === "أب") family.father = p;
      else if (p.relationship === "أم") family.mother = p;
      else if (!family.father && !family.mother) family.father = p;
    });
    return Array.from(familyMap.values());
  }, [parents]);

  return (
    <div className="parents-directory-compact" dir={isAr ? "rtl" : "ltr"}>
      {/* COMPACT HEADER */}
      <div className="directory-header-compact">
        <div className="badge-luxe-mini">
           <ShieldCheck size={12} />
           <span>{isAr ? "دليل العائلات المعتمد" : "Verified Directory"}</span>
        </div>
        <h1 className="title-compact">
          {isAr ? "أولياء الأمور" : "Parents Directory"}
          <span className="count-mini">{families.length}</span>
        </h1>
        <p className="subtitle-compact">
          {isAr ? "إدارة عائلات الطلاب والربط الأبوي" : "Family management & parent-student associations"}
        </p>

        {/* COMPACT SEARCH */}
        <div className="search-wrap-mini">
           <div className="search-bar-mini">
              <Search className="icon-search" size={16} />
              <input 
                type="text" 
                placeholder={isAr ? "ابحث بالاسم أو الكود..." : "Search name or ID..."}
                className="input-mini"
                value={q}
                onChange={(e) => setQ(e.target.value)}
              />
           </div>
        </div>
      </div>

      {error && <div className="error-box card-glass">{error}</div>}

      {/* COMPACT GRID */}
      {isLoading ? (
        <div className="loading-compact">
          <div className="spinner-mini" />
        </div>
      ) : (
        <div className="families-grid-compact">
          {families.map((family: any, idx) => (
            <div key={idx} className="family-card-mini luxury-stat-card">
              <div className="glow-blob"></div>
              <div className="card-content">
                <div className="card-top-mini">
                   <div className="avatar-stack-mini">
                      <Users size={16} />
                   </div>
                   <div className="header-info-mini">
                      <h3 className="family-name-mini">{isAr ? "عائلة" : "Family of"} {family.students?.[0]?.nameEn || family.students?.[0]?.user?.fullName}</h3>
                      <div className="kids-badges-mini">
                         {family.students?.map((s: any) => (
                            <span key={s.id} className="k-badge">#{s.studentCode}</span>
                         ))}
                      </div>
                   </div>
                </div>

                <div className="card-body-mini">
                   <div className="parent-sec father">
                      <div className="p-type blue">{isAr ? "الأب" : "Father"}</div>
                      <div className="p-name">{family.father?.nameAr || family.father?.user?.fullName || "—"}</div>
                      <div className="p-meta">
                         {family.father?.phone && <span><Smartphone size={10} /> {family.father.phone}</span>}
                         {family.father?.user?.email && <span className="email-truncate"><Mail size={10} /> {family.father.user.email}</span>}
                      </div>
                   </div>

                   <div className="p-divider"></div>

                   <div className="parent-sec mother">
                      <div className="p-type pink">{isAr ? "الأم" : "Mother"}</div>
                      <div className="p-name">{family.mother?.nameAr || family.mother?.user?.fullName || "—"}</div>
                      <div className="p-meta">
                         {family.mother?.phone && <span><Smartphone size={10} /> {family.mother.phone}</span>}
                         {family.mother?.user?.email && <span className="email-truncate"><Mail size={10} /> {family.mother.user.email}</span>}
                      </div>
                   </div>
                </div>

                <div className="card-footer-mini">
                   <button className="btn-mini" onClick={() => setSelectedFamily(family)}>
                      {isAr ? "التفاصيل" : "Details"} <ChevronRight size={12} style={{ transform: isAr ? "rotate(180deg)" : "none" }} />
                   </button>
                </div>
              </div>
            </div>
          ))}

          {families.length === 0 && (
            <div className="empty-mini">
               <p>{isAr ? "لا توجد نتائج" : "No results found"}</p>
            </div>
          )}
        </div>
      )}

      {/* FAMILY DETAILS MODAL - REDESIGNED */}
      <Modal 
        isOpen={!!selectedFamily} 
        onClose={() => setSelectedFamily(null)} 
        title={isAr ? "ملف العائلة الأكاديمي" : "Family Academic Profile"}
        width="1000px"
      >
        {selectedFamily && (
          <div className="family-profile-premium">
            {/* PROFILE BANNER */}
            <div className="profile-banner">
               <div className="banner-glow"></div>
               <div className="banner-content">
                  <div className="family-main-icon"><Users size={32} /></div>
                  <div className="family-hero-text">
                     <h1>Family of {selectedFamily.students?.[0]?.user?.fullName}</h1>
                     <div className="family-meta-tags">
                        <span className="meta-tag"><ShieldCheck size={14} /> {isAr ? "عائلة معتمدة" : "Verified Family"}</span>
                        <span className="meta-tag"><Fingerprint size={14} /> ID: {selectedFamily.students?.[0]?.studentCode}</span>
                     </div>
                  </div>
               </div>
            </div>

            <div className="profile-content-grid">
               {/* MAIN INFO SECTION */}
               <div className="info-main-area" style={{ gridColumn: "1 / -1" }}>
                  <div className="section-title-luxe">
                     <Contact size={18} /> <span>{isAr ? "بيانات أولياء الأمور" : "Parent Information"}</span>
                  </div>
                  
                  <div className="parents-horizontal-cards">
                     {/* FATHER CARD */}
                     <div className="parent-luxe-card father-theme">
                        <div className="p-card-header-mini">
                           <div className="p-badge blue">{isAr ? "الأب" : "Father"}</div>
                        </div>
                        <h3 className="p-full-name">{selectedFamily.father?.nameAr || "—"}</h3>
                        <div className="p-detail-list">
                           <div className="d-row"><Smartphone size={14} /> <span>{selectedFamily.father?.phone || "—"}</span></div>
                           <div className="d-row"><Mail size={14} /> <span>{selectedFamily.father?.user?.email || "—"}</span></div>
                           <div className="d-row"><Briefcase size={14} /> <span>{selectedFamily.father?.occupation || "—"}</span></div>
                           <div className="d-row"><Hash size={14} /> <span>{selectedFamily.father?.nationalId || "—"}</span></div>
                        </div>
                        {/* LOGIN CREDENTIALS SECTION */}
                        <div className="p-login-info">
                           <div className="login-head"><Fingerprint size={12} /> {isAr ? "بيانات الدخول (التطبيق)" : "App Login Credentials"}</div>
                           <div className="login-row"><strong>Login ID:</strong> {selectedFamily.father?.credentials?.[0]?.loginId || "—"}</div>
                           <div className="login-row"><strong>Password:</strong> <span className="pass-text">{selectedFamily.father?.credentials?.[0]?.plainTextPw || "••••••••"}</span></div>
                        </div>
                     </div>

                     {/* MOTHER CARD */}
                     <div className="parent-luxe-card mother-theme">
                        <div className="p-card-header-mini">
                           <div className="p-badge pink">{isAr ? "الأم" : "Mother"}</div>
                        </div>
                        <h3 className="p-full-name">{selectedFamily.mother?.nameAr || "—"}</h3>
                        <div className="p-detail-list">
                           <div className="d-row"><Smartphone size={14} /> <span>{selectedFamily.mother?.phone || "—"}</span></div>
                           <div className="d-row"><Mail size={14} /> <span>{selectedFamily.mother?.user?.email || "—"}</span></div>
                           <div className="d-row"><Briefcase size={14} /> <span>{selectedFamily.mother?.occupation || "—"}</span></div>
                           <div className="d-row"><Hash size={14} /> <span>{selectedFamily.mother?.nationalId || "—"}</span></div>
                        </div>
                        {/* LOGIN CREDENTIALS SECTION */}
                        <div className="p-login-info">
                           <div className="login-head"><Fingerprint size={12} /> {isAr ? "بيانات الدخول (التطبيق)" : "App Login Credentials"}</div>
                           <div className="login-row"><strong>Login ID:</strong> {selectedFamily.mother?.credentials?.[0]?.loginId || "—"}</div>
                           <div className="login-row"><strong>Password:</strong> <span className="pass-text">{selectedFamily.mother?.credentials?.[0]?.plainTextPw || "••••••••"}</span></div>
                        </div>
                     </div>
                  </div>

                  {selectedFamily.father?.address && (
                    <div className="address-bar-luxe" style={{ marginBottom: "30px" }}>
                       <MapPin size={16} />
                       <span>{isAr ? "العنوان بالتفصيل:" : "Home Address:"} {selectedFamily.father.address}</span>
                    </div>
                  )}

                  {/* CHILDREN SECTION MOVED HERE */}
                  <div className="section-title-luxe">
                     <Baby size={18} /> <span>{isAr ? "الأبناء المسجلون" : "Registered Children"}</span>
                  </div>
                  
                  <div className="children-grid-wide">
                     {selectedFamily.students?.map((s: any) => (
                       <div key={s.id} className="child-wide-entry">
                          {s.photo ? (
                             <img src={s.photo} alt={s.user?.fullName} className="c-img-mini" />
                          ) : (
                             <div className="c-avatar-mini">{s.user?.fullName?.[0]}</div>
                          )}
                          <div className="c-info-mini">
                             <div className="c-name-mini">{s.user?.fullName}</div>
                             <div className="c-meta-mini">
                                <span>{s.grade?.name || (isAr ? "الصف الدراسي" : "Grade")}</span>
                                <span className="c-code-tag">ID: {s.studentCode}</span>
                             </div>
                          </div>
                          <button 
                            className="btn-academic-mini" 
                            onClick={() => router.push(`/dashboard/students/${s.id}`)}
                          >
                             {isAr ? "السجل الأكاديمي" : "Academic Record"}
                             <ExternalLink size={12} />
                          </button>
                       </div>
                     ))}
                  </div>
               </div>
            </div>
          </div>
        )}
      </Modal>

      <style jsx>{`
        .parents-directory-compact { padding-bottom: 60px; }
        .directory-header-compact { margin-bottom: 40px; display: flex; flex-direction: column; align-items: center; text-align: center; }
        .badge-luxe-mini { display: inline-flex; align-items: center; gap: 6px; background: rgba(16, 185, 129, 0.08); color: #10b981; padding: 4px 12px; border-radius: 100px; font-size: 10px; font-weight: 800; text-transform: uppercase; margin-bottom: 12px; border: 1px solid rgba(16, 185, 129, 0.15); }
        .title-compact { font-size: 28px; font-weight: 900; color: var(--glass-text-primary); margin-bottom: 8px; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px; }
        .count-mini { background: var(--primary); color: #fff; font-size: 12px; padding: 2px 10px; border-radius: 8px; font-weight: 800; }
        .subtitle-compact { color: var(--glass-text-secondary); font-size: 13px; max-width: 400px; }
        .search-wrap-mini { margin-top: 24px; width: 100%; max-width: 450px; }
        .search-bar-mini { display: flex; align-items: center; gap: 12px; background: var(--glass-input-bg); backdrop-filter: blur(10px); border: 1px solid var(--glass-border); border-radius: 16px; padding: 12px 18px; transition: 0.3s; }
        :global(.dashboard--light) .search-bar-mini { background: #fff; box-shadow: 0 4px 15px rgba(0,0,0,0.03); }
        .search-bar-mini:focus-within { border-color: var(--primary); box-shadow: 0 8px 25px rgba(0,0,0,0.1); transform: translateY(-2px); }
        .icon-search { color: var(--primary); }
        .input-mini { flex: 1; background: transparent; border: none; color: var(--glass-text-primary); font-size: 14px; font-weight: 500; outline: none; }
        .families-grid-compact { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 20px; }
        
        .luxury-stat-card {
          position: relative;
          background: var(--glass-bg);
          backdrop-filter: blur(20px);
          border: 1px solid var(--glass-border);
          border-radius: 24px;
          padding: 18px;
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
          width: 120px;
          height: 120px;
          background: var(--gradient-primary);
          filter: blur(50px);
          opacity: 0.15;
          border-radius: 50%;
          top: -40px;
          inset-inline-end: -40px;
          z-index: 0;
          transition: 0.6s;
        }

        .luxury-stat-card:hover .glow-blob {
          opacity: 0.3;
          transform: scale(1.5) translate(-10%, 10%);
        }

        .card-content {
          position: relative;
          z-index: 2;
        }

        .family-card-mini { min-height: 200px; display: flex; flex-direction: column; }
        :global(.dashboard--light) .luxury-stat-card { background: rgba(255, 255, 255, 0.8); }
        .card-top-mini { display: flex; gap: 12px; align-items: flex-start; margin-bottom: 16px; }
        .avatar-stack-mini { width: 32px; height: 32px; border-radius: 10px; background: var(--primary); color: #fff; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        :global(.dashboard--light) .avatar-stack-mini { background: rgba(37, 99, 235, 0.1); color: #2563eb; }
        .family-name-mini { font-size: 15px; font-weight: 800; color: var(--glass-text-primary); margin-bottom: 4px; }
        .kids-badges-mini { display: flex; gap: 6px; flex-wrap: wrap; }
        .k-badge { font-size: 10px; font-weight: 700; color: var(--primary); background: rgba(59, 130, 246, 0.05); padding: 1px 6px; border-radius: 4px; }
        .card-body-mini { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; background: rgba(0, 0, 0, 0.02); border: 1px solid var(--glass-border); border-radius: 14px; padding: 12px; margin-bottom: 14px; }
        :global(.dashboard--light) .card-body-mini { background: #f8fafc; }
        .p-divider { width: 1px; background: var(--glass-border); }
        .parent-sec { display: flex; flex-direction: column; min-width: 0; }
        .p-type { font-size: 9px; font-weight: 900; text-transform: uppercase; margin-bottom: 4px; }
        .p-type.blue { color: #3b82f6; }
        .p-type.pink { color: #f472b6; }
        .p-name { font-size: 13px; font-weight: 700; color: var(--glass-text-primary); margin-bottom: 6px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .p-meta { display: flex; flex-direction: column; gap: 3px; font-size: 10px; color: var(--glass-text-muted); }
        .p-meta span { display: flex; align-items: center; gap: 4px; }
        .email-truncate { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .card-footer-mini { display: flex; justify-content: flex-end; }
        .btn-mini { background: transparent; border: none; color: var(--primary); font-size: 12px; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 4px; }
        .loading-compact { padding: 60px; text-align: center; }
        .spinner-mini { width: 24px; height: 24px; border: 2px solid rgba(59, 130, 246, 0.1); border-top-color: var(--primary); border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto; }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* PROFILE MODAL REDESIGN */
        .family-profile-premium { padding: 0; margin-top: -10px; }
        .profile-banner { 
          background: var(--gradient-primary); 
          padding: 30px; 
          border-radius: 20px; 
          position: relative; 
          overflow: hidden; 
          margin-bottom: 30px; 
          color: #fff;
        }
        .banner-glow { 
          position: absolute; 
          top: -50%; right: -20%; 
          width: 300px; height: 300px; 
          background: rgba(255,255,255,0.1); 
          filter: blur(80px); 
          border-radius: 50%; 
        }
        .banner-content { display: flex; align-items: center; gap: 20px; position: relative; z-index: 2; }
        .family-main-icon { 
          width: 60px; height: 60px; 
          background: rgba(255,255,255,0.15); 
          backdrop-filter: blur(10px); 
          border-radius: 16px; 
          display: flex; align-items: center; justify-content: center; 
          border: 1px solid rgba(255,255,255,0.2);
        }
        .family-hero-text h1 { font-size: 26px; font-weight: 900; margin-bottom: 6px; }
        .family-meta-tags { display: flex; gap: 12px; }
        .meta-tag { 
          font-size: 11px; font-weight: 700; 
          background: rgba(0,0,0,0.15); 
          padding: 4px 12px; 
          border-radius: 8px; 
          display: flex; align-items: center; gap: 6px; 
        }

        .profile-content-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 30px; }
        .section-title-luxe { 
          font-size: 12px; font-weight: 900; 
          text-transform: uppercase; letter-spacing: 1px; 
          color: var(--glass-text-muted); 
          margin-bottom: 20px; 
          display: flex; align-items: center; justify-content: center; gap: 10px; 
        }
        .parents-horizontal-cards { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
        .parent-luxe-card { 
          background: var(--glass-bg); 
          border: 1px solid var(--glass-border); 
          border-radius: 20px; 
          padding: 20px; 
          position: relative;
        }
        :global(.dashboard--light) .parent-luxe-card { background: #f8fafc; }
        .p-card-header-mini { display: flex; justify-content: center; margin-bottom: 10px; }
        .p-badge { 
          font-size: 10px; font-weight: 900; 
          padding: 3px 12px; border-radius: 6px; 
          text-transform: uppercase;
        }
        .p-badge.blue { background: rgba(59, 130, 246, 0.1); color: #3b82f6; border: 1px solid rgba(59, 130, 246, 0.2); }
        .p-badge.pink { background: rgba(244, 114, 182, 0.1); color: #f472b6; border: 1px solid rgba(244, 114, 182, 0.2); }
        .p-full-name { font-size: 17px; font-weight: 800; color: var(--glass-text-primary); margin-bottom: 16px; line-height: 1.4; text-align: center; }
        .p-detail-list { display: flex; flex-direction: column; gap: 10px; align-items: center; }
        .d-row { display: flex; align-items: center; gap: 10px; font-size: 12px; color: var(--glass-text-secondary); width: 100%; justify-content: center; }
        .p-login-info { 
          margin-top: 20px; 
          background: rgba(59, 130, 246, 0.05); 
          border: 1px dashed rgba(59, 130, 246, 0.2); 
          border-radius: 12px; padding: 12px; 
          text-align: center;
        }
        :global(.dashboard--light) .p-login-info { background: #f0f9ff; border-color: #bae6fd; }
        .login-head { font-size: 10px; font-weight: 800; text-transform: uppercase; color: var(--primary); margin-bottom: 8px; display: flex; align-items: center; justify-content: center; gap: 6px; }
        .login-row { font-size: 12px; color: var(--glass-text-primary); margin-bottom: 4px; }
        .login-row strong { color: var(--glass-text-muted); margin-right: 4px; }
        .pass-text { font-family: monospace; font-weight: 700; color: #10b981; background: rgba(16, 185, 129, 0.05); padding: 2px 6px; border-radius: 4px; }
        .address-bar-luxe { 
          background: rgba(16, 185, 129, 0.05); 
          border: 1px solid rgba(16, 185, 129, 0.1); 
          padding: 14px; border-radius: 12px; 
          color: #10b981; font-size: 12px; font-weight: 600; 
          display: flex; align-items: center; gap: 10px; 
        }

        .children-grid-wide { 
          display: flex; 
          flex-wrap: wrap; 
          gap: 20px; 
          justify-content: center; 
          width: 100%;
        }
        .child-wide-entry { 
          background: var(--glass-bg); 
          border: 1px solid var(--glass-border); 
          border-radius: 20px; 
          padding: 24px; 
          width: 320px;
          display: flex; flex-direction: column; align-items: center; text-align: center; gap: 16px; 
          transition: 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        :global(.dashboard--light) .child-wide-entry { background: #f8fafc; }
        .child-wide-entry:hover { transform: translateY(-4px); border-color: var(--primary); }
        .c-avatar-mini, .c-img-mini { 
          width: 50px; height: 50px; 
          border-radius: 14px; 
          flex-shrink: 0;
        }
        .c-img-mini { object-fit: cover; border: 1px solid var(--glass-border); }
        .c-avatar-mini { 
          background: var(--primary); color: #fff; 
          display: flex; align-items: center; justify-content: center; 
          font-weight: 800; font-size: 20px;
        }
        .c-info-mini { flex: 1; width: 100%; }
        .c-name-mini { font-size: 15px; font-weight: 800; color: var(--glass-text-primary); margin-bottom: 6px; }
        .c-meta-mini { display: flex; align-items: center; justify-content: center; gap: 8px; font-size: 11px; color: var(--glass-text-muted); }
        .c-code-tag { background: rgba(59, 130, 246, 0.1); color: #3b82f6; padding: 1px 6px; border-radius: 4px; font-weight: 700; }
        .btn-academic-mini { 
          background: transparent; border: 1px solid var(--glass-border); 
          color: var(--glass-text-secondary); padding: 6px 12px; border-radius: 8px; 
          font-size: 11px; font-weight: 700; cursor: pointer; 
          display: flex; align-items: center; gap: 6px; transition: 0.3s;
        }
        .btn-academic-mini:hover { background: var(--primary); color: #fff; border-color: var(--primary); }
        .modal-footer-luxe { margin-top: 40px; display: flex; justify-content: flex-end; padding-top: 20px; border-top: 1px solid var(--glass-border); }
        .btn-close-luxe { background: var(--glass-border); border: none; color: var(--glass-text-primary); padding: 10px 30px; border-radius: 12px; font-weight: 700; cursor: pointer; }
        .btn-close-luxe:hover { background: #ef4444; color: #fff; }
      `}</style>
    </div>
  );
}
