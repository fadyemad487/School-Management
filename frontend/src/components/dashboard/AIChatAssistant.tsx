"use client";

import React, { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, Send, BrainCircuit, Activity, RotateCcw, Menu, MessageSquarePlus, History, Trash2, Lock, Unlock, Key, ShieldCheck } from "lucide-react";
import { useTranslation } from "@/lib/i18n";
import { useAuth } from "@/components/shared/AuthProvider";
import { api } from "@/lib/api";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

export function AIChatAssistant({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  const { isAr } = useTranslation();
  const { user } = useAuth();
  const schoolName = user?.school?.name || (isAr ? "إديو كنترول" : "EduControl");
  const [message, setMessage] = useState("");
  const [history, setHistory] = useState<{ role: "user" | "model"; parts: { text: string }[] }[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  
  // New States for Sessions
  const [currentSessionId, setCurrentSessionId] = useState<string | null>(null);
  const [sessions, setSessions] = useState<{ sessionId: string, content: string, createdAt: string }[]>([]);
  
  // Security States
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [hasAIPassword, setHasAIPassword] = useState<boolean | null>(null);
  const [aiPasswordInput, setAiPasswordInput] = useState("");
  const [securityError, setSecurityError] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);
  
  const scrollRef = useRef<HTMLDivElement>(null);
  const assistantRef = useRef<HTMLDivElement>(null);

  // Click Outside logic
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (isOpen && assistantRef.current && !assistantRef.current.contains(event.target as Node)) {
        onClose();
      }
    }
    
    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isOpen, onClose]);

  const fetchHistory = async (sid?: string) => {
    try {
      const url = sid ? `/ai/history?sessionId=${sid}` : "/ai/history";
      const response = await api.get(url);
      if (response.data.success && response.data.history) {
        setHistory(response.data.history);
        if (sid) setCurrentSessionId(sid);
      }
    } catch (error) {
      console.error("Failed to load AI history:", error);
    }
  };

  const fetchSessions = async () => {
    try {
      const response = await api.get("/ai/sessions");
      if (response.data.success && response.data.sessions) {
        setSessions(response.data.sessions);
      }
    } catch (error) {
      console.error("Failed to load AI sessions:", error);
    }
  };

  const checkSecurityStatus = async () => {
    try {
      const response = await api.get("/ai/password-status");
      setHasAIPassword(response.data.isPasswordSet);
    } catch (error) {
      console.error("Failed to check AI security status:", error);
    }
  };

  useEffect(() => {
    if (isOpen) {
      setIsUnlocked(false);
      setAiPasswordInput("");
      setSecurityError("");
      checkSecurityStatus();
    }
  }, [isOpen]);

  useEffect(() => {
    if (isOpen && isUnlocked) {
      fetchSessions();
    }
  }, [isOpen, isUnlocked]);

  const handleVerifyPassword = async () => {
    if (!aiPasswordInput) return;
    setIsVerifying(true);
    setSecurityError("");
    try {
      const endpoint = hasAIPassword ? "/ai/verify-password" : "/ai/set-password";
      const response = await api.post(endpoint, { password: aiPasswordInput });
      if (response.data.success) {
        setIsUnlocked(true);
        if (!hasAIPassword) setHasAIPassword(true);
      }
    } catch (error: any) {
      setSecurityError(error.response?.data?.message || (isAr ? "كلمة المرور غير صحيحة" : "Incorrect password"));
    } finally {
      setIsVerifying(false);
    }
  };

  const handleNewChat = () => {
    setHistory([]);
    setCurrentSessionId(null);
    setIsMenuOpen(false);
  };

  const loadSession = (sid: string) => {
    fetchHistory(sid);
    setIsMenuOpen(false);
  };

  const handleDeleteSession = async (sid: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!window.confirm(isAr ? "هل أنت متأكد من حذف هذه المحادثة؟" : "Are you sure you want to delete this chat?")) return;
    
    try {
      const response = await api.delete(`/ai/sessions/${sid}`);
      if (response.data.success) {
        setSessions(sessions.filter(s => s.sessionId !== sid));
        if (currentSessionId === sid) {
          handleNewChat();
        }
      }
    } catch (error) {
      console.error("Failed to delete session:", error);
    }
  };

  useEffect(() => {
    const checkTheme = () => {
      setIsDarkMode(document.documentElement.classList.contains("dark"));
    };
    checkTheme();
    const observer = new MutationObserver(checkTheme);
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ["class"] });
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
    }
  }, [history, isLoading]);

  const handleSend = async (customMsg?: string, clearLast: boolean = false) => {
    const msgToSend = customMsg || message.trim();
    if (!msgToSend || isLoading) return;

    if (!customMsg) setMessage("");
    
    let newHistory = history;
    if (clearLast) {
      newHistory = [...history];
      newHistory.pop();
    } else if (!customMsg) {
      newHistory = [...history, { role: "user" as const, parts: [{ text: msgToSend }] }];
    }
    
    if (!customMsg || clearLast) setHistory(newHistory);

    setIsLoading(true);

    // Generate a new session ID if one doesn't exist
    let activeSessionId = currentSessionId;
    if (!activeSessionId) {
      activeSessionId = crypto.randomUUID();
      setCurrentSessionId(activeSessionId);
    }

    try {
      const res = await api.post("/ai/chat", { 
        message: msgToSend, 
        history: newHistory, 
        isRetry: clearLast,
        sessionId: activeSessionId
      });
      setHistory([...newHistory, { role: "model" as const, parts: [{ text: res.data.reply }] }]);
      // Refresh sessions list silently so the new chat appears in the menu
      fetchSessions();
    } catch (error) {
      setHistory([...newHistory, { role: "model" as const, parts: [{ text: isAr ? "خلل في النظام العصبي للذكاء الاصطناعي." : "Neural link failed." }] }]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleRetry = () => {
    const lastUserMsg = [...history].reverse().find(h => h.role === "user");
    if (lastUserMsg) {
      // Retry by sending the last message and clearing the "failed" one
      handleSend(lastUserMsg.parts[0].text, true);
    }
  };

  return (
    <div className="ai-neural-root" style={{ position: "fixed", top: 0, right: 0, bottom: 0, zIndex: 999999, pointerEvents: "none" }}>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            ref={assistantRef}
            initial={{ x: "100%", opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: "100%", opacity: 0 }}
            transition={{ type: "spring", damping: 25, stiffness: 200 }}
            style={{
              position: "absolute",
              top: "20px",
              right: "20px",
              bottom: "20px",
              width: "450px",
              background: "rgba(5, 5, 10, 0.9)",
              backdropFilter: "blur(50px)",
              borderRadius: "32px",
              border: "1px solid rgba(255, 255, 255, 0.05)",
              boxShadow: "-20px 0 80px rgba(0,0,0,0.8)",
              display: "flex",
              flexDirection: "column",
              pointerEvents: "auto",
              overflow: "hidden"
            }}
          >
            <div style={{ padding: "40px 30px 20px", position: "relative" }}>
              <motion.div
                animate={{
                  backgroundPosition: ["0% 50%", "100% 50%", "0% 50%"],
                  boxShadow: [
                    "0 0 5px rgba(124, 58, 237, 0.2)",
                    "0 0 15px rgba(124, 58, 237, 0.6)",
                    "0 0 5px rgba(124, 58, 237, 0.2)"
                  ]
                }}
                transition={{ repeat: Infinity, duration: 4, ease: "linear" }}
                style={{
                  position: "absolute",
                  top: 0,
                  left: 0,
                  right: 0,
                  height: "4px",
                  background: "linear-gradient(90deg, transparent, rgb(29, 78, 216), rgb(124, 58, 237), rgb(29, 78, 216), transparent)",
                  backgroundSize: "200% 200%",
                  zIndex: 10
                }}
              />
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <h2 style={{ color: "#fff", fontSize: "24px", fontWeight: 900, letterSpacing: "-1px" }}>EduControl</h2>
                  <div style={{ display: "flex", alignItems: "center", gap: "8px", marginTop: "4px" }}>
                    <Activity size={14} color="rgb(124, 58, 237)" />
                    <span style={{ color: "rgba(255,255,255,0.4)", fontSize: "11px", fontWeight: 700, textTransform: "uppercase", letterSpacing: "2px" }}>
                      {isAr ? "المساعد الذكي نشط" : "AI Smart Assistant"}
                    </span>
                  </div>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                  <div style={{ position: "relative" }}>
                    <button
                      onClick={() => setIsMenuOpen(!isMenuOpen)}
                      style={{
                        width: "40px",
                        height: "40px",
                        borderRadius: "12px",
                        background: isMenuOpen ? "rgba(124, 58, 237, 0.2)" : "rgba(255,255,255,0.05)",
                        border: isMenuOpen ? "1px solid rgba(124, 58, 237, 0.4)" : "1px solid rgba(255,255,255,0.1)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: isMenuOpen ? "rgb(124, 58, 237)" : "rgba(255,255,255,0.5)",
                        cursor: "pointer",
                        transition: "all 0.2s"
                      }}
                    >
                      <Menu size={20} />
                    </button>
                    
                    <AnimatePresence>
                      {isMenuOpen && (
                        <motion.div
                          initial={{ opacity: 0, y: 10, scale: 0.95 }}
                          animate={{ opacity: 1, y: 0, scale: 1 }}
                          exit={{ opacity: 0, y: 10, scale: 0.95 }}
                          style={{
                            position: "absolute",
                            top: "50px",
                            right: 0,
                            width: "280px",
                            background: "rgba(10, 10, 15, 0.95)",
                            backdropFilter: "blur(20px)",
                            borderRadius: "16px",
                            border: "1px solid rgba(255,255,255,0.1)",
                            boxShadow: "0 10px 40px rgba(0,0,0,0.5)",
                            overflow: "hidden",
                            zIndex: 20
                          }}
                        >
                          <button
                            onClick={handleNewChat}
                            style={{
                              width: "100%",
                              padding: "12px 16px",
                              display: "flex",
                              alignItems: "center",
                              gap: "10px",
                              color: "#fff",
                              background: "rgba(124, 58, 237, 0.1)",
                              border: "none",
                              borderBottom: "1px solid rgba(255,255,255,0.05)",
                              cursor: "pointer",
                              textAlign: isAr ? "right" : "left",
                              fontSize: "14px",
                              fontWeight: 600
                            }}
                            onMouseOver={(e) => e.currentTarget.style.background = "rgba(124, 58, 237, 0.2)"}
                            onMouseOut={(e) => e.currentTarget.style.background = "rgba(124, 58, 237, 0.1)"}
                          >
                            <MessageSquarePlus size={16} color="rgb(124, 58, 237)" />
                            {isAr ? "محادثة جديدة" : "New Chat"}
                          </button>
                          
                          <div style={{ maxHeight: "300px", overflowY: "auto" }}>
                            {sessions.map((session, index) => (
                              <div
                                key={session.sessionId}
                                style={{
                                  width: "100%",
                                  display: "flex",
                                  alignItems: "center",
                                  borderBottom: index < sessions.length - 1 ? "1px solid rgba(255,255,255,0.05)" : "none",
                                  background: currentSessionId === session.sessionId ? "rgba(255,255,255,0.05)" : "transparent",
                                  transition: "all 0.2s"
                                }}
                                onMouseOver={(e) => { if(currentSessionId !== session.sessionId) e.currentTarget.style.background = "rgba(255,255,255,0.05)" }}
                                onMouseOut={(e) => { if(currentSessionId !== session.sessionId) e.currentTarget.style.background = "transparent" }}
                              >
                                <button
                                  onClick={() => loadSession(session.sessionId)}
                                  style={{
                                    flex: 1,
                                    padding: "12px 10px 12px 16px",
                                    display: "flex",
                                    alignItems: "center",
                                    gap: "10px",
                                    color: currentSessionId === session.sessionId ? "#fff" : "rgba(255,255,255,0.7)",
                                    background: "transparent",
                                    border: "none",
                                    cursor: "pointer",
                                    textAlign: isAr ? "right" : "left",
                                    fontSize: "13px",
                                    fontWeight: currentSessionId === session.sessionId ? 600 : 400,
                                    overflow: "hidden"
                                  }}
                                >
                                  <History size={14} color={currentSessionId === session.sessionId ? "rgb(124, 58, 237)" : "rgba(255,255,255,0.4)"} style={{ minWidth: "14px" }} />
                                  <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", flex: 1, textAlign: isAr ? "right" : "left" }}>
                                    {session.content}
                                  </span>
                                </button>
                                <button
                                  onClick={(e) => handleDeleteSession(session.sessionId, e)}
                                  style={{
                                    padding: "0 15px",
                                    height: "100%",
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    color: "rgba(255,255,255,0.2)",
                                    background: "transparent",
                                    border: "none",
                                    cursor: "pointer",
                                    transition: "all 0.2s"
                                  }}
                                  onMouseOver={(e) => e.currentTarget.style.color = "#ef4444"}
                                  onMouseOut={(e) => e.currentTarget.style.color = "rgba(255,255,255,0.2)"}
                                >
                                  <Trash2 size={14} />
                                </button>
                              </div>
                            ))}
                            {sessions.length === 0 && (
                              <div style={{ padding: "20px 16px", textAlign: "center", color: "rgba(255,255,255,0.3)", fontSize: "12px" }}>
                                {isAr ? "لا يوجد محادثات سابقة" : "No previous chats"}
                              </div>
                            )}
                          </div>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>

                  <button
                    onClick={onClose}
                    style={{
                      width: "40px",
                      height: "40px",
                      borderRadius: "12px",
                      background: "rgba(255,255,255,0.05)",
                      border: "1px solid rgba(255,255,255,0.1)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: "rgba(255,255,255,0.5)",
                      cursor: "pointer",
                      transition: "all 0.2s"
                    }}
                    onMouseOver={(e) => e.currentTarget.style.background = "rgba(239, 68, 68, 0.2)"}
                    onMouseOut={(e) => e.currentTarget.style.background = "rgba(255,255,255,0.05)"}
                  >
                    <X size={20} />
                  </button>
                </div>
              </div>
            </div>

            <AnimatePresence mode="wait">
              {!isUnlocked ? (
                <motion.div
                  key="lock-screen"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  style={{
                    flex: 1,
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    justifyContent: "center",
                    padding: "40px",
                    textAlign: "center"
                  }}
                >
                  <motion.div
                    animate={{ y: [0, -10, 0] }}
                    transition={{ repeat: Infinity, duration: 3 }}
                    style={{
                      width: "100px",
                      height: "100px",
                      borderRadius: "30px",
                      background: "rgba(124, 58, 237, 0.1)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      marginBottom: "30px",
                      border: "1px solid rgba(124, 58, 237, 0.2)",
                      boxShadow: "0 0 40px rgba(124, 58, 237, 0.1)"
                    }}
                  >
                    <Lock size={40} color="rgb(124, 58, 237)" />
                  </motion.div>

                  <h3 style={{ color: "#fff", fontSize: "20px", fontWeight: 800, marginBottom: "12px" }}>
                    {hasAIPassword === false 
                      ? (isAr ? "تفعيل نظام الحماية" : "Activate Security System")
                      : (isAr ? "نظام الحماية مفعل" : "AI Neural Lock Active")
                    }
                  </h3>
                  <p style={{ color: "rgba(255,255,255,0.4)", fontSize: "14px", marginBottom: "30px", maxWidth: "300px", lineHeight: 1.6 }}>
                    {hasAIPassword === false
                      ? (isAr ? "يجب إنشاء كلمة مرور قوية للمساعد الذكي لأول مرة لحماية بيانات المدرسة." : "Set a master password for the AI Agent to protect your school data.")
                      : (isAr ? "يرجى إدخال كلمة مرور المساعد الذكي للمتابعة." : "Please enter the AI Agent master password to continue.")
                    }
                  </p>

                  <div style={{ width: "100%", maxWidth: "300px", position: "relative" }}>
                    <div style={{ position: "relative" }}>
                      <Key size={18} color="rgba(255,255,255,0.3)" style={{ position: "absolute", left: "15px", top: "50%", transform: "translateY(-50%)" }} />
                      <input
                        type="password"
                        value={aiPasswordInput}
                        onChange={(e) => setAiPasswordInput(e.target.value)}
                        onKeyDown={(e) => e.key === "Enter" && handleVerifyPassword()}
                        placeholder={isAr ? "كلمة المرور..." : "Enter password..."}
                        autoFocus
                        style={{
                          width: "100%",
                          background: "rgba(255,255,255,0.03)",
                          border: `1px solid ${securityError ? "rgba(239, 68, 68, 0.3)" : "rgba(255,255,255,0.1)"}`,
                          borderRadius: "16px",
                          padding: "15px 15px 15px 45px",
                          color: "#fff",
                          fontSize: "15px",
                          outline: "none",
                          textAlign: isAr ? "right" : "left"
                        }}
                      />
                    </div>
                    
                    {securityError && (
                      <motion.p
                        initial={{ opacity: 0, y: -5 }}
                        animate={{ opacity: 1, y: 0 }}
                        style={{ color: "#ef4444", fontSize: "12px", marginTop: "10px", fontWeight: 600 }}
                      >
                        {securityError}
                      </motion.p>
                    )}

                    <motion.button
                      whileHover={{ scale: 1.02, background: "rgb(139, 92, 246)" }}
                      whileTap={{ scale: 0.98 }}
                      onClick={handleVerifyPassword}
                      disabled={isVerifying || !aiPasswordInput}
                      style={{
                        width: "100%",
                        marginTop: "20px",
                        padding: "15px",
                        borderRadius: "16px",
                        background: "rgb(124, 58, 237)",
                        color: "#fff",
                        border: "none",
                        fontWeight: 700,
                        fontSize: "14px",
                        cursor: isVerifying ? "not-allowed" : "pointer",
                        opacity: isVerifying || !aiPasswordInput ? 0.6 : 1,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        gap: "10px"
                      }}
                    >
                      {isVerifying ? (
                        <RotateCcw size={16} className="animate-spin" />
                      ) : (
                        <>
                          <ShieldCheck size={18} />
                          {hasAIPassword === false ? (isAr ? "تأكيد وإنشاء" : "Initialize & Secure") : (isAr ? "فتح النظام" : "Unlock Neural Core")}
                        </>
                      )}
                    </motion.button>
                  </div>
                </motion.div>
              ) : (
                <>
                  <div
                    ref={scrollRef}
                    style={{ flex: 1, overflowY: "auto", padding: "20px 30px", display: "flex", flexDirection: "column", gap: "20px" }}
                  >
              {history.length === 0 && (
                <div style={{
                  padding: "40px 0",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  textAlign: "center",
                  gap: "24px"
                }}>
                  <motion.div
                    animate={{
                      scale: [1, 1.05, 1],
                      filter: ["drop-shadow(0 0 5px rgba(79, 172, 254, 0.4))", "drop-shadow(0 0 20px rgba(124, 58, 237, 0.6))", "drop-shadow(0 0 5px rgba(79, 172, 254, 0.4))"]
                    }}
                    transition={{ repeat: Infinity, duration: 4, ease: "easeInOut" }}
                    style={{
                      width: "80px",
                      height: "80px",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      marginTop: "-60px"
                    }}
                  >
                    <svg width="70" height="70" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M12 4C12 4 12.5 8.5 18 10C12.5 11.5 12 17 12 17C12 17 11.5 11.5 6 10C11.5 8.5 12 4 12 4Z" fill="url(#gemini-grad-1)" />
                      <path d="M19 5C19 5 19.2 6.5 21 7.2C19.2 7.9 19 9.4 19 9.4C19 9.4 18.8 7.9 17 7.2C18.8 6.5 19 5 19 5Z" fill="url(#gemini-grad-2)" />
                      <path d="M6 14C6 14 6.2 16.5 8.5 17.5C6.2 18.5 6 21 6 21C6 21 5.8 18.5 3.5 17.5C5.8 16.5 6 14 6 14Z" fill="url(#gemini-grad-3)" />
                      <defs>
                        <linearGradient id="gemini-grad-1" x1="6" y1="4" x2="18" y2="17" gradientUnits="userSpaceOnUse">
                          <stop stopColor="#4facfe" />
                          <stop offset="1" stopColor="#7c3aed" />
                        </linearGradient>
                        <linearGradient id="gemini-grad-2" x1="17" y1="5" x2="21" y2="9.4" gradientUnits="userSpaceOnUse">
                          <stop stopColor="#00f2fe" />
                          <stop offset="1" stopColor="#4facfe" />
                        </linearGradient>
                        <linearGradient id="gemini-grad-3" x1="3.5" y1="14" x2="8.5" y2="21" gradientUnits="userSpaceOnUse">
                          <stop stopColor="#7c3aed" />
                          <stop offset="1" stopColor="#4facfe" />
                        </linearGradient>
                      </defs>
                    </svg>
                  </motion.div>

                  <div>
                    <h3 style={{ color: "#fff", fontSize: "22px", fontWeight: 900, marginBottom: "8px" }}>
                      {isAr ? `أهلاً بك في ${schoolName}` : `Welcome to ${schoolName}`}
                    </h3>
                    <p style={{ color: "rgba(255,255,255,0.4)", fontSize: "14px", maxWidth: "280px", margin: "0 auto", lineHeight: 1.6 }}>
                      {isAr
                        ? "وحدة التحكم الذكية جاهزة لتنفيذ أوامرك. ماذا تريد أن تنجز اليوم؟"
                        : "The neural core is online. What would you like to achieve today?"}
                    </p>
                  </div>

                  <div style={{ display: "flex", flexWrap: "wrap", justifyContent: "center", gap: "10px", marginTop: "10px" }}>
                    {[
                      isAr ? "تحليل الغياب" : "Attendance AI",
                      isAr ? "الجدول الزمني" : "Schedule",
                      isAr ? "التقارير" : "Reports"
                    ].map((action, idx) => (
                      <motion.button
                        key={idx}
                        whileHover={{ scale: 1.05, background: "rgba(124, 58, 237, 0.2)" }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => {
                          setMessage(action);
                          setTimeout(() => handleSend(), 0);
                        }}
                        style={{
                          padding: "8px 16px",
                          borderRadius: "12px",
                          background: "rgba(255,255,255,0.03)",
                          border: "1px solid rgba(255,255,255,0.05)",
                          color: "rgba(255,255,255,0.6)",
                          fontSize: "12px",
                          fontWeight: 600,
                          cursor: "pointer"
                        }}
                      >
                        {action}
                      </motion.button>
                    ))}
                  </div>
                </div>
              )}

              {history.map((chat, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  style={{ alignSelf: chat.role === "user" ? "flex-end" : "flex-start", maxWidth: "90%" }}
                >
                  <div style={{ color: chat.role === "user" ? "#fff" : "rgba(255,255,255,0.8)", fontSize: "15px", lineHeight: 1.7, textAlign: chat.role === "user" ? "right" : "left", display: "flex", flexDirection: "column", alignItems: chat.role === "user" ? "flex-end" : "flex-start" }}>
                    {chat.role === "user" ? (
                      <span style={{ paddingBottom: "4px", borderBottom: "2px solid rgb(124, 58, 237)" }}>{chat.parts[0].text}</span>
                    ) : (
                      <div style={{ display: "flex", alignItems: "flex-end", gap: "10px", width: "100%" }}>
                        <div className="prose prose-invert max-w-none" style={{ background: "rgba(255,255,255,0.03)", padding: "20px", borderRadius: "20px", border: "1px solid rgba(255,255,255,0.05)", width: "100%", fontSize: "14px" }}>
                          <ReactMarkdown 
                            remarkPlugins={[remarkGfm]}
                            components={{
                              table: ({node, ...props}) => <div style={{ overflowX: "auto", margin: "10px 0" }}><table style={{ width: "100%", borderCollapse: "collapse", background: "rgba(0,0,0,0.2)", borderRadius: "10px" }} {...props} /></div>,
                              th: ({node, ...props}) => <th style={{ borderBottom: "1px solid rgba(255,255,255,0.1)", padding: "10px", textAlign: "right", color: "rgb(124, 58, 237)" }} {...props} />,
                              td: ({node, ...props}) => <td style={{ padding: "10px", borderBottom: "1px solid rgba(255,255,255,0.05)", color: "rgba(255,255,255,0.7)" }} {...props} />,
                              p: ({node, ...props}) => <p style={{ margin: "5px 0" }} {...props} />,
                              ul: ({node, ...props}) => <ul style={{ paddingRight: "20px", margin: "10px 0" }} {...props} />,
                              li: ({node, ...props}) => <li style={{ marginBottom: "5px" }} {...props} />
                            }}
                          >
                            {chat.parts[0].text}
                          </ReactMarkdown>
                        </div>
                        {(chat.parts[0].text.includes("Neural link failed") || chat.parts[0].text.includes("خلل في النظام")) && (
                          <motion.button
                            whileHover={{ scale: 1.1, color: "#fff" }}
                            whileTap={{ scale: 0.9 }}
                            onClick={handleRetry}
                            style={{ background: "transparent", border: "none", color: "rgba(255,255,255,0.4)", cursor: "pointer", padding: "5px" }}
                            title={isAr ? "إعادة المحاولة" : "Retry"}
                          >
                            <RotateCcw size={16} />
                          </motion.button>
                        )}
                      </div>
                    )}
                  </div>
                </motion.div>
              ))}

              {isLoading && (
                <div style={{ display: "flex", gap: "8px", padding: "10px" }}>
                  <motion.div animate={{ opacity: [0.3, 1, 0.3] }} transition={{ repeat: Infinity, duration: 1 }} style={{ width: "6px", height: "6px", borderRadius: "50%", background: "rgb(124, 58, 237)" }} />
                  <motion.div animate={{ opacity: [0.3, 1, 0.3] }} transition={{ repeat: Infinity, duration: 1, delay: 0.2 }} style={{ width: "6px", height: "6px", borderRadius: "50%", background: "rgb(124, 58, 237)" }} />
                  <motion.div animate={{ opacity: [0.3, 1, 0.3] }} transition={{ repeat: Infinity, duration: 1, delay: 0.4 }} style={{ width: "6px", height: "6px", borderRadius: "50%", background: "rgb(124, 58, 237)" }} />
                </div>
              )}
            </div>

            <div style={{ padding: "30px", background: "rgba(0,0,0,0.2)" }}>
              <div style={{ position: "relative" }}>
                <input
                  type="text"
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && handleSend()}
                  placeholder={isAr ? "اكتب استفسارك هنا..." : "Input neural command..."}
                  style={{
                    width: "100%",
                    background: "rgba(255,255,255,0.03)",
                    border: "1px solid rgba(255,255,255,0.08)",
                    borderRadius: "20px",
                    padding: "15px 50px 15px 20px",
                    color: "#fff",
                    fontSize: "15px",
                    outline: "none"
                  }}
                />
                <button onClick={() => handleSend()} style={{ position: "absolute", right: 15, top: "50%", transform: "translateY(-50%)", background: "transparent", border: "none", color: "rgb(124, 58, 237)", cursor: "pointer" }}>
                  <Send size={20} />
                </button>
              </div>
            </div>
          </>
        )}
      </AnimatePresence>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
