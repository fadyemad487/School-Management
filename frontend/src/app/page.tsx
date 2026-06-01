"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  GraduationCap, School, Users, BookOpen, CalendarCheck,
  CreditCard, BarChart3, ShieldCheck, TrendingUp, Clock,
  ArrowRight, ArrowLeft, ChevronRight, ChevronLeft, Menu, X
} from "lucide-react";
import { useTranslation, getLang } from "@/lib/i18n";
import { LanguageSwitcher } from "@/components/ui/LanguageSwitcher";
import { StatCard } from "@/components/ui/StatCard";
import { motion, Variants } from "framer-motion";

export default function LandingPage() {
  const { t, isAr, mounted } = useTranslation();
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenu, setMobileMenu] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const staticText = isAr ? "دير مدرستك بالكامل" : "Run Your Entire";
  const animatedText = isAr ? "من لوحة تحكم واحدة جبارة" : "School from One Powerful Dashboard";

  // Ultra-Premium Entrance Animation (No disappearing)
  const entranceVariant: Variants = {
    hidden: { 
      y: 15, 
      opacity: 0, 
      filter: "blur(12px)", 
      scale: 0.95 
    },
    visible: { 
      y: 0, 
      opacity: 1, 
      filter: "blur(0px)", 
      scale: 1,
      transition: {
        duration: 1.2,
        ease: [0.22, 1, 0.36, 1], // Extremely smooth cinematic deceleration
        delay: 0.2 // Small delay to let the page load first
      }
    }
  };

  const logos = [
    "🏫 Future Leaders",
    "📚 Al Noor Academy",
    "🎓 Bright Minds",
    "📖 Horizon Schools",
    "🏛️ Al Azhar Int'l"
  ];

  return (
    <div className="landing-page">
      {/* ── NAVIGATION ── */}
      <nav className={`landing-nav ${scrolled ? "scrolled" : ""}`}>
        <div className="nav-brand">
          <div className="logo-icon"><GraduationCap size={22} /></div>
          <h3>Edu<span>Control</span></h3>
        </div>
        <div className="nav-links">
          <a href="#features">{t('nav_features')}</a>
          <a href="#how">{t('nav_how')}</a>
          <a href="#testimonials">{t('nav_testimonials')}</a>
        </div>
        <div className="nav-actions">
          <Link href="/login" className="btn">{t('nav_signin')}</Link>
          <Link href="/register" className="btn primary">
            {t('nav_get_started')} {isAr ? <ChevronLeft size={16} /> : <ChevronRight size={16} />}
          </Link>
          <LanguageSwitcher />
        </div>
        <button className="mobile-menu-toggle" onClick={() => setMobileMenu(!mobileMenu)}>
          {mobileMenu ? <X size={24} color="#fff" /> : <Menu size={24} color="#fff" />}
        </button>
      </nav>

      {/* ── HERO ── */}
      <section className="hero-section">
        <div className="hero-bg-effects">
          <div className="orb orb-1" />
          <div className="orb orb-2" />
          <div className="orb orb-3" />
        </div>
        <div className="hero-grid-pattern" />

        <div className="hero-container">
          <div className="hero-content">
            <div className="hero-badge">
              <span className="dot" />
              {t('land_hero_badge')}
            </div>

            <h1 style={{ minHeight: isAr ? "120px" : "140px" }}>
              {staticText}{" "}
              <motion.span
                variants={entranceVariant}
                initial="hidden"
                animate="visible"
                className="gradient-text"
                style={{ display: "inline-block" }}
              >
                {animatedText}
              </motion.span>
            </h1>

            <p style={{ marginTop: "16px" }}>
              {t('land_hero_desc')}
            </p>
            <div className="hero-actions">
              <Link href="/register" className="btn primary lg">
                {t('land_hero_start')}  {isAr ? <ArrowLeft size={18} /> : <ArrowRight size={18} />}
              </Link>
              <Link href="/login" className="btn outline lg">
                {t('land_hero_view')}
              </Link>
            </div>
            <div className="hero-stats">
              <div className="hero-stat">
                <div className="number">250+</div>
                <div className="label">{t('land_hero_schools')}</div>
              </div>
              <div className="hero-stat">
                <div className="number">50K+</div>
                <div className="label">{t('land_hero_students')}</div>
              </div>
              <div className="hero-stat">
                <div className="number">99.9%</div>
                <div className="label">{t('land_hero_uptime')}</div>
              </div>
            </div>
          </div>

          <div className="hero-visual">
            <div className="hero-image-wrapper">
              <img src="/hero-dashboard.png" alt="EduControl Dashboard" />
              <div className="hero-float-card card-1">
                <div className="card-icon">📊</div>
                <div className="card-label">Attendance Rate</div>
                <div className="card-value">96.4%</div>
              </div>
              <div className="hero-float-card card-2">
                <div className="card-icon">🎓</div>
                <div className="card-label">Active Students</div>
                <div className="card-value">1,248</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── TRUSTED BY ── */}
      <section className="trusted-section">
        <div className="trusted-container">
          <p>{t('land_trusted')}</p>
          <div className="trusted-logos-wrapper">
            <div className="trusted-logos">
              {[...logos, ...logos].map((logo, index) => (
                <span key={index}>{logo}</span>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ── STATS ── */}
      <section className="stats-section">
        <div className="stats-container">
          <StatCard icon={<School size={24} color="#1d4ed8" />} end={250} suffix="+" label={t('land_hero_schools')} />
          <StatCard icon={<Users size={24} color="#1d4ed8" />} end={50000} suffix="+" label={t('land_hero_students')} />
          <StatCard icon={<TrendingUp size={24} color="#1d4ed8" />} end={40} suffix="%" label={t('land_hero_faster')} />
          <StatCard icon={<Clock size={24} color="#1d4ed8" />} end={99} suffix=".9%" label={t('land_hero_uptime')} />
        </div>
      </section>

      {/* ── FEATURES ── */}
      <section className="features-section" id="features">
        <div className="section-header">
          <div className="section-label"><span className="line" /> {t('land_feat_label')} <span className="line" /></div>
          <h2>{t('land_feat_title')}</h2>
          <p>{t('land_feat_desc')}</p>
        </div>
        <div className="features-grid">
          {[
            { icon: <Users size={24} color="#1d4ed8" />, title: t('land_feat1_title'), desc: t('land_feat1_desc') },
            { icon: <BookOpen size={24} color="#1d4ed8" />, title: t('land_feat2_title'), desc: t('land_feat2_desc') },
            { icon: <CalendarCheck size={24} color="#1d4ed8" />, title: t('land_feat3_title'), desc: t('land_feat3_desc') },
            { icon: <CreditCard size={24} color="#1d4ed8" />, title: t('land_feat4_title'), desc: t('land_feat4_desc') },
            { icon: <BarChart3 size={24} color="#1d4ed8" />, title: t('land_feat5_title'), desc: t('land_feat5_desc') },
            { icon: <ShieldCheck size={24} color="#1d4ed8" />, title: t('land_feat6_title'), desc: t('land_feat6_desc') },
          ].map((feature) => (
            <div className="feature-card" key={feature.title}>
              <div className="feature-icon">{feature.icon}</div>
              <h3>{feature.title}</h3>
              <p>{feature.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── HOW IT WORKS ── */}
      <section className="how-section" id="how">
        <div className="how-container">
          <div className="section-header">
            <div className="section-label"><span className="line" /> {t('land_how_label')} <span className="line" /></div>
            <h2>{t('land_how_title')}</h2>
            <p>{t('land_how_desc')}</p>
          </div>
          <div className="how-grid">
            <div className="how-step">
              <div className="step-number">1</div>
              <h3>{t('land_step1_title')}</h3>
              <p>{t('land_step1_desc')}</p>
            </div>
            <div className="how-step">
              <div className="step-number">2</div>
              <h3>{t('land_step2_title')}</h3>
              <p>{t('land_step2_desc')}</p>
            </div>
            <div className="how-step">
              <div className="step-number">3</div>
              <h3>{t('land_step3_title')}</h3>
              <p>{t('land_step3_desc')}</p>
            </div>
          </div>
        </div>
      </section>

      {/* ── TESTIMONIALS ── */}
      <section className="testimonials-section" id="testimonials">
        <div className="section-header">
          <div className="section-label"><span className="line" /> {t('nav_testimonials')} <span className="line" /></div>
          <h2>{t('land_testi_title')}</h2>
          <p>{t('land_testi_desc')}</p>
        </div>
        <div className="testimonials-grid">
          {[
            {
              stars: 5,
              quote: t('land_testi1_quote'),
              name: "Ahmed Hassan",
              role: t('land_testi1_role'),
              avatar: "A"
            },
            {
              stars: 5,
              quote: t('land_testi2_quote'),
              name: "Sara Ibrahim",
              role: t('land_testi2_role'),
              avatar: "S"
            },
            {
              stars: 5,
              quote: t('land_testi3_quote'),
              name: "Dr. Mona Khalil",
              role: t('land_testi3_role'),
              avatar: "M"
            }
          ].map((tItem) => (
            <div className="testimonial-card" key={tItem.name}>
              <div className="testimonial-stars">
                {Array.from({ length: tItem.stars }).map((_, i) => (
                  <span key={i}>★</span>
                ))}
              </div>
              <blockquote>"{tItem.quote}"</blockquote>
              <div className="testimonial-author">
                <div className="testimonial-avatar">{tItem.avatar}</div>
                <div className="testimonial-info">
                  <cite>{tItem.name}</cite>
                  <span>{tItem.role}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ── CTA ── */}
      <section className="cta-section">
        <div className="cta-container">
          <h2>{t('land_cta_title')}</h2>
          <p>{t('land_cta_desc')}</p>
          <div className="cta-actions">
            <Link href="/register" className="btn primary lg">
              {t('land_cta_signup')} {isAr ? <ArrowLeft size={18} /> : <ArrowRight size={18} />}
            </Link>
            <Link href="/login" className="btn outline lg">{t('nav_signin')}</Link>
          </div>
        </div>
      </section>

      {/* ── FOOTER ── */}
      <footer className="landing-footer">
        <div className="footer-container">
          <div className="footer-brand">
            <h3><School size={22} /> EduControl</h3>
            <p>{t('footer_desc')}</p>
          </div>
          <div className="footer-col">
            <h4>{t('footer_product')}</h4>
            <a href="#features">{t('nav_features')}</a>
            <a href="#how">{t('nav_how')}</a>
            <a href="#">{t('footer_pricing')}</a>
            <a href="#">{t('footer_changelog')}</a>
          </div>
          <div className="footer-col">
            <h4>{t('footer_resources')}</h4>
            <a href="#">{t('footer_docs')}</a>
            <a href="#">{t('footer_help')}</a>
            <a href="#">{t('footer_contact')}</a>
          </div>
          <div className="footer-col">
            <h4>{t('footer_legal')}</h4>
            <a href="#">{t('footer_privacy')}</a>
            <a href="#">{t('footer_terms')}</a>
          </div>
        </div>
        <div className="footer-bottom">
          <span>© {new Date().getFullYear()} EduControl. All rights reserved.</span>
        </div>
      </footer>
    </div>
  );
}
