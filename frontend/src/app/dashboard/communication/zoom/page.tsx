"use client";

import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { api, extractApiError } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { 
  Video, 
  Users, 
  User, 
  Settings, 
  Plus, 
  Calendar, 
  Clock, 
  ShieldCheck,
  CheckCircle2,
  ChevronRight,
  Monitor,
  Camera,
  Mic,
  ArrowRight,
  ExternalLink,
  Loader2,
  Trash2,
  Search
} from "lucide-react";

export default function ZoomPage() {
  const { t, isAr } = useTranslation();
  const [targetType, setTargetType] = useState<"all_parents" | "all_teachers" | "specific">("all_parents");
  const [targetIds, setTargetIds] = useState<string[]>([]);
  const [meetingTopic, setMeetingTopic] = useState("");
  const [duration, setDuration] = useState(40);
  const [createdMeeting, setCreatedMeeting] = useState<any>(null);
  const [searchQuery, setSearchQuery] = useState("");

  const { data: settings } = useQuery({
    queryKey: ["school-settings"],
    queryFn: async () => (await api.get("/settings")).data.data
  });

  const { data: meetings, isLoading: meetingsLoading, error: zoomError, refetch: refetchMeetings } = useQuery({
    queryKey: ["zoom-meetings"],
    queryFn: async () => (await api.get("/zoom/meetings")).data.data,
    enabled: !!settings?.zoomEnabled,
    retry: false
  });

  // Fetch users for specific selection
  const { data: usersList } = useQuery({
    queryKey: ["users-search", searchQuery],
    queryFn: async () => (await api.get(`/users?search=${searchQuery}`)).data.data,
    enabled: targetType === "specific" && searchQuery.length > 2
  });

  const createMutation = useMutation({
    mutationFn: async (payload: any) => {
      const res = await api.post("/zoom/meetings", payload);
      return res.data.data;
    },
    onSuccess: (data) => {
      setCreatedMeeting(data);
      refetchMeetings(); // Refresh the list automatically
      setMeetingTopic(""); // Clear topic
      setTargetIds([]); // Clear selection
      alert(isAr ? "تم إنشاء الاجتماع وإرسال التنبيهات!" : "Meeting created and notifications sent!");
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (meetingId: string | number) => {
      await api.delete(`/zoom/meetings/${meetingId}`);
    },
    onSuccess: () => {
      window.location.reload();
    }
  });

  const handleStart = () => {
    if (!meetingTopic) return alert(isAr ? "يرجى إدخال عنوان الاجتماع" : "Please enter a meeting topic");
    if (targetType === "specific" && targetIds.length === 0) return alert(isAr ? "يرجى اختيار شخص واحد على الأقل" : "Please select at least one person");
    
    createMutation.mutate({
      topic: meetingTopic,
      duration: duration,
      agenda: `Meeting for ${targetType.replace("_", " ")}`,
      startTime: new Date().toISOString(),
      targetType,
      targetIds
    });
  };

  if (settings && !settings.zoomEnabled) {
    return (
      <div className="card-glass" style={{ padding: "40px", textAlign: "center", maxWidth: "600px", margin: "100px auto" }}>
        <div style={{ width: "80px", height: "80px", borderRadius: "20px", background: "rgba(248,113,113,0.1)", color: "#f87171", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 24px" }}>
          <Video size={40} />
        </div>
        <h2 style={{ fontSize: "24px", fontWeight: 800, color: "var(--glass-text-primary)", marginBottom: "12px" }}>
          {isAr ? "خدمة Zoom غير مفعلة" : "Zoom Service Not Enabled"}
        </h2>
        <p style={{ color: "var(--glass-text-secondary)", marginBottom: "32px", lineHeight: 1.6 }}>
          {isAr ? "يرجى تفعيل خدمة Zoom وإدخال بيانات الـ API في صفحة الإعدادات لتتمكن من بدء الاجتماعات." : "Please enable Zoom service and enter API credentials in the Settings page to start meetings."}
        </p>
        <a href="/dashboard/settings" className="btn-glass" style={{ display: "inline-flex", alignItems: "center", gap: "8px", padding: "12px 24px", background: "var(--gradient-primary)", color: "#fff", borderRadius: "12px", textDecoration: "none", fontWeight: 700 }}>
          <Settings size={18} /> {isAr ? "انتقل للإعدادات" : "Go to Settings"}
        </a>
      </div>
    );
  }

  return (
    <div className="zoom-module fade-in" style={{ height: "100%", display: "flex", flexDirection: "column", gap: "32px" }}>
      {/* Header Section */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: "12px", marginBottom: "8px" }}>
            <div style={{ 
              width: "44px", 
              height: "44px", 
              background: "linear-gradient(135deg, #2D8CFF 0%, #0E5EAD 100%)", 
              borderRadius: "12px", 
              display: "flex", 
              alignItems: "center", 
              justifyContent: "center", 
              color: "#fff",
              boxShadow: "0 10px 20px rgba(45, 140, 255, 0.3), inset 0 0 10px rgba(255,255,255,0.2)",
              border: "1px solid rgba(255, 255, 255, 0.15)",
              position: "relative"
            }}>
              <Video size={22} fill="rgba(255, 255, 255, 0.2)" />
            </div>
            <h2 style={{ fontSize: "28px", fontWeight: 900, color: "var(--glass-text-primary)" }}>
              {isAr ? "اجتماعات زووم الذكية" : "Smart Zoom Meetings"}
            </h2>
          </div>
          <p style={{ color: "var(--glass-text-secondary)" }}>{isAr ? "ابدأ اجتماعات فورية مع أولياء الأمور أو الموظفين" : "Start instant meetings with parents or staff members"}</p>
        </div>

        <div style={{ display: "flex", gap: "12px" }}>
           <div style={{ padding: "10px 16px", background: "rgba(45, 140, 255, 0.1)", border: "1px solid rgba(45, 140, 255, 0.2)", borderRadius: "12px", display: "flex", alignItems: "center", gap: "8px", color: "#2D8CFF", fontWeight: 700, fontSize: "13px" }}>
             <ShieldCheck size={16} /> Enterprise Secure
           </div>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 380px", gap: "32px", flex: 1 }}>
        {/* Main Interface */}
        <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
          
          {/* Zoom Visual Card */}
          <div className="card-glass" style={{ 
            height: "300px", 
            background: "linear-gradient(135deg, #2D8CFF 0%, #0E5EAD 100%) !important", 
            backgroundColor: "#2D8CFF",
            borderRadius: "24px",
            position: "relative",
            overflow: "hidden",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#fff",
            boxShadow: "0 20px 40px rgba(45, 140, 255, 0.3)",
            border: "none"
          }}>
            {/* Background Layer to force color if card-glass overrides it */}
            <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, #2D8CFF 0%, #0E5EAD 100%)", zIndex: 0 }}></div>

            {/* Pattern with better visibility in both modes */}
            <div style={{ 
              position: "absolute", 
              inset: 0, 
              opacity: 0.15, 
              backgroundImage: "radial-gradient(circle at 2px 2px, rgba(255,255,255,0.8) 1px, transparent 0)", 
              backgroundSize: "24px 24px" 
            }}></div>
            
            {/* Decorative Gradients for depth */}
            <div style={{ position: "absolute", top: "-50px", right: "-50px", width: "200px", height: "200px", background: "rgba(255,255,255,0.1)", filter: "blur(50px)", borderRadius: "50%" }}></div>
            <div style={{ position: "absolute", bottom: "-50px", left: "-50px", width: "200px", height: "200px", background: "rgba(0,0,0,0.2)", filter: "blur(50px)", borderRadius: "50%" }}></div>

            <div style={{ textAlign: "center", zIndex: 1 }}>
              <div style={{ 
                width: "110px", 
                height: "110px", 
                background: "rgba(255,255,255,0.15)", 
                borderRadius: "32px", 
                display: "flex", 
                alignItems: "center", 
                justifyContent: "center", 
                margin: "0 auto 8px", 
                backdropFilter: "blur(12px)", 
                border: "1px solid rgba(255,255,255,0.3)",
                boxShadow: "0 10px 20px rgba(0,0,0,0.1)"
              }}>
                <Video size={54} fill="currentColor" />
              </div>
              <h3 style={{ fontSize: "24px", fontWeight: 800, letterSpacing: "-0.5px", textShadow: "0 2px 10px rgba(0,0,0,0.2)" }}>Zoom Pro</h3>
            </div>

            {/* Micro Controls Mockup */}
            <div style={{ position: "absolute", bottom: "20px", left: "50%", transform: "translateX(-50%)", display: "flex", gap: "12px", background: "rgba(0,0,0,0.3)", padding: "10px 20px", borderRadius: "100px", backdropFilter: "blur(10px)" }}>
              <div style={controlIconStyle}><Mic size={18} /></div>
              <div style={controlIconStyle}><Camera size={18} /></div>
              <div style={controlIconStyle}><Monitor size={18} /></div>
              <div style={{ ...controlIconStyle, background: "#FF3B30", color: "#fff" }}><Users size={18} /></div>
            </div>
          </div>

          {/* Action Area */}
          <div className="card-glass" style={{ padding: "32px", flex: 1, display: "flex", flexDirection: "column", gap: "32px" }}>
            <div>
              <h4 style={sectionHeaderStyle}>{isAr ? "1. حدد الجمهور المستهدف" : "1. Select Target Audience"}</h4>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "16px", marginTop: "16px" }}>
                <button 
                  onClick={() => { setTargetType("all_parents"); setTargetIds([]); }}
                  style={audienceButtonStyle(targetType === "all_parents", "#6366f1")}
                >
                  <Users size={24} />
                  <div>
                    <p style={{ fontWeight: 800 }}>{isAr ? "كل أولياء الأمور" : "All Parents"}</p>
                    <p style={{ fontSize: "11px", opacity: 0.7 }}>Broadcast to entire family database</p>
                  </div>
                </button>
                <button 
                  onClick={() => { setTargetType("all_teachers"); setTargetIds([]); }}
                  style={audienceButtonStyle(targetType === "all_teachers", "#10b981")}
                >
                  <ShieldCheck size={24} />
                  <div>
                    <p style={{ fontWeight: 800 }}>{isAr ? "كل المعلمين" : "All Teachers"}</p>
                    <p style={{ fontSize: "11px", opacity: 0.7 }}>Staff-wide virtual meeting</p>
                  </div>
                </button>
                <button 
                  onClick={() => setTargetType("specific")}
                  style={audienceButtonStyle(targetType === "specific", "#f59e0b")}
                >
                  <User size={24} />
                  <div>
                    <p style={{ fontWeight: 800 }}>{isAr ? "تحديد مخصص" : "Specific People"}</p>
                    <p style={{ fontSize: "11px", opacity: 0.7 }}>One-on-one or group select</p>
                  </div>
                </button>
              </div>

              {/* Specific Selection UI */}
              {targetType === "specific" && (
                <div style={{ marginTop: "20px", padding: "16px", background: "rgba(0,0,0,0.05)", borderRadius: "16px" }}>
                  <div style={{ position: "relative" }}>
                    <Search size={18} style={{ position: "absolute", left: "12px", top: "50%", transform: "translateY(-50%)", color: "var(--glass-text-muted)" }} />
                    <input 
                      type="text"
                      placeholder={isAr ? "ابحث عن اسم الشخص..." : "Search for person..."}
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      style={{ ...inputStyle, paddingLeft: "40px" }}
                    />
                  </div>
                  
                  {/* Selected Tags */}
                  <div style={{ display: "flex", flexWrap: "wrap", gap: "8px", marginTop: "12px" }}>
                    {targetIds.map(id => {
                      const user = usersList?.find((u: any) => u.id === id);
                      return (
                        <div key={id} style={{ padding: "4px 10px", background: "var(--gradient-primary)", color: "#fff", borderRadius: "8px", fontSize: "12px", display: "flex", alignItems: "center", gap: "6px" }}>
                          {user?.fullName || id}
                          <button onClick={() => setTargetIds(targetIds.filter(i => i !== id))} style={{ border: "none", background: "none", color: "#fff", cursor: "pointer" }}>×</button>
                        </div>
                      )
                    })}
                  </div>

                  {/* Search Results */}
                  {usersList && usersList.length > 0 && (
                    <div style={{ marginTop: "10px", maxHeight: "150px", overflowY: "auto", background: "var(--glass-surface)", borderRadius: "10px", border: "1px solid var(--glass-border)" }}>
                      {usersList.map((user: any) => (
                        <div 
                          key={user.id} 
                          onClick={() => {
                            if (!targetIds.includes(user.id)) setTargetIds([...targetIds, user.id]);
                            setSearchQuery("");
                          }}
                          style={{ padding: "10px 16px", cursor: "pointer", borderBottom: "1px solid var(--glass-divider)", display: "flex", justifyContent: "space-between" }}
                        >
                          <span style={{ fontSize: "13px", fontWeight: 600 }}>{user.fullName}</span>
                          <span style={{ fontSize: "11px", opacity: 0.6 }}>{user.role}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>

            <div>
              <h4 style={sectionHeaderStyle}>{isAr ? "2. تفاصيل الاجتماع" : "2. Meeting Details"}</h4>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 200px", gap: "20px", marginTop: "16px" }}>
                <div className="field-group">
                  <label style={labelStyle}>{isAr ? "عنوان الاجتماع" : "Meeting Topic"}</label>
                  <input 
                    type="text" 
                    value={meetingTopic}
                    onChange={(e) => setMeetingTopic(e.target.value)}
                    style={inputStyle} 
                    placeholder={isAr ? "مثلاً: اجتماع مجلس الآباء الدوري" : "e.g. Monthly Parents Council"}
                  />
                </div>
                <div className="field-group">
                  <label style={labelStyle}>{isAr ? "المدة (بالدقائق)" : "Duration (Mins)"}</label>
                  <select 
                    value={duration}
                    onChange={(e) => setDuration(parseInt(e.target.value))}
                    style={inputStyle}
                  >
                    <option value={40}>40 Minutes (Standard)</option>
                    <option value={60}>1 Hour</option>
                    <option value={90}>1.5 Hours</option>
                    <option value={120}>2 Hours</option>
                  </select>
                </div>
              </div>

              {/* Action Button */}
              <div style={{ marginTop: "24px", display: "flex", justifyContent: "center" }}>
                 <button 
                  onClick={handleStart}
                  disabled={createMutation.isPending}
                  className="btn-glass" 
                  style={{ 
                    padding: "14px 32px", 
                    background: "#2D8CFF", 
                    color: "#fff", 
                    borderRadius: "14px", 
                    fontSize: "16px", 
                    fontWeight: 900, 
                    display: "flex", 
                    alignItems: "center", 
                    gap: "10px",
                    boxShadow: "0 10px 25px rgba(45, 140, 255, 0.2)",
                    transition: "all 0.3s ease"
                  }}
                 >
                   {createMutation.isPending ? <Loader2 className="animate-spin" /> : <Video size={20} />}
                   {isAr ? "بدء الاجتماع الآن" : "Launch Meeting Now"}
                   <ArrowRight size={18} />
                 </button>
              </div>
            </div>
          </div>
        </div>

        {/* Sidebar Info & History */}
        <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
           
           {/* Active/Created Meeting Card */}
           {createdMeeting && (
             <div className="card-glass fade-in" style={{ padding: "24px", background: "rgba(52, 211, 153, 0.1)", border: "1px solid #10b981" }}>
               <div style={{ display: "flex", alignItems: "center", gap: "10px", color: "#10b981", fontWeight: 800, marginBottom: "16px" }}>
                 <CheckCircle2 size={20} /> MEETING CREATED
               </div>
               <p style={{ fontSize: "14px", color: "var(--glass-text-secondary)", marginBottom: "20px" }}>
                 {isAr ? "تم إنشاء الاجتماع بنجاح وإرسال التنبيهات." : "Meeting successfully created and notifications sent."}
               </p>
               
               <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                 <a 
                  href={createdMeeting.join_url} 
                  target="_blank" 
                  style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "10px", padding: "12px", background: "#10b981", color: "#fff", borderRadius: "10px", fontWeight: 800, textDecoration: "none" }}
                 >
                   Join Meeting <ExternalLink size={16} />
                 </a>
                 <button 
                  onClick={() => {
                    navigator.clipboard.writeText(createdMeeting.join_url);
                    alert("Meeting link copied!");
                  }}
                  style={{ padding: "10px", background: "var(--glass-icon-bg)", color: "var(--glass-text-primary)", border: "1px solid var(--glass-border)", borderRadius: "10px", fontWeight: 700 }}
                 >
                   Copy Invitation Link
                 </button>
               </div>
             </div>
           )}

           <div className="card-glass" style={{ padding: "24px", flex: 1 }}>
             <h4 style={{ fontSize: "16px", fontWeight: 800, color: "var(--glass-text-primary)", marginBottom: "20px" }}>
               {isAr ? "الجلسات القادمة" : "Upcoming Sessions"}
             </h4>
             
             <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
                {meetingsLoading ? (
                  <div style={{ textAlign: "center", padding: "20px" }}><Loader2 className="animate-spin" style={{ margin: "0 auto" }} /></div>
                ) : meetings && meetings.length > 0 ? (
                  meetings.map((m: any) => (
                    <div key={m.id} style={{ padding: "16px", background: "var(--glass-icon-bg)", borderRadius: "16px", border: "1px solid var(--glass-border)" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "10px" }}>
                        <span style={{ fontSize: "12px", padding: "4px 8px", background: "rgba(45, 140, 255, 0.1)", color: "#2D8CFF", borderRadius: "6px", fontWeight: 700 }}>
                          {m.type === 2 ? "Scheduled" : "Instant"}
                        </span>
                        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                          <span style={{ color: "var(--glass-text-muted)", fontSize: "12px" }}>
                            {new Date(m.start_time).toLocaleString(isAr ? 'ar-EG' : 'en-US')}
                          </span>
                          <button 
                            onClick={() => {
                              if(confirm(isAr ? "هل أنت متأكد من حذف هذا الاجتماع؟" : "Are you sure you want to delete this meeting?")) {
                                deleteMutation.mutate(m.id);
                              }
                            }}
                            style={{ background: "none", border: "none", color: "#f87171", cursor: "pointer", padding: "4px", borderRadius: "4px", display: "flex", alignItems: "center", justifyContent: "center" }}
                            onMouseOver={(e) => e.currentTarget.style.background = "rgba(248, 113, 113, 0.1)"}
                            onMouseOut={(e) => e.currentTarget.style.background = "none"}
                          >
                            <Trash2 size={14} />
                          </button>
                        </div>
                      </div>
                      <p style={{ fontWeight: 700, color: "var(--glass-text-primary)", fontSize: "14px" }}>{m.topic}</p>
                      <a href={m.join_url} target="_blank" style={{ fontSize: "11px", color: "#2D8CFF", textDecoration: "none", marginTop: "8px", display: "inline-flex", alignItems: "center", gap: "4px" }}>
                        {isAr ? "رابط الاجتماع" : "Join URL"} <ExternalLink size={10} />
                      </a>
                    </div>
                  ))
                ) : (
                  <div style={{ textAlign: "center", padding: "20px", color: "var(--glass-text-muted)", fontSize: "13px" }}>
                    {isAr ? "لا توجد اجتماعات قادمة" : "No upcoming meetings"}
                  </div>
                )}

                <div style={{ textAlign: "center", padding: "20px", borderTop: "1px solid var(--glass-border)", marginTop: "10px" }}>
                  <p style={{ color: "var(--glass-text-muted)", fontSize: "13px" }}>
                    {isAr ? "حالة الربط:" : "Integration Status:"} 
                    <span style={{ color: zoomError ? "#f87171" : "#34d399", fontWeight: 700, marginLeft: "8px" }}>
                      {zoomError ? (isAr ? "خطأ في الاتصال" : "Disconnected") : (isAr ? "متصل" : "Online")}
                    </span>
                  </p>
                </div>
             </div>
           </div>
        </div>
      </div>
    </div>
  );
}

const audienceButtonStyle = (active: boolean, color: string) => ({
  display: "flex",
  flexDirection: "column" as const,
  alignItems: "center",
  gap: "12px",
  padding: "24px 16px",
  borderRadius: "20px",
  background: active ? `${color}15` : "var(--glass-icon-bg)",
  border: active ? `2px solid ${color}` : "2px solid var(--glass-border)",
  color: active ? color : "var(--glass-text-secondary)",
  cursor: "pointer" as const,
  transition: "all 0.2s ease",
  textAlign: "center" as const,
  flex: 1
});

const sectionHeaderStyle = {
  fontSize: "15px",
  fontWeight: 800,
  textTransform: "uppercase" as const,
  letterSpacing: "1px",
  color: "var(--primary-light)",
  marginBottom: "12px"
};

const labelStyle = {
  display: "block",
  fontSize: "13px",
  fontWeight: 600,
  marginBottom: "8px",
  color: "var(--glass-text-secondary)"
};

const inputStyle = {
  width: "100%",
  padding: "14px 16px",
  borderRadius: "12px",
  background: "var(--glass-input-bg)",
  border: "1px solid var(--glass-border)",
  color: "var(--glass-text-primary)",
  fontSize: "15px",
  outline: "none"
};

const controlIconStyle = {
  width: "36px",
  height: "36px",
  borderRadius: "50%",
  background: "rgba(255,255,255,0.1)",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  color: "#fff",
  cursor: "pointer"
};
