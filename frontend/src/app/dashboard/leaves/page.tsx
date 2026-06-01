"use client";

import React, { useState, useMemo } from "react";
import { 
  Check, X, Calendar, Search, Filter, 
  ChevronLeft, ChevronRight, Clock, Trash2
} from "lucide-react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import styles from "@/components/dashboard/PremiumAnalyticsHome.module.css";
import pageStyles from "./LeavesPage.module.css";

export default function LeavesPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("ALL");

  // Fetch all leave requests (History)
  const { data: leavesData, isLoading } = useQuery({
    queryKey: ["leaves-history"],
    queryFn: async () => (await api.get("/leaves")).data.data,
    staleTime: 0,
    refetchOnMount: "always",
  });

  const leaves = useMemo(() => (Array.isArray(leavesData) ? leavesData : []), [leavesData]);

  const filteredLeaves = useMemo(() => {
    return leaves.filter(l => {
      const isTeacher = !!l.teacherId;
      const person = isTeacher ? l.teacher : l.student;
      const name = (isAr ? (person?.nameAr || person?.user?.fullName) : (person?.nameEn || person?.user?.fullName)) || "";
      const role = isTeacher ? "Teacher" : "Student";
      
      const matchesSearch = name.toLowerCase().includes(searchTerm.toLowerCase()) || 
                            role.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesStatus = statusFilter === "ALL" || l.status === statusFilter;
      
      return matchesSearch && matchesStatus;
    });
  }, [leaves, searchTerm, statusFilter, isAr]);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "APPROVED": return <span className={`${styles.tag} ${styles.green}`}>{isAr ? "مقبول" : "Approved"}</span>;
      case "REJECTED": return <span className={`${styles.tag} ${styles.red}`}>{isAr ? "مرفوض" : "Rejected"}</span>;
      case "PENDING": return <span className={`${styles.tag} ${styles.blue}`}>{isAr ? "قيد الانتظار" : "Pending"}</span>;
      default: return <span className={styles.tag}>{status}</span>;
    }
  };

  return (
    <div className={styles.container}>
      {/* HEADER */}
      <header className={styles.header}>
        <div className={styles.headerLeft}>
          <h1>{isAr ? "سجل الإجازات" : "Leaves Log"}</h1>
          <p>{isAr ? "الأفراد / سجل الإجازات" : "People / Leaves Log"}</p>
        </div>
        <div className={styles.headerRight}>
          <div className={pageStyles.searchBox}>
            <Search size={18} />
            <input 
              type="text" 
              placeholder={isAr ? "بحث بالاسم..." : "Search by name..."} 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <select 
            className={styles.btnSecondary} 
            style={{ padding: '8px 12px', borderRadius: '10px' }}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="ALL">{isAr ? "الكل" : "All"}</option>
            <option value="PENDING">{isAr ? "قيد الانتظار" : "Pending"}</option>
            <option value="APPROVED">{isAr ? "مقبول" : "Approved"}</option>
            <option value="REJECTED">{isAr ? "مرفوض" : "Rejected"}</option>
          </select>
        </div>
      </header>

      <div className={pageStyles.mainContent}>
        <div className={styles.card} style={{ maxWidth: '1000px', margin: '0 auto' }}>
          <div className={styles.cardHeader}>
            <h3 className={styles.cardTitle}>{isAr ? "تاريخ طلبات الإجازات" : "Leave Requests History"}</h3>
            <span className={styles.cardSubtitle}>
              <Calendar size={14}/> {isAr ? "كل الأوقات" : "All Time"}
            </span>
          </div>

          <div className={pageStyles.listScrollContainer} style={{ maxHeight: '600px' }}>
            <div className={styles.list}>
              {isLoading ? (
                <div className={pageStyles.emptyState}>{isAr ? "جاري التحميل..." : "Loading..."}</div>
              ) : filteredLeaves.length === 0 ? (
                <div className={pageStyles.emptyState}>
                  <Clock size={48} />
                  <p>{isAr ? "لا توجد سجلات" : "No records found"}</p>
                </div>
              ) : (
                filteredLeaves.map((l) => {
                  const isTeacher = !!l.teacherId;
                  const person = isTeacher ? l.teacher : l.student;
                  const name = isAr ? (person?.nameAr || person?.user?.fullName) : (person?.nameEn || person?.user?.fullName);
                  const role = isTeacher ? (isAr ? "معلم" : "Teacher") : (isAr ? "طالب" : "Student");
                  const roleIcon = isTeacher ? "👨‍🏫" : "🎓";
                  const startDate = new Date(l.startDate).toLocaleDateString(isAr ? 'ar-EG' : 'en-GB', { day: '2-digit', month: 'short' });
                  const endDate = new Date(l.endDate).toLocaleDateString(isAr ? 'ar-EG' : 'en-GB', { day: '2-digit', month: 'short' });
                  const applyDate = new Date(l.applyDate).toLocaleDateString(isAr ? 'ar-EG' : 'en-GB', { day: '2-digit', month: 'short' });

                  return (
                    <div key={l.id} className={styles.listItem}>
                      <div className={styles.avatar}>
                        {person?.photo ? <img src={person.photo} alt="P" /> : roleIcon}
                      </div>
                      <div className={styles.listBody}>
                        <h4>
                          {name} 
                          {getStatusBadge(l.status)}
                          <span className={styles.tag} style={{ background: '#f1f5f9', color: '#475569', marginLeft: '8px' }}>
                             {l.type}
                          </span>
                        </h4>
                        <p>{role}</p>
                        <div className={pageStyles.leaveMeta}>
                          <span>{isAr ? "الإجازة :" : "Leave :"} <strong>{startDate} - {endDate}</strong></span>
                          <span>{isAr ? "التقديم :" : "Apply on :"} <strong>{applyDate}</strong></span>
                        </div>
                        {l.adminNotes && (
                          <div style={{ marginTop: 8, fontSize: 11, padding: '4px 8px', background: 'var(--ov-surface-2)', borderRadius: 4 }}>
                            <strong>{isAr ? "ملاحظة الإدارة:" : "Admin Note:"}</strong> {l.adminNotes}
                          </div>
                        )}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          <div className={pageStyles.footerInfo}>
             <p>{isAr ? `إجمالي السجلات: ${filteredLeaves.length}` : `Total records: ${filteredLeaves.length}`}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
