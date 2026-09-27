"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { DotLottieReact } from "@lottiefiles/dotlottie-react";
import { useTranslation } from "@/lib/i18n";
import styles from "./onboarding.module.css";

const onboardingKey = "edu_registration_onboarding";
const successDuration = 6500;
const preparationDuration = 25000;

type OnboardingState = { startedAt: number };

function getOnboardingState(): OnboardingState | null {
  try {
    const value = sessionStorage.getItem(onboardingKey);
    if (!value) return null;
    const state = JSON.parse(value) as OnboardingState;
    return Number.isFinite(state.startedAt) ? state : null;
  } catch {
    return null;
  }
}

export default function OnboardingPage() {
  const router = useRouter();
  const { isAr } = useTranslation();
  const [elapsed, setElapsed] = useState(0);
  const redirected = useRef(false);

  useEffect(() => {
    const state = getOnboardingState();
    if (!state) {
      router.replace("/");
      return;
    }

    const updateProgress = () => {
      const nextElapsed = Date.now() - state.startedAt;
      setElapsed(nextElapsed);

      if (nextElapsed >= successDuration + preparationDuration && !redirected.current) {
        redirected.current = true;
        sessionStorage.removeItem(onboardingKey);
        localStorage.setItem("play_intro", "true");
        router.replace("/dashboard");
      }
    };

    updateProgress();
    const timer = window.setInterval(updateProgress, 80);
    return () => window.clearInterval(timer);
  }, [router]);

  const isPreparing = elapsed >= successDuration;
  const progress = Math.min(100, Math.max(0, ((elapsed - successDuration) / preparationDuration) * 100));

  return (
    <main className={styles.page} dir={isAr ? "rtl" : "ltr"}>
      <section className={styles.content} aria-live="polite">
        {!isPreparing ? (
          <div className={styles.phase}>
            <DotLottieReact
              src="/animations/success.lottie"
              autoplay
              loop={false}
              className={styles.successAnimation}
              aria-hidden="true"
            />
            <p className={styles.eyebrow}>{isAr ? "تم بنجاح" : "All set"}</p>
            <h1>{isAr ? "تم إنشاء مدرستك بنجاح" : "Your school has been created"}</h1>
            <p className={styles.description}>
              {isAr ? "نجهز لوحة التحكم الخاصة بك الآن." : "We are setting up your dashboard now."}
            </p>
          </div>
        ) : (
          <div className={styles.phase}>
            <p className={styles.eyebrow}>{isAr ? "جاري الإعداد" : "Preparing your workspace"}</p>
            <h1>{isAr ? "لوحة التحكم تصبح جاهزة" : "Your dashboard is coming to life"}</h1>
            <p className={styles.description}>
              {isAr ? "نرتب الإعدادات الأساسية لمدرستك." : "We are arranging the essentials for your school."}
            </p>

            <div
              className={styles.progressArea}
              role="progressbar"
              aria-label={isAr ? "تجهيز لوحة التحكم" : "Preparing dashboard"}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-valuenow={Math.round(progress)}
            >
              <div className={styles.rocket} style={{ left: `clamp(0%, ${progress}%, 100%)` }} aria-hidden="true">
                <DotLottieReact src="/animations/rocket.lottie" autoplay loop className={styles.rocketPlayer} />
              </div>
              <div className={styles.track}>
                <div className={styles.fill} style={{ width: `${progress}%` }} />
              </div>
              <p className={styles.progressLabel}>{Math.round(progress)}%</p>
            </div>
          </div>
        )}
      </section>
    </main>
  );
}
