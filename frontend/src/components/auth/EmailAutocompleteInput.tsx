"use client";

import { useState, useMemo } from "react";
import { Mail, Check, X } from "lucide-react";

export function EmailAutocompleteInput({ register, setValue, watch, name, placeholder, isValid, isLoading, isError }: any) {
  const [showSuggestions, setShowSuggestions] = useState(false);
  const emailValue = watch(name) || "";
  const domains = ["gmail.com", "yahoo.com", "outlook.com", "hotmail.com", "icloud.com"];
  
  const suggestions = useMemo(() => {
    if (!emailValue.includes("@")) return [];
    const [local, domain] = emailValue.split("@");
    if (!local) return [];
    return domains
      .filter(d => d.startsWith(domain.toLowerCase()))
      .map(d => `${local}@${d}`);
  }, [emailValue]);

  const handleSelect = (val: string) => {
    setValue(name, val);
    setShowSuggestions(false);
  };

  return (
    <div className={`glass-input-wrapper ${isError ? "input-error" : ""}`} style={{ position: "relative" }}>
      <Mail className="glass-input-icon" size={18} />
      <input
        placeholder={placeholder}
        {...register(name)}
        onFocus={() => setShowSuggestions(true)}
        onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
        autoComplete="off"
      />
      {/* 🟢 Integrated Check Status */}
      <div className="school-id-status" style={{ right: "12px" }}>
        {isLoading && <div className="spinner-mini" />}
        {!isLoading && isValid === true && <Check size={16} color="#10b981" />}
        {!isLoading && isValid === false && <X size={16} color="#ef4444" />}
      </div>

      {showSuggestions && suggestions.length > 0 && (
        <div className="email-suggestions-container">
          {suggestions.map((s) => {
            const [l, d] = s.split("@");
            return (
              <button
                key={s}
                className="email-suggestion-item"
                onClick={() => handleSelect(s)}
                type="button"
              >
                <span>{l}@</span>
                <span className="email-suggestion-domain">{d}</span>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
