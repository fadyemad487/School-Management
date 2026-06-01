"use client";

import { useEffect, useState, useRef } from "react";

/* ── Animated counter hook ── */
export function useCountUp(end: number, duration = 2000) {
  const [count, setCount] = useState(0);
  const ref = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          let start = 0;
          const step = end / (duration / 16);
          const timer = setInterval(() => {
            start += step;
            if (start >= end) { 
              setCount(end); 
              clearInterval(timer); 
            } else {
              setCount(Math.floor(start));
            }
          }, 16);
          observer.disconnect();
        }
      },
      { threshold: 0.3 }
    );
    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, [end, duration]);
  
  return { count, ref };
}

export function StatCard({ icon, end, suffix = "", label }: { icon: React.ReactNode; end: number; suffix?: string; label: string }) {
  const { count, ref } = useCountUp(end);
  return (
    <div className="stat-card" ref={ref}>
      <div className="stat-icon">{icon}</div>
      <div className="stat-number">{count.toLocaleString()}{suffix}</div>
      <div className="stat-label">{label}</div>
    </div>
  );
}
