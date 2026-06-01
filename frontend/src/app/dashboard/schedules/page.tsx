"use client";

import React, { useState } from "react";
import { 
  Calendar, Clock, Users, Megaphone, Plus, 
  ChevronLeft, ChevronRight, X, Check,
  CalendarDays, Loader2
} from "lucide-react";
import { useTranslation } from "@/lib/i18n";
import styles from "@/components/dashboard/PremiumAnalyticsHome.module.css";
import pageStyles from "./SchedulesPage.module.css";

interface ScheduleEvent {
  id: number;
  titleAr: string;
  titleEn: string;
  date: string;
  day: number;
  month: number;
  year: number;
  time: string;
  icon: React.ReactNode;
  bgColor: string;
  iconColor: string;
}

// Initial Mock Data (Started empty as per user request)
const INITIAL_EVENTS: ScheduleEvent[] = [];

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";

export default function SchedulesPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [viewDate, setViewDate] = useState(new Date());

  // Fetch real events
  const { data: eventsData, isFetching } = useQuery({
    queryKey: ["schedules", viewDate.getMonth(), viewDate.getFullYear()],
    queryFn: async () => (await api.get(`/schedules?month=${viewDate.getMonth()}&year=${viewDate.getFullYear()}`)).data.data,
    staleTime: 0,
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    refetchInterval: 5000,
  });
  const events = Array.isArray(eventsData) ? eventsData : [];

  // Create event mutation
  const createMutation = useMutation({
    mutationFn: (data: any) => api.post("/schedules", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["schedules"] });
      queryClient.invalidateQueries({ queryKey: ["overview"] });
      setIsModalOpen(false);
    }
  });

  // Delete event mutation
  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/schedules/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["schedules"] });
      queryClient.invalidateQueries({ queryKey: ["overview"] });
    }
  });

  const isUpdating = isFetching || createMutation.isPending || deleteMutation.isPending;
  
  // New Event State
  const [newEvent, setNewEvent] = useState({
    title: "",
    day: new Date().getDate(),
    month: new Date().getMonth(),
    year: new Date().getFullYear(),
    startTime: "09:00",
    endTime: "10:00",
    type: "GENERAL"
  });

  const handleAddEvent = () => {
    createMutation.mutate(newEvent);
  };

  const changeMonth = (offset: number) => {
    const d = new Date(viewDate);
    d.setMonth(d.getMonth() + offset);
    setViewDate(d);
  };

  const getDaysInMonth = (year: number, month: number) => {
    const date = new Date(year, month, 1);
    const days = [];
    // Prev month padding
    const firstDay = date.getDay();
    const prevMonthLastDay = new Date(year, month, 0).getDate();
    for (let i = firstDay - 1; i >= 0; i--) {
      days.push({ day: prevMonthLastDay - i, current: false });
    }
    // Current month
    const lastDay = new Date(year, month + 1, 0).getDate();
    for (let i = 1; i <= lastDay; i++) {
      days.push({ day: i, current: true });
    }
    return days;
  };

  const days = getDaysInMonth(viewDate.getFullYear(), viewDate.getMonth());

  return (
    <div className={styles.container}>
      <header className={styles.header}>
        <div className={styles.headerLeft}>
          <h1>{isAr ? "الجداول الزمنية" : "Schedules"}</h1>
          <p>{isAr ? "العمليات / الجداول الزمنية" : "Operations / Schedules"}</p>
        </div>
        <div className={styles.headerRight}>
          <button className={styles.btnPrimary} onClick={() => setIsModalOpen(true)}>
            <Plus size={18} />
            <span>{isAr ? "إضافة جديد" : "Add New"}</span>
          </button>
        </div>
      </header>

      <div className={`${pageStyles.grid} ${isUpdating ? pageStyles.loadingState : ""}`}>
        {/* CALENDAR SECTION */}
        <div className={styles.card}>
          {isUpdating && (
            <div className={pageStyles.cardLoader}>
              <Loader2 className="animate-spin" size={24} />
            </div>
          )}
          <div className={styles.cardHeader}>
            <h3 className={styles.cardTitle}>{isAr ? "التقويم" : "Calendar"}</h3>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
            <h4 style={{ fontSize: 16, fontWeight: 700, margin: 0 }}>
              {viewDate.toLocaleString(isAr ? 'ar-EG' : 'en-US', { month: 'long', year: 'numeric' })}
            </h4>
            <div style={{ display: 'flex', gap: 12 }}>
              <button className={pageStyles.navBtn} onClick={() => changeMonth(-1)}><ChevronLeft size={16}/></button>
              <button className={`${pageStyles.navBtn} ${pageStyles.active}`} onClick={() => changeMonth(1)}><ChevronRight size={16}/></button>
            </div>
          </div>
          <div className={styles.calendarGrid}>
            {(isAr ? ['ح','ن','ث','ر','خ','ج','س'] : ['S','M','T','W','T','F','S']).map((d,i) => <div key={`dh-${i}`} className={styles.calDayHead}>{d}</div>)}
            {days.map((d, i) => {
              const hasEvent = d.current && events.some(e => e.day === d.day && e.month === viewDate.getMonth() && e.year === viewDate.getFullYear());
              let c = styles.calDay;
              if (!d.current) c += ` ${styles.muted}`;
              if (hasEvent) c += ` ${styles.active}`;
              return <div key={`d-${i}`} className={c} style={{ width: 36, height: 36, fontSize: 14 }}>{d.day}</div>
            })}
          </div>
        </div>

        {/* UPCOMING EVENTS SECTION */}
        <div className={styles.card}>
          {isUpdating && (
            <div className={pageStyles.cardLoader}>
              <Loader2 className="animate-spin" size={24} />
            </div>
          )}
          <div className={styles.cardHeader}>
            <h3 className={styles.cardTitle}>{isAr ? "الفعاليات القادمة" : "Upcoming Events"}</h3>
          </div>
          <div className={styles.list}>
            {events.length === 0 ? (
              <p style={{ textAlign: 'center', padding: '40px 0', color: 'var(--ov-text-muted)' }}>
                {isAr ? "لا توجد فعاليات" : "No events scheduled"}
              </p>
            ) : (
              events.map((event: any) => (
                <div key={event.id} className={styles.listItem} style={{ alignItems: 'center', padding: '16px 0' }}>
                  <div style={{ 
                    width: 48, height: 48, borderRadius: 12, 
                    background: event.type === 'MEETING' ? '#e0f2fe' : '#dbeafe', 
                    color: event.type === 'MEETING' ? '#0ea5e9' : '#3b82f6', 
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0
                  }}>
                    {event.type === 'MEETING' ? <Users size={20}/> : <Megaphone size={20}/>}
                  </div>
                  <div className={styles.listBody}>
                    <h4 style={{ margin: '0 0 4px 0', fontSize: 15 }}>{event.title}</h4>
                    <p style={{ color: 'var(--ov-text)', fontWeight: 600, fontSize: 12, display: 'flex', alignItems: 'center', gap: 6 }}>
                      <Calendar size={12}/> {event.day} {new Date(event.year, event.month).toLocaleString(isAr ? 'ar-EG' : 'en-US', { month: 'long' })} {event.year}
                    </p>
                    <p style={{ fontSize: 12, display: 'flex', alignItems: 'center', gap: 6 }}>
                      <Clock size={12}/> {event.startTime} - {event.endTime}
                    </p>
                  </div>
                  <button 
                    onClick={() => deleteMutation.mutate(event.id)}
                    className={pageStyles.deleteBtn}
                  >
                    <X size={14}/>
                  </button>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* ADD NEW MODAL */}
      {isModalOpen && (
        <div className={pageStyles.modalOverlay}>
          <div className={pageStyles.modal}>
            <div className={pageStyles.modalHeader}>
              <h3>{isAr ? "إضافة فعالية جديدة" : "Add New Event"}</h3>
              <button onClick={() => setIsModalOpen(false)}><X size={20}/></button>
            </div>
            <div className={pageStyles.modalBody}>
              <div className={pageStyles.formGroup}>
                <label>{isAr ? "عنوان الفعالية" : "Event Title"}</label>
                <input 
                  type="text" 
                  value={newEvent.title}
                  onChange={(e) => setNewEvent({...newEvent, title: e.target.value})}
                  placeholder={isAr ? "مثال: اجتماع طارئ" : "e.g. Emergency Meeting"}
                />
              </div>
              <div style={{ display: 'flex', gap: 16 }}>
                <div className={pageStyles.formGroup} style={{ flex: 1 }}>
                  <label>{isAr ? "اليوم" : "Day"}</label>
                  <input 
                    type="number" min="1" max="31"
                    value={newEvent.day || ""}
                    onChange={(e) => setNewEvent({...newEvent, day: parseInt(e.target.value) || 0})}
                  />
                </div>
                <div className={pageStyles.formGroup} style={{ flex: 1 }}>
                  <label>{isAr ? "الشهر" : "Month"}</label>
                  <select 
                    value={newEvent.month}
                    onChange={(e) => setNewEvent({...newEvent, month: parseInt(e.target.value) || 0})}
                  >
                    {Array.from({ length: 12 }).map((_, i) => (
                      <option key={i} value={i}>
                        {new Date(2024, i).toLocaleString(isAr ? 'ar-EG' : 'en-US', { month: 'long' })}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <div style={{ display: 'flex', gap: 16 }}>
                <div className={pageStyles.formGroup} style={{ flex: 1 }}>
                  <label>{isAr ? "السنة" : "Year"}</label>
                  <input 
                    type="number"
                    value={newEvent.year || ""}
                    onChange={(e) => setNewEvent({...newEvent, year: parseInt(e.target.value) || new Date().getFullYear()})}
                  />
                </div>
              </div>
              <div style={{ display: 'flex', gap: 16 }}>
                <div className={pageStyles.formGroup} style={{ flex: 1 }}>
                  <label>{isAr ? "من" : "From"}</label>
                  <input 
                    type="time" 
                    value={newEvent.startTime}
                    onChange={(e) => setNewEvent({...newEvent, startTime: e.target.value})}
                  />
                </div>
                <div className={pageStyles.formGroup} style={{ flex: 1 }}>
                  <label>{isAr ? "إلى" : "To"}</label>
                  <input 
                    type="time" 
                    value={newEvent.endTime}
                    onChange={(e) => setNewEvent({...newEvent, endTime: e.target.value})}
                  />
                </div>
              </div>
              <div className={pageStyles.formGroup}>
                <label>{isAr ? "النوع" : "Type"}</label>
                <select 
                  value={newEvent.type}
                  onChange={(e) => setNewEvent({...newEvent, type: e.target.value})}
                >
                  <option value="GENERAL">{isAr ? "عام" : "General"}</option>
                  <option value="MEETING">{isAr ? "اجتماع" : "Meeting"}</option>
                </select>
              </div>
            </div>
            <div className={pageStyles.modalFooter}>
              <button className={styles.btnSecondary} onClick={() => setIsModalOpen(false)}>{isAr ? "إلغاء" : "Cancel"}</button>
              <button 
                className={styles.btnPrimary} 
                onClick={handleAddEvent}
                disabled={createMutation.isPending}
              >
                {createMutation.isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "حفظ" : "Save")}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
