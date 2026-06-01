"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { 
  Bus, 
  Users,
  MapPin, 
  Plus, 
  User, 
  Navigation, 
  Play, 
  Square, 
  Settings, 
  Clock, 
  MoreVertical,
  Activity,
  AlertTriangle,
  Map as MapIcon,
  ShieldCheck,
  Zap,
  Trash2,
  Search
} from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";

export default function TransportPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [isBusModalOpen, setIsBusModalOpen] = useState(false);
  const [isRouteModalOpen, setIsRouteModalOpen] = useState(false);
  const [activeBusId, setActiveBusId] = useState<string | null>(null);

  const { data: buses, isLoading: busesLoading } = useQuery({
    queryKey: ["buses"],
    queryFn: async () => (await api.get("/transport/buses")).data.data
  });

  const { data: routes, isLoading: routesLoading } = useQuery({
    queryKey: ["routes"],
    queryFn: async () => (await api.get("/transport/routes")).data.data
  });

  const { data: drivers, isLoading: driversLoading } = useQuery({
    queryKey: ["drivers"],
    queryFn: async () => (await api.get("/transport/drivers")).data.data
  });

  const { data: supervisors, isLoading: supervisorsLoading } = useQuery({
    queryKey: ["supervisors"],
    queryFn: async () => (await api.get("/transport/supervisors")).data.data
  });

  const { data: transportStudents, isLoading: studentsLoading } = useQuery({
    queryKey: ["transport-students"],
    queryFn: async () => (await api.get("/transport/students")).data.data
  });

  const [busForm, setBusForm] = useState({
    id: undefined as string | undefined,
    number: "",
    plateNumber: "",
    capacity: 30,
    status: "ACTIVE",
    driverId: "",
    supervisorId: ""
  });

  const [routeForm, setRouteForm] = useState({
    name: "",
    busId: "",
    pickupTime: "07:30",
    dropoffTime: "15:30"
  });

  const [selectedBusForStudents, setSelectedBusForStudents] = useState<any | null>(null);
  const [selectedStudentIds, setSelectedStudentIds] = useState<string[]>([]);
  const [isStudentModalOpen, setIsStudentModalOpen] = useState(false);
  const [studentSearch, setStudentSearch] = useState("");
  
  // Custom states for student bus attendance logs view
  const [selectedStudentForLogs, setSelectedStudentForLogs] = useState<any | null>(null);
  const [isLogsModalOpen, setIsLogsModalOpen] = useState(false);

  // Tab & Filter States for Attendance Tracker
  const [activeTab, setActiveTab] = useState<"fleet" | "attendance">("fleet");
  const [attendanceDate, setAttendanceDate] = useState(() => {
    const d = new Date();
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const r = String(d.getDate()).padStart(2, "0");
    return `${y}-${m}-${r}`;
  });
  const [filterBusId, setFilterBusId] = useState<string>("");
  const [filterStatus, setFilterStatus] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState<string>("");

  // Map and calculate logs for the selected date
  const logsForDate = React.useMemo(() => {
    if (!transportStudents) return [];
    return transportStudents.map((s: any) => {
      // Find log matching selected date
      const dateLog = s.BusAttendance?.find((log: any) => {
        const logD = typeof log.date === "string" ? log.date.split("T")[0] : new Date(log.date).toISOString().split("T")[0];
        return logD === attendanceDate;
      });
      return {
        student: s,
        log: dateLog || null, // null means UNRECORDED
        status: dateLog ? dateLog.status : "UNRECORDED",
        busId: s.busAssignment?.busId || null,
        busNumber: s.busAssignment?.bus?.number || "---",
        route: s.busAssignment?.route?.name || (s.busAssignment?.bus?.routes?.map((r: any) => r.name).join(", ")) || "---",
        notes: dateLog?.notes || "",
        recordedBy: dateLog?.supervisor?.name || "---",
        recordedAt: dateLog?.createdAt ? new Date(dateLog.createdAt).toLocaleTimeString(isAr ? 'ar-EG' : 'en-US', { hour: '2-digit', minute: '2-digit' }) : "---"
      };
    });
  }, [transportStudents, attendanceDate, isAr]);

  const filteredLogs = React.useMemo(() => {
    return logsForDate.filter((entry: any) => {
      // Filter by bus assignment
      if (filterBusId && entry.busId !== filterBusId) return false;
      // Filter by status
      if (filterStatus && entry.status !== filterStatus) return false;
      // Filter by search query
      if (searchQuery) {
        const name = (entry.student.nameAr || entry.student.nameEn || entry.student.user?.fullName || "").toLowerCase();
        if (!name.includes(searchQuery.toLowerCase())) return false;
      }
      return true;
    });
  }, [logsForDate, filterBusId, filterStatus, searchQuery]);

  const trackerStats = React.useMemo(() => {
    let boarded = 0;
    let absent = 0;
    let unrecorded = 0;

    // Filter baseline stats according to selected bus (if filterBusId is selected)
    const baseEntries = filterBusId 
      ? logsForDate.filter((e: any) => e.busId === filterBusId) 
      : logsForDate;

    baseEntries.forEach((entry: any) => {
      if (entry.status === "BOARDED") boarded++;
      else if (entry.status === "ABSENT") absent++;
      else if (entry.status === "UNRECORDED") unrecorded++;
    });

    return { boarded, absent, unrecorded, total: baseEntries.length };
  }, [logsForDate, filterBusId]);

  const busMutation = useMutation({
    mutationFn: async (data: any) => api.post("/transport/buses", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["buses"] });
      queryClient.invalidateQueries({ queryKey: ["drivers"] });
      queryClient.invalidateQueries({ queryKey: ["supervisors"] });
      queryClient.invalidateQueries({ queryKey: ["routes"] });
      setIsBusModalOpen(false);
      setBusForm({ id: undefined, number: "", plateNumber: "", capacity: 30, status: "ACTIVE", driverId: "", supervisorId: "" });
    },
    onError: (err: any) => {
      const msg = err.response?.data?.message || "Error saving bus";
      alert(isAr ? `خطأ: ${msg}` : `Error: ${msg}`);
    }
  });

  const routeMutation = useMutation({
    mutationFn: async (data: any) => api.post("/transport/routes", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["routes"] });
      queryClient.invalidateQueries({ queryKey: ["buses"] });
      setIsRouteModalOpen(false);
      setRouteForm({ name: "", busId: "", pickupTime: "07:30", dropoffTime: "15:30" });
    }
  });

  const deleteBusMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/transport/buses/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["buses"] });
      queryClient.invalidateQueries({ queryKey: ["drivers"] });
      queryClient.invalidateQueries({ queryKey: ["supervisors"] });
    }
  });

  const deleteRouteMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/transport/routes/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["routes"] });
    }
  });

  const tripMutation = useMutation({
    mutationFn: async ({ id, action }: { id: string, action: "START" | "END" }) => {
      return await api.post(`/transport/buses/${id}/trip`, { action });
    },
    onSuccess: (_, variables) => {
      if (variables.action === "START") setActiveBusId(variables.id);
      else setActiveBusId(null);
      queryClient.invalidateQueries({ queryKey: ["buses"] });
      queryClient.invalidateQueries({ queryKey: ["drivers"] });
      queryClient.invalidateQueries({ queryKey: ["supervisors"] });
    }
  });

  const assignStudentsMutation = useMutation({
    mutationFn: async ({ busId, studentIds }: { busId: string, studentIds: string[] }) => {
      return api.post(`/transport/buses/${busId}/students`, { studentIds });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["buses"] });
      queryClient.invalidateQueries({ queryKey: ["transport-students"] });
      setIsStudentModalOpen(false);
    },
    onError: (err: any) => {
      const msg = err.response?.data?.message || "Error assigning students";
      alert(isAr ? `خطأ: ${msg}` : `Error: ${msg}`);
    }
  });

  return (
    <div className="transport-module" dir={isAr ? "rtl" : "ltr"}>
      {/* Header */}
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "32px", fontWeight: 800, color: "var(--glass-text-primary)", letterSpacing: "-0.5px" }}>{isAr ? "إدارة النقل المدرسي" : "Fleet & Transport"}</h2>
          <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>{isAr ? "متابعة حافلات المدرسة، السائقين، والمسارات اليومية" : "Manage school bus fleet, drivers, and daily routing logistics."}</p>
        </div>
        <div style={{ display: "flex", gap: "12px" }}>
          <button className="btn-premium-outline" onClick={() => setIsRouteModalOpen(true)}>
            <MapPin size={18} />
            <span>{isAr ? "مسار جديد" : "New Route"}</span>
          </button>
          <button className="btn-premium-primary" onClick={() => setIsBusModalOpen(true)}>
            <Bus size={18} />
            <span>{isAr ? "إضافة حافلة" : "Add Bus"}</span>
          </button>
        </div>
      </div>
      <div style={{ display: "flex", gap: "16px", borderBottom: "1px solid var(--glass-border)", marginBottom: "32px", paddingBottom: "2px" }}>
        <button 
          onClick={() => setActiveTab("fleet")}
          style={{
            background: "transparent",
            border: "none",
            borderBottom: activeTab === "fleet" ? "3px solid #3b82f6" : "3px solid transparent",
            color: activeTab === "fleet" ? "var(--glass-text-primary)" : "var(--glass-text-secondary)",
            padding: "8px 16px",
            fontSize: "16px",
            fontWeight: 800,
            cursor: "pointer",
            transition: "all 0.2s"
          }}
        >
          {isAr ? "الأسطول والمسارات" : "Fleet & Routing"}
        </button>
        <button 
          onClick={() => setActiveTab("attendance")}
          style={{
            background: "transparent",
            border: "none",
            borderBottom: activeTab === "attendance" ? "3px solid #3b82f6" : "3px solid transparent",
            color: activeTab === "attendance" ? "var(--glass-text-primary)" : "var(--glass-text-secondary)",
            padding: "8px 16px",
            fontSize: "16px",
            fontWeight: 800,
            cursor: "pointer",
            transition: "all 0.2s"
          }}
        >
          {isAr ? "متابعة الحضور والغياب" : "Attendance Tracker"}
        </button>
      </div>

      {activeTab === "fleet" ? (
        <>
          {/* Stats Summary Row */}
          <div className="module-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", gap: "24px", marginBottom: "40px" }}>
            <div className="luxury-stat-card" style={{ "--accent-color": "#3b82f6" } as any}>
              <div className="l-stat-bg-blob"></div>
              <div className="luxury-stat-inner">
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <div>
                    <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "13px", fontWeight: 700, textTransform: "uppercase" }}>{isAr ? "إجمالي الأسطول" : "Total Fleet"}</h4>
                    <div style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)", marginTop: "4px" }}>{buses?.length || 0} {isAr ? "حافلة" : "Buses"}</div>
                  </div>
                  <Bus color="#3b82f6" opacity={0.6} />
                </div>
              </div>
            </div>
            <div className="luxury-stat-card" style={{ "--accent-color": "#ef4444" } as any}>
              <div className="l-stat-bg-blob"></div>
              <div className="luxury-stat-inner">
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <div>
                    <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "13px", fontWeight: 700, textTransform: "uppercase" }}>{isAr ? "رحلات نشطة" : "Active Trips"}</h4>
                    <div style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)", marginTop: "4px" }}>{activeBusId ? 1 : 0} {isAr ? "مباشر" : "Live"}</div>
                  </div>
                  <Activity color="#ef4444" opacity={0.6} className={activeBusId ? "animate-pulse" : ""} />
                </div>
              </div>
            </div>
            <div className="luxury-stat-card" style={{ "--accent-color": "#10b981" } as any}>
              <div className="l-stat-bg-blob"></div>
              <div className="luxury-stat-inner">
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <div>
                    <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "13px", fontWeight: 700, textTransform: "uppercase" }}>{isAr ? "طاقم السائقين" : "Driver Roster"}</h4>
                    <div style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)", marginTop: "4px" }}>{drivers?.length || 0} {isAr ? "سائق" : "Drivers"}</div>
                  </div>
                  <Users color="#10b981" opacity={0.6} />
                </div>
              </div>
            </div>
          </div>

          <div className="transport-grid">
            {/* Fleet Section */}
            <div className="fleet-section">
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
                <h3 style={{ fontSize: "20px", fontWeight: 800, display: "flex", alignItems: "center", gap: "10px", color: "var(--glass-text-primary)" }}>
                  <Zap size={20} color="#f59e0b" fill="#f59e0b" /> {isAr ? "حالة الأسطول" : "Fleet Status"}
                </h3>
              </div>
              
              <div className="buses-list">
                {busesLoading ? (
                  <div style={{ padding: "60px 0", textAlign: "center" }}>
                    <div className="spinner-large" style={{ margin: "0 auto" }} />
                  </div>
                ) : buses?.length === 0 ? (
                  <div className="luxury-stat-card" style={{ padding: "60px", textAlign: "center", "--accent-color": "var(--glass-border)" } as any}>
                    <div className="luxury-stat-inner">
                      <Bus size={48} style={{ opacity: 0.2, margin: "0 auto" }} />
                      <p style={{ marginTop: "16px", color: "var(--glass-text-muted)" }}>{isAr ? "لا توجد حافلات مسجلة" : "No buses registered yet."}</p>
                    </div>
                  </div>
                ) : buses?.map((bus: any) => (
                  <div key={bus.id} className="luxury-stat-card" style={{ "--accent-color": bus.status === "ACTIVE" ? "#3b82f6" : "#f59e0b" } as any}>
                    <div className="l-stat-bg-blob"></div>
                    <div className="luxury-stat-inner bus-card-main">
                      <div className="bus-avatar-box">
                        <Bus size={28} />
                        <div className="bus-num">#{bus.number}</div>
                      </div>
                      
                      <div className="bus-info">
                        <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                           <h4 className="bus-title">{isAr ? "حافلة رقم" : "Bus"} {bus.number}</h4>
                           <span className={`status-tag ${bus.status.toLowerCase()}`}>{bus.status}</span>
                        </div>
                        <div className="bus-meta" style={{ display: 'flex', flexDirection: 'column', gap: '4px', marginTop: '8px' }}>
                          <div style={{ display: 'flex', gap: '16px' }}>
                            <span className="meta-item"><User size={12} /> <strong>{isAr ? "السائق: " : "Driver: "}</strong> {bus.driver?.name || (isAr ? "بدون سائق" : "Unassigned")}</span>
                            <span className="meta-item"><User size={12} /> <strong>{isAr ? "المشرفة: " : "Supervisor: "}</strong> {bus.supervisor?.name || (isAr ? "بدون مشرفة" : "Unassigned")}</span>
                          </div>
                          <span className="meta-item"><MapPin size={12} /> {bus.plateNumber || "---"}</span>
                        </div>
                        
                        <div className="capacity-bar-container">
                           <div className="capacity-label">
                             <span>{isAr ? "الإشغال" : "Occupancy"}</span>
                             <span>{bus.students?.length || 0} / {bus.capacity}</span>
                           </div>
                           <div className="progress-bg">
                             <div className="progress-fill" style={{ width: `${bus.capacity > 0 ? (Math.min(1, (bus.students?.length || 0) / bus.capacity) * 100) : 0}%` }}></div>
                           </div>
                        </div>

                        {bus.students && bus.students.length > 0 && (
                          <div className="bus-students-list" style={{ marginTop: '16px', background: 'rgba(255,255,255,0.02)', borderRadius: '12px', padding: '12px', border: '1px solid var(--glass-border)' }}>
                            <div style={{ fontSize: '12px', fontWeight: 800, color: 'var(--glass-text-secondary)', marginBottom: '8px', display: 'flex', justifyContent: 'space-between' }}>
                              <span>{isAr ? "الطلاب المقيدين بالباص:" : "Assigned Students:"}</span>
                              <span style={{ color: '#3b82f6' }}>{bus.students.length} {isAr ? "طالب" : "Students"}</span>
                            </div>
                            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(130px, 1fr))', gap: '8px', maxHeight: '120px', overflowY: 'auto', paddingRight: '4px' }}>
                              {bus.students.map((bs: any) => (
                                <div 
                                  key={bs.id} 
                                  title={isAr ? "اضغط لعرض سجل الحضور والغياب للباص" : "Click to view bus attendance logs"}
                                  onClick={() => {
                                    setSelectedStudentForLogs(bs.student);
                                    setIsLogsModalOpen(true);
                                  }}
                                  style={{ 
                                    display: 'flex', 
                                    alignItems: 'center', 
                                    gap: '8px', 
                                    fontSize: '11px', 
                                    color: 'var(--glass-text-primary)', 
                                    padding: '6px 8px', 
                                    background: 'rgba(255,255,255,0.03)', 
                                    borderRadius: '6px', 
                                    border: '1px solid rgba(255,255,255,0.03)',
                                    cursor: 'pointer',
                                    transition: 'all 0.2s'
                                  }}
                                  onMouseEnter={(e) => {
                                    e.currentTarget.style.background = 'rgba(59, 130, 246, 0.15)';
                                    e.currentTarget.style.borderColor = 'rgba(59, 130, 246, 0.3)';
                                  }}
                                  onMouseLeave={(e) => {
                                    e.currentTarget.style.background = 'rgba(255,255,255,0.03)';
                                    e.currentTarget.style.borderColor = 'rgba(255,255,255,0.03)';
                                  }}
                                >
                                  <div style={{ width: '16px', height: '16px', borderRadius: '50%', background: '#3b82f6', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '8px', fontWeight: 900 }}>
                                    {bs.student?.user?.fullName?.[0]?.toUpperCase() || 'S'}
                                  </div>
                                  <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }} title={bs.student?.user?.fullName}>
                                    {isAr ? (bs.student?.nameAr || bs.student?.user?.fullName) : (bs.student?.nameEn || bs.student?.user?.fullName)}
                                  </span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>

                      <div className="bus-actions">
                        {activeBusId === bus.id ? (
                          <button className="trip-btn stop" onClick={() => tripMutation.mutate({ id: bus.id, action: "END" })}>
                            <Square size={16} fill="currentColor" /> {isAr ? "إنهاء" : "End"}
                          </button>
                        ) : (
                          <button 
                            className="trip-btn start" 
                            onClick={() => tripMutation.mutate({ id: bus.id, action: "START" })}
                            disabled={bus.status !== "ACTIVE"}
                          >
                            <Play size={16} fill="currentColor" /> {isAr ? "بدء" : "Start"}
                          </button>
                        )}
                        <button 
                          className="settings-btn"
                          style={{ background: 'rgba(255,255,255,0.05)', color: 'var(--glass-text-primary)' }}
                          onClick={() => {
                            setBusForm({
                              id: bus.id,
                              number: bus.number,
                              plateNumber: bus.plateNumber || "",
                              capacity: bus.capacity,
                              status: bus.status,
                              driverId: bus.driver?.id || "",
                              supervisorId: bus.supervisor?.id || ""
                            });
                            setIsBusModalOpen(true);
                          }}
                        >
                          <Settings size={18} />
                        </button>
                        <button 
                          className="settings-btn"
                          style={{ background: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6', border: '1px solid rgba(59, 130, 246, 0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', padding: '8px' }}
                          onClick={() => {
                            setSelectedBusForStudents(bus);
                            const assignedIds = bus.students?.map((s: any) => s.studentId) || [];
                            setSelectedStudentIds(assignedIds);
                            setIsStudentModalOpen(true);
                          }}
                        >
                          <Users size={14} />
                          <span style={{ fontSize: '11px', fontWeight: 800 }}>{isAr ? "الطلاب" : "Students"}</span>
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Right Sidebar (Routes + Drivers Summary) */}
            <div className="sidebar-section">
              {/* Routes Section */}
              <div className="routes-section" style={{ marginBottom: "32px" }}>
                <h3 style={{ fontSize: "20px", fontWeight: 800, marginBottom: "20px", display: "flex", alignItems: "center", gap: "10px", color: "var(--glass-text-primary)" }}>
                  <MapIcon size={20} color="#3b82f6" /> {isAr ? "المسارات النشطة" : "Active Routes"}
                </h3>
                
                <div className="routes-list">
                  {routesLoading ? (
                    <p>{isAr ? "جاري التحميل..." : "Loading routes..."}</p>
                  ) : routes?.length === 0 ? (
                    <div className="empty-state-mini">{isAr ? "لا توجد مسارات" : "No routes defined."}</div>
                  ) : routes?.map((route: any) => (
                    <div key={route.id} className="luxury-stat-card" style={{ padding: "16px 20px", "--accent-color": "#3b82f6" } as any}>
                      <div className="l-stat-bg-blob"></div>
                      <div className="luxury-stat-inner">
                        <div className="route-header">
                          <div className="route-name">{route.name}</div>
                          <div className="route-bus-tag">Bus #{route.bus?.number || "?"}</div>
                        </div>
                        <div className="route-timeline" style={{ position: "relative" }}>
                          <div className="time-node">
                            <div className="node-icon"><Clock size={12} /></div>
                            <div className="node-content">
                              <div className="node-label">{isAr ? "وقت التجمع" : "Pickup"}</div>
                              <div className="node-time">{route.pickupTime || "07:30 AM"}</div>
                            </div>
                          </div>
                          <div className="time-node">
                            <div className="node-icon"><Clock size={12} /></div>
                            <div className="node-content">
                              <div className="node-label">{isAr ? "وقت العودة" : "Dropoff"}</div>
                              <div className="node-time">{route.dropoffTime || "03:15 PM"}</div>
                            </div>
                          </div>
                          
                          <button 
                            className="delete-icon-btn" 
                            style={{ 
                              position: "absolute", 
                              bottom: "-4px", 
                              left: isAr ? "-4px" : "auto", 
                              right: isAr ? "auto" : "-4px",
                              padding: "4px"
                            }}
                            onClick={() => {
                              if (confirm(isAr ? "حذف المسار؟" : "Delete route?")) {
                                deleteRouteMutation.mutate(route.id);
                              }
                            }}
                          >
                            <Trash2 size={16} />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Drivers Section */}
              <div className="drivers-section">
                <h3 style={{ fontSize: "20px", fontWeight: 800, marginBottom: "20px", display: "flex", alignItems: "center", gap: "10px", color: "var(--glass-text-primary)" }}>
                  <User size={20} color="#10b981" /> {isAr ? "طاقم السائقين" : "Driver Roster"}
                </h3>
                
                <div className="drivers-list" style={{ display: "grid", gap: "12px" }}>
                   {driversLoading ? (
                     <p>{isAr ? "جاري التحميل..." : "Loading drivers..."}</p>
                   ) : drivers?.length === 0 ? (
                     <div className="empty-state-mini">{isAr ? "لم يتم إضافة سواقين بعد" : "No drivers added."}</div>
                   ) : drivers?.map((driver: any) => (
                     <div key={driver.id} className="luxury-stat-card" style={{ padding: "12px 16px", "--accent-color": "#10b981" } as any}>
                        <div className="luxury-stat-inner">
                          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                             <div>
                               <div style={{ fontWeight: 800, color: "var(--glass-text-primary)" }}>{driver.name}</div>
                               <div style={{ fontSize: "11px", color: "var(--glass-text-muted)" }}>{driver.phone || "---"}</div>
                             </div>
                             <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
                                <span className={`badge-mini ${driver.bus ? 'active' : 'idle'}`}>
                                  {driver.bus ? `Bus #${driver.bus.number}` : (isAr ? "بدون باص" : "Idle")}
                                </span>
                             </div>
                          </div>
                        </div>
                     </div>
                   ))}
                </div>
              </div>

              <div className="safety-card card-glass" style={{ marginTop: "32px" }}>
                <ShieldCheck color="#10b981" size={24} />
                <div>
                  <h5>{isAr ? "تذكير السلامة" : "Safety Protocol"}</h5>
                  <p>{isAr ? "تأكد من مراجعة كشف حضور الطلاب قبل بدء كل رحلة." : "Verify student attendance logs before every departure."}</p>
                </div>
              </div>
            </div>
          </div>
        </>
      ) : (
        /* Attendance Tracker Tab Content */
        <div className="attendance-tracker-view fade-in">
          <style>{`
            @media print {
              .shell-sidebar, .shell-topbar, .module-header-row, .transport-module > div:first-of-type, .attendance-tracker-view > div:nth-of-type(2), .attendance-tracker-view button {
                display: none !important;
              }
              .dashboard, .shell-main, .transport-module, .attendance-tracker-view {
                background: transparent !important;
                padding: 0 !important;
                margin: 0 !important;
                border: none !important;
                box-shadow: none !important;
                color: #000 !important;
              }
              .card-glass {
                background: transparent !important;
                border: none !important;
                box-shadow: none !important;
                color: #000 !important;
              }
              .premium-table th {
                color: #000 !important;
                border-bottom: 2px solid #000 !important;
              }
              .premium-table td {
                color: #000 !important;
                border-bottom: 1px solid #ddd !important;
              }
            }
          `}</style>

          {/* Tracker Stats Banner */}
          <div className="module-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: "20px", marginBottom: "32px" }}>
            <div className="luxury-stat-card" style={{ "--accent-color": "#10b981" } as any}>
              <div className="l-stat-bg-blob"></div>
              <div className="luxury-stat-inner" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "12px", fontWeight: 700, textTransform: "uppercase" }}>{isAr ? "تم الركوب" : "Boarded"}</h4>
                  <div style={{ fontSize: "28px", fontWeight: 800, color: "#10b981", marginTop: "4px" }}>{trackerStats.boarded}</div>
                </div>
                <div style={{ padding: "10px", borderRadius: "12px", background: "rgba(16, 185, 129, 0.1)" }}>
                  <ShieldCheck color="#10b981" size={24} />
                </div>
              </div>
            </div>
            <div className="luxury-stat-card" style={{ "--accent-color": "#ef4444" } as any}>
              <div className="l-stat-bg-blob"></div>
              <div className="luxury-stat-inner" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "12px", fontWeight: 700, textTransform: "uppercase" }}>{isAr ? "غائب" : "Absent"}</h4>
                  <div style={{ fontSize: "28px", fontWeight: 800, color: "#ef4444", marginTop: "4px" }}>{trackerStats.absent}</div>
                </div>
                <div style={{ padding: "10px", borderRadius: "12px", background: "rgba(239, 68, 68, 0.1)" }}>
                  <AlertTriangle color="#ef4444" size={24} />
                </div>
              </div>
            </div>
            <div className="luxury-stat-card" style={{ "--accent-color": "#f59e0b" } as any}>
              <div className="l-stat-bg-blob"></div>
              <div className="luxury-stat-inner" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "12px", fontWeight: 700, textTransform: "uppercase" }}>{isAr ? "لم يسجل بعد" : "Unrecorded"}</h4>
                  <div style={{ fontSize: "28px", fontWeight: 800, color: "#f59e0b", marginTop: "4px" }}>{trackerStats.unrecorded}</div>
                </div>
                <div style={{ padding: "10px", borderRadius: "12px", background: "rgba(245, 158, 11, 0.1)" }}>
                  <Clock color="#f59e0b" size={24} />
                </div>
              </div>
            </div>
            <div className="luxury-stat-card" style={{ "--accent-color": "#3b82f6" } as any}>
              <div className="l-stat-bg-blob"></div>
              <div className="luxury-stat-inner" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "12px", fontWeight: 700, textTransform: "uppercase" }}>{isAr ? "إجمالي طلاب الباص" : "Total Students"}</h4>
                  <div style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)", marginTop: "4px" }}>{trackerStats.total}</div>
                </div>
                <div style={{ padding: "10px", borderRadius: "12px", background: "rgba(59, 130, 246, 0.1)" }}>
                  <Users color="#3b82f6" size={24} />
                </div>
              </div>
            </div>
          </div>

          {/* Filters Panel */}
          <div className="card-glass" style={{ padding: "24px", borderRadius: "16px", marginBottom: "32px", display: "flex", flexWrap: "wrap", gap: "16px", alignItems: "flex-end" }}>
            <div style={{ flex: "1 1 200px" }}>
              <label className="premium-label" style={{ marginBottom: "8px", display: "block" }}>{isAr ? "التاريخ" : "Date"}</label>
              <input 
                type="date"
                className="premium-input"
                value={attendanceDate}
                onChange={(e) => setAttendanceDate(e.target.value)}
              />
            </div>
            <div style={{ flex: "1 1 200px" }}>
              <label className="premium-label" style={{ marginBottom: "8px", display: "block" }}>{isAr ? "تصفية بالحافلة" : "Filter by Bus"}</label>
              <select 
                className="premium-input"
                value={filterBusId}
                onChange={(e) => setFilterBusId(e.target.value)}
              >
                <option value="">{isAr ? "جميع الحافلات" : "All Buses"}</option>
                {buses?.map((bus: any) => (
                  <option key={bus.id} value={bus.id}>{isAr ? `حافلة رقم ${bus.number}` : `Bus #${bus.number}`}</option>
                ))}
              </select>
            </div>
            <div style={{ flex: "1 1 200px" }}>
              <label className="premium-label" style={{ marginBottom: "8px", display: "block" }}>{isAr ? "الحالة" : "Status"}</label>
              <select 
                className="premium-input"
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                <option value="">{isAr ? "جميع الحالات" : "All Statuses"}</option>
                <option value="BOARDED">{isAr ? "ركب الباص" : "Boarded"}</option>
                <option value="ABSENT">{isAr ? "غائب" : "Absent"}</option>
                <option value="UNRECORDED">{isAr ? "لم يسجل بعد" : "Unrecorded"}</option>
              </select>
            </div>
            <div style={{ flex: "2 1 250px", position: "relative" }}>
              <label className="premium-label" style={{ marginBottom: "8px", display: "block" }}>{isAr ? "بحث باسم الطالب" : "Search Student"}</label>
              <div style={{ position: "relative" }}>
                <input 
                  type="text"
                  placeholder={isAr ? "اكتب اسم الطالب..." : "Type student name..."}
                  className="premium-input"
                  style={{ paddingRight: isAr ? "40px" : "12px", paddingLeft: isAr ? "12px" : "40px" }}
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
                <Search 
                  size={18} 
                  style={{ 
                    position: "absolute", 
                    top: "50%", 
                    transform: "translateY(-50%)", 
                    [isAr ? "right" : "left"]: "12px",
                    color: "var(--glass-text-muted)" 
                  }} 
                />
              </div>
            </div>
            <button 
              className="btn-premium-outline" 
              style={{ height: "46px", padding: "0 20px" }}
              onClick={() => window.print()}
            >
              {isAr ? "طباعة التقرير" : "Print Report"}
            </button>
          </div>

          {/* Table */}
          <div className="card-glass" style={{ overflow: "hidden", borderRadius: "16px" }}>
            <div style={{ overflowX: "auto" }}>
              <table className="premium-table" style={{ width: "100%", borderCollapse: "collapse", textAlign: isAr ? "right" : "left" }}>
                <thead>
                  <tr style={{ background: "rgba(255,255,255,0.03)", borderBottom: "1px solid var(--glass-border)" }}>
                    <th style={{ padding: "16px", fontWeight: 800, fontSize: "14px", color: "var(--glass-text-secondary)" }}>{isAr ? "الطالب" : "Student"}</th>
                    <th style={{ padding: "16px", fontWeight: 800, fontSize: "14px", color: "var(--glass-text-secondary)" }}>{isAr ? "الصف الدراسي" : "Grade & Class"}</th>
                    <th style={{ padding: "16px", fontWeight: 800, fontSize: "14px", color: "var(--glass-text-secondary)" }}>{isAr ? "الحافلة والمسار" : "Bus & Route"}</th>
                    <th style={{ padding: "16px", fontWeight: 800, fontSize: "14px", color: "var(--glass-text-secondary)" }}>{isAr ? "بواسطة المشرفة" : "Supervisor"}</th>
                    <th style={{ padding: "16px", fontWeight: 800, fontSize: "14px", color: "var(--glass-text-secondary)" }}>{isAr ? "وقت التسجيل" : "Recorded At"}</th>
                    <th style={{ padding: "16px", fontWeight: 800, fontSize: "14px", color: "var(--glass-text-secondary)" }}>{isAr ? "الحالة" : "Status"}</th>
                    <th style={{ padding: "16px", fontWeight: 800, fontSize: "14px", color: "var(--glass-text-secondary)" }}>{isAr ? "ملاحظات" : "Notes"}</th>
                  </tr>
                </thead>
                <tbody>
                  {studentsLoading ? (
                    <tr>
                      <td colSpan={7} style={{ padding: "60px 0", textAlign: "center" }}>
                        <div className="spinner-large" style={{ margin: "0 auto" }} />
                      </td>
                    </tr>
                  ) : filteredLogs.length === 0 ? (
                    <tr>
                      <td colSpan={7} style={{ padding: "60px 0", textAlign: "center", color: "var(--glass-text-muted)" }}>
                        {isAr ? "لا توجد سجلات مطابقة للتصفية" : "No attendance logs matching filters."}
                      </td>
                    </tr>
                  ) : (
                    filteredLogs.map((entry: any, index: number) => (
                      <tr key={index} style={{ borderBottom: "1px solid var(--glass-border)", transition: "background 0.2s" }}>
                        <td style={{ padding: "16px" }}>
                          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                            <div style={{ width: "32px", height: "32px", borderRadius: "50%", background: "var(--primary-glow)", color: "var(--primary-light)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "12px", fontWeight: 900 }}>
                              {entry.student.user?.fullName?.[0]?.toUpperCase() || 'S'}
                            </div>
                            <div>
                              <div style={{ fontWeight: 800, color: "var(--glass-text-primary)" }}>
                                {isAr ? (entry.student.nameAr || entry.student.user?.fullName) : (entry.student.nameEn || entry.student.user?.fullName)}
                              </div>
                              <div style={{ fontSize: "11px", color: "var(--glass-text-muted)" }}>{entry.student.user?.email}</div>
                            </div>
                          </div>
                        </td>
                        <td style={{ padding: "16px", color: "var(--glass-text-primary)", fontWeight: 600 }}>
                          {entry.student.grade?.name || "---"} - {entry.student.class?.name || "---"}
                        </td>
                        <td style={{ padding: "16px" }}>
                          <div style={{ fontWeight: 700, color: "var(--glass-text-primary)" }}>
                            {entry.busNumber !== "---" ? (isAr ? `باص #${entry.busNumber}` : `Bus #${entry.busNumber}`) : "---"}
                          </div>
                          <div style={{ fontSize: "11px", color: "var(--glass-text-muted)" }}>{entry.route}</div>
                        </td>
                        <td style={{ padding: "16px", color: "var(--glass-text-secondary)", fontWeight: 600 }}>
                          {entry.recordedBy}
                        </td>
                        <td style={{ padding: "16px", color: "var(--glass-text-secondary)", fontWeight: 600 }}>
                          {entry.recordedAt}
                        </td>
                        <td style={{ padding: "16px" }}>
                          <span className={`status-pill ${entry.status.toLowerCase()}`} style={{
                            display: "inline-flex",
                            padding: "4px 10px",
                            borderRadius: "8px",
                            fontSize: "11px",
                            fontWeight: 800,
                            textTransform: "uppercase",
                            background: entry.status === "BOARDED" ? "rgba(16, 185, 129, 0.12)" : entry.status === "ABSENT" ? "rgba(239, 68, 68, 0.12)" : "rgba(245, 158, 11, 0.12)",
                            color: entry.status === "BOARDED" ? "#10b981" : entry.status === "ABSENT" ? "#ef4444" : "#f59e0b",
                            border: entry.status === "BOARDED" ? "1px solid rgba(16, 185, 129, 0.2)" : entry.status === "ABSENT" ? "1px solid rgba(239, 68, 68, 0.2)" : "1px solid rgba(245, 158, 11, 0.2)"
                          }}>
                            {entry.status === "BOARDED" ? (isAr ? "ركب الباص" : "Boarded") : entry.status === "ABSENT" ? (isAr ? "غائب" : "Absent") : (isAr ? "لم يسجل بعد" : "Unrecorded")}
                          </span>
                        </td>
                        <td style={{ padding: "16px", color: "var(--glass-text-secondary)", fontSize: "12px", maxWidth: "200px", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }} title={entry.notes}>
                          {entry.notes || "---"}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Bus Modal */}
      <Modal
        isOpen={isBusModalOpen}
        onClose={() => setIsBusModalOpen(false)}
        title={isAr ? "إضافة حافلة جديدة" : "Add New Bus"}
        footer={
          <div style={{ display: "flex", gap: "12px", justifyContent: "flex-end", width: "100%" }}>
            <button className="btn-cancel" onClick={() => setIsBusModalOpen(false)}>{isAr ? "إلغاء" : "Cancel"}</button>
            <button 
              className="btn-submit-premium" 
              onClick={() => busMutation.mutate(busForm)}
              disabled={busMutation.isPending || !busForm.number}
            >
              <Bus size={18} />
              <span>{busMutation.isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "حفظ الحافلة" : "Save Bus")}</span>
            </button>
          </div>
        }
      >
        <div className="form-content">
           <div className="form-group">
             <label className="premium-label">{isAr ? "رقم الحافلة" : "Bus Number"}</label>
             <input 
               className="premium-input" 
               placeholder="e.g. 101" 
               value={busForm.number}
               onChange={e => setBusForm({...busForm, number: e.target.value})}
             />
           </div>
           <div className="form-group">
             <label className="premium-label">{isAr ? "رقم اللوحة" : "Plate Number"}</label>
             <input 
               className="premium-input" 
               placeholder="ABC-123" 
               value={busForm.plateNumber}
               onChange={e => setBusForm({...busForm, plateNumber: e.target.value})}
             />
           </div>
           <div className="form-group">
             <label className="premium-label">{isAr ? "السائق المخصص" : "Assigned Driver"}</label>
             <select 
               className="premium-select"
               value={busForm.driverId}
               onChange={e => setBusForm({...busForm, driverId: e.target.value})}
             >
               <option value="">{isAr ? "اختر سواق" : "Select a driver"}</option>
               {drivers?.map((d: any) => (
                 <option key={d.id} value={d.id}>{d.name} {d.bus ? `(Has Bus #${d.bus.number})` : ""}</option>
               ))}
             </select>
           </div>
           <div className="form-group">
             <label className="premium-label">{isAr ? "المشرفة المخصصة" : "Assigned Supervisor"}</label>
             <select 
               className="premium-select"
               value={busForm.supervisorId}
               onChange={e => setBusForm({...busForm, supervisorId: e.target.value})}
             >
               <option value="">{isAr ? "اختر مشرفة" : "Select a supervisor"}</option>
               {supervisors?.map((s: any) => (
                 <option key={s.id} value={s.id}>{s.name} {s.bus ? `(Has Bus #${s.bus.number})` : ""}</option>
               ))}
             </select>
           </div>
           <div className="form-group">
             <label className="premium-label">{isAr ? "السعة (طلاب)" : "Capacity (Students)"}</label>
             <input 
               type="number"
               className="premium-input" 
               value={busForm.capacity}
               onChange={e => setBusForm({...busForm, capacity: parseInt(e.target.value) || 0})}
             />
           </div>
        </div>
      </Modal>


      {/* Student Association Modal */}
      <Modal
        isOpen={isStudentModalOpen}
        onClose={() => setIsStudentModalOpen(false)}
        title={isAr ? `تخصيص الطلاب للباص #${selectedBusForStudents?.number}` : `Assign Students to Bus #${selectedBusForStudents?.number}`}
        footer={
          <div style={{ display: "flex", gap: "12px", justifyContent: "flex-end", width: "100%" }}>
            <button className="btn-cancel" onClick={() => setIsStudentModalOpen(false)}>{isAr ? "إلغاء" : "Cancel"}</button>
            <button 
              className="btn-submit-premium" 
              onClick={() => assignStudentsMutation.mutate({ busId: selectedBusForStudents?.id, studentIds: selectedStudentIds })}
              disabled={assignStudentsMutation.isPending}
            >
              <Users size={18} />
              <span>{assignStudentsMutation.isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "حفظ التخصيص" : "Save Assignments")}</span>
            </button>
          </div>
        }
      >
        <div className="form-content">
          <div className="form-group">
            <label className="premium-label">{isAr ? "بحث عن طالب" : "Search Student"}</label>
            <input 
              className="premium-input" 
              placeholder={isAr ? "اكتب اسم الطالب..." : "Type student name..."}
              value={studentSearch}
              onChange={e => setStudentSearch(e.target.value)}
            />
          </div>

          <div style={{ maxHeight: '300px', overflowY: 'auto', paddingRight: '8px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {studentsLoading ? (
              <p>{isAr ? "جاري تحميل الطلاب..." : "Loading students..."}</p>
            ) : transportStudents?.filter((s: any) => {
              const name = (s.nameAr || s.user?.fullName || "").toLowerCase();
              return name.includes(studentSearch.toLowerCase());
            }).map((s: any) => {
              const isAssigned = selectedStudentIds.includes(s.id);
              const otherBusNum = s.busAssignment?.bus && s.busAssignment.bus.id !== selectedBusForStudents?.id ? s.busAssignment.bus.number : null;

              return (
                <div 
                  key={s.id} 
                  style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'space-between', 
                    padding: '10px 14px', 
                    background: isAssigned ? 'rgba(59, 130, 246, 0.08)' : 'rgba(255,255,255,0.02)', 
                    borderRadius: '10px', 
                    border: isAssigned ? '1px solid rgba(59, 130, 246, 0.3)' : '1px solid var(--glass-border)',
                    cursor: 'pointer'
                  }}
                  onClick={() => {
                    if (isAssigned) {
                      setSelectedStudentIds(selectedStudentIds.filter(id => id !== s.id));
                    } else {
                      setSelectedStudentIds([...selectedStudentIds, s.id]);
                    }
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <input 
                      type="checkbox" 
                      checked={isAssigned}
                      readOnly
                      style={{ cursor: 'pointer' }}
                    />
                    <div>
                      <div style={{ fontWeight: 800, color: 'var(--glass-text-primary)', fontSize: '13px' }}>
                        {isAr ? (s.nameAr || s.user?.fullName) : (s.nameEn || s.user?.fullName)}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--glass-text-muted)', marginTop: '2px' }}>
                        {s.grade?.name || ""} - {s.class?.name || ""}
                      </div>
                    </div>
                  </div>
                  {otherBusNum && (
                    <span style={{ fontSize: '10px', background: 'rgba(245, 158, 11, 0.1)', color: '#f59e0b', padding: '2px 8px', borderRadius: '4px', fontWeight: 700 }}>
                      {isAr ? `في باص #${otherBusNum}` : `On Bus #${otherBusNum}`}
                    </span>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </Modal>

      {/* Route Modal */}
      <Modal
        isOpen={isRouteModalOpen}
        onClose={() => setIsRouteModalOpen(false)}
        title={isAr ? "إنشاء مسار جديد" : "Create New Route"}
        footer={
          <div style={{ display: "flex", gap: "12px", justifyContent: "flex-end", width: "100%" }}>
            <button className="btn-cancel" onClick={() => setIsRouteModalOpen(false)}>{isAr ? "إلغاء" : "Cancel"}</button>
            <button 
              className="btn-submit-premium" 
              onClick={() => routeMutation.mutate(routeForm)}
              disabled={routeMutation.isPending || !routeForm.name}
            >
              <MapPin size={18} />
              <span>{routeMutation.isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "حفظ المسار" : "Save Route")}</span>
            </button>
          </div>
        }
      >
        <div className="form-content">
           <div className="form-group">
             <label className="premium-label">{isAr ? "اسم المسار" : "Route Name"}</label>
             <input 
               className="premium-input" 
               placeholder={isAr ? "مثال: حي المعادي" : "e.g. Maadi District"} 
               value={routeForm.name}
               onChange={e => setRouteForm({...routeForm, name: e.target.value})}
             />
           </div>
           <div className="form-group">
             <label className="premium-label">{isAr ? "الحافلة المخصصة" : "Assigned Bus"}</label>
             <select 
               className="premium-select"
               value={routeForm.busId}
               onChange={e => setRouteForm({...routeForm, busId: e.target.value})}
             >
               <option value="">{isAr ? "اختر حافلة" : "Select a bus"}</option>
               {buses?.map((b: any) => (
                 <option key={b.id} value={b.id}>Bus #{b.number}</option>
               ))}
             </select>
           </div>
           <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
              <div className="form-group">
                <label className="premium-label">{isAr ? "وقت التجمع" : "Pickup Time"}</label>
                <input 
                  type="time"
                  className="premium-input" 
                  value={routeForm.pickupTime}
                  onChange={e => setRouteForm({...routeForm, pickupTime: e.target.value})}
                />
              </div>
              <div className="form-group">
                <label className="premium-label">{isAr ? "وقت العودة" : "Dropoff Time"}</label>
                <input 
                  type="time"
                  className="premium-input" 
                  value={routeForm.dropoffTime}
                  onChange={e => setRouteForm({...routeForm, dropoffTime: e.target.value})}
                />
              </div>
           </div>
        </div>
      </Modal>

      {/* Student Bus Attendance Logs Modal */}
      <Modal
        isOpen={isLogsModalOpen}
        onClose={() => setIsLogsModalOpen(false)}
        title={isAr ? `سجل حضور الباص — ${selectedStudentForLogs?.nameAr || selectedStudentForLogs?.user?.fullName || ""}` : `Bus Attendance Log — ${selectedStudentForLogs?.nameEn || selectedStudentForLogs?.user?.fullName || ""}`}
        footer={
          <div style={{ display: "flex", justifyContent: "flex-end", width: "100%" }}>
            <button className="btn-cancel" onClick={() => setIsLogsModalOpen(false)}>{isAr ? "إغلاق" : "Close"}</button>
          </div>
        }
      >
        <div className="form-content" style={{ padding: '4px' }}>
          {/* Quick Stats Summary Banner */}
          <div style={{ padding: '16px', background: 'rgba(255,255,255,0.02)', borderRadius: '12px', border: '1px solid var(--glass-border)', marginBottom: '20px' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', textAlign: 'center' }}>
              <div style={{ padding: '12px', background: 'rgba(16, 185, 129, 0.08)', border: '1px solid rgba(16, 185, 129, 0.2)', borderRadius: '10px' }}>
                <div style={{ fontSize: '24px', fontWeight: 900, color: '#10b981' }}>
                  {selectedStudentForLogs?.BusAttendance?.filter((a: any) => a.status === 'BOARDED').length || 0}
                </div>
                <div style={{ fontSize: '11px', color: 'var(--glass-text-secondary)', marginTop: '4px', fontWeight: 700 }}>
                  {isAr ? "مرات الركوب 🚌" : "Times Boarded"}
                </div>
              </div>
              <div style={{ padding: '12px', background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.2)', borderRadius: '10px' }}>
                <div style={{ fontSize: '24px', fontWeight: 900, color: '#ef4444' }}>
                  {selectedStudentForLogs?.BusAttendance?.filter((a: any) => a.status === 'ABSENT').length || 0}
                </div>
                <div style={{ fontSize: '11px', color: 'var(--glass-text-secondary)', marginTop: '4px', fontWeight: 700 }}>
                  {isAr ? "مرات الغياب 🔴" : "Times Absent"}
                </div>
              </div>
            </div>
          </div>

          <h4 style={{ fontSize: '13px', fontWeight: 800, color: 'var(--glass-text-primary)', marginBottom: '12px' }}>
            {isAr ? "التواريخ والسجلات التفصيلية:" : "Detailed History Logs:"}
          </h4>

          <div style={{ maxHeight: '250px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '10px', paddingRight: '4px' }}>
            {!selectedStudentForLogs?.BusAttendance || selectedStudentForLogs.BusAttendance.length === 0 ? (
              <div style={{ padding: '30px', textAlign: 'center', color: 'var(--glass-text-muted)', fontSize: '12px' }}>
                {isAr ? "لا يوجد سجل حضور وغياب مسجل لهذا الطالب بعد." : "No attendance logs recorded yet."}
              </div>
            ) : (
              selectedStudentForLogs.BusAttendance.map((log: any) => {
                const logDate = new Date(log.date).toLocaleDateString(isAr ? 'ar-EG' : 'en-US', {
                  weekday: 'long',
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                });
                const isBoarded = log.status === 'BOARDED';
                return (
                  <div 
                    key={log.id} 
                    style={{ 
                      display: 'flex', 
                      alignItems: 'center', 
                      justifyContent: 'space-between', 
                      padding: '10px 14px', 
                      background: 'rgba(255,255,255,0.01)', 
                      borderRadius: '10px', 
                      border: '1px solid var(--glass-border)' 
                    }}
                  >
                    <div>
                      <div style={{ fontWeight: 700, color: 'var(--glass-text-primary)', fontSize: '12px' }}>
                        {logDate}
                      </div>
                      {log.notes && (
                        <div style={{ fontSize: '10px', color: 'var(--glass-text-muted)', marginTop: '4px' }}>
                          {isAr ? `ملاحظات: ${log.notes}` : `Notes: ${log.notes}`}
                        </div>
                      )}
                    </div>
                    <span 
                      style={{ 
                        fontSize: '10px', 
                        fontWeight: 800, 
                        padding: '3px 8px', 
                        borderRadius: '20px', 
                        background: isBoarded ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)', 
                        color: isBoarded ? '#10b981' : '#ef4444',
                        border: isBoarded ? '1px solid rgba(16, 185, 129, 0.15)' : '1px solid rgba(239, 68, 68, 0.15)'
                      }}
                    >
                      {isBoarded ? (isAr ? "ركب الباص 🚌" : "Boarded") : (isAr ? "غائب 🔴" : "Absent")}
                    </span>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </Modal>

      <style jsx>{`
        .transport-grid {
          display: grid;
          grid-template-columns: 1.4fr 1fr;
          gap: 32px;
        }
        .buses-list, .routes-list {
          display: flex;
          flex-direction: column;
          gap: 16px;
        }
        .bus-card {
          padding: 24px;
          border: 1px solid var(--glass-border);
          transition: 0.3s;
        }
        .bus-card:hover {
          transform: translateY(-4px);
          border-color: var(--primary-light);
        }
        .bus-card-main {
          display: flex;
          gap: 24px;
          align-items: center;
        }
        .bus-avatar-box {
          width: 70px;
          height: 70px;
          border-radius: 18px;
          background: rgba(255,255,255,0.05);
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          color: var(--glass-text-primary);
          border: 1px solid var(--glass-border);
        }
        .bus-num {
          font-size: 11px;
          font-weight: 800;
          margin-top: 4px;
          color: var(--glass-text-muted);
        }
        .bus-info {
          flex: 1;
        }
        .bus-title {
          font-size: 18px;
          font-weight: 800;
          color: var(--glass-text-primary);
        }
        .status-tag {
          font-size: 9px;
          font-weight: 900;
          padding: 2px 8px;
          border-radius: 6px;
          text-transform: uppercase;
        }
        .status-tag.active { background: rgba(16, 185, 129, 0.1); color: #10b981; }
        .status-tag.maintenance { background: rgba(245, 158, 11, 0.1); color: #f59e0b; }
        .bus-meta {
          display: flex;
          gap: 16px;
          margin-top: 6px;
          font-size: 12px;
          color: var(--glass-text-muted);
        }
        .meta-item { display: flex; alignItems: center; gap: 4px; }
        .capacity-bar-container {
          margin-top: 16px;
        }
        .capacity-label {
          display: flex;
          justify-content: space-between;
          font-size: 11px;
          font-weight: 700;
          color: var(--glass-text-secondary);
          margin-bottom: 6px;
        }
        .progress-bg {
          height: 6px;
          background: rgba(255,255,255,0.05);
          border-radius: 3px;
          overflow: hidden;
        }
        .progress-fill {
          height: 100%;
          background: var(--gradient-primary);
          border-radius: 3px;
        }
        .bus-actions {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }
        .trip-btn {
          padding: 10px 16px;
          border-radius: 10px;
          border: none;
          font-weight: 700;
          font-size: 13px;
          display: flex;
          align-items: center;
          gap: 8px;
          cursor: pointer;
          transition: 0.2s;
        }
        .trip-btn.start { background: rgba(16, 185, 129, 0.1); color: #10b981; }
        .trip-btn.start:hover { background: #10b981; color: #fff; }
        .trip-btn.stop { background: rgba(239, 68, 68, 0.1); color: #ef4444; }
        .trip-btn.stop:hover { background: #ef4444; color: #fff; }
        .settings-btn {
          width: 100%;
          padding: 8px;
          background: transparent;
          border: 1px solid var(--glass-border);
          border-radius: 8px;
          color: var(--glass-text-muted);
          cursor: pointer;
        }
        .live-indicator {
          display: flex;
          align-items: center;
          gap: 6px;
          font-size: 11px;
          font-weight: 900;
          color: #ef4444;
          background: rgba(239, 68, 68, 0.1);
          padding: 4px 10px;
          border-radius: 20px;
        }
        .live-indicator .dot {
          width: 6px;
          height: 6px;
          background: #ef4444;
          border-radius: 50%;
          animation: blink 1.5s infinite;
        }
        @keyframes blink { 0% { opacity: 0.2; } 50% { opacity: 1; } 100% { opacity: 0.2; } }
        
        .route-card {
          padding: 16px 20px;
          border: 1px solid var(--glass-border);
        }
        .route-header {
          display: flex;
          justify-content: space-between;
          margin-bottom: 16px;
        }
        .route-name { font-weight: 800; color: var(--glass-text-primary); }
        .route-bus-tag { font-size: 11px; font-weight: 700; color: #3b82f6; background: rgba(59, 130, 246, 0.1); padding: 2px 8px; border-radius: 6px; }
        .route-timeline { display: flex; gap: 24px; }
        .time-node { display: flex; gap: 10px; align-items: center; }
        .node-icon { color: var(--glass-text-muted); }
        .node-label { font-size: 10px; color: var(--glass-text-muted); text-transform: uppercase; font-weight: 700; }
        .node-time { font-size: 14px; font-weight: 800; color: var(--glass-text-primary); }
        
        .driver-mini-card { padding: 12px 16px; border: 1px solid var(--glass-border); }
        .badge-mini { font-size: 10px; font-weight: 800; padding: 2px 8px; border-radius: 4px; }
        .badge-mini.active { background: rgba(59, 130, 246, 0.1); color: #3b82f6; }
        .badge-mini.idle { background: rgba(255,255,255,0.05); color: var(--glass-text-muted); }
        .delete-icon-btn { background: transparent; border: none; color: #ef4444; opacity: 0.4; cursor: pointer; transition: 0.2s; }
        .delete-icon-btn:hover { opacity: 1; transform: scale(1.1); }

        .safety-card {
          margin-top: 32px;
          padding: 20px;
          display: flex;
          gap: 16px;
          border-left: 4px solid #10b981;
          background: rgba(16, 185, 129, 0.03);
        }
        .safety-card h5 { color: #10b981; font-weight: 800; margin-bottom: 4px; }
        .safety-card p { font-size: 12px; color: var(--glass-text-muted); line-height: 1.5; }

        .btn-premium-primary {
          background: var(--gradient-primary);
          color: #fff; border: none; padding: 12px 24px; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 8px; cursor: pointer; box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
        }
        .btn-premium-outline {
          background: transparent; border: 1px solid var(--glass-border); padding: 12px 24px; border-radius: 12px; color: var(--glass-text-primary); font-weight: 700; display: flex; align-items: center; gap: 8px; cursor: pointer;
        }
        .form-content { display: flex; flex-direction: column; gap: 20px; }
        .premium-label { display: block; font-size: 13px; font-weight: 700; color: var(--glass-text-secondary); margin-bottom: 8px; }
        .premium-input, .premium-select {
          width: 100%; background: rgba(0,0,0,0.02); border: 1px solid var(--glass-border); border-radius: 12px; padding: 12px 16px; color: var(--glass-text-primary); outline: none; transition: 0.3s;
        }
        .btn-submit-premium {
          background: var(--gradient-primary); color: #fff; border: none; padding: 12px 24px; border-radius: 12px; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 8px;
        }
        .btn-cancel { background: transparent; border: 1px solid var(--glass-border); padding: 10px 20px; border-radius: 10px; color: var(--glass-text-secondary); font-weight: 600; cursor: pointer; }

        @media (max-width: 1024px) {
          .transport-grid { grid-template-columns: 1fr; }
        }
      `}</style>
    </div>
  );
}

