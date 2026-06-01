"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { 
  Archive as ArchiveIcon, 
  RotateCcw, 
  Search, 
  Trash2,
  Calendar,
  User as UserIcon,
  Filter,
  Eye,
  X
} from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";

export default function ArchivesPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [filterType, setFilterType] = useState("STUDENT");
  const [viewingItem, setViewingItem] = useState<any>(null);

  const { data: archives, isLoading } = useQuery({
    queryKey: ["archives", filterType],
    queryFn: async () => (await api.get("/archives", { params: { entityType: filterType } })).data.data
  });

  const restoreMutation = useMutation({
    mutationFn: async (id: string) => await api.post(`/archives/${id}/restore`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["archives"] });
      queryClient.invalidateQueries({ queryKey: ["students"] });
      alert(isAr ? "تم استرجاع البيانات بنجاح!" : "Data restored successfully!");
    }
  });

  const filteredArchives = archives?.filter((a: any) => {
    const data = a.entityData;
    const name = data.user?.fullName || data.nameAr || "";
    return name.toLowerCase().includes(search.toLowerCase()) || a.entityId.includes(search);
  });

  return (
    <div className="archives-module">
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px", flexDirection: isAr ? "row-reverse" : "row" }}>
        <div style={{ textAlign: isAr ? "right" : "left" }}>
          <h2 style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)" }}>
            {isAr ? "أرشيف البيانات المحذوفة" : "Data Archives"}
          </h2>
          <p style={{ color: "var(--glass-text-secondary)" }}>
            {isAr ? "إدارة واسترجاع بيانات الطلاب وأولياء الأمور المحذوفة" : "Manage and restore deleted student and parent records"}
          </p>
        </div>
      </div>

      <div className="card-glass" style={{ marginBottom: "24px", padding: "20px", display: "flex", gap: "16px", alignItems: "center", flexDirection: isAr ? "row-reverse" : "row" }}>
        <div style={{ position: "relative", flex: 1 }}>
          <Search size={18} style={{ position: "absolute", left: isAr ? "auto" : "12px", right: isAr ? "12px" : "auto", top: "50%", transform: "translateY(-50%)", color: "var(--glass-text-muted)" }} />
          <input 
            type="text" 
            placeholder={isAr ? "ابحث بالاسم أو الكود..." : "Search by name or ID..."}
            className="glass-input" 
            style={{ paddingLeft: isAr ? "12px" : "40px", paddingRight: isAr ? "40px" : "12px", width: "100%" }}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select 
          className="glass-input" 
          style={{ width: "200px" }}
          value={filterType}
          onChange={(e) => setFilterType(e.target.value)}
        >
          <option value="STUDENT">{isAr ? "الطلاب" : "Students"}</option>
          <option value="STAFF">{isAr ? "الموظفين" : "Staff"}</option>
        </select>
      </div>

      <div className="premium-table-wrapper card-glass" style={{ padding: "0" }}>
        <table className="premium-table" dir={isAr ? "rtl" : "ltr"}>
          <thead>
            <tr>
              <th style={{ textAlign: "start" }}>{isAr ? "الاسم" : "Name"}</th>
              <th style={{ textAlign: "start" }}>{isAr ? "النوع" : "Type"}</th>
              <th style={{ textAlign: "start" }}>{isAr ? "تاريخ الأرشفة" : "Archived At"}</th>
              <th style={{ textAlign: "start" }}>{isAr ? "بواسطة" : "By"}</th>
              <th style={{ textAlign: "end" }}>{isAr ? "إجراءات" : "Actions"}</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr><td colSpan={5} style={{ textAlign: "center", padding: "40px" }}>{isAr ? "جاري التحميل..." : "Loading..."}</td></tr>
            ) : filteredArchives?.length === 0 ? (
              <tr><td colSpan={5} style={{ textAlign: "center", padding: "40px", color: "var(--glass-text-muted)" }}>{isAr ? "الأرشيف فارغ" : "Archive is empty"}</td></tr>
            ) : filteredArchives?.map((item: any) => (
              <tr key={item.id}>
                <td style={{ textAlign: "start" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                    <div style={{ width: "36px", height: "36px", borderRadius: "10px", background: "rgba(255,255,255,0.05)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                      <UserIcon size={18} />
                    </div>
                    <div style={{ textAlign: "start" }}>
                      <div style={{ fontWeight: 700 }}>{item.entityData.user?.fullName || item.entityData.nameAr}</div>
                      <div style={{ fontSize: "12px", color: "var(--glass-text-muted)" }}>ID: {item.entityData.studentCode || item.entityId}</div>
                    </div>
                  </div>
                </td>
                <td style={{ textAlign: "start" }}><span className="badge" style={{ background: "rgba(59, 130, 246, 0.1)", color: "#3b82f6" }}>{item.entityType}</span></td>
                <td style={{ textAlign: "start" }}>{new Date(item.archivedAt).toLocaleDateString()}</td>
                <td style={{ textAlign: "start" }}>{item.archivedBy}</td>
                <td style={{ textAlign: "end" }}>
                  <div style={{ display: "flex", gap: "10px", justifyContent: "end", alignItems: "center" }}>
                    <button 
                      className="btn-icon premium" 
                      onClick={() => setViewingItem(item)}
                      title={isAr ? "عرض البيانات" : "View Data"}
                      style={{ 
                        width: "34px", 
                        height: "34px", 
                        borderRadius: "10px", 
                        background: "var(--glass-card-bg)", 
                        border: "1px solid var(--glass-border)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "var(--primary-light)",
                        transition: "all 0.2s"
                      }}
                    >
                      <Eye size={18} />
                    </button>
                    <button 
                      className="btn primary" 
                      style={{ padding: "8px 16px", fontSize: "13px", borderRadius: "10px", display: "flex", alignItems: "center", gap: "6px" }}
                      onClick={() => { if(confirm(isAr ? 'هل تريد استعادة هذه البيانات؟' : 'Restore this record?')) restoreMutation.mutate(item.id); }}
                      disabled={restoreMutation.isPending}
                    >
                      <RotateCcw size={16} /> {isAr ? "استعادة" : "Restore"}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Viewing Modal */}
      {viewingItem && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.6)", backdropFilter: "blur(8px)", zIndex: 1000, display: "flex", alignItems: "center", justifyContent: "center", padding: "20px" }} onClick={() => setViewingItem(null)}>
          <div className="card-glass fade-in" style={{ width: "100%", maxWidth: "600px", maxHeight: "80vh", overflow: "hidden", display: "flex", flexDirection: "column", padding: "24px", borderRadius: "24px" }} onClick={e => e.stopPropagation()}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexDirection: isAr ? "row-reverse" : "row" }}>
              <h3 style={{ fontSize: "20px", fontWeight: 800 }}>{isAr ? "تفاصيل البيانات المؤرشفة" : "Archived Data Details"}</h3>
              <button 
                className="btn-icon premium" 
                onClick={() => setViewingItem(null)}
                style={{ 
                  width: "36px", 
                  height: "36px", 
                  borderRadius: "10px", 
                  background: "rgba(255,255,255,0.05)", 
                  border: "1px solid var(--glass-border)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "var(--glass-text-secondary)"
                }}
              >
                <X size={20} />
              </button>
            </div>
            
            <div style={{ overflowY: "auto", flex: 1, padding: "4px" }} dir={isAr ? "rtl" : "ltr"}>
              <div style={{ display: "grid", gap: "24px" }}>
                {/* Personal Info */}
                <section>
                  <h4 style={{ fontSize: "14px", color: "var(--primary-light)", marginBottom: "12px", borderBottom: "1px solid rgba(255,255,255,0.1)", paddingBottom: "8px", textAlign: "start" }}>
                    {isAr ? "المعلومات الشخصية" : "Personal Information"}
                  </h4>
                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
                    <DataField label={isAr ? "الاسم العربي" : "Arabic Name"} value={viewingItem.entityData.nameAr} />
                    <DataField label={isAr ? "الاسم الإنجليزي" : "English Name"} value={viewingItem.entityData.nameEn} />
                    <DataField label={isAr ? "الرقم القومي" : "National ID"} value={viewingItem.entityData.nationalId} />
                    <DataField label={isAr ? "تاريخ الميلاد" : "Date of Birth"} value={viewingItem.entityData.dob && new Date(viewingItem.entityData.dob).toLocaleDateString()} />
                    <DataField label={isAr ? "النوع" : "Gender"} value={viewingItem.entityData.gender} />
                    <DataField label={isAr ? "العنوان" : "Address"} value={viewingItem.entityData.address} />
                  </div>
                </section>

                {/* School Info */}
                <section>
                  <h4 style={{ fontSize: "14px", color: "var(--primary-light)", marginBottom: "12px", borderBottom: "1px solid rgba(255,255,255,0.1)", paddingBottom: "8px", textAlign: "start" }}>
                    {isAr ? "المعلومات المدرسية" : "School Information"}
                  </h4>
                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
                    <DataField label={isAr ? "كود الطالب" : "Student Code"} value={viewingItem.entityData.studentCode} />
                    <DataField label={isAr ? "رقم الجلوس" : "Roll Number"} value={viewingItem.entityData.rollNumber} />
                    <DataField label={isAr ? "الحالة عند الأرشفة" : "Status at Archive"} value={viewingItem.entityData.status} />
                  </div>
                </section>

                {/* Family Info */}
                {(viewingItem.entityData.father || viewingItem.entityData.mother) && (
                  <section>
                    <h4 style={{ fontSize: "14px", color: "var(--primary-light)", marginBottom: "12px", borderBottom: "1px solid rgba(255,255,255,0.1)", paddingBottom: "8px", textAlign: "start" }}>
                      {isAr ? "معلومات العائلة" : "Family Information"}
                    </h4>
                    <div style={{ display: "grid", gap: "16px" }}>
                      {viewingItem.entityData.father && (
                        <div style={{ padding: "12px", background: "rgba(255,255,255,0.03)", borderRadius: "12px", textAlign: "start" }}>
                          <div style={{ fontWeight: 700, fontSize: "13px", marginBottom: "8px" }}>{isAr ? "الأب:" : "Father:"} {viewingItem.entityData.father.nameAr}</div>
                          <div style={{ fontSize: "12px", color: "var(--glass-text-secondary)" }}>{viewingItem.entityData.father.phone} | {viewingItem.entityData.father.occupation}</div>
                        </div>
                      )}
                      {viewingItem.entityData.mother && (
                        <div style={{ padding: "12px", background: "rgba(255,255,255,0.03)", borderRadius: "12px", textAlign: "start" }}>
                          <div style={{ fontWeight: 700, fontSize: "13px", marginBottom: "8px" }}>{isAr ? "الأم:" : "Mother:"} {viewingItem.entityData.mother.nameAr}</div>
                          <div style={{ fontSize: "12px", color: "var(--glass-text-secondary)" }}>{viewingItem.entityData.mother.phone} | {viewingItem.entityData.mother.occupation}</div>
                        </div>
                      )}
                    </div>
                  </section>
                )}
              </div>
            </div>

            <div style={{ marginTop: "24px", display: "flex", justifyContent: isAr ? "flex-start" : "flex-end" }}>
              <button className="btn" style={{ padding: "10px 24px" }} onClick={() => setViewingItem(null)}>{isAr ? "إغلاق" : "Close"}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function DataField({ label, value }: { label: string, value: any }) {
  return (
    <div style={{ textAlign: "start" }}>
      <div style={{ 
        fontSize: "11px", 
        color: "var(--glass-text-muted)", 
        textTransform: "uppercase", 
        fontWeight: 700, 
        marginBottom: "4px",
        letterSpacing: "0.5px"
      }}>{label}</div>
      <div style={{ 
        fontSize: "14px", 
        color: "var(--glass-text-primary)", 
        fontWeight: 500,
        wordBreak: "break-word"
      }}>{value || "—"}</div>
    </div>
  );
}
