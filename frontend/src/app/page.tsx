"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useTranslation } from "@/lib/i18n";
import { LanguageSwitcher } from "@/components/ui/LanguageSwitcher";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { AuthModal } from "@/components/auth/AuthModal";

/* ── SVG Icons (inline for zero deps) ── */
const BrandIcon = () => (
  <svg viewBox="0 0 24 24" fill="none"><path d="M12 3l9 4.5-9 4.5-9-4.5L12 3z" stroke="#fff" strokeWidth="1.6" strokeLinejoin="round"/><path d="M6 10.5V16c0 1.5 2.7 3 6 3s6-1.5 6-3v-5.5" stroke="#fff" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/></svg>
);
const ChevIcon = () => (
  <svg className="chev" viewBox="0 0 24 24" fill="none"><path d="M6 9l6 6 6-6" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/></svg>
);
const SearchIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="7" stroke="currentColor" strokeWidth="2"/><path d="M21 21l-4-4" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/></svg>
);
const CheckIcon = () => (
  <svg viewBox="0 0 24 24" fill="none"><path d="M5 12l5 5L20 7" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/></svg>
);
const AttendanceIcon = () => (
  <svg viewBox="0 0 24 24" fill="none"><path d="M4 12h16M4 6h10M4 18h7" stroke="#fff" strokeWidth="2.2" strokeLinecap="round"/></svg>
);
const GradeIcon = () => (
  <svg viewBox="0 0 24 24" fill="none"><path d="M9 13h6M9 16h6" stroke="#fff" strokeWidth="2" strokeLinecap="round"/><path d="M6 4h9l5 5v11a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z" stroke="#fff" strokeWidth="1.8"/></svg>
);
const CalendarIcon = () => (
  <svg viewBox="0 0 24 24" fill="none"><rect x="4" y="5" width="16" height="15" rx="2" stroke="#fff" strokeWidth="1.8"/><path d="M4 9.5h16" stroke="#fff" strokeWidth="1.8"/></svg>
);
const ChatIcon = () => (
  <svg viewBox="0 0 24 24" fill="none"><path d="M4 5h16v11H8l-4 4V5z" stroke="#fff" strokeWidth="1.8" strokeLinejoin="round"/></svg>
);
const ReportIcon = () => (
  <svg viewBox="0 0 24 24" fill="none"><path d="M4 20V10M11 20V4M18 20v-7" stroke="#fff" strokeWidth="2.2" strokeLinecap="round"/></svg>
);

interface LandingPageProps {
  initialAuthOpen?: boolean;
  initialAuthMode?: 'login' | 'register' | 'forgot';
}

