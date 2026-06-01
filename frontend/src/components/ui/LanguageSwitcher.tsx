"use client";

import { useEffect, useState, useRef } from "react";
import { Globe, Check } from "lucide-react";
import { useTranslation, setLang } from "@/lib/i18n";

export type LanguageSwitcherAppearance = "onDark" | "onLight";

type Props = {
  className?: string;
  /** Controls contrast: dashboard light theme needs `onLight`. */
  appearance?: LanguageSwitcherAppearance;
  variant?: "navbar" | "landing";
};

export function LanguageSwitcher({ className = "", appearance = "onDark", variant = "landing" }: Props) {
  const { lang: currentLang } = useTranslation();
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const rootClass = `lang-switcher lang-switcher--${appearance} lang-switcher--${variant}${isOpen ? " lang-switcher--open" : ""} ${className}`.trim();
  const triggerClass = `lang-switcher__trigger ${variant === "navbar" ? "shell-topbar__icon-btn" : ""}`.trim();

  return (
    <div ref={containerRef} className={rootClass}>
      <button
        type="button"
        onClick={() => setIsOpen((v) => !v)}
        className={triggerClass}
        aria-expanded={isOpen}
        aria-haspopup="listbox"
        aria-label="Language"
      >
        <Globe size={20} strokeWidth={2} aria-hidden />
      </button>

      {isOpen ? (
        <div className="lang-switcher__menu" role="listbox">
          <button
            type="button"
            className={`lang-switcher__option${currentLang === "en" ? " lang-switcher__option--active" : ""}`}
            onClick={() => {
              setLang("en");
              setIsOpen(false);
              window.location.reload();
            }}
          >
            <span className="lang-switcher__flag" aria-hidden>
              EN
            </span>
            <span className="lang-switcher__label">English</span>
            {currentLang === "en" ? <Check className="lang-switcher__check" size={16} strokeWidth={2.5} /> : null}
          </button>

          <button
            type="button"
            className={`lang-switcher__option${currentLang === "ar" ? " lang-switcher__option--active" : ""}`}
            onClick={() => {
              setLang("ar");
              setIsOpen(false);
              window.location.reload();
            }}
          >
            <span className="lang-switcher__flag" aria-hidden>
              ع
            </span>
            <span className="lang-switcher__label">العربية</span>
            {currentLang === "ar" ? <Check className="lang-switcher__check" size={16} strokeWidth={2.5} /> : null}
          </button>
        </div>
      ) : null}
    </div>
  );
}
