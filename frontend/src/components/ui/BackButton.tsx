"use client";

import { useRouter } from "next/navigation";
import { ArrowLeft, ArrowRight } from "lucide-react";
import { getLang } from "@/lib/i18n";

export function BackButton({ to, className = "" }: { to?: string; className?: string }) {
  const router = useRouter();
  
  return (
    <button
      className={`back-button ${className}`}
      onClick={() => {
        if (to) router.push(to);
        else router.back();
        window.scrollTo(0, 0);
      }}
      type="button"
    >
      {getLang() === 'ar' ? <ArrowRight size={20} /> : <ArrowLeft size={20} />}
    </button>
  );
}
