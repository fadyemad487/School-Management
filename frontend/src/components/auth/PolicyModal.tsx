"use client";

import { X, ShieldCheck, CheckCircle2 } from "lucide-react";
import { useTranslation } from "@/lib/i18n";

export function PolicyModal({ isOpen, onClose, onAccept }: { isOpen: boolean; onClose: () => void; onAccept?: () => void }) {
  const { t } = useTranslation();
  if (!isOpen) return null;
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-glass" onClick={e => e.stopPropagation()}>
        <button className="modal-close-btn" onClick={onClose}><X size={20} /></button>
        <div className="modal-icon-header">
          <ShieldCheck size={40} color="var(--primary-light)" />
        </div>
        <h2 style={{ textAlign: "center", marginBottom: "12px", fontSize: "24px", fontWeight: 800 }}>{t('policy_title')}</h2>
        <p className="modal-intro">{t('policy_intro')}</p>
        <div className="policy-list">
          <div className="policy-item">
            <CheckCircle2 size={18} color="#10b981" style={{ flexShrink: 0 }} />
            <span>{t('policy_item1')}</span>
          </div>
          <div className="policy-item">
            <CheckCircle2 size={18} color="#10b981" style={{ flexShrink: 0 }} />
            <span>{t('policy_item2')}</span>
          </div>
          <div className="policy-item">
            <CheckCircle2 size={18} color="#10b981" style={{ flexShrink: 0 }} />
            <span>{t('policy_item3')}</span>
          </div>
        </div>
        <button 
          className="btn primary lg" 
          style={{ width: "100%", marginTop: "32px", borderRadius: "12px" }} 
          onClick={() => {
            if (onAccept) onAccept();
            onClose();
          }}
        >
          {t('btn_close')}
        </button>
      </div>
    </div>
  );
}
