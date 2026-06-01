"use client";

import React, { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { 
  Bell, Check, Send, AlertCircle, BookOpen, Wallet, Bus, 
  MessageSquare, Info, History, Filter, User, Mail, Calendar, Sparkles, Trash2
} from "lucide-react";
import { api, extractApiError } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { useAuth } from "@/components/shared/AuthProvider";
import { Modal } from "@/components/ui/Modal";

const TYPE_CONFIG: Record<string, { icon: any, color: string, bg: string }> = {
  GENERAL: { icon: Info, color: "#3b82f6", bg: "rgba(59, 130, 246, 0.1)" },
  ABSENCE: { icon: AlertCircle, color: "#ef4444", bg: "rgba(239, 68, 68, 0.1)" },
  HOMEWORK: { icon: BookOpen, color: "#8b5cf6", bg: "rgba(139, 92, 246, 0.1)" },
  RESULT: { icon: Sparkles, color: "#10b981", bg: "rgba(16, 185, 129, 0.1)" },
  FEE_DUE: { icon: Wallet, color: "#f59e0b", bg: "rgba(245, 158, 11, 0.1)" },
  BUS: { icon: Bus, color: "#06b6d4", bg: "rgba(6, 182, 212, 0.1)" },
};

const CHANNEL_COLORS: Record<string, string> = {
  SYSTEM: "rgba(255, 255, 255, 0.1)",
  SMS: "rgba(16, 185, 129, 0.1)",
  WHATSAPP: "rgba(34, 197, 94, 0.1)",
  EMAIL: "rgba(59, 130, 246, 0.1)",
};

export default function NotificationsPage() {
  const { t, isAr } = useTranslation();
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<any>({ recipientId: "", title: "", message: "", type: "GENERAL", channel: "SYSTEM" });

  const [userSearch, setUserSearch] = useState("");
  const [showDropdown, setShowDropdown] = useState(false);

  const { data: usersData } = useQuery({
    queryKey: ["users-lookup"],
    queryFn: async () => (await api.get("/users")).data.data,
  });
  const users = Array.isArray(usersData) ? usersData : [];

  const filteredUsers = users.filter((u: any) =>
    (u.fullName || "").toLowerCase().includes(userSearch.toLowerCase()) ||
    (u.email || "").toLowerCase().includes(userSearch.toLowerCase()) ||
    (u.id || "").toLowerCase() === userSearch.toLowerCase()
  );

  const { data, isLoading } = useQuery({
    queryKey: ["notifications"],
    queryFn: async () => (await api.get("/notifications")).data.data,
  });

  const items = useMemo(() => (Array.isArray(data) ? data : []), [data]);

  const readMutation = useMutation({
    mutationFn: async (id: string) => api.post(`/notifications/${id}/read`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["notifications"] }),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/notifications/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["notifications"] }),
    onError: (e) => setError(extractApiError(e).message),
  });

  const canSend = ["SUPER_ADMIN", "SCHOOL_ADMIN", "ADMIN"].includes(user?.role || "");
  const sendMutation = useMutation({
    mutationFn: async () =>
      api.post("/notifications", {
        ...form,
        recipientId: form.recipientId.trim() ? form.recipientId.trim() : null,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
      setOpen(false);
      setForm({ recipientId: "", title: "", message: "", type: "GENERAL", channel: "SYSTEM" });
      setUserSearch("");
      setError(null);
    },
    onError: (e) => setError(extractApiError(e).message),
  });

  const formatType = (type: string) => type.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, c => c.toUpperCase());

  return (
    <div className="notifications-module" dir={isAr ? "rtl" : "ltr"}>
      {/* Header Section */}
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "32px", fontWeight: 800, color: "var(--glass-text-primary)", letterSpacing: "-0.5px" }}>{isAr ? "الإشعارات" : "Notifications Center"}</h2>
          <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>{isAr ? "إرسال ومتابعة التنبيهات والرسائل لجميع أعضاء المدرسة" : "Send and track alerts and messages to all school members"}</p>
        </div>
        {canSend && (
          <button className="btn-send-premium" onClick={() => setOpen(true)}>
            <Send size={18} />
            <span>{isAr ? "إرسال إشعار" : "New Notification"}</span>
          </button>
        )}
      </div>

      {error && <div className="error-box">{error}</div>}

      {isLoading ? (
        <div style={{ padding: "100px 0", textAlign: "center" }}>
          <div className="spinner-large" style={{ margin: "0 auto" }} />
          <p style={{ marginTop: "16px", color: "var(--glass-text-muted)" }}>{isAr ? "جاري جلب الإشعارات..." : "Loading notifications history..."}</p>
        </div>
      ) : (
        <div className="notifications-list">
          {items.map((n: any) => {
            const config = TYPE_CONFIG[n.type] || TYPE_CONFIG.GENERAL;
            const TypeIcon = config.icon;
            const unread = !n.readAt && n.recipientId;
            
            return (
              <div key={n.id} className={`alert-row-luxe ${unread ? 'unread' : ''}`} style={{ "--accent-color": config.color } as any}>
                <div className="notification-icon-wrapper" style={{ background: config.bg, color: config.color }}>
                  <TypeIcon size={22} />
                </div>
                
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: "12px" }}>
                    <div className="notification-title">{n.title}</div>
                    <div className="notification-time">
                      <Calendar size={12} style={{ marginRight: "4px" }} />
                      {new Date(n.sentAt).toLocaleDateString()} {new Date(n.sentAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </div>
                  </div>
                  
                  <div className="notification-message">{n.message}</div>
                  
                  <div className="notification-meta">
                    <span className="meta-tag type" style={{ color: config.color }}>{formatType(n.type)}</span>
                    <span className="meta-tag channel">{n.channel}</span>
                    {n.recipientId && (
                       <span className="meta-tag direct"><User size={10} style={{ marginRight: "4px" }} /> Direct</span>
                    )}
                  </div>
                </div>

                {unread && (
                  <button className="btn-read-mark" onClick={() => readMutation.mutate(n.id)} title={isAr ? "تحديد كمقروء" : "Mark as read"}>
                    <Check size={18} />
                  </button>
                )}
                {canSend && (
                  <button className="btn-delete-notif" onClick={() => deleteMutation.mutate(n.id)} title={isAr ? "حذف" : "Delete"}>
                    <Trash2 size={18} />
                  </button>
                )}
              </div>
            );
          })}
          
          {items.length === 0 && (
            <div className="empty-state">
              <History size={48} />
              <p>{isAr ? "لا توجد إشعارات حتى الآن" : "No notifications in the history yet."}</p>
            </div>
          )}
        </div>
      )}

      <Modal
        isOpen={open}
        onClose={() => setOpen(false)}
        title={isAr ? "إرسال إشعار جديد" : "Compose New Notification"}
        footer={
          <div style={{ display: "flex", gap: "12px", justifyContent: "flex-end", width: "100%" }}>
            <button className="btn-cancel" onClick={() => setOpen(false)}>
              {isAr ? "إلغاء" : "Cancel"}
            </button>
            <button 
              className="btn-submit-premium" 
              onClick={() => sendMutation.mutate()} 
              disabled={sendMutation.isPending || !form.title.trim() || !form.message.trim()}
            >
              {sendMutation.isPending ? (isAr ? "جاري الإرسال..." : "Sending...") : (isAr ? "إرسال الآن" : "Send Now")}
            </button>
          </div>
        }
      >
        <div style={{ display: "flex", flexDirection: "column", gap: "16px", padding: "8px 0" }}>
          <div className="form-group" style={{ position: "relative" }}>
            <label>{isAr ? "المستلم (اختياري - ابحث بالاسم أو معرف المستخدم)" : "Recipient (Optional - Search by Name or ID)"}</label>
            <div className="input-with-icon">
              <User size={16} />
              <input 
                placeholder={isAr ? "ابحث عن مستخدم أو الصق المعرف..." : "Search user by name or paste ID..."} 
                value={userSearch} 
                onChange={(e) => {
                  setUserSearch(e.target.value);
                  setShowDropdown(true);
                  if (!e.target.value.trim()) {
                    setForm({ ...form, recipientId: "" });
                  } else {
                    // Also support direct pasting of ID
                    setForm({ ...form, recipientId: e.target.value });
                  }
                }} 
                onFocus={() => setShowDropdown(true)}
              />
            </div>
            
            {showDropdown && userSearch.trim() && (
              <div className="users-search-dropdown" style={{
                position: "absolute",
                top: "100%",
                left: 0,
                right: 0,
                background: "rgba(30, 30, 45, 0.95)",
                backdropFilter: "blur(25px)",
                border: "1px solid var(--glass-border)",
                borderRadius: "12px",
                maxHeight: "220px",
                overflowY: "auto",
                zIndex: 1000,
                marginTop: "4px",
                boxShadow: "0 10px 30px rgba(0,0,0,0.3)"
              }}>
                {filteredUsers.slice(0, 8).map((u: any) => (
                  <div 
                    key={u.id} 
                    onClick={() => {
                      setForm({ ...form, recipientId: u.id });
                      setUserSearch(`${u.fullName} (${u.role}) - ${u.id}`);
                      setShowDropdown(false);
                    }}
                    style={{
                      padding: "12px 16px",
                      cursor: "pointer",
                      borderBottom: "1px solid rgba(255,255,255,0.05)",
                      transition: "all 0.2s",
                      fontSize: "13px",
                      display: "flex",
                      flexDirection: "column",
                      gap: "2px",
                      color: "#fff"
                    }}
                    className="dropdown-item-hover"
                  >
                    <span style={{ fontWeight: 700 }}>{u.fullName || u.email}</span>
                    <span style={{ opacity: 0.5, fontSize: "10px" }}>ID: {u.id} | Role: {u.role}</span>
                  </div>
                ))}
                {filteredUsers.length === 0 && (
                  <div style={{ padding: "12px", textAlign: "center", color: "var(--glass-text-muted)", fontSize: "13px" }}>
                    {isAr ? "لم يتم العثور على مستخدمين" : "No users found"}
                  </div>
                )}
              </div>
            )}
          </div>

          <div className="form-group">
            <label>{isAr ? "العنوان *" : "Title *"}</label>
            <input className="premium-input" placeholder={isAr ? "مثال: تنبيه هام، واجب جديد..." : "e.g. Important Alert, New Homework..."} value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
          </div>

          <div className="form-group">
            <label>{isAr ? "الرسالة *" : "Message *"}</label>
            <textarea className="premium-input" placeholder={isAr ? "اكتب محتوى الإشعار هنا..." : "Type the notification content here..."} rows={4} value={form.message} onChange={(e) => setForm({ ...form, message: e.target.value })} />
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
            <div className="form-group">
              <label>{isAr ? "نوع الإشعار" : "Notification Type"}</label>
              <select className="premium-select" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
                {Object.keys(TYPE_CONFIG).map((x) => (
                  <option key={x} value={x}>{formatType(x)}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label>{isAr ? "قناة الإرسال" : "Send Channel"}</label>
              <select className="premium-select" value={form.channel} onChange={(e) => setForm({ ...form, channel: e.target.value })}>
                {["SYSTEM", "SMS", "WHATSAPP", "EMAIL"].map((x) => (
                  <option key={x} value={x}>{x}</option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </Modal>

      <style jsx>{`
        .notifications-list {
          display: flex;
          flex-direction: column;
          gap: 16px;
        }
        .alert-row-luxe {
          position: relative;
          display: flex;
          gap: 20px;
          padding: 20px 24px;
          border-radius: 16px;
          background: var(--glass-bg);
          border: 1px solid var(--glass-border);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          align-items: flex-start;
          box-shadow: 0 4px 20px rgba(0,0,0,0.02);
        }
        .alert-row-luxe:hover {
          transform: translateY(-2px);
          box-shadow: 0 10px 30px rgba(0,0,0,0.06);
          border-color: var(--accent-color, var(--primary-light));
          background: rgba(255, 255, 255, 0.01);
        }
        .alert-row-luxe.unread {
          border-left: 4px solid var(--accent-color, var(--primary-light));
          background: var(--glass-input-bg);
        }
        .notification-icon-wrapper {
          width: 48px;
          height: 48px;
          border-radius: 14px;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
          box-shadow: 0 4px 15px rgba(0,0,0,0.05);
        }
        .notification-title {
          font-weight: 800;
          color: var(--glass-text-primary);
          font-size: 17px;
        }
        .notification-message {
          color: var(--glass-text-secondary);
          margin-top: 8px;
          font-size: 14px;
          line-height: 1.6;
        }
        .notification-time {
          font-size: 11px;
          color: var(--glass-text-muted);
          display: flex;
          align-items: center;
          font-weight: 600;
        }
        .notification-meta {
          display: flex;
          gap: 12px;
          margin-top: 16px;
        }
        .meta-tag {
          font-size: 10px;
          font-weight: 800;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          padding: 2px 8px;
          border-radius: 6px;
          background: rgba(255,255,255,0.05);
        }
        .meta-tag.type {
          background: transparent;
          border: 1px solid currentColor;
        }
        .btn-send-premium {
          background: var(--gradient-primary);
          color: #fff;
          border: none;
          padding: 12px 24px;
          border-radius: 14px;
          font-weight: 700;
          display: flex;
          align-items: center;
          gap: 10px;
          cursor: pointer;
          transition: 0.3s;
          box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);
        }
        .btn-send-premium:hover {
          transform: translateY(-2px);
          box-shadow: 0 8px 25px rgba(59, 130, 246, 0.4);
        }
        .btn-read-mark {
          width: 40px;
          height: 40px;
          border-radius: 12px;
          border: 1px solid var(--glass-border);
          background: var(--glass-bg);
          color: #10b981;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: 0.2s;
        }
        .btn-read-mark:hover {
          background: #10b981;
          color: #fff;
          border-color: #10b981;
        }
        .btn-delete-notif {
          width: 40px;
          height: 40px;
          border-radius: 12px;
          border: 1px solid var(--glass-border);
          background: var(--glass-bg);
          color: #ef4444;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: 0.2s;
        }
        .btn-delete-notif:hover {
          background: #ef4444;
          color: #fff;
          border-color: #ef4444;
        }
        .empty-state {
          padding: 80px;
          text-align: center;
          color: var(--glass-text-muted);
          opacity: 0.5;
        }
        .form-group label {
          display: block;
          font-size: 13px;
          font-weight: 700;
          color: var(--glass-text-secondary);
          margin-bottom: 8px;
        }
        .input-with-icon {
          position: relative;
        }
        .input-with-icon :global(svg) {
          position: absolute;
          left: 14px;
          top: 50%;
          transform: translateY(-50%);
          color: var(--glass-text-muted);
        }
        .input-with-icon input {
          width: 100%;
          background: var(--glass-input-bg);
          border: 1px solid var(--glass-border);
          border-radius: 12px;
          padding: 12px 12px 12px 42px;
          color: var(--glass-text-primary);
        }
        .premium-input, .premium-select {
          width: 100%;
          background: var(--glass-input-bg);
          border: 1px solid var(--glass-border);
          border-radius: 12px;
          padding: 12px 16px;
          color: var(--glass-text-primary);
          outline: none;
          transition: 0.3s;
        }
        .premium-input:focus, .premium-select:focus {
          border-color: var(--primary-light);
          box-shadow: 0 0 0 4px var(--primary-glow);
        }
        .btn-cancel {
          background: transparent;
          border: 1px solid var(--glass-border);
          padding: 10px 20px;
          border-radius: 10px;
          color: var(--glass-text-secondary);
          font-weight: 600;
          cursor: pointer;
        }
        .btn-submit-premium {
          background: var(--gradient-primary);
          color: #fff;
          border: none;
          padding: 10px 24px;
          border-radius: 10px;
          font-weight: 700;
          cursor: pointer;
          transition: 0.3s;
        }
        .btn-submit-premium:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
        .error-box {
          background: rgba(239, 68, 68, 0.05);
          border: 1px solid rgba(239, 68, 68, 0.2);
          color: #ef4444;
          padding: 12px 16px;
          border-radius: 12px;
          margin-bottom: 24px;
          font-size: 14px;
          font-weight: 600;
        }
      `}</style>
    </div>
  );
}