export default function LandingPage({ initialAuthOpen = false, initialAuthMode = 'login' }: LandingPageProps = {}) {
  const { t, isAr } = useTranslation();
  const [scrolled, setScrolled] = useState(false);
  const [isDark, setIsDark] = useState(false);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [authModalOpen, setAuthModalOpen] = useState(initialAuthOpen);
  const [authModalMode, setAuthModalMode] = useState<'login' | 'register' | 'forgot'>(initialAuthMode);

  const openLogin = () => {
    setDrawerOpen(false);
    setAuthModalMode('login');
    setAuthModalOpen(true);
  };

  const openRegister = () => {
    setDrawerOpen(false);
    setAuthModalMode('register');
    setAuthModalOpen(true);
  };

  const openForgot = () => {
    setDrawerOpen(false);
    setAuthModalMode('forgot');
    setAuthModalOpen(true);
  };

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    window.addEventListener("scroll", onScroll);

    if (typeof window !== "undefined") {
      const savedTheme = localStorage.getItem("cv_theme");
      if (savedTheme === "dark") {
        setIsDark(true);
      }

      const params = new URLSearchParams(window.location.search);
      if (params.get("auth") === "register" || params.get("register") === "true") {
        openRegister();
      } else if (params.get("auth") === "forgot" || params.get("forgot") === "true") {
        openForgot();
      } else if (params.get("auth") === "login" || params.get("login") === "true") {
        openLogin();
      }
    }

    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const toggleTheme = () => {
    setIsDark((prev) => {
      const next = !prev;
      if (typeof window !== "undefined") {
        localStorage.setItem("cv_theme", next ? "dark" : "light");
      }
      return next;
    });
  };

  const searchPlaceholder = isAr
    ? "دوّر على طالب، فصل، أو تقرير..."
    : "Search a student, class, or report...";

  return (
    <div className={`cv-landing ${isDark ? "cv-dark" : ""}`}>
      {/* ══════════ HEADER / NAV ══════════ */}
      <header className={`cv-header ${scrolled ? "scrolled" : ""}`}>
        <div className="wrap cv-nav">
          <Link href="/" className="cv-brand disp">
            <span className="cv-brand-mark"><BrandIcon /></span>
            EduControl
          </Link>

          <nav className="cv-nav-links">
            {/* Features Dropdown */}
            <div className="cv-nav-item">
              <button type="button">
                {isAr ? "المميزات" : "Features"} <ChevIcon />
              </button>
              <div className="cv-mega">
                <a href="#modules">
                  <i style={{ background: "var(--cv-purple)" }}><AttendanceIcon /></i>
                  <span>{isAr ? "الحضور" : "Attendance"}<span className="d">{isAr ? "تسجيل بلمسة واحدة" : "One-tap check-in"}</span></span>
                </a>
                <a href="#modules">
                  <i style={{ background: "var(--cv-cyan)" }}><GradeIcon /></i>
                  <span>{isAr ? "الدرجات" : "Gradebook"}<span className="d">{isAr ? "تقارير أوتوماتيك" : "Automatic reports"}</span></span>
                </a>
                <a href="#modules">
                  <i style={{ background: "var(--cv-pink)" }}><CalendarIcon /></i>
                  <span>{isAr ? "الجدول" : "Timetable"}<span className="d">{isAr ? "جدول كل فصل" : "Every class synced"}</span></span>
                </a>
                <a href="#modules">
                  <i style={{ background: "#22B573" }}><ChatIcon /></i>
                  <span>{isAr ? "التواصل" : "Messaging"}<span className="d">{isAr ? "رسايل فورية للأهل" : "Instant parent alerts"}</span></span>
                </a>
              </div>
            </div>
            <div className="cv-nav-item"><a href="#showcase">{isAr ? "شغل النظام" : "How it works"}</a></div>
            <div className="cv-nav-item"><a href="#voices">{isAr ? "آراء المدارس" : "Reviews"}</a></div>
            <div className="cv-nav-item"><a href="#footer">{isAr ? "تواصل معنا" : "Contact"}</a></div>
          </nav>

          <div className="cv-nav-actions">
            <LanguageSwitcher appearance={isDark ? "onDark" : "onLight"} />
            <ThemeToggle isDark={isDark} onToggle={toggleTheme} />
            <button type="button" onClick={openLogin} className="cv-link-login" style={{ background: "none", border: "none", cursor: "pointer", fontFamily: "inherit" }}>{isAr ? "تسجيل الدخول" : "Log in"}</button>
            <button type="button" onClick={openRegister} className="cv-btn cv-btn-dark">{isAr ? "ابدأ مجانًا" : "Sign up free"}</button>
          </div>

          {/* Glass Burger Button for Mobile & Tablet */}
          <div className={`glass-btn-wrap vd-burger-wrap ${drawerOpen ? "is-open" : ""}`}>
            <div className="glass-btn-shadow" />
            <button
              className="glass-btn edupulse-vd-burger"
              type="button"
              aria-label="Menu"
              aria-expanded={drawerOpen}
              onClick={() => setDrawerOpen((prev) => !prev)}
            >
              <span className="glass-btn-inner">
                <span className="vd-burger-ic">
                  <i /><i /><i />
                </span>
              </span>
            </button>
          </div>
        </div>

        {/* Glass Drawer Menu */}
        <div className={`vd-drawer ${drawerOpen ? "open" : ""}`}>
          <div className="vd-drawer-links">
            <a className="hv2" href="#modules" onClick={() => setDrawerOpen(false)}>{isAr ? "المميزات" : "Features"}</a>
            <a className="hv2" href="#showcase" onClick={() => setDrawerOpen(false)}>{isAr ? "شغل النظام" : "How it works"}</a>
            <a className="hv2" href="#voices" onClick={() => setDrawerOpen(false)}>{isAr ? "آراء المدارس" : "Reviews"}</a>
            <a className="hv2" href="#footer" onClick={() => setDrawerOpen(false)}>{isAr ? "تواصل معنا" : "Contact"}</a>
          </div>

          <div className="vd-drawer-row">
            <LanguageSwitcher appearance={isDark ? "onDark" : "onLight"} />
            <ThemeToggle isDark={isDark} onToggle={toggleTheme} />
          </div>

          <div className="vd-drawer-actions">
            <button
              type="button"
              onClick={openLogin}
              style={{
                width: "100%", padding: "12px", borderRadius: "999px",
                background: isDark ? "rgba(255,255,255,0.08)" : "#F7F3FB",
                border: "none", color: isDark ? "#fff" : "#2A1145",
                fontWeight: 600, fontSize: "15px", cursor: "pointer", fontFamily: "inherit"
              }}
            >
              {isAr ? "تسجيل الدخول" : "Log in"}
            </button>
            <button
              type="button"
              onClick={openRegister}
              className="cv-btn cv-btn-dark cv-btn-block"
            >
              {isAr ? "ابدأ مجانًا" : "Sign up free"}
            </button>
          </div>
        </div>
      </header>

      {/* ══════════ ROUNDED STAGE WRAPPER ══════════ */}
      <div id="edupulse-stage">
        <div id="edupulse-scrollbody">
          {/* ══════════ HERO ══════════ */}
          <main id="top">
        <section className="cv-hero">
          <div className="cv-blob b1" />
          <div className="cv-blob b2" />
          <div className="cv-blob b3" />
          <div className="wrap">
            <h1 className="disp">
              {isAr ? (
                <>كل حاجة مدرستك محتاجاها، <span className="cv-grad-text">في مكان واحد</span></>
              ) : (
                <>Everything your school needs, <span className="cv-grad-text">in one place</span></>
              )}
            </h1>
            <p className="cv-lead">
              {isAr
                ? "الحضور، الدرجات، الجدول، والتواصل مع أولياء الأمور — نظام واحد سهل يستخدمه المدير والمعلم وولي الأمر من غير تعقيد."
                : "Attendance, grades, timetables, and parent communication — one easy system for admins, teachers, and parents alike."}
            </p>

            <div className="cv-search-bar">
              <SearchIcon />
              <input type="text" placeholder={searchPlaceholder} readOnly onClick={openRegister} style={{ cursor: "pointer" }} />
              <button type="button" onClick={openRegister} className="cv-btn cv-btn-grad">{isAr ? "ابدأ" : "Start"}</button>
            </div>

            <div className="cv-quick-tags">
              {[
                { icon: <AttendanceIcon />, bg: "var(--cv-purple)", ar: "الحضور", en: "Attendance" },
                { icon: <GradeIcon />, bg: "var(--cv-cyan)", ar: "الدرجات", en: "Grades" },
                { icon: <CalendarIcon />, bg: "var(--cv-pink)", ar: "الجدول", en: "Schedule" },
                { icon: <ChatIcon />, bg: "#22B573", ar: "الرسائل", en: "Messages" },
                { icon: <ReportIcon />, bg: "#FFB020", ar: "التقارير", en: "Reports" },
              ].map((tag, i) => (
                <a className="cv-quick-tag" href="#modules" key={i}>
                  <i style={{ background: tag.bg }}>{tag.icon}</i>
                  {isAr ? tag.ar : tag.en}
                </a>
              ))}
            </div>
          </div>
        </section>

        {/* ══════════ MODULE TILES ══════════ */}
        <section id="modules" className="cv-modules">
          <div className="wrap">
            <div className="cv-section-head">
              <h2 className="disp">
                {isAr ? "ابدأ من أي وحدة تحتاجها" : "Start from whichever module you need"}
              </h2>
              <p>
                {isAr
                  ? "كل قسم في النظام مصمم يخلي شغل يومك أسرع، من غير ما تحتاج تتعلم نظام معقد."
                  : "Every section is built to make your day faster, with nothing complicated to learn."}
              </p>
            </div>
            <div className="cv-tile-grid">
              {[
                { cls: "t1", icon: <AttendanceIcon />, ar: "الحضور", en: "Attendance", arD: "تسجيل حضور الفصل في دقيقة", enD: "Mark a class present in a minute" },
                { cls: "t2", icon: <GradeIcon />, ar: "الدرجات", en: "Gradebook", arD: "تقارير آخر الترم جاهزة أوتوماتيك", enD: "Term reports generated automatically" },
                { cls: "t3", icon: <CalendarIcon />, ar: "الجدول الدراسي", en: "Timetable", arD: "جدول كل فصل ومعلم في مكان واحد", enD: "Every class & teacher's schedule, in sync" },
                { cls: "t4", icon: <ChatIcon />, ar: "التواصل", en: "Messaging", arD: "رسايل وتنبيهات لأولياء الأمور فورًا", enD: "Instant messages & alerts to parents" },
              ].map((tile, i) => (
                <div className={`cv-tile ${tile.cls}`} key={i}>
                  <div className="ic">{tile.icon}</div>
                  <h4 className="disp">{isAr ? tile.ar : tile.en}</h4>
                  <p>{isAr ? tile.arD : tile.enD}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ══════════ PRODUCT SHOWCASE ══════════ */}
        <section id="showcase" className="cv-showcase">
          <div className="wrap">
            {/* Row 1: Admin Dashboard */}
            <div className="cv-showcase-row">
              <div className="cv-sc-text">
                <span className="cv-sc-tag" style={{ background: "var(--cv-lavender)", color: "var(--cv-purple)" }}>
                  {isAr ? "لوحة المدير" : "Admin dashboard"}
                </span>
                <h3 className="disp">{isAr ? "شوف مدرستك كلها من شاشة واحدة" : "See your whole school on one screen"}</h3>
                <p>
                  {isAr
                    ? "من لحظة ما تفتح الحساب، تقدر تشوف نسب الحضور، أداء الفصول، وأي تنبيه محتاج تصرف سريع — كله واضح وبسيط."
                    : "The moment you log in, you see attendance rates, class performance, and anything that needs quick action — all clear, all simple."}
                </p>
                <ul className="cv-sc-list">
                  <li><i style={{ background: "var(--cv-purple)" }}><CheckIcon /></i>{isAr ? "تحديث لحظي لكل الفصول" : "Live updates across every class"}</li>
                  <li><i style={{ background: "var(--cv-purple)" }}><CheckIcon /></i>{isAr ? "تقارير قابلة للتصدير بضغطة" : "One-click exportable reports"}</li>
                </ul>
              </div>
              <div className="cv-sc-panel p1">
                <div className="cv-sc-card">
                  <div className="top"><h5>{isAr ? "نظرة عامة على المدرسة" : "School overview"}</h5><span>+4.2%</span></div>
                  <div className="cv-sc-bars">
                    <i style={{ height: "55%" }} /><i style={{ height: "80%" }} /><i style={{ height: "40%" }} /><i style={{ height: "92%" }} /><i style={{ height: "65%" }} />
                  </div>
                  <div className="cv-sc-rows">
                    <div className="row"><span className="dot" style={{ background: "var(--cv-purple)" }} /><span className="tr"><i style={{ width: "88%" }} /></span></div>
                    <div className="row"><span className="dot" style={{ background: "var(--cv-cyan)" }} /><span className="tr"><i style={{ width: "72%", background: "var(--cv-cyan)" }} /></span></div>
                    <div className="row"><span className="dot" style={{ background: "var(--cv-pink)" }} /><span className="tr"><i style={{ width: "60%", background: "var(--cv-pink)" }} /></span></div>
                  </div>
                </div>
              </div>
            </div>

            {/* Row 2: Parent App */}
            <div className="cv-showcase-row rev">
              <div className="cv-sc-text">
                <span className="cv-sc-tag" style={{ background: "var(--cv-skywash)", color: "var(--cv-cyan)" }}>
                  {isAr ? "تطبيق ولي الأمر" : "Parent app"}
                </span>
                <h3 className="disp">{isAr ? "الأهل متابعين، من غير ما يقلقوا" : "Parents stay in the loop, without the worry"}</h3>
                <p>
                  {isAr
                    ? "إشعار غياب، رسالة من المعلم، أو درجة جديدة — كله بيوصل لولي الأمر على موبايله في نفس اللحظة."
                    : "An absence alert, a teacher's note, or a new grade — it reaches the parent's phone the moment it happens."}
                </p>
                <ul className="cv-sc-list">
                  <li><i style={{ background: "var(--cv-cyan)" }}><CheckIcon /></i>{isAr ? "إشعارات فورية على الموبايل" : "Instant mobile notifications"}</li>
                  <li><i style={{ background: "var(--cv-cyan)" }}><CheckIcon /></i>{isAr ? "رد مباشر للمعلم من نفس المكان" : "Reply to teachers from the same place"}</li>
                </ul>
              </div>
              <div className="cv-sc-panel p2">
                <div className="cv-sc-card">
                  <div className="top"><h5>{isAr ? "آخر التنبيهات" : "Recent alerts"}</h5><span>{isAr ? "مباشر" : "Live"}</span></div>
                  <div className="cv-sc-rows">
                    <div className="row"><span className="dot" style={{ background: "var(--cv-pink)" }} /><span className="tr"><i style={{ width: "100%", background: "var(--cv-pink)" }} /></span></div>
                    <div className="row"><span className="dot" style={{ background: "var(--cv-purple)" }} /><span className="tr"><i style={{ width: "76%" }} /></span></div>
                    <div className="row"><span className="dot" style={{ background: "#22B573" }} /><span className="tr"><i style={{ width: "64%", background: "#22B573" }} /></span></div>
                    <div className="row"><span className="dot" style={{ background: "var(--cv-cyan)" }} /><span className="tr"><i style={{ width: "84%", background: "var(--cv-cyan)" }} /></span></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ══════════ STATS BAND ══════════ */}
        <div className="wrap">
          <section className="cv-stats">
            <div className="cv-stats-grid">
              <div>
                <div className="num">300+</div>
                <p>{isAr ? "مدرسة بتستخدم النظام" : "schools using EduControl"}</p>
              </div>
              <div>
                <div className="num">45K</div>
                <p>{isAr ? "مستخدم نشط يوميًا" : "daily active users"}</p>
              </div>
              <div>
                <div className="num">4.8/5</div>
                <p>{isAr ? "تقييم من المدارس" : "average school rating"}</p>
              </div>
            </div>
          </section>
        </div>

        {/* ══════════ TESTIMONIALS ══════════ */}
        <section className="cv-voices" id="voices">
          <div className="wrap">
            <div className="cv-section-head">
              <h2 className="disp">{isAr ? "مدارس بتستخدم النظام كل يوم" : "Schools who run on EduControl"}</h2>
            </div>
            <div className="cv-voice-grid">
              {[
                { cls: "c1", q: isAr ? "قللنا وقت تجهيز تقارير آخر الترم من أسبوع كامل لساعتين." : "We cut term-report prep from a full week to two hours.", name: isAr ? "سلمى فتحي" : "Salma Fathy", role: isAr ? "مديرة مدرسة" : "Principal", color: "var(--cv-purple)" },
                { cls: "c2", q: isAr ? "رصد الحضور بقى أسرع حاجة أعملها الصبح، من غير ورق." : "Attendance is the fastest thing I do all morning now — no paper.", name: isAr ? "كريم عادل" : "Kareem Adel", role: isAr ? "معلم" : "Teacher", color: "var(--cv-cyan)" },
                { cls: "c3", q: isAr ? "بحس إني متابعة ابني أول بأول من غير ما أقلق." : "I finally feel connected to my son's day without worrying.", name: isAr ? "هبة يوسف" : "Heba Youssef", role: isAr ? "ولية أمر" : "Parent", color: "var(--cv-pink)" },
              ].map((v, i) => (
                <div className={`cv-vcard ${v.cls}`} key={i}>
                  <div className="stars">★★★★★</div>
                  <p className="q">{v.q}</p>
                  <div className="cv-vperson">
                    <span className="av" style={{ background: v.color }} />
                    <div><strong>{v.name}</strong><span>{v.role}</span></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ══════════ CTA ══════════ */}
        <section className="cv-cta">
          <div className="wrap">
            <div className="cv-cta-text">
              <h2 className="disp">
                {isAr
                  ? "كل أدوات إدارة مدرستك في مكان واحد؟"
                  : "All your school management tools in one place?"}
              </h2>
              <p className="cv-cta-sub">
                {isAr
                  ? "ابدأ تجربتك الآن، وادخل إلى لوحة التحكم خلال دقائق — بدون الحاجة لإدخال أي بيانات دفع."
                  : "Start your trial now and access your control panel in minutes — no payment details required."}
              </p>
            </div>
            <div className="cv-cta-actions">
              <button type="button" onClick={openRegister} className="cv-btn cv-btn-grad">{isAr ? "ابدأ مجانًا" : "Start for free"}</button>
              <button type="button" onClick={openLogin} className="cv-btn cv-btn-outline">{isAr ? "تسجيل الدخول" : "Log in"}</button>
            </div>
          </div>
        </section>
      </main>

      {/* ══════════ FOOTER ══════════ */}
      <footer id="footer" className="cv-footer">
        <div className="wrap">
          <div className="cv-foot-top">
            <div className="cv-foot-brand">
              <Link href="/" className="cv-brand disp" style={{ color: "#fff" }}>
                <span className="cv-brand-mark"><BrandIcon /></span>
                EduControl
              </Link>
              <p>{isAr ? "نظام إدارة مدرسي بيربط الإدارة والمعلمين وأولياء الأمور في مكان واحد." : "A school management system that keeps admins, teachers, and parents on the same page."}</p>
            </div>
            <div className="cv-foot-grid">
              <div className="cv-foot-col">
                <h4>{isAr ? "المنتج" : "Product"}</h4>
                <a href="#modules">{isAr ? "المميزات" : "Features"}</a>
              </div>
              <div className="cv-foot-col">
                <h4>{isAr ? "الشركة" : "Company"}</h4>
                <a href="#voices">{isAr ? "آراء المدارس" : "Reviews"}</a>
              </div>
              <div className="cv-foot-col">
                <h4>{isAr ? "الدعم" : "Support"}</h4>
                <a href="#">{isAr ? "تواصل معنا" : "Contact us"}</a>
              </div>
            </div>
          </div>
          <div className="cv-foot-bottom">
            <span>© {new Date().getFullYear()} EduControl. {isAr ? "كل الحقوق محفوظة." : "All rights reserved."}</span>
          </div>
        </div>
           </footer>
        </div>
      </div>

      {/* ══════════ CANVA AUTH MODAL ══════════ */}
      <AuthModal
        isOpen={authModalOpen}
        initialMode={authModalMode}
        onClose={() => setAuthModalOpen(false)}
      />
    </div>
  );
}
