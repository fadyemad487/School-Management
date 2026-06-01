import React from "react";
import { X } from "lucide-react";

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  width?: string;
}

/**
 * Reusable Premium Modal using existing globals.css glassmorphism classes.
 */
export const Modal: React.FC<ModalProps> = ({ isOpen, onClose, title, children, footer, width }) => {
  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div 
        className="modal-glass" 
        style={{ 
          maxWidth: width || "600px", 
          padding: "32px",
          maxHeight: "90vh",
          overflowY: "auto",
          display: "flex",
          flexDirection: "column"
        }}
      >
        <button 
          className="modal-close-btn" 
          onClick={onClose}
          aria-label="Close"
          style={{ position: "absolute", top: "24px", insetInlineEnd: "24px", zIndex: 10 }}
        >
          <X size={20} />
        </button>

        <h3 style={{ fontSize: "24px", fontWeight: 800, marginBottom: "24px", color: "var(--glass-text-primary)" }}>
          {title}
        </h3>

        <div className="modal-body" style={{ color: "var(--glass-text-secondary)", marginBottom: footer ? "32px" : "0" }}>
          {children}
        </div>

        {footer && (
          <div className="modal-footer" style={{ display: "flex", justifyContent: "flex-end", gap: "12px", borderTop: "1px solid var(--dash-chart-border)", paddingTop: "24px" }}>
            {footer}
          </div>
        )}
      </div>
    </div>
  );
};
