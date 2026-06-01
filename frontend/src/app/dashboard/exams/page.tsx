"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  Trash2,
  BookOpen,
  Calendar,
  Trophy,
  AlertCircle,
  Layout,
  Upload,
  FileText,
  Download,
  Search,
  CheckCircle2,
  FileUp,
  MoreVertical,
  ExternalLink
} from "lucide-react";
import { api, extractApiError } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";
import { supabase } from "@/lib/supabase";

export default function ExamsPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<"exams" | "results" | "student-results">("exams");

  // Modals
  const [isExamOpen, setIsExamOpen] = useState(false);
  const [isResultOpen, setIsResultOpen] = useState(false);

  const [error, setError] = useState<string | null>(null);

  // Forms
  const [examForm, setExamForm] = useState({
    name: "", type: "QUIZ", date: "", subjectId: "", gradeId: "", classId: ""
  });

  const [resultForm, setResultForm] = useState({
    name: "", category: "", term: "Term 1", year: "2024/2025", fileUrl: ""
  });

  const [uploading, setUploading] = useState(false);

  // Queries
  const { data: exams, isLoading: examsLoading } = useQuery({
    queryKey: ["exams"],
    queryFn: async () => (await api.get("/exams")).data.data,
  });

  const { data: schoolResults, isLoading: resultsLoading } = useQuery({
    queryKey: ["school-results"],
    queryFn: async () => (await api.get("/results")).data.data,
    enabled: activeTab === "results"
  });

  const { data: subjects } = useQuery({
    queryKey: ["subjects"],
    queryFn: async () => (await api.get("/subjects")).data.data,
  });

  const { data: grades } = useQuery({
    queryKey: ["grades"],
    queryFn: async () => (await api.get("/academic/grades")).data.data,
  });

  // Student results query
  const { data: allExamResults, isLoading: studentResultsLoading } = useQuery({
    queryKey: ["exam-all-results"],
    queryFn: async () => {
      // Fetch all exams first
      const examsRes = await api.get("/exams");
      const exams = examsRes.data.data;

      // Fetch results for each exam
      const resultsPromises = exams.map(async (exam: any) => {
        try {
          const res = await api.get(`/exams/${exam.id}/results`);
          return {
            exam,
            results: res.data.data.results || [],
          };
        } catch {
          return { exam, results: [] };
        }
      });

      return await Promise.all(resultsPromises);
    },
    enabled: activeTab === "student-results",
  });

  // Render functions for each tab
  const renderExamsTab = () => {
    if (examsLoading) {
      return <div className="loading-state card-glass"><div className="spinner" /></div>;
    }

    return (
      <div className="exams-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))", gap: "16px" }}>
        {exams?.map((exam: any) => (
          <div key={exam.id} className="luxury-stat-card" style={{ "--accent-color": "#8b5cf6" } as any}>
            <div className="luxury-stat-inner">
              <div className="exam-type-badge">{exam.type}</div>
              <h3 className="exam-name">{exam.name}</h3>
              <div className="exam-meta">
                <div className="meta-item"><BookOpen size={14} /> {exam.subject?.name || "---"}</div>
                <div className="meta-item"><Layout size={14} /> {exam.grade?.name}</div>
                <div className="meta-item"><Calendar size={14} /> {exam.date ? new Date(exam.date).toLocaleDateString() : "TBD"}</div>
              </div>
              <div className="card-actions">
                <button className="action-btn delete" onClick={() => confirm(isAr ? "حذف؟" : "Delete?") && deleteExamMutation.mutate(exam.id)}><Trash2 size={16} /></button>
              </div>
              <div className="l-stat-bg-blob"></div>
            </div>
          </div>
        ))}
        {exams?.length === 0 && <div className="empty-state card-glass"><p>{isAr ? "لا توجد اختبارات" : "No exams."}</p></div>}
      </div>
    );
  };

  const renderResultsTab = () => {
    if (resultsLoading) {
      return <div className="loading-state card-glass"><div className="spinner" /></div>;
    }

    return (
      <div className="results-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: "16px" }}>
        {schoolResults?.map((res: any) => (
          <div key={res.id} className="luxury-stat-card" style={{ "--accent-color": "#10b981" } as any}>
            <div className="luxury-stat-inner" style={{ display: "flex", alignItems: "center", gap: "20px" }}>
              <div className="res-icon">
                <FileText size={24} />
              </div>
              <div className="res-content" style={{ flex: 1, minWidth: 0, position: "relative", zIndex: 10 }}>
                <div className="res-top">
                  <span className="res-tag">{res.category || "General"}</span>
                  <span className="res-date">{res.year}</span>
                </div>
                <h4 className="res-title">{res.name}</h4>
                <p className="res-sub">{res.term}</p>
              </div>
              <div className="res-ops" style={{ position: "relative", zIndex: 10 }}>
                <a href={res.fileUrl} target="_blank" className="op-btn dl" title="Download"><Download size={18} /></a>
                <button className="op-btn del" title="Delete" onClick={() => confirm(isAr ? "حذف؟" : "Delete?") && deleteResultMutation.mutate(res.id)}><Trash2 size={18} /></button>
              </div>
              <div className="l-stat-bg-blob"></div>
            </div>
          </div>
        ))}
        {schoolResults?.length === 0 && <div className="empty-state card-glass"><p>{isAr ? "لم يتم رفع أي نتائج بعد" : "No results published yet."}</p></div>}
      </div>
    );
  };

  const renderStudentResultsTab = () => {
    if (studentResultsLoading) {
      return <div className="loading-state card-glass"><div className="spinner" /></div>;
    }

    return (
      <div className="student-results-container">
        <div className="filter-section card-glass" style={{ marginBottom: "20px", padding: "20px" }}>
          <h3 style={{ fontSize: "18px", fontWeight: 700, marginBottom: "16px" }}>{isAr ? "تصفية النتائج" : "Filter Results"}</h3>
          <div style={{ display: "flex", gap: "12px", flexWrap: "wrap" }}>
            <select
              className="glass-input"
              style={{ padding: "10px 16px", borderRadius: "8px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)" }}
              defaultValue=""
            >
              <option value="">{isAr ? "كل الصفوف" : "All Grades"}</option>
              {grades?.map((g: any) => <option key={g.id} value={g.id}>{g.name}</option>)}
            </select>
          </div>
        </div>

        <div className="students-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: "16px" }}>
          {allExamResults?.map(({ exam, results }: any) => (
            results.length > 0 && (
              <div key={exam.id} className="card-glass" style={{ padding: "20px", borderRadius: "16px" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
                  <h4 style={{ fontSize: "16px", fontWeight: 700 }}>{exam.name}</h4>
                  <span style={{ fontSize: "12px", padding: "4px 12px", borderRadius: "12px", background: "rgba(99, 102, 241, 0.1)", color: "#6366f1" }}>{exam.type}</span>
                </div>
                <div style={{ marginBottom: "12px", fontSize: "14px", color: "var(--glass-text-secondary)" }}>
                  <div>{exam.subject?.name} • {exam.grade?.name}</div>
                  {exam.class?.name && <div>{exam.class?.name}</div>}
                </div>
                <div style={{ marginTop: "16px", borderTop: "1px solid var(--glass-input-border)", paddingTop: "16px" }}>
                  {results.map((result: any) => (
                    <div key={result.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px 0", borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
                      <div>
                        <div style={{ fontWeight: 600, fontSize: "14px" }}>{result.student?.user?.fullName || result.student?.nameAr || result.student?.nameEn || "الطالب"}</div>
                        {result.notes && <div style={{ fontSize: "12px", color: "var(--glass-text-secondary)" }}>{result.notes}</div>}
                      </div>
                      <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                        <span style={{
                          fontSize: "18px",
                          fontWeight: 800,
                          color: result.absent ? "#f87171" : (result.score >= 60 ? "#34d399" : "#fbbf24")
                        }}>
                          {result.absent ? "غائب" : result.score}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )
          ))}
          {allExamResults?.filter((r: any) => r.results.length > 0).length === 0 && (
            <div className="empty-state card-glass" style={{ gridColumn: "1 / -1", padding: "60px", textAlign: "center" }}>
              <BookOpen size={48} color="var(--glass-text-muted)" style={{ marginBottom: "20px" }} />
              <p style={{ fontSize: "18px", color: "var(--glass-text-secondary)" }}>{isAr ? "لم يتم رصد أي درجات بعد" : "No grades published yet."}</p>
            </div>
          )}
        </div>
      </div>
    );
  };

  // Mutations
  const createExamMutation = useMutation({
    mutationFn: async (payload: any) => api.post("/exams", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["exams"] });
      setIsExamOpen(false);
      setExamForm({ name: "", type: "QUIZ", date: "", subjectId: "", gradeId: "", classId: "" });
      setError(null);
    },
    onError: (e) => setError(extractApiError(e).message),
  });

  const deleteExamMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/exams/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["exams"] }),
  });

  const uploadResultMutation = useMutation({
    mutationFn: async (payload: any) => api.post("/results", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["school-results"] });
      setIsResultOpen(false);
      setResultForm({ name: "", category: "", term: "Term 1", year: "2024/2025", fileUrl: "" });
      setError(null);
    },
    onError: (e) => setError(extractApiError(e).message),
  });

  const deleteResultMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/results/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["school-results"] }),
  });

  // Handlers
  const handleFileUpload = async (file: File) => {
    try {
      setUploading(true);
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random()}.${fileExt}`;
      const filePath = `results/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('documents')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from('documents')
        .getPublicUrl(filePath);

      setResultForm({ ...resultForm, fileUrl: publicUrl });
    } catch (e: any) {
      alert("Error uploading: " + e.message);
    } finally {
      setUploading(false);
    }
  };

  const handleExamSubmit = () => {
    if (!examForm.name || !examForm.subjectId || !examForm.gradeId) {
      setError(isAr ? "يرجى ملء الحقول الأساسية" : "Please fill required fields");
      return;
    }
    createExamMutation.mutate({
      ...examForm,
      date: examForm.date ? new Date(examForm.date).toISOString() : undefined,
    });
  };

  const handleResultSubmit = () => {
    if (!resultForm.name || !resultForm.fileUrl) {
      setError(isAr ? "يرجى إدخال الاسم ورفع الملف" : "Please enter name and upload file");
      return;
    }
    uploadResultMutation.mutate(resultForm);
  };

  return (
    <div className="exams-module" dir={isAr ? "rtl" : "ltr"}>
      {/* Tab Switcher Row */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div className="tab-switcher card-glass">
          <button className={activeTab === 'exams' ? 'active' : ''} onClick={() => setActiveTab('exams')}>
            <Trophy size={18} /> {isAr ? "جدول الاختبارات" : "Exam Schedule"}
          </button>
          <button className={activeTab === 'results' ? 'active' : ''} onClick={() => setActiveTab('results')}>
            <FileUp size={18} /> {isAr ? "مركز النتائج العامة" : "Results Center"}
          </button>
          <button className={activeTab === 'student-results' ? 'active' : ''} onClick={() => setActiveTab('student-results')}>
            <BookOpen size={18} /> {isAr ? "نتائج الطلاب" : "Student Results"}
          </button>
        </div>

        <button
          className="btn-add"
          style={{ padding: "10px 20px", height: "fit-content" }}
          onClick={() => activeTab === 'exams' ? setIsExamOpen(true) : (activeTab === 'results' ? setIsResultOpen(true) : {})}
          disabled={activeTab === 'student-results'}
        >
          <Plus size={18} />
          <span>{activeTab === 'exams' ? (isAr ? "إضافة اختبار" : "Add Exam") : (activeTab === 'results' ? (isAr ? "رفع نتيجة" : "Upload Result") : "")}</span>
        </button>
      </div>

      <div className="module-header">
        <div>
          <h2 className="title">
            {activeTab === 'exams'
              ? (isAr ? "إدارة الاختبارات" : "Exam Management")
              : (activeTab === 'results'
                  ? (isAr ? "مركز نشر نتائج المدرسة" : "Institutional Results Hub")
                  : (isAr ? "نتائج الطلاب" : "Student Results"))}
          </h2>
          <p className="subtitle">
            {activeTab === 'exams'
              ? (isAr ? "تخطيط مواعيد الاختبارات وأنواعها" : "Coordinate exam types and schedules.")
              : (activeTab === 'results'
                  ? (isAr ? "رفع واعتماد كشوف النتائج النهائية للمدرسة" : "Upload and certify finalized institution-wide result sheets.")
                  : (isAr ? "عرض درجات الطلاب في المواد المختلفة" : "View student grades across various subjects."))}
          </p>
        </div>
      </div>

      {activeTab === 'exams' ? renderExamsTab() :
       activeTab === 'results' ? renderResultsTab() :
       renderStudentResultsTab()}

      {/* Exam Modal */}
      <Modal isOpen={isExamOpen} onClose={() => setIsExamOpen(false)} title={isAr ? "إضافة اختبار" : "Add Exam"}>
        <div className="modal-form">
          <div className="form-group">
            <label>{isAr ? "اسم الاختبار *" : "Exam Name *"}</label>
            <input value={examForm.name} onChange={e => setExamForm({ ...examForm, name: e.target.value })} />
          </div>
          <div className="form-grid">
            <div className="form-group">
              <label>{isAr ? "المادة *" : "Subject *"}</label>
              <select value={examForm.subjectId} onChange={e => setExamForm({ ...examForm, subjectId: e.target.value })}>
                <option value="">Select</option>
                {subjects?.map((s: any) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label>{isAr ? "الصف *" : "Grade *"}</label>
              <select value={examForm.gradeId} onChange={e => setExamForm({ ...examForm, gradeId: e.target.value })}>
                <option value="">Select</option>
                {grades?.map((g: any) => <option key={g.id} value={g.id}>{g.name}</option>)}
              </select>
            </div>
          </div>
          {error && <div className="error-msg">{error}</div>}
          <div className="modal-btns">
            <button className="btn-save" onClick={handleExamSubmit} disabled={createExamMutation.isPending}>{isAr ? "حفظ" : "Save"}</button>
          </div>
        </div>
      </Modal>

      {/* Result Upload Modal */}
      <Modal isOpen={isResultOpen} onClose={() => setIsResultOpen(false)} title={isAr ? "رفع نتائج المدرسة" : "Upload School Results"}>
        <div className="modal-form">
          <div className="form-group">
            <label>{isAr ? "عنوان الكشف *" : "Document Title *"}</label>
            <input placeholder="e.g. Term 1 Results - Primary" value={resultForm.name} onChange={e => setResultForm({ ...resultForm, name: e.target.value })} />
          </div>
          <div className="form-grid">
            <div className="form-group">
              <label>{isAr ? "الصف الدراسي / المرحلة" : "Grade / Category"}</label>
              <select value={resultForm.category} onChange={e => setResultForm({ ...resultForm, category: e.target.value })}>
                <option value="">{isAr ? "اختر الصف" : "Select Grade"}</option>
                {grades?.map((g: any) => (
                  <option key={g.id} value={g.name}>{g.name}</option>
                ))}
                <option value="General">{isAr ? "نتائج عامة" : "General Results"}</option>
              </select>
            </div>
            <div className="form-group">
              <label>{isAr ? "السنة الدراسية" : "Academic Year"}</label>
              <input value={resultForm.year} onChange={e => setResultForm({ ...resultForm, year: e.target.value })} />
            </div>
          </div>

          <div className="upload-zone card-glass">
            <input type="file" id="resFile" hidden onChange={e => e.target.files?.[0] && handleFileUpload(e.target.files[0])} />
            <label htmlFor="resFile" className="upload-label">
              {uploading ? <div className="spinner" /> : resultForm.fileUrl ? <CheckCircle2 color="#10b981" /> : <Upload />}
              <span>{resultForm.fileUrl ? (isAr ? "تم الرفع بنجاح" : "File Ready") : (isAr ? "اضغط لرفع ملف (PDF/Excel)" : "Click to upload PDF/Excel")}</span>
            </label>
          </div>

          {error && <div className="error-msg">{error}</div>}
          <div className="modal-btns">
            <button className="btn-save" onClick={handleResultSubmit} disabled={uploadResultMutation.isPending || !resultForm.fileUrl}>
              {uploadResultMutation.isPending ? "..." : (isAr ? "نشر النتائج" : "Publish Results")}
            </button>
          </div>
        </div>
      </Modal>

      <style jsx>{`
        .exams-module { display: flex; flex-direction: column; gap: 32px; }
        .tab-switcher { display: flex; gap: 8px; padding: 6px; border-radius: 14px; width: fit-content; }
        .tab-switcher button { padding: 10px 20px; border-radius: 10px; border: none; background: transparent; color: var(--glass-text-muted); font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 8px; transition: 0.2s; }
        .tab-switcher button.active { background: var(--gradient-primary); color: #fff; }
        
        .module-header { display: flex; justify-content: space-between; align-items: center; }
        .title { font-size: 28px; font-weight: 800; color: var(--glass-text-primary); }
        .subtitle { color: var(--glass-text-secondary); font-size: 14px; margin-top: 4px; }
        
        .btn-add { background: var(--gradient-primary); color: #fff; border: none; padding: 12px 24px; border-radius: 12px; font-weight: 800; display: flex; align-items: center; gap: 8px; cursor: pointer; }
        
        .exams-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 24px; }
        .exam-card { padding: 24px; position: relative; border: 1px solid var(--glass-border); border-radius: 20px; transition: 0.3s; }
        .exam-card:hover { transform: translateY(-4px); border-color: var(--primary-light); }
        .exam-type-badge { position: absolute; top: 12px; inset-inline-end: 12px; font-size: 10px; font-weight: 900; padding: 4px 8px; background: rgba(0,0,0,0.05); border-radius: 6px; }
        .exam-name { font-size: 15px; font-weight: 800; margin-bottom: 8px; }
        .exam-meta { display: flex; flex-direction: column; gap: 4px; }
        .meta-item { display: flex; align-items: center; gap: 8px; font-size: 12px; color: var(--glass-text-muted); font-weight: 600; }
        .card-actions { display: flex; gap: 8px; position: absolute; bottom: 12px; inset-inline-end: 12px; }
        .action-btn { width: 36px; height: 36px; border-radius: 10px; border: 1px solid var(--glass-border); background: transparent; display: flex; align-items: center; justify-content: center; cursor: pointer; color: var(--glass-text-muted); }
        .action-btn:hover { color: var(--glass-text-primary); border-color: var(--primary-light); }
        .action-btn.delete:hover { color: #ef4444; border-color: rgba(239, 68, 68, 0.2); background: rgba(239, 68, 68, 0.1); }

        /* LUXURY STAT CARDS */
        .luxury-stat-card { position: relative; border-radius: 24px; background: var(--glass-bg); border: 1px solid var(--glass-border); overflow: hidden; transition: 0.4s cubic-bezier(0.2, 0, 0, 1); cursor: default; }
        .luxury-stat-card:hover { transform: translateY(-6px) scale(1.02); border-color: var(--accent-color); box-shadow: 0 12px 25px rgba(0,0,0,0.1); }
        .luxury-stat-inner { padding: 14px 18px; position: relative; z-index: 2; height: 100%; display: flex; flex-direction: column; }
        .l-stat-bg-blob { position: absolute; bottom: -20px; inset-inline-end: -20px; width: 80px; height: 80px; background: var(--accent-color); filter: blur(40px); opacity: 0.12; transition: 0.4s; z-index: 1; pointer-events: none; }
        .luxury-stat-card:hover .l-stat-bg-blob { opacity: 0.25; transform: scale(1.3); }

        /* CLEAN PREMIUM RESULTS GRID */
        .results-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(380px, 1fr)); gap: 24px; }
        
        .result-card-v2 {
          display: flex;
          align-items: center;
          gap: 20px;
          padding: 24px;
          background: var(--glass-bg);
          border: 1px solid var(--glass-border);
          border-radius: 20px;
          transition: all 0.3s ease;
          position: relative;
        }
        .result-card-v2:hover {
          transform: translateY(-5px);
          border-color: var(--primary-light);
          box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .res-icon {
          width: 44px;
          height: 44px;
          border-radius: 12px;
          background: var(--gradient-primary);
          color: #fff;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 10px rgba(59, 130, 246, 0.2);
        }
        
        .res-content { flex: 1; min-width: 0; }
        .res-top { display: flex; align-items: center; gap: 8px; margin-bottom: 2px; }
        .res-tag { font-size: 9px; font-weight: 800; text-transform: uppercase; color: var(--primary-light); background: rgba(59, 130, 246, 0.1); padding: 1px 6px; border-radius: 4px; }
        .res-date { font-size: 10px; color: var(--glass-text-muted); font-weight: 600; }
        
        .res-title { 
          font-size: 15px; 
          font-weight: 800; 
          color: var(--glass-text-primary); 
          margin: 0;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .res-sub { font-size: 12px; color: var(--glass-text-secondary); margin-top: 1px; font-weight: 600; }
        
        .res-ops { display: flex; gap: 6px; }
        .op-btn {
          width: 34px;
          height: 34px;
          border-radius: 10px;
          border: 1px solid var(--glass-border);
          background: transparent;
          display: flex;
          align-items: center;
          justify-content: center;
          color: var(--glass-text-muted);
          transition: 0.2s;
          cursor: pointer;
        }
        .op-btn:hover { border-color: var(--primary-light); color: var(--glass-text-primary); }
        .op-btn.dl:hover { background: var(--gradient-primary); color: #fff; border: none; }
        .op-btn.del:hover { background: rgba(239, 68, 68, 0.1); color: #ef4444; border-color: rgba(239, 68, 68, 0.2); }

        /* Modal Form */
        .modal-form { display: flex; flex-direction: column; gap: 20px; }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .form-group label { display: block; font-size: 13px; font-weight: 700; color: var(--glass-text-secondary); margin-bottom: 8px; }
        .form-group input, .form-group select { width: 100%; padding: 12px; border-radius: 10px; background: var(--glass-input-bg); border: 1px solid var(--glass-border); color: var(--glass-text-primary); outline: none; }
        
        .upload-zone { padding: 40px; text-align: center; border: 2px dashed var(--glass-border); }
        .upload-label { cursor: pointer; display: flex; flex-direction: column; align-items: center; gap: 12px; font-weight: 700; color: var(--glass-text-secondary); }
        
        .modal-btns { display: flex; justify-content: flex-end; margin-top: 10px; }
        .btn-save { padding: 12px 32px; border-radius: 12px; border: none; background: var(--gradient-primary); color: #fff; font-weight: 800; cursor: pointer; }
        
        .loading-state, .empty-state { text-align: center; padding: 80px 0; }
        .spinner { width: 24px; height: 24px; border: 3px solid rgba(255,255,255,0.1); border-top-color: var(--primary-light); border-radius: 50%; animation: spin 1s linear infinite; }
        @keyframes spin { to { transform: rotate(360deg); } }
        .error-msg { color: #ef4444; font-size: 13px; font-weight: 600; }
      `}</style>
    </div>
  );
}
