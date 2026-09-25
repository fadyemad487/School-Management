"use client";

import React from "react";
import { Check, ShieldAlert, ShieldCheck } from "lucide-react";
import { useTranslation } from "@/lib/i18n";

interface PasswordStrengthIndicatorProps {
  password?: string;
}

export function PasswordStrengthIndicator({ password }: PasswordStrengthIndicatorProps) {
  const { isAr } = useTranslation();

  if (!password) return null;

  const rules = [
    { key: "min8", labelAr: "8+ أحرف", labelEn: "8+ chars", met: password.length >= 8 },
    { key: "lower", labelAr: "حروف صغيرة a-z", labelEn: "a-z", met: /[a-z]/.test(password) },
    { key: "upper", labelAr: "حروف كبيرة A-Z", labelEn: "A-Z", met: /[A-Z]/.test(password) },
    { key: "num", labelAr: "أرقام 0-9", labelEn: "0-9", met: /[0-9]/.test(password) },
    { key: "symbol", labelAr: "رموز (!@#$)", labelEn: "Symbols (!@#$)", met: /[^a-zA-Z0-9]/.test(password) },
  ];

  const metCount = rules.filter((r) => r.met).length;

  let strengthLabelAr = "ضعيفة جداً";
  let strengthLabelEn = "Very Weak";
  let themeColor = "#FF5757"; // Red
  let filledBars = 1;

  if (metCount === 2) {
    strengthLabelAr = "ضعيفة";
    strengthLabelEn = "Weak";
    themeColor = "#FF8A00"; // Orange
    filledBars = 1;
  } else if (metCount === 3) {
    strengthLabelAr = "متوسطة";
    strengthLabelEn = "Fair";
    themeColor = "#FFB020"; // Yellow
    filledBars = 2;
  } else if (metCount === 4) {
    strengthLabelAr = "قوية";
    strengthLabelEn = "Strong";
    themeColor = "#00C4CC"; // Cyan
    filledBars = 3;
  } else if (metCount >= 5) {
    strengthLabelAr = "ممتازة 🔒";
    strengthLabelEn = "Excellent 🔒";
    themeColor = "#22B573"; // Emerald Green
    filledBars = 4;
  }

  return (
    <div className="cv-strength-box">
      {/* Header Row */}
      <div className="cv-strength-header">
        <span className="cv-strength-title">
          {isAr ? "قوة كلمة المرور:" : "Password Strength:"}
        </span>
        <span
          className="cv-strength-badge"
          style={{
            backgroundColor: `${themeColor}18`,
            color: themeColor,
            borderColor: `${themeColor}40`,
          }}
        >
          {isAr ? strengthLabelAr : strengthLabelEn}
        </span>
      </div>

      {/* 4 Segmented Progress Bar */}
      <div className="cv-strength-meter">
        {[1, 2, 3, 4].map((barIndex) => (
          <div
            key={barIndex}
            className="cv-strength-segment"
            style={{
              backgroundColor: barIndex <= filledBars ? themeColor : "#E5E7EB",
              boxShadow: barIndex <= filledBars ? `0 2px 8px ${themeColor}40` : "none",
            }}
          />
        ))}
      </div>

      {/* Modern Colorful Requirement Chips */}
      <div className="cv-strength-chips">
        {rules.map((rule) => (
          <span
            key={rule.key}
            className={`cv-chip ${rule.met ? "met" : ""}`}
          >
            {rule.met ? (
              <Check size={12} strokeWidth={3} className="cv-chip-check" />
            ) : (
              <span className="cv-chip-dot" />
            )}
            {isAr ? rule.labelAr : rule.labelEn}
          </span>
        ))}
      </div>
    </div>
  );
}
