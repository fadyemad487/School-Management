"use client";

import React, { useState } from "react";
import { Lock, Eye, EyeOff } from "lucide-react";

export function GlassPasswordInput({ placeholder, ...rest }: React.InputHTMLAttributes<HTMLInputElement>) {
  const [show, setShow] = useState(false);
  return (
    <div className="glass-input-wrapper">
      <Lock className="glass-input-icon" size={18} />
      <input type={show ? "text" : "password"} placeholder={placeholder} {...rest} />
      <button type="button" className="glass-input-toggle" onClick={() => setShow(!show)} tabIndex={-1}>
        {show ? <EyeOff size={18} /> : <Eye size={18} />}
      </button>
    </div>
  );
}
