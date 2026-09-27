"use client";

import { FormEvent, useEffect, useState } from "react";
import Link from "next/link";
import { ArrowLeft, ArrowRight, BookOpenCheck, CheckCircle2, Mail, Send, ShieldCheck } from "lucide-react";
import { useTranslation } from "@/lib/i18n";
import styles from "./contact.module.css";

export default function ContactPage() {
  const { isAr } = useTranslation();
  const [sent, setSent] = useState(false);
  const [isDark, setIsDark] = useState(false);
  const BackIcon = isAr ? ArrowRight : ArrowLeft;

  useEffect(() => {
    setIsDark(localStorage.getItem("cv_theme") === "dark");
  }, []);

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const name = String(form.get("name") || "");
    const email = String(form.get("email") || "");
    const school = String(form.get("school") || "");
    const subject = String(form.get("subject") || "");
    const message = String(form.get("message") || "");
    const body = `Name: ${name}\nEmail: ${email}\nSchool: ${school || "Not provided"}\n\n${message}`;

    setSent(true);
    window.location.href = `mailto:fadyemad487@gmail.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
  };

  return (
    <main className={`${styles.page} ${isDark ? styles.dark : ""}`} dir={isAr ? "rtl" : "ltr"}>
      <header className={styles.header}>
        <Link href="/" className={styles.brand}>
          <span className={styles.brandMark}><BookOpenCheck size={19} /></span>
          EduControl
        </Link>
        <Link href="/" className={styles.backLink}>
          <BackIcon size={17} />
          {isAr ? "العودة للرئيسية" : "Back to home"}
        </Link>
      </header>

      <section className={styles.content}>
        <div className={styles.intro}>
          <p className={styles.kicker}>{isAr ? "دعم EduControl" : "EduControl support"}</p>
          <h1>{isAr ? "خلّينا نتواصل" : "Let’s talk"}</h1>
          <p>{isAr ? "سواء عندك سؤال، تحتاج مساعدة، أو تريد مشاركة فكرة، فريقنا جاهز للاستماع." : "Whether you have a question, need help, or want to share an idea, we are here to listen."}</p>

          <a className={styles.emailCard} href="mailto:fadyemad487@gmail.com">
            <span><Mail size={22} /></span>
            <div>
              <small>{isAr ? "راسلنا مباشرة" : "Email us directly"}</small>
              <strong>fadyemad487@gmail.com</strong>
            </div>
            <ArrowRight className={styles.cardArrow} size={19} />
          </a>

          <div className={styles.promise}>
            <ShieldCheck size={20} />
            <span>{isAr ? "لن نستخدم بياناتك إلا للرد على رسالتك." : "Your details are used only to respond to your message."}</span>
          </div>
        </div>

        <form className={styles.form} onSubmit={handleSubmit}>
          <div className={styles.formHeading}>
            <h2>{isAr ? "أرسل رسالة" : "Send a message"}</h2>
            <p>{isAr ? "سنفتح رسالة بريد جاهزة بكل التفاصيل التي تكتبها." : "Your email app will open with your message ready to send."}</p>
          </div>
          <div className={styles.twoColumns}>
            <label>
              <span>{isAr ? "الاسم" : "Name"}</span>
              <input name="name" required autoComplete="name" placeholder={isAr ? "اسمك الكامل" : "Your full name"} />
            </label>
            <label>
              <span>{isAr ? "البريد الإلكتروني" : "Email address"}</span>
              <input name="email" type="email" required autoComplete="email" placeholder="you@school.edu" />
            </label>
          </div>
          <label>
            <span>{isAr ? "اسم المدرسة (اختياري)" : "School name (optional)"}</span>
            <input name="school" autoComplete="organization" placeholder={isAr ? "اسم مدرستك" : "Your school"} />
          </label>
          <label>
            <span>{isAr ? "الموضوع" : "Subject"}</span>
            <input name="subject" required placeholder={isAr ? "كيف يمكننا مساعدتك؟" : "How can we help?"} />
          </label>
          <label>
            <span>{isAr ? "الرسالة" : "Message"}</span>
            <textarea name="message" required rows={5} placeholder={isAr ? "اكتب تفاصيل رسالتك هنا..." : "Tell us a little more..."} />
          </label>
          <button type="submit">
            {sent ? <CheckCircle2 size={18} /> : <Send size={18} />}
            {sent ? (isAr ? "تم تجهيز رسالتك" : "Message ready") : (isAr ? "فتح البريد وإرسال الرسالة" : "Open email to send")}
          </button>
        </form>
      </section>
    </main>
  );
}
