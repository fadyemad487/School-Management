"use client";

import React, { useState } from "react";
import { Lock, Eye, EyeOff } from "lucide-react";

export function GlassPasswordInput({ placeholder, style, ...rest }: React.InputHTMLAttributes<HTMLInputElement>) {
  const [show, setShow] = useState(false);
  const [focused, setFocused] = useState(false);

  return (
    <div
      style={{
        position: "relative",
        display: "flex",
        alignItems: "center",
        width: "100%",
        background: "rgba(255, 255, 255, 0.04)",
        border: focused ? "1px solid #6366f1" : "1px solid rgba(255, 255, 255, 0.12)",
        boxShadow: focused ? "0 0 0 3px rgba(99, 102, 241, 0.25), inset 0 1px 2px rgba(0,0,0,0.2)" : "inset 0 1px 2px rgba(0,0,0,0.1)",
        borderRadius: "14px",
        padding: "0 14px",
        transition: "all 0.2s ease-in-out",
        ...style
      }}
    >
      <Lock size={18} style={{ color: focused ? "#818cf8" : "rgba(255, 255, 255, 0.4)", flexShrink: 0, transition: "color 0.2s ease" }} />
      <input
        type={show ? "text" : "password"}
        placeholder={placeholder}
        onFocus={(e) => {
          setFocused(true);
          rest.onFocus?.(e);
        }}
        onBlur={(e) => {
          setFocused(false);
          rest.onBlur?.(e);
        }}
        style={{
          width: "100%",
          background: "transparent",
          border: "none",
          outline: "none",
          color: "#ffffff",
          fontSize: "15px",
          fontWeight: 500,
          padding: "14px 12px",
          fontFamily: "inherit"
        }}
        {...rest}
      />
      <button
        type="button"
        onClick={() => setShow(!show)}
        tabIndex={-1}
        style={{
          background: "none",
          border: "none",
          color: show ? "#818cf8" : "rgba(255, 255, 255, 0.4)",
          cursor: "pointer",
          padding: "4px",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexShrink: 0,
          borderRadius: "8px",
          transition: "color 0.2s ease"
        }}
      >
        {show ? <EyeOff size={18} /> : <Eye size={18} />}
      </button>
    </div>
  );
}
