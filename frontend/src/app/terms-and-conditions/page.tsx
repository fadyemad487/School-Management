"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowLeft, ArrowRight, BookOpenCheck, Mail, ShieldCheck } from "lucide-react";
import { useTranslation } from "@/lib/i18n";
import styles from "./terms.module.css";

const sections = [
  {
    title: "1. Your agreement",
    body: "By creating an EduControl account or using the platform, you agree to these Terms & Conditions. If you use EduControl for a school, you confirm that you are authorized to accept these terms for that school.",
  },
  {
    title: "2. School accounts",
    body: "Keep your account credentials secure and make sure the information submitted for your school is accurate. School administrators are responsible for managing access for their staff and removing access when it is no longer needed.",
  },
  {
    title: "3. Acceptable use",
    body: "Use EduControl only for lawful educational and administrative purposes. Do not attempt to disrupt the service, access another school’s data, share credentials, or upload content that violates the rights or privacy of others.",
  },
  {
    title: "4. Student and school data",
    body: "You remain responsible for the data entered by your school. Please only add information you are permitted to process, keep it accurate, and apply the appropriate safeguards when inviting teachers, parents, and staff.",
  },
  {
    title: "5. Service availability",
    body: "We work to keep EduControl reliable and improving, but maintenance, updates, or circumstances outside our control may occasionally affect availability. We may update features when needed to protect the service or improve the experience.",
  },
  {
    title: "6. Changes to these terms",
    body: "We may update these Terms & Conditions as EduControl evolves. The latest version will always be available on this page. Continuing to use the platform after an update means you accept the revised terms.",
  },
];

export default function TermsAndConditionsPage() {
  const { isAr } = useTranslation();
  const [isDark, setIsDark] = useState(false);
  const BackIcon = isAr ? ArrowRight : ArrowLeft;

  useEffect(() => {
    setIsDark(localStorage.getItem("cv_theme") === "dark");
  }, []);

  const localizedSections = isAr
    ? [
        { title: "1. الموافقة على الشروط", body: "بإنشائك حساباً في EduControl أو باستخدام المنصة، فإنك توافق على هذه الشروط والأحكام. وإذا كنت تستخدم المنصة نيابةً عن مدرسة، فأنت تؤكد أن لديك الصلاحية للموافقة باسمها." },
        { title: "2. حسابات المدارس", body: "حافظ على سرية بيانات الدخول وتأكد من دقة معلومات المدرسة التي تضيفها. مسؤول المدرسة مسؤول عن إدارة صلاحيات فريقه وإلغائها عند عدم الحاجة إليها." },
        { title: "3. الاستخدام المقبول", body: "استخدم EduControl للأغراض التعليمية والإدارية المشروعة فقط. لا تحاول تعطيل الخدمة أو الوصول لبيانات مدرسة أخرى أو مشاركة بيانات الدخول أو رفع محتوى ينتهك خصوصية وحقوق الآخرين." },
        { title: "4. بيانات الطلاب والمدرسة", body: "تظل مدرستك مسؤولة عن البيانات التي تضيفها. أضف فقط المعلومات التي تملك حق معالجتها، وحافظ على دقتها، واتخذ الاحتياطات المناسبة عند دعوة المعلمين وأولياء الأمور والموظفين." },
        { title: "5. توفر الخدمة", body: "نعمل على أن تكون EduControl موثوقة وفي تطور مستمر، لكن الصيانة أو التحديثات أو الظروف الخارجة عن إرادتنا قد تؤثر على توفرها أحياناً. قد نحدّث بعض المزايا لحماية الخدمة أو تحسينها." },
        { title: "6. التغييرات على الشروط", body: "قد نحدّث هذه الشروط مع تطور EduControl. ستجد دائماً أحدث نسخة في هذه الصفحة، واستمرارك في استخدام المنصة بعد أي تحديث يعني موافقتك على النسخة المحدثة." },
      ]
    : sections;

  return (
    <main className={`${styles.page} ${isDark ? styles.dark : ""}`} dir={isAr ? "rtl" : "ltr"}>
      <header className={styles.header}>
        <Link href="/" className={styles.brand}>
          <span className={styles.brandMark}><BookOpenCheck size={19} /></span>
          EduControl
        </Link>
        <Link href="/login" className={styles.backLink}>
          <BackIcon size={17} />
          {isAr ? "العودة لتسجيل الدخول" : "Back to sign in"}
        </Link>
      </header>

      <section className={styles.hero}>
        <div className={styles.iconWrap}><ShieldCheck size={32} /></div>
        <p className={styles.kicker}>{isAr ? "قانوني وشفاف" : "Clear and transparent"}</p>
        <h1>{isAr ? "الشروط والأحكام" : "Terms & Conditions"}</h1>
        <p>
          {isAr
            ? "هذه القواعد توضّح كيفية استخدام EduControl بشكل آمن ومسؤول."
            : "These terms explain how to use EduControl safely and responsibly."}
        </p>
        <span>{isAr ? "آخر تحديث: 27 سبتمبر 2026" : "Last updated: September 27, 2026"}</span>
      </section>

      <section className={styles.layout}>
        <aside className={styles.sideNote}>
          <ShieldCheck size={21} />
          <div>
            <strong>{isAr ? "ملخص بسيط" : "The short version"}</strong>
            <p>{isAr ? "استخدم المنصة بمسؤولية، واحمِ بيانات مدرستك وطلابك." : "Use the platform responsibly and protect your school and student data."}</p>
          </div>
        </aside>

        <article className={styles.document}>
          <p className={styles.intro}>
            {isAr
              ? "مرحباً بك في EduControl. صممنا هذه الشروط بلغة واضحة حتى تعرف ما المتوقع منك وما يمكنك توقعه منا."
              : "Welcome to EduControl. We wrote these terms in plain language so you know what is expected of you and what you can expect from us."}
          </p>
          {localizedSections.map((section) => (
            <section className={styles.termSection} key={section.title}>
              <h2>{section.title}</h2>
              <p>{section.body}</p>
            </section>
          ))}
          <section className={styles.contactBlock}>
            <Mail size={22} />
            <div>
              <h2>{isAr ? "أسئلة عن الشروط؟" : "Questions about these terms?"}</h2>
              <p>{isAr ? "تواصل معنا وسنساعدك في أي استفسار يخص استخدام المنصة." : "Reach out to us and we will help with any question about using the platform."}</p>
              <Link href="/contact">{isAr ? "تواصل معنا" : "Contact us"}</Link>
            </div>
          </section>
        </article>
      </section>
    </main>
  );
}
