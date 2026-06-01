"use client";

import React from "react";
import { AdmissionWizard } from "@/components/dashboard/AdmissionWizard";
import { useTranslation } from "@/lib/i18n";
import { BackButton } from "@/components/ui/BackButton";

export default function NewAdmissionPage() {
  const { t } = useTranslation();

  return (
    <div className="new-admission-module">
      <div className="module-header-row" style={{ display: "flex", alignItems: "center", gap: "20px", marginBottom: "40px" }}>
        <BackButton />
        <div>
          <h2 style={{ fontSize: "32px", fontWeight: 900, letterSpacing: "-1px", color: "var(--glass-text-primary)" }}>{t('adm_title')}</h2>
          <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>{t('adm_subtitle')}</p>
        </div>
      </div>

      <div style={{ paddingBottom: "100px" }}>
        <AdmissionWizard />
      </div>
    </div>
  );
}
