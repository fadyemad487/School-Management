"use client";

import { Construction } from "lucide-react";

type Props = {
  title: string;
  subtitle?: string;
  hint?: string;
};

export function ModulePlaceholder({ title, subtitle, hint }: Props) {
  return (
    <section className="module-placeholder">
      <div className="module-placeholder__icon" aria-hidden>
        <Construction size={28} strokeWidth={1.75} />
      </div>
      <h1 className="module-placeholder__title">{title}</h1>
      {subtitle ? <p className="module-placeholder__subtitle">{subtitle}</p> : null}
      {hint ? <p className="module-placeholder__hint">{hint}</p> : null}
    </section>
  );
}
