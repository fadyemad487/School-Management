"use client";

import React, { useState } from "react";

interface NodeData {
  badge?: string;
  title: string;
  desc: string;
  glow: string;
  showBadge: boolean;
}

interface TooltipState {
  cx: number;
  cy: number;
  data: NodeData;
}

export function AnimatedVectorHub() {
  const [activeTooltip, setActiveTooltip] = useState<TooltipState | null>(null);

  const showTip = (cx: number, cy: number, data: NodeData) => {
    setActiveTooltip({ cx, cy, data });
  };

  const hideTip = () => {
    setActiveTooltip(null);
  };

  return (
    <div
      style={{
        position: "relative",
        width: "100%",
        height: "100%",
        minHeight: "100%",
        borderRadius: "0px",
        overflow: "hidden",
        userSelect: "none",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      {/* ── Main SVG Graphic ── */}
      <svg
        style={{ width: "100%", height: "100%", display: "block" }}
        viewBox="10 200 720 520"
        preserveAspectRatio="xMidYMid meet"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <radialGradient id="paint8_radial_sms_exact" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(399.355 677.67) rotate(-99.8756) scale(174.954 237.518)">
            <stop offset="0.2" stopColor="#7D2AE8" />
            <stop offset="0.5" stopColor="#5A32FA" />
            <stop offset="0.97" stopColor="#00C4CC" />
          </radialGradient>

          <filter id="filter_dd_node" x="-20%" y="-20%" width="140%" height="140%" filterUnits="userSpaceOnUse">
            <feGaussianBlur stdDeviation="8" />
            <feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.35 0" />
          </filter>
        </defs>

        {/* Twinkle Stars */}
        <g id="sparkle-stars-group">
          <g className="twinkle-star-1"><path d="M365.03 273.977C365.037 273.844 365.146 273.738 365.28 273.738H365.809C365.942 273.738 366.051 273.844 366.058 273.977C366.41 280.602 371.178 285.908 377.138 286.311C377.27 286.319 377.374 286.428 377.374 286.56V287.205C377.374 287.338 377.27 287.446 377.138 287.455C371.178 287.858 366.41 293.163 366.058 299.788C366.051 299.921 365.942 300.027 365.809 300.027H365.28C365.146 300.027 365.037 299.921 365.03 299.788C364.678 293.163 359.91 287.858 353.951 287.455C353.819 287.446 353.714 287.338 353.714 287.205V286.56C353.714 286.428 353.819 286.319 353.951 286.311C359.91 285.908 364.678 280.602 365.03 273.977Z" fill="white" /></g>
          <g className="twinkle-star-2"><path d="M159.459 345.103C159.465 345.002 159.548 344.922 159.649 344.922H160.248C160.349 344.922 160.432 345.002 160.437 345.103C160.76 351.017 165.343 355.755 171.065 356.091C171.166 356.097 171.246 356.179 171.246 356.28V356.912C171.246 357.013 171.166 357.096 171.065 357.102C165.343 357.438 160.76 362.175 160.437 368.09C160.432 368.19 160.349 368.271 160.248 368.271H159.649C159.548 368.271 159.465 368.19 159.459 368.09C159.137 362.175 154.554 357.438 148.831 357.102C148.73 357.096 148.65 357.013 148.65 356.912V356.28C148.65 356.179 148.73 356.097 148.831 356.091C154.554 355.755 159.137 351.017 159.459 345.103Z" fill="white" /></g>
          <g className="twinkle-star-3"><path d="M292.766 409.196C292.773 409.063 292.882 408.957 293.015 408.957H293.544C293.677 408.957 293.786 409.063 293.793 409.196C294.145 415.821 298.913 421.126 304.873 421.529C305.005 421.538 305.109 421.647 305.109 421.779V422.424C305.109 422.556 305.005 422.665 304.873 422.674C298.913 423.077 294.145 428.382 293.793 435.007C293.786 435.14 293.677 435.246 293.544 435.246H293.015C292.882 435.246 292.773 435.14 292.766 435.007C292.414 428.382 287.646 423.077 281.686 422.674C281.554 422.665 281.449 422.556 281.449 422.424V421.779C281.449 421.647 281.554 421.538 281.686 421.529C287.646 421.126 292.414 415.821 292.766 409.196Z" fill="white" /></g>
          <g className="twinkle-star-6"><path d="M647.966 431.769C647.972 431.662 648.06 431.576 648.167 431.576H648.761C648.868 431.576 648.956 431.662 648.962 431.769C649.29 438.046 653.953 443.075 659.775 443.435C659.882 443.442 659.967 443.53 659.967 443.637V444.309C659.967 444.416 659.882 444.503 659.775 444.51C653.953 444.871 649.29 449.899 648.962 456.176C648.956 456.284 648.868 456.369 648.761 456.369H648.167C648.06 456.369 647.972 456.284 647.966 456.176C647.638 449.899 642.976 444.871 637.153 444.51C637.046 444.503 636.962 444.416 636.962 444.309V443.637C636.962 443.53 637.046 443.442 637.153 443.435C642.976 443.075 647.638 438.046 647.966 431.769Z" fill="white" /></g>
        </g>

        {/* NODE 1 */}
        <g
          className="anim-node node-1"
          onMouseEnter={() => showTip(127, 612, { badge: "الطلاب", title: "شؤون الطلاب والقبول", desc: "إدارة ملفات وسجلات الطلاب والتسجيل الذكي", glow: "#138EFF", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="127.327" cy="612.075" fill="#138EFF" rx="52.3" ry="52.6" />
          <g transform="translate(101.5, 586.5) scale(1.12)">
            <circle cx="23" cy="14" fill="white" r="7.5" />
            <path d="M11 36 C11 27.5, 16 24.5, 23 24.5 C30 24.5, 35 27.5, 35 36 Z" fill="white" />
            <circle cx="34" cy="12" fill="white" opacity="0.85" r="5" />
            <path d="M35 22.5 C38.5 23.2, 42 25.8, 42 33" fill="none" stroke="white" strokeWidth="3" strokeLinecap="round" />
          </g>
        </g>

        {/* NODE 2 */}
        <g
          className="anim-node node-2"
          onMouseEnter={() => showTip(130, 518, { badge: "المناهج", title: "المناهج والمقررات الرقمية", desc: "توزيع الخطط الدراسية والكتب المنهجية التفاعلية", glow: "#13A3B5", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="130.438" cy="518.668" fill="#13A3B5" rx="52.7" ry="53" />
          <g transform="translate(105.5, 494) scale(1.05)">
            <path d="M24 15 C20 12, 10 12, 4 15 L4 37 C10 34, 20 34, 24 37 C28 34, 38 34, 44 37 L44 15 C38 12, 28 12, 24 15 Z" fill="white" />
            <line x1="24" y1="15" x2="24" y2="37" stroke="#13A3B5" strokeWidth="2.5" strokeLinecap="round" />
          </g>
        </g>

        {/* NODE 3 */}
        <g
          className="anim-node node-3"
          onMouseEnter={() => showTip(158, 437, { badge: "الانضباط", title: "الحضور والانضباط الذكي", desc: "تسجيل الحضور الآلي وبوابات الاستشعار الذكية", glow: "#0BA84A", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="158.39" cy="437.049" fill="#0BA84A" rx="52.7" ry="53" />
          <g transform="translate(133.5, 412) scale(1.05)">
            <rect x="7" y="6" width="36" height="38" rx="8" fill="white" />
            <path d="M15 25 L22 32 L35 18" stroke="#0BA84A" strokeWidth="4.5" strokeLinecap="round" strokeLinejoin="round" />
          </g>
        </g>

        {/* NODE 4 */}
        <g
          className="anim-node node-4"
          onMouseEnter={() => showTip(230, 379, { badge: "المواعيد", title: "جدول الحصص والمواعيد", desc: "توزيع الحصص الذكي وإدارة القاعات الدراسية", glow: "#FF6105", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="230.408" cy="379.593" fill="#FF6105" rx="52.7" ry="53" />
          <g transform="translate(206, 355) scale(1.05)">
            <rect x="7" y="10" width="36" height="34" rx="8" fill="white" />
            <circle cx="25" cy="27" r="9" fill="white" stroke="#FF6105" strokeWidth="2.8" />
            <polyline points="25,22 25,27 29,29" stroke="#FF6105" strokeWidth="2.5" strokeLinecap="round" />
          </g>
        </g>

        {/* NODE 5 */}
        <g
          className="anim-node node-5"
          onMouseEnter={() => showTip(320, 344, { badge: "التقييم", title: "الاختبارات والتقييم الأكاديمي", desc: "رصد الدرجات وإصدار الشهادات والتقارير الفورية", glow: "#FF3B4B", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="320.749" cy="344.515" fill="#FF3B4B" rx="52.7" ry="53" />
          <g transform="translate(297, 321) scale(1.05)">
            <rect x="8" y="6" width="34" height="40" rx="7" fill="white" />
            <text x="21" y="27" fill="#FF3B4B" fontSize="18" fontWeight="900" textAnchor="middle">A</text>
            <text x="32" y="22" fill="#FF3B4B" fontSize="14" fontWeight="900" textAnchor="middle">+</text>
          </g>
        </g>

        {/* NODE 6 */}
        <g
          className="anim-node node-6"
          onMouseEnter={() => showTip(413, 344, { badge: "المعلمون", title: "الفصول الذكية وشؤون المعلمين", desc: "إدارة الكوادر التعليمية ومنصات الشرح التفاعلي", glow: "#FF339C", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="413.071" cy="344.515" fill="#FF339C" rx="52.7" ry="53" />
          <g transform="translate(388, 320) scale(1.05)">
            <rect x="6" y="8" width="38" height="26" rx="5" fill="white" />
            <line x1="12" y1="15" x2="24" y2="15" stroke="#FF339C" strokeWidth="2.5" strokeLinecap="round" />
            <line x1="12" y1="21" x2="30" y2="21" stroke="#FF339C" strokeWidth="2.5" strokeLinecap="round" />
          </g>
        </g>

        {/* NODE 7 */}
        <g
          className="anim-node node-7"
          onMouseEnter={() => showTip(503, 380, { badge: "التواصل", title: "بوابة أولياء الأمور والمحادثات", desc: "قنوات اتصال فورية وإشعارات لحظية للأهالي", glow: "#E950F7", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="503.876" cy="380.375" fill="#E950F7" rx="52.7" ry="53" />
          <g transform="translate(480, 356) scale(1.05)">
            <path d="M8 12 C8 7.5, 11.5 4, 16 4 L34 4 C38.5 4, 42 7.5, 42 12 L42 26 C42 30.5, 38.5 34, 34 34 L22 34 L12 44 L12 34 C9.8 34, 8 32.2, 8 30 Z" fill="white" />
            <circle cx="20" cy="19" r="3" fill="#E950F7" />
            <circle cx="28" cy="19" r="3" fill="#E950F7" />
            <circle cx="36" cy="19" r="3" fill="#E950F7" />
          </g>
        </g>

        {/* NODE 8 */}
        <g
          className="anim-node node-8"
          onMouseEnter={() => showTip(575, 437, { badge: "المكتبة", title: "المكتبة الرقمية والمراجع", desc: "فهرسة الكتب واستعارة المراجع والأبحاث إلكترونياً", glow: "#992BFF", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="575.295" cy="437.398" fill="#992BFF" rx="52.7" ry="53" />
          <g transform="translate(551, 413) scale(1.05)">
            <path d="M8 20 L38 20 C40 20, 42 22, 42 24 C42 26, 40 28, 38 28 L8 28 Z" fill="white" />
            <path d="M12 28 L40 28 C42 28, 44 30, 44 32 C44 34, 42 36, 40 36 L12 36 Z" fill="white" opacity="0.9" />
          </g>
        </g>

        {/* NODE 9 */}
        <g
          className="anim-node node-9"
          onMouseEnter={() => showTip(603, 518, { badge: "التحليلات", title: "التقارير ومؤشرات الأداء", desc: "تحليلات بيانية شاملة لرفع الكفاءة التعليمية", glow: "#4A53FA", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="603.705" cy="518.927" fill="#4A53FA" rx="52.7" ry="53" />
          <g transform="translate(580, 495) scale(1.05)">
            <rect x="7" y="7" width="40" height="38" rx="8" fill="white" />
            <rect x="13" y="27" width="5" height="12" rx="2" fill="#4A53FA" />
            <rect x="21" y="21" width="5" height="18" rx="2" fill="#4A53FA" />
            <rect x="29" y="15" width="5" height="24" rx="2" fill="#4A53FA" />
          </g>
        </g>

        {/* NODE 10 */}
        <g
          className="anim-node node-10"
          onMouseEnter={() => showTip(606, 612, { badge: "الأمان", title: "الإدارة العامة والأمن المدرسي", desc: "التحكم بالصلاحيات وحماية البيانات المدرسية", glow: "#5334EB", showBadge: true })}
          onMouseLeave={hideTip}
        >
          <ellipse cx="606.177" cy="612.55" fill="#5334EB" rx="52.1" ry="52.1" />
          <g transform="translate(582, 588) scale(1.05)">
            <path d="M24 7 L40 13 L40 25 C40 34, 33 42, 24 45 C15 42, 8 34, 8 25 L8 13 Z" fill="white" />
            <path d="M24 16 L26.5 21 L32 21.8 L28 25.5 L29 31 L24 28.2 L19 31 L20 25.5 L16 21.8 L21.5 21 Z" fill="#5334EB" />
          </g>
        </g>

        {/* CENTRAL ORB */}
        <g
          className="central-orb-group"
          style={{ cursor: "pointer" }}
          onMouseEnter={() => showTip(369, 588, { badge: "التحكم المركزي", title: "Edu Control", desc: "المنصة الذكية الشاملة للإدارة والتحكم المدرسي", glow: "#00C4CC", showBadge: false })}
          onMouseLeave={hideTip}
        >
          <circle cx="369" cy="588" r="112" fill="url(#paint8_radial_sms_exact)" />
          <g transform="translate(369, 588)">
            <polygon points="0,-48 58,-24 0,0 -58,-24" fill="#FFFFFF" />
            <path d="M-34,-11 L-34,10 C-34,24 34,24 34,10 L34,-11" fill="#FFFFFF" opacity="0.95" />
            <path d="M0,-24 L-48,-12 L-50,16" fill="none" stroke="#FFFFFF" strokeWidth="3.5" strokeLinecap="round" />
            <circle cx="-50" cy="20" r="4.5" fill="#FFFFFF" />
            <path d="M-44,42 L44,42" stroke="#FFFFFF" strokeWidth="4.5" strokeLinecap="round" />
          </g>
        </g>

        {/* ── SVG-Native Tooltip (foreignObject) ── */}
        {activeTooltip && (
          <foreignObject
            x={activeTooltip.cx - 160}
            y={activeTooltip.cy - 125}
            width="320"
            height="125"
            style={{ overflow: "visible", pointerEvents: "none" }}
          >
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: "6px",
                padding: "10px 18px",
                borderRadius: "16px",
                background: "rgba(10, 14, 28, 0.96)",
                backdropFilter: "blur(20px)",
                border: "1.5px solid rgba(255,255,255,0.25)",
                textAlign: "center",
                boxShadow: `0 16px 40px -4px rgba(0,0,0,0.7), 0 0 24px ${activeTooltip.data.glow}90`,
                width: "max-content",
                margin: "0 auto",
                maxWidth: "290px",
                direction: "rtl",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "8px" }}>
                {activeTooltip.data.showBadge && activeTooltip.data.badge && (
                  <span
                    style={{
                      padding: "3px 10px",
                      fontSize: "11px",
                      fontWeight: 800,
                      borderRadius: "9999px",
                      background: "rgba(255,255,255,0.18)",
                      color: "#ffffff",
                      border: `1px solid ${activeTooltip.data.glow}`,
                      whiteSpace: "nowrap",
                    }}
                  >
                    {activeTooltip.data.badge}
                  </span>
                )}
                <span style={{ fontWeight: 800, fontSize: "15px", color: "#ffffff", fontFamily: "Cairo, system-ui, sans-serif" }}>
                  {activeTooltip.data.title}
                </span>
              </div>
              <p style={{ fontSize: "12px", fontWeight: 600, color: "rgba(255,255,255,0.92)", maxWidth: "260px", lineHeight: 1.4, margin: 0, fontFamily: "Cairo, system-ui, sans-serif" }}>
                {activeTooltip.data.desc}
              </p>
            </div>
          </foreignObject>
        )}
      </svg>
    </div>
  );
}
