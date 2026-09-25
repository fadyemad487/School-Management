"use client";

import React, { useEffect, useState } from "react";
import { Sun, Moon } from "lucide-react";

export type DashboardTheme = "light" | "dark";

export function useDashboardTheme() {
  const [theme, setTheme] = useState<DashboardTheme>("light");

  useEffect(() => {
    if (typeof window !== "undefined") {
      const saved = localStorage.getItem("edu_dashboard_theme") as DashboardTheme | null;
      if (saved === "dark" || saved === "light") {
        setTheme(saved);
      }
    }
  }, []);

  const toggle = () => {
    setTheme((prev) => {
      const next = prev === "light" ? "dark" : "light";
      if (typeof window !== "undefined") {
        localStorage.setItem("edu_dashboard_theme", next);
      }
      return next;
    });
  };

  return { theme, toggle, setTheme };
}

interface ThemeToggleProps {
  theme?: DashboardTheme;
  isDark?: boolean;
  onToggle?: () => void;
  labels?: { light: string; dark: string };
  className?: string;
}

export function ThemeToggle({ theme, isDark, onToggle, labels, className = "" }: ThemeToggleProps) {
  const activeIsDark = isDark ?? (theme === "dark");

  return (
    <button
      type="button"
      onClick={onToggle}
      className={`cv-theme-toggle ${className}`}
      aria-label="Toggle Theme"
      title={activeIsDark ? labels?.light || "Switch to light mode" : labels?.dark || "Switch to dark mode"}
    >
      {activeIsDark ? (
        <Sun size={19} strokeWidth={2.2} style={{ color: "#FFD600" }} />
      ) : (
        <Moon size={19} strokeWidth={2.2} style={{ color: "var(--cv-ink)" }} />
      )}
    </button>
  );
}
