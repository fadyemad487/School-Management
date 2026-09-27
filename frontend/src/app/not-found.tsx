"use client";

import Link from "next/link";
import { DotLottieReact } from "@lottiefiles/dotlottie-react";
import { ArrowLeft, LayoutDashboard, SearchX } from "lucide-react";
import styles from "./not-found.module.css";

export default function NotFound() {
  return (
    <main className={styles.page}>
      <section className={styles.content} aria-labelledby="not-found-title">
        <div className={styles.animation} aria-hidden="true">
          <DotLottieReact
            src="/animations/error-404.lottie"
            autoplay
            loop
            className={styles.player}
          />
        </div>

        <p className={styles.code}>Error 404</p>
        <h1 id="not-found-title">
          We couldn&apos;t find that page
          <SearchX size={30} strokeWidth={2.1} aria-hidden="true" />
        </h1>
        <p className={styles.description}>
          The link may be incorrect, or this page may have moved.
        </p>

        <Link href="/dashboard" className={styles.action}>
          <LayoutDashboard size={18} strokeWidth={2.2} aria-hidden="true" />
          <span>Back to Dashboard</span>
          <ArrowLeft size={18} strokeWidth={2.2} aria-hidden="true" />
        </Link>
      </section>
    </main>
  );
}
