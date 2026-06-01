"use client";

import { Moon, Sun } from "lucide-react";
import { useEffect, useState } from "react";

type Theme = "dark" | "light";

export function useDashboardTheme() {
  const [theme, setThemeState] = useState<Theme>("light");

  useEffect(() => {
    const stored = localStorage.getItem("edu_theme") as Theme | null;
    if (stored === "light" || stored === "dark") setThemeState(stored);
  }, []);

  const setTheme = (next: Theme) => {
    setThemeState(next);
    localStorage.setItem("edu_theme", next);
  };

  const toggle = () => setTheme(theme === "dark" ? "light" : "dark");

  return { theme, setTheme, toggle };
}

export function ThemeToggle({
  theme,
  onToggle,
  labels,
}: {
  theme: Theme;
  onToggle: () => void;
  labels: { light: string; dark: string };
}) {
  const isDark = theme === "dark";
  return (
    <button
      type="button"
      className="theme-toggle"
      onClick={onToggle}
      title={isDark ? labels.light : labels.dark}
      aria-label={isDark ? labels.light : labels.dark}
    >
      {isDark ? <Sun size={18} strokeWidth={2} /> : <Moon size={18} strokeWidth={2} />}
    </button>
  );
}
