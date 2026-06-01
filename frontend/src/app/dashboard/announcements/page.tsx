"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { 
  Megaphone, 
  Plus, 
  Users, 
  Calendar, 
  Trash2, 
  MoreVertical,
  Layers,
  Send,
  CheckCircle2,
  Bell,
  X,
  Target,
  Clock
} from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";

const AUDIENCE_CONFIG: Record<string, { label: string, labelAr: string, color: string, bg: string }> = {
  all: { label: "Whole School", labelAr: "الكل", color: "#3b82f6", bg: "rgba(59, 130, 246, 0.1)" },
  parents: { label: "Parents", labelAr: "أولياء الأمور", color: "#10b981", bg: "rgba(16, 185, 129, 0.1)" },
  teachers: { label: "Teachers", labelAr: "المدرسين", color: "#f59e0b", bg: "rgba(245, 158, 11, 0.1)" },
};

export default function AnnouncementsPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState({
    title: "",
    body: "",
    audience: "all"
  });

  const { data, isLoading } = useQuery({
    queryKey: ["announcements"],
    queryFn: async () => (await api.get("/announcements")).data.data
  });

  const createMutation = useMutation({
    mutationFn: async (newData: typeof formData) => api.post("/announcements", newData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
      setIsModalOpen(false);
      setFormData({ title: "", body: "", audience: "all" });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/announcements/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
    }
  });

  const handleDelete = (id: string) => {
    if (window.confirm(isAr ? "هل أنت متأكد من حذف هذا الإعلان؟" : "Are you sure you want to delete this announcement?")) {
      deleteMutation.mutate(id);
    }
  };

  return (
    <div className="announcements-module" dir={isAr ? "rtl" : "ltr"}>
      {/* Header */}
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "32px", fontWeight: 800, color: "var(--glass-text-primary)", letterSpacing: "-0.5px" }}>{isAr ? "الإعلانات المدرسية" : "School Announcements"}</h2>
          <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>{isAr ? "نشر الأخبار والتحديثات الهامة لأولياء الأمور والموظفين" : "Broadcast important updates and news to parents, students, and staff."}</p>
        </div>
        <button 
          className="btn-premium-primary" 
          onClick={() => setIsModalOpen(true)}
        >
          <Plus size={20} />
          <span>{isAr ? "إعلان جديد" : "New Broadcast"}</span>
        </button>
      </div>

      <div className="announcements-layout">
        {/* Feed */}
        <div className="feed-container">
          {isLoading ? (
            <div style={{ padding: "100px 0", textAlign: "center" }}>
              <div className="spinner-large" style={{ margin: "0 auto" }} />
            </div>
          ) : data?.length === 0 ? (
            <div className="empty-state-card">
              <Megaphone size={64} />
              <h3>{isAr ? "لا توجد إعلانات حالياً" : "No Announcements"}</h3>
              <p>{isAr ? "ابدأ بنشر أول إعلان للمدرسة من زر 'إعلان جديد'" : "Start by broadcasting your first update using the button above."}</p>
            </div>
          ) : data?.map((post: any) => {
            const aud = AUDIENCE_CONFIG[post.audience] || AUDIENCE_CONFIG.all;
            return (
              <div key={post.id} className="announcement-card luxury-stat-card">
                <div className="glow-blob"></div>
                <div className="card-content">
                  <div className="card-header">
                    <div className="user-info">
                      <div className="icon-box">
                        <Megaphone size={20} />
                      </div>
                      <div className="title-area">
                        <h3 className="post-title">{post.title}</h3>
                        <div className="post-meta">
                          <span className="meta-item"><Target size={12} /> {isAr ? aud.labelAr : aud.label}</span>
                          <span className="separator">•</span>
                          <span className="meta-item"><Clock size={12} /> {new Date(post.createdAt).toLocaleDateString()}</span>
                        </div>
                      </div>
                    </div>
                    <button 
                      onClick={() => handleDelete(post.id)}
                      className="delete-btn"
                      title={isAr ? "حذف" : "Delete"}
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
                  
                  <div className="post-body">
                    {post.body}
                  </div>

                  <div className="post-footer">
                     <div className="audience-tag" style={{ color: aud.color, background: aud.bg }}>
                       {isAr ? `${aud.labelAr}` : `Target: ${aud.label}`}
                     </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Sidebar */}
        <div className="sidebar-container">
          <div className="card-glass stat-card">
            <h4 className="sidebar-title">{isAr ? "ملخص الإحصائيات" : "ANALYTICS"}</h4>
            <div className="stat-grid">
              <div className="stat-item">
                <div className="stat-value">{data?.length || 0}</div>
                <div className="stat-label">{isAr ? "إجمالي الإعلانات" : "Total Posts"}</div>
              </div>
              <div className="stat-item">
                <div className="stat-value">--</div>
                <div className="stat-label">{isAr ? "نسبة الوصول" : "Reach Rate"}</div>
              </div>
            </div>
          </div>

          <div className="card-glass channel-card">
            <h4 className="sidebar-title">{isAr ? "قنوات النشر" : "BROADCAST CHANNELS"}</h4>
            <div className="channel-list">
              <ChannelItem icon={<Layers size={16} />} label={isAr ? "تطبيق الموبايل" : "Mobile App"} active />
              <ChannelItem icon={<Bell size={16} />} label={isAr ? "نظام الإشعارات" : "System Inbox"} active />
              <ChannelItem icon={<Send size={16} />} label={isAr ? "رسائل SMS" : "SMS Alerts"} active={false} />
            </div>
          </div>
        </div>
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={isAr ? "إرسال إعلان جديد" : "Compose New Broadcast"}
        footer={
          <div style={{ display: "flex", gap: "12px", justifyContent: "flex-end", width: "100%" }}>
            <button className="btn-cancel" onClick={() => setIsModalOpen(false)}>{isAr ? "إلغاء" : "Cancel"}</button>
            <button 
              className="btn-submit-premium" 
              onClick={() => createMutation.mutate(formData)}
              disabled={createMutation.isPending || !formData.title.trim() || !formData.body.trim()}
            >
              <Send size={18} /> 
              <span>{createMutation.isPending ? (isAr ? "جاري الإرسال..." : "Sending...") : (isAr ? "إرسال الآن" : "Send Now")}</span>
            </button>
          </div>
        }
      >
        <div className="form-content">
          <div className="form-group">
            <label className="premium-label">{isAr ? "عنوان الإعلان *" : "Announcement Title *"}</label>
            <input 
              className="premium-input" 
              placeholder={isAr ? "مثال: موعد امتحانات نصف العام" : "e.g. Mid-term Exam Schedule"}
              value={formData.title}
              onChange={e => setFormData({...formData, title: e.target.value})}
            />
          </div>
          <div className="form-group">
            <label className="premium-label">{isAr ? "الفئة المستهدفة" : "Target Audience"}</label>
            <select 
              className="premium-select"
              value={formData.audience}
              onChange={e => setFormData({...formData, audience: e.target.value})}
            >
              <option value="all">{isAr ? "الكل (أولياء أمور، مدرسين، طلاب)" : "All (Parents, Staff, Students)"}</option>
              <option value="parents">{isAr ? "أولياء الأمور فقط" : "Parents Only"}</option>
              <option value="teachers">{isAr ? "المدرسين فقط" : "Teachers Only"}</option>
            </select>
          </div>
          <div className="form-group">
            <label className="premium-label">{isAr ? "نص الإعلان *" : "Announcement Body *"}</label>
            <textarea 
              className="premium-textarea" 
              rows={6} 
              placeholder={isAr ? "اكتب تفاصيل الإعلان هنا..." : "Type the broadcast content here..."}
              value={formData.body}
              onChange={e => setFormData({...formData, body: e.target.value})}
            />
          </div>
        </div>
      </Modal>

      <style jsx>{`
        .announcements-layout {
          display: grid;
          grid-template-columns: 1fr 320px;
          gap: 32px;
        }
        .luxury-stat-card {
          position: relative;
          background: var(--glass-bg);
          backdrop-filter: blur(20px);
          border: 1px solid var(--glass-border);
          border-radius: 28px;
          padding: 28px;
          overflow: hidden;
          transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
          z-index: 1;
        }
        .luxury-stat-card:hover {
          transform: translateY(-8px) scale(1.01);
          border-color: var(--primary-light);
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
        }
        .glow-blob {
          position: absolute;
          width: 150px;
          height: 150px;
          background: var(--gradient-primary);
          filter: blur(60px);
          opacity: 0.1;
          border-radius: 50%;
          top: -40px;
          inset-inline-end: -40px;
          z-index: 0;
          transition: 0.6s;
        }
        .luxury-stat-card:hover .glow-blob {
          opacity: 0.25;
          transform: scale(2) translate(-10%, 10%);
        }
        .card-content {
          position: relative;
          z-index: 2;
        }
        .sidebar-container {
          display: flex;
          flex-direction: column;
          gap: 24px;
        }
        .stat-card, .channel-card {
          padding: 24px;
          border-radius: 24px;
        }
        .announcement-card {
          margin-bottom: 24px;
        }
        .card-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 20px;
        }
        .user-info {
          display: flex;
          gap: 16px;
          align-items: center;
        }
        .icon-box {
          width: 52px;
          height: 52px;
          border-radius: 14px;
          background: var(--glass-icon-bg);
          color: var(--primary-light);
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .post-title {
          font-size: 20px;
          font-weight: 800;
          color: var(--glass-text-primary);
        }
        .post-meta {
          display: flex;
          gap: 12px;
          font-size: 12px;
          color: var(--glass-text-muted);
          margin-top: 4px;
          font-weight: 600;
        }
        .meta-item {
          display: flex;
          align-items: center;
          gap: 4px;
        }
        .post-body {
          font-size: 16px;
          line-height: 1.8;
          color: var(--glass-text-secondary);
          white-space: pre-wrap;
          margin-bottom: 24px;
        }
        .post-footer {
          border-top: 1px solid var(--glass-border);
          padding-top: 16px;
          display: flex;
        }
        .audience-tag {
          font-size: 10px;
          font-weight: 800;
          text-transform: uppercase;
          padding: 4px 10px;
          border-radius: 8px;
        }
        .delete-btn {
          background: transparent;
          border: none;
          color: var(--glass-text-muted);
          cursor: pointer;
          transition: 0.2s;
          opacity: 0.4;
        }
        .delete-btn:hover {
          color: #ef4444;
          opacity: 1;
          transform: scale(1.1);
        }
        .sidebar-title {
          font-size: 11px;
          font-weight: 800;
          color: var(--glass-text-muted);
          letter-spacing: 1px;
          margin-bottom: 20px;
        }
        .stat-grid {
          display: flex;
          flex-direction: column;
          gap: 20px;
        }
        .stat-value {
          font-size: 28px;
          font-weight: 900;
          color: var(--glass-text-primary);
        }
        .stat-label {
          font-size: 12px;
          color: var(--glass-text-muted);
          font-weight: 600;
        }
        .channel-list {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }
        .empty-state-card {
          padding: 100px 40px;
          text-align: center;
          background: var(--glass-input-bg);
          border: 2px dashed var(--glass-border);
          border-radius: 24px;
          color: var(--glass-text-muted);
        }
        .empty-state-card h3 {
          margin-top: 20px;
          color: var(--glass-text-primary);
          font-size: 22px;
          font-weight: 800;
        }
        .empty-state-card p {
          margin-top: 8px;
          max-width: 300px;
          margin-left: auto;
          margin-right: auto;
        }
        .btn-premium-primary {
          background: var(--gradient-primary);
          color: #fff;
          border: none;
          padding: 14px 28px;
          border-radius: 14px;
          font-weight: 700;
          display: flex;
          align-items: center;
          gap: 10px;
          cursor: pointer;
          transition: 0.3s;
          box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);
        }
        .btn-premium-primary:hover {
          transform: translateY(-2px);
          box-shadow: 0 8px 25px rgba(59, 130, 246, 0.4);
        }
        .form-content {
          display: flex;
          flex-direction: column;
          gap: 20px;
        }
        .premium-label {
          display: block;
          font-size: 13px;
          font-weight: 700;
          color: var(--glass-text-secondary);
          margin-bottom: 8px;
        }
        .premium-input, .premium-select, .premium-textarea {
          width: 100%;
          background: var(--glass-input-bg);
          border: 1px solid var(--glass-border);
          border-radius: 12px;
          padding: 12px 16px;
          color: var(--glass-text-primary);
          outline: none;
          transition: 0.3s;
          font-family: inherit;
        }
        .premium-input:focus, .premium-select:focus, .premium-textarea:focus {
          border-color: var(--primary-light);
          box-shadow: 0 0 0 4px var(--primary-glow);
        }
        .btn-submit-premium {
          background: var(--gradient-primary);
          color: #fff;
          border: none;
          padding: 12px 24px;
          border-radius: 12px;
          font-weight: 700;
          cursor: pointer;
          transition: 0.3s;
          display: flex;
          align-items: center;
          gap: 8px;
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
        @media (max-width: 1024px) {
          .announcements-layout {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </div>
  );
}

const ChannelItem = ({ icon, label, active }: any) => (
  <div style={{ display: "flex", alignItems: "center", gap: "10px", opacity: active ? 1 : 0.4 }}>
    <div style={{ width: "32px", height: "32px", borderRadius: "10px", background: active ? "rgba(16, 185, 129, 0.1)" : "rgba(255,255,255,0.05)", display: "flex", alignItems: "center", justifyContent: "center", color: active ? "#10b981" : "var(--glass-text-muted)" }}>
      {icon}
    </div>
    <span style={{ fontSize: "14px", fontWeight: active ? 700 : 500, color: "var(--glass-text-primary)" }}>{label}</span>
    {active && <CheckCircle2 size={12} color="#10b981" style={{ marginLeft: "auto" }} />}
  </div>
);
