"use client";

import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { useTranslation, type TranslationKey } from "@/lib/i18n";
import { 
  Plus, 
  Trash2, 
  Clock, 
  MapPin, 
  User, 
  BookOpen, 
  X,
  Filter,
  Loader2,
  Wand2
} from "lucide-react";

export default function TimetablePage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  
  const [selectedClassId, setSelectedClassId] = useState<string>("");
  const [showModal, setShowModal] = useState(false);
  const [editingSlot, setEditingSlot] = useState<any>(null);

  // 1. Fetch Settings
  const { data: settings } = useQuery({
    queryKey: ["school-settings"],
    queryFn: async () => (await api.get("/settings")).data.data
  });

  // 2. Fetch Classes
  const { data: classes } = useQuery({
    queryKey: ["classes"],
    queryFn: async () => (await api.get("/classes")).data.data
  });

  // 3. Fetch Subjects
  const { data: subjects } = useQuery({
    queryKey: ["subjects"],
    queryFn: async () => (await api.get("/subjects")).data.data
  });

  // 4. Fetch Teachers
  const { data: teachers } = useQuery({
    queryKey: ["teachers"],
    queryFn: async () => (await api.get("/teachers")).data.data
  });

  // 5. Fetch Timetable for selected class
  const { data: timetable, isLoading: loadingTimetable } = useQuery({
    queryKey: ["timetable", selectedClassId],
    queryFn: async () => (await api.get(`/timetable?classId=${selectedClassId}`)).data.data,
    enabled: !!selectedClassId
  });

  const mutation = useMutation({
    mutationFn: (payload: any) => api.post("/timetable", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["timetable"] });
      setShowModal(false);
      setEditingSlot(null);
    },
    onError: (err: any) => {
      alert(err.response?.data?.message || t('tt_conflict_msg'));
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/timetable/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["timetable"] });
    }
  });

  const generateMutation = useMutation({
    mutationFn: () => api.post("/timetable/auto-generate", { classId: selectedClassId }),
    onSuccess: (res) => {
      alert(res.data.message || t('tt_auto_success'));
      queryClient.invalidateQueries({ queryKey: ["timetable"] });
    },
    onError: (err: any) => {
      alert(err.response?.data?.message || t('tt_auto_error'));
    }
  });

  const handleAddClick = (day: number, period: number) => {
    setEditingSlot({ day, periodNumber: period, classId: selectedClassId });
    setShowModal(true);
  };

  const handleEditClick = (slot: any) => {
    setEditingSlot(slot);
    setShowModal(true);
  };

  const handleSave = () => {
    if (!editingSlot?.classId || !editingSlot?.subjectId) return;
    mutation.mutate(editingSlot);
  };

  const findSlot = (day: number, period: number) => {
    return timetable?.find((s: any) => s.day === day && s.periodNumber === period);
  };

  if (!settings) return <div style={{ padding: "40px", color: "var(--glass-text-primary)" }}>Loading environment...</div>;

  const weekOrder = [6, 0, 1, 2, 3, 4, 5];
  const workingDays = [...(settings.workingDays || [0, 1, 2, 3, 4, 5, 6])].sort((a, b) => 
    weekOrder.indexOf(a) - weekOrder.indexOf(b)
  );
  const periods = Array.from({ length: settings.periodsPerDay || 7 }, (_, i) => i + 1);

  return (
    <div className="timetable-module" style={{ height: "100%", display: "flex", flexDirection: "column" }} dir={isAr ? "rtl" : "ltr"}>
      {/* Header */}
      <div className="module-header" style={{ marginBottom: "24px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div>
          <h2 style={{ fontSize: "32px", fontWeight: 900, letterSpacing: "-1px", color: "var(--glass-text-primary)" }}>{t('dash_timetable')}</h2>
          <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>{t('mod_timetable_desc')}</p>
        </div>

        <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
          {selectedClassId && (
            <button 
              onClick={() => { if(confirm(isAr ? "سيتم مسح الجدول الحالي لهذا الفصل وإنشاء جدول جديد تلقائياً. هل توافق؟" : "This will replace the current timetable for this class. Proceed?")) generateMutation.mutate(); }}
              disabled={generateMutation.isPending}
              style={{ display: "flex", alignItems: "center", gap: "8px", background: "var(--gradient-primary)", color: "#fff", padding: "8px 16px", borderRadius: "12px", border: "none", fontWeight: 700, cursor: generateMutation.isPending ? "not-allowed" : "pointer", fontSize: "14px", boxShadow: "0 4px 12px rgba(59, 130, 246, 0.3)" }}
            >
              {generateMutation.isPending ? <Loader2 size={16} className="spin" /> : <Wand2 size={16} />}
              {isAr ? "توزيع تلقائي" : "Auto Generate"}
            </button>
          )}

          <div style={{ display: "flex", alignItems: "center", gap: "12px", background: "var(--glass-input-bg)", padding: "8px 16px", borderRadius: "12px", border: "1px solid var(--glass-input-border)" }}>
             <Filter size={16} color="var(--glass-text-muted)" />
             <select 
               value={selectedClassId} 
               onChange={e => setSelectedClassId(e.target.value)}
               style={{ background: "transparent", border: "none", color: "var(--glass-text-primary)", outline: "none", fontWeight: 600, fontSize: "14px", cursor: "pointer" }}
             >
               <option value="" style={{ color: "#000" }}>{t('attn_select_class')}...</option>
               {classes?.map((c: any) => <option key={c.id} value={c.id} style={{ color: "#000" }}>{c.name}</option>)}
             </select>
          </div>
        </div>
      </div>

      {!selectedClassId ? (
        <div className="card-glass" style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", minHeight: "400px" }}>
           <div style={{ padding: "32px", borderRadius: "50%", background: "rgba(99, 102, 241, 0.1)", marginBottom: "24px" }}>
              <Clock size={48} color="#6366f1" style={{ opacity: 0.6 }} />
           </div>
           <h3 style={{ fontSize: "20px", fontWeight: 700, marginBottom: "8px", color: "var(--glass-text-primary)" }}>Unified Academy Scheduler</h3>
           <p style={{ color: "var(--glass-text-secondary)", maxWidth: "400px", textAlign: "center" }}>
             Select a class from the filter above to visualize and manage their weekly lesson distribution and teacher assignments.
           </p>
        </div>
      ) : (
        <div style={{ overflowX: "auto", flex: 1 }}>
          <table style={{ width: "100%", borderCollapse: "separate", borderSpacing: "12px" }}>
            <thead>
              <tr>
                <th style={{ width: "100px" }}></th>
                {workingDays.map((day: number) => (
                  <th key={day} style={dayHeaderStyle}>
                    {t(`day_${day}` as any)}
                  </th>
                ) )}
              </tr>
            </thead>
            <tbody>
              {periods.map(p => (
                <tr key={p}>
                  <td style={periodLabelStyle}>
                     <span style={{ fontSize: "18px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{p}</span>
                     <span style={{ fontSize: "10px", color: "var(--glass-text-muted)", textTransform: "uppercase" }}>Period</span>
                  </td>
                  {workingDays.map((day: number) => {
                    const slot = findSlot(day, p);
                    return (
                      <td key={day} onClick={() => slot ? handleEditClick(slot) : handleAddClick(day, p)} style={{ cursor: "pointer" }}>
                         {slot ? (
                           <div style={slotStyle(slot.subject?.name || "lesson")}>
                              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "8px" }}>
                                <span style={subjectTagStyle}>{slot.subject?.name || "No Subject"}</span>
                                <button 
                                  onClick={(e) => { e.stopPropagation(); if(confirm(t('tt_delete_confirm'))) deleteMutation.mutate(slot.id); }}
                                  style={{ background: "transparent", border: "none", color: "rgba(0,0,0,0.3)", cursor: "pointer" }}
                                >
                                  <Trash2 size={12} />
                                </button>
                              </div>
                              <div style={slotInfoItem}>
                                <User size={12} />
                                <span>{slot.teacher?.nameAr || slot.teacher?.user?.fullName || "No Teacher"}</span>
                              </div>
                               {slot.room && (
                                 <div style={slotInfoItem}>
                                   <MapPin size={12} />
                                   <span>{slot.room}</span>
                                 </div>
                               )}
                               {(slot.startTime || slot.endTime) && (
                                 <div style={slotInfoItem}>
                                   <Clock size={12} />
                                   <span style={{ fontWeight: 700, color: "var(--glass-text-primary)" }}>
                                     {slot.startTime || ""} {slot.startTime && slot.endTime ? "-" : ""} {slot.endTime || ""}
                                   </span>
                                 </div>
                               )}
                           </div>
                         ) : (
                           <div className="slot-empty" style={emptySlotStyle}>
                              <Plus size={16} style={{ opacity: 0.2, color: "var(--glass-text-muted)" }} />
                           </div>
                         )}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal */}
      {showModal && (
        <div style={modalOverlayStyle}>
           <div className="card-glass" style={modalContentStyle}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "24px" }}>
                 <h3 style={{ fontSize: "20px", fontWeight: 700, color: "var(--glass-text-primary)" }}>{editingSlot?.id ? t('tt_edit_slot') : t('tt_add_slot')}</h3>
                 <button onClick={() => setShowModal(false)} style={{ background: "transparent", border: "none", color: "var(--glass-text-primary)", cursor: "pointer" }}>
                    <X size={24} />
                 </button>
              </div>

              <div style={{ display: "grid", gap: "24px" }}>
                 <div>
                    <label style={labelStyle}>{t('tt_select_subject')}</label>
                    <select 
                      value={editingSlot?.subjectId || ""} 
                      onChange={e => setEditingSlot({...editingSlot, subjectId: e.target.value})}
                      style={inputStyle}
                    >
                      <option value="" style={{ color: "#000" }}>-- {t('tt_select_subject')} --</option>
                      {subjects?.map((s: any) => <option key={s.id} value={s.id} style={{ color: "#000" }}>{s.name}</option>)}
                    </select>
                 </div>

                 <div>
                    <label style={labelStyle}>{t('tt_select_teacher')}</label>
                    <select 
                      value={editingSlot?.teacherId || ""} 
                      onChange={e => setEditingSlot({...editingSlot, teacherId: e.target.value})}
                      style={inputStyle}
                    >
                      <option value="" style={{ color: "#000" }}>-- {t('tt_select_teacher')} --</option>
                      {teachers?.map((t: any) => <option key={t.id} value={t.id} style={{ color: "#000" }}>{t.nameAr || t.user?.fullName}</option>)}
                    </select>
                 </div>

                 <div>
                    <label style={labelStyle}>{t('tt_room_ph')}</label>
                    <input 
                      type="text" 
                      placeholder="e.g. Lab 1, Room 102"
                      value={editingSlot?.room || ""}
                      onChange={e => setEditingSlot({...editingSlot, room: e.target.value})}
                      style={inputStyle}
                    />
                 </div>

                 <div style={{ display: "flex", gap: "12px" }}>
                   <div style={{ flex: 1 }}>
                      <label style={labelStyle}>{isAr ? "من الساعة" : "From Time"}</label>
                      <input 
                        type="time" 
                        value={editingSlot?.startTime || ""}
                        onChange={e => setEditingSlot({...editingSlot, startTime: e.target.value})}
                        style={inputStyle}
                      />
                   </div>
                   <div style={{ flex: 1 }}>
                      <label style={labelStyle}>{isAr ? "إلى الساعة" : "To Time"}</label>
                      <input 
                        type="time" 
                        value={editingSlot?.endTime || ""}
                        onChange={e => setEditingSlot({...editingSlot, endTime: e.target.value})}
                        style={inputStyle}
                      />
                   </div>
                 </div>

                 <div style={{ display: "flex", gap: "12px", marginTop: "12px" }}>
                    <button 
                      onClick={handleSave} 
                      disabled={mutation.isPending}
                      className="btn primary" 
                      style={{ flex: 1, padding: "14px", borderRadius: "14px", fontWeight: 700 }}
                    >
                      {mutation.isPending ? "..." : "Save Slot"}
                    </button>
                    <button onClick={() => setShowModal(false)} className="btn outline" style={{ flex: 1, borderRadius: "14px" }}>
                      Cancel
                    </button>
                 </div>
              </div>
           </div>
        </div>
      )}

      {/* Global CSS for hover effects */}
      <style jsx global>{`
        .slot-empty:hover {
          background: var(--glass-icon-bg) !important;
          border-color: var(--glass-border) !important;
        }
        .slot-empty:hover svg {
          opacity: 0.8 !important;
          scale: 1.2;
        }
        .spin {
          animation: spin 1s linear infinite;
        }
        @keyframes spin { 100% { transform: rotate(360deg); } }
      `}</style>
    </div>
  );
}

// Styles
const dayHeaderStyle = {
  padding: "12px",
  textAlign: "center" as const,
  color: "var(--glass-text-secondary)",
  fontSize: "14px",
  fontWeight: 700,
  textTransform: "uppercase" as const,
  letterSpacing: "1px"
};

const periodLabelStyle = {
  background: "var(--glass-input-bg)",
  borderRadius: "16px",
  display: "flex",
  flexDirection: "column" as const,
  alignItems: "center",
  justifyContent: "center",
  padding: "16px",
  border: "1px solid var(--glass-input-border)"
};

const slotStyle = (seed: string) => {
  const hues = [210, 260, 330, 160, 30, 10, 180];
  const charSum = seed.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
  const hue = hues[charSum % hues.length];
  
  return {
    padding: "16px",
    borderRadius: "16px",
    background: `linear-gradient(135deg, hsla(${hue}, 80%, 45%, 0.15) 0%, hsla(${hue}, 80%, 30%, 0.1) 100%)`,
    border: "1px solid",
    borderColor: `hsla(${hue}, 80%, 50%, 0.3)`,
    minHeight: "100px",
    transition: "all 0.2s ease",
    boxShadow: "0 4px 12px rgba(0,0,0,0.1)"
  };
};

const emptySlotStyle = {
  height: "100px",
  borderRadius: "16px",
  border: "2px dashed var(--glass-border)",
  background: "var(--glass-input-bg)",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  transition: "all 0.2s ease"
};

const subjectTagStyle = {
  fontSize: "13px",
  fontWeight: 800,
  color: "var(--glass-text-primary)",
  maxWidth: "120px",
  overflow: "hidden",
  textOverflow: "ellipsis",
  whiteSpace: "nowrap" as const
};

const slotInfoItem = {
  display: "flex",
  alignItems: "center",
  gap: "8px",
  fontSize: "11px",
  color: "var(--glass-text-secondary)",
  marginTop: "4px"
};

const labelStyle = {
  display: "block",
  fontSize: "12px",
  fontWeight: 700,
  textTransform: "uppercase" as const,
  marginBottom: "8px",
  color: "var(--glass-text-secondary)"
};

const inputStyle = {
  width: "100%",
  padding: "12px 16px",
  borderRadius: "10px",
  background: "var(--glass-input-bg)",
  border: "1px solid var(--glass-input-border)",
  color: "var(--glass-text-primary)",
  fontSize: "15px",
  outline: "none"
};

const modalOverlayStyle = {
  position: "fixed" as const,
  top: 0,
  left: 0,
  right: 0,
  bottom: 0,
  background: "var(--modal-overlay-bg)",
  backdropFilter: "blur(10px)",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  zIndex: 1000,
  padding: "20px"
};

const modalContentStyle = {
  width: "100%",
  maxWidth: "460px",
  padding: "40px",
  border: "1px solid var(--glass-border)",
  boxShadow: "0 40px 80px rgba(0,0,0,0.5)",
  background: "var(--glass-bg)",
  borderRadius: "28px"
};
