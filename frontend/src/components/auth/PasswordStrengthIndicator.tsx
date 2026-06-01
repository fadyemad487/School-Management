"use client";

import { CheckCircle2, Circle } from "lucide-react";

export function PasswordStrengthIndicator({ password }: { password?: string }) {
  if (!password) return null;

  const requirements = [
    { label: "Small letters (a-z)", met: /[a-z]/.test(password) },
    { label: "Capital letters (A-Z)", met: /[A-Z]/.test(password) },
    { label: "Numbers (0-9)", met: /[0-9]/.test(password) },
    { label: "Special symbols (!@#$%)", met: /[^a-zA-Z0-9]/.test(password) }
  ];

  const metCount = requirements.filter(r => r.met).length;
  let strengthLabel = "Weak";
  let strengthColor = "#ef4444";
  let width = "33%";

  if (metCount === 3) {
    strengthLabel = "Medium";
    strengthColor = "#f59e0b";
    width = "66%";
  } else if (metCount >= 4) {
    strengthLabel = "Strong";
    strengthColor = "#10b981";
    width = "100%";
  }

  return (
    <div className="password-strength-wrapper">
      <div className="strength-label">
        <span>Security Strength</span>
        <span style={{ color: strengthColor }}>{strengthLabel}</span>
      </div>
      <div className="strength-bar-container">
        <div
          className="strength-bar"
          style={{ width, backgroundColor: strengthColor }}
        />
      </div>
      <div className="password-checklist">
        {requirements.map((req, i) => (
          <div key={i} className={`checklist-item ${req.met ? "met" : ""}`}>
            {req.met ? (
              <CheckCircle2 className="checklist-icon" size={16} />
            ) : (
              <Circle className="checklist-icon" size={16} />
            )}
            <span>{req.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
