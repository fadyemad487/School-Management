"use client";

import { CheckCircle2, ShieldCheck, X } from "lucide-react";
import { useTranslation } from "@/lib/i18n";

export function PolicyModal({
  isOpen,
  onClose,
  onAccept,
}: {
  isOpen: boolean;
  onClose: () => void;
  onAccept?: () => void;
}) {
  const { t, isAr } = useTranslation();
  if (!isOpen) return null;

  const accept = () => {
    onAccept?.();
    onClose();
  };

  return (
    <div className="cv-policy-backdrop" onClick={onClose}>
      <section
        className="cv-policy-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="policy-title"
        onClick={(event) => event.stopPropagation()}
        dir={isAr ? "rtl" : "ltr"}
      >
        <button type="button" className="cv-policy-close" onClick={onClose} aria-label={isAr ? "إغلاق" : "Close"}>
          <X size={20} />
        </button>

        <div className="cv-policy-icon" aria-hidden="true">
          <ShieldCheck size={30} strokeWidth={2.1} />
        </div>
        <h2 id="policy-title">{t("policy_title")}</h2>
        <p className="cv-policy-intro">{t("policy_intro")}</p>

        <div className="cv-policy-list">
          <div className="cv-policy-item">
            <CheckCircle2 size={18} aria-hidden="true" />
            <span>{t("policy_item1")}</span>
          </div>
          <div className="cv-policy-item">
            <CheckCircle2 size={18} aria-hidden="true" />
            <span>{t("policy_item2")}</span>
          </div>
          <div className="cv-policy-item">
            <CheckCircle2 size={18} aria-hidden="true" />
            <span>{t("policy_item3")}</span>
          </div>
        </div>

        <button type="button" className="cv-policy-accept" onClick={accept}>
          <CheckCircle2 size={18} aria-hidden="true" />
          {isAr ? "أوافق وأتابع" : "I agree and continue"}
        </button>
      </section>
    </div>
  );
}
