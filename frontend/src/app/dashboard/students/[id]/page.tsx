"use client";
import React, { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Modal } from "@/components/ui/Modal";
import { Send, Clock, Calendar, FileText, BookOpen, ChevronLeft, ChevronRight, Mail, MessageSquare, CreditCard, Users, AlertCircle, Settings, Thermometer, Briefcase, Activity, Bus, Utensils, Home, School, Shirt, Plus, PackagePlus, CalendarCheck } from "lucide-react";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, Cell, PieChart, Pie } from "recharts";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import styles from "./StudentDashboard.module.css";

export default function StudentDashboard() {
  const { id } = useParams();
  const router = useRouter();
  const { isAr } = useTranslation();
  const queryClient = useQueryClient();
  
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editForm, setEditForm] = useState({
    fullName: "",
    nameEn: "",
    classId: ""
  });

  const updateStudentMutation = useMutation({
    mutationFn: async (data: any) => {
      const res = await api.put(`/students/${id}`, data);
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["student", id] });
      setIsEditModalOpen(false);
    }
  });

  const handleEditOpen = () => {
    if(student) {
      setEditForm({
        fullName: student.user?.fullName || student.nameAr || "",
        nameEn: student.nameEn || "",
        classId: student.classId || ""
      });
      setIsEditModalOpen(true);
    }
  };

  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    updateStudentMutation.mutate(editForm);
  };
  
  const { data: student, isLoading } = useQuery({
    queryKey: ["student", id],
    queryFn: async () => (await api.get(`/students/${id}`)).data.data,
  });

  const { data: classes } = useQuery({
    queryKey: ["classes"],
    queryFn: async () => (await api.get(`/classes`)).data.data,
  });

  if (isLoading) return <div className={styles.loading}><div className={styles.spinner}></div></div>;
  const name = isAr ? (student?.nameAr || student?.user?.fullName || "Sara Magdy") : (student?.nameEn || student?.user?.fullName || "Sara Magdy");

  return (
    <div className={styles.page} dir={isAr ? "rtl" : "ltr"}>
      <h1 className={styles.title}>{isAr ? "لوحة تحكم الطالب" : "Student Dashboard"}</h1>
      <div className={styles.bc}>{isAr ? "الطلاب / لوحة تحكم الطالب" : "Students / Students Dashboard"}</div>

      {/* TOP GRID: Profile, Attendance, Schedules */}
      <div className={styles.topGrid}>
        {/* LEFT: Profile + Today's Class */}
        <div className={styles.leftCol}>
          <div className={`${styles.card} ${styles.dark}`}>
            {/* Decorative Shapes */}
            <svg className={styles.shapeBlue} width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M20 10C10 10 10 20 10 40C10 70 30 90 50 90C70 90 90 70 90 40C90 20 90 10 80 10C70 10 60 20 50 20C40 20 30 10 20 10Z" stroke="#3D5EE1" strokeWidth="12" strokeLinecap="round"/>
            </svg>
            <svg className={styles.shapeYellow} width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M35 5L10 20L35 35L30 20L35 5Z" stroke="#FFB800" strokeWidth="4" strokeLinejoin="round"/>
            </svg>
            <svg className={styles.shapeCyan} width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M15 5L5 10L15 15L15 5Z" stroke="#00CFE8" strokeWidth="3" strokeLinejoin="round"/>
            </svg>
            <svg className={styles.shapeGrey} width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M10 10C10 10 10 30 30 30C50 30 70 50 70 70" stroke="#334155" strokeWidth="12" strokeLinecap="round" opacity="0.4"/>
            </svg>

            <div className={styles.profTop}>
              <div className={styles.profPhoto}>
                {student?.photo ? <img src={student.photo} alt="" /> : <div className={styles.profAvatar}>{name[0]}</div>}
              </div>
              <div className={styles.profInfo}>
                <span className={styles.idTag}>#ST {student?.studentCode || "1234546"}</span>
                <h2>{name}</h2>
                <div className={styles.profMeta}>
                  {isAr ? "الفصل" : "Class"} : {student?.class?.name || (isAr ? "غير محدد" : "Unassigned")}  |  {isAr ? "رقم القيد" : "Roll No"} : #{student?.rollNumber || "36545"}
                </div>
              </div>
            </div>
            <div className={styles.profBot}>
              <div className={styles.qBox}>
                <span className={styles.qLabel}>
                  <span className={styles.q1st}>{isAr ? "الربع" : "1st"}</span> <span className={styles.qQuarter}>{isAr ? "الأول" : "Quarterly"}</span>
                </span> 
                <span className={styles.passTag}>
                  <span className={styles.dot}>●</span> {isAr ? "ناجح" : "Pass"}
                </span>
              </div>
              <button className={styles.editBtn} onClick={handleEditOpen}>{isAr ? "تعديل الملف" : "Edit Profile"}</button>
            </div>
          </div>

          <div className={`${styles.card} ${styles.todayClassCard}`}>
            <div className={styles.cHead}><h3>{isAr ? "حصص اليوم" : "Today's Class"}</h3><div className={styles.dateNav}><ChevronLeft size={14}/> <span>16 May 2024</span> <ChevronRight size={14}/></div></div>
            {[
              {n: isAr ? "الإنجليزية" : "English",t:"09:00 - 09:45 AM",s: isAr ? "مكتمل" : "Completed",sc:"#28C76F",img:"https://i.pravatar.cc/60?u=e1"},
              {n: isAr ? "الكيمياء" : "Chemistry",t:"10:45 - 11:30 AM",s: isAr ? "مكتمل" : "Completed",sc:"#28C76F",img:"https://i.pravatar.cc/60?u=e2"},
              {n: isAr ? "الفيزياء" : "Physics",t:"11:30 - 12:15 AM",s: isAr ? "قيد التنفيذ" : "Inprogress",sc:"#FF9F43",img:"https://i.pravatar.cc/60?u=e3"},
            ].map((c,i)=>(
              <div key={i} className={styles.classRow}>
                <img src={c.img} alt="" className={styles.classImg}/>
                <div className={styles.clMeta}><strong>{c.n}</strong><span><Clock size={11}/> {c.t}</span></div>
                <span style={{color:c.sc}} className={styles.clSt}>● {c.s}</span>
              </div>
            ))}
          </div>

          <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px'}}>
            {[
              {n: isAr ? "دفع المصروفات" : "Pay Fees",i:<CreditCard size={18}/>,c:"#4C6FFF",l:"#4C6FFF"},
              {n: isAr ? "نتائج الامتحانات" : "Exam Result",i:<PackagePlus size={18}/>,c:"#1ABE17",l:"#1ABE17"},
            ].map((a,i)=>(
              <div key={i} className={styles.qCard}>
                <div className={styles.qIcon} style={{background:a.c}}>{a.i}</div>
                <span>{a.n}</span>
                <div className={styles.qLine} style={{background:a.l}}></div>
              </div>
            ))}
          </div>
        </div>

        {/* MIDDLE: Attendance */}
        <div className={styles.leftCol}>
          <div className={`${styles.card} ${styles.attendanceCard}`}>
            <div className={styles.cHead}><h3>{isAr ? "الحضور" : "Attendance"}</h3><button className={styles.ddBtn}><Calendar size={13}/> {isAr ? "هذا الشهر" : "This Month"}</button></div>
            <p className={styles.wdText}><Calendar size={13}/> {isAr ? "إجمالي أيام العمل" : "No of total working days"} <strong>28 {isAr ? "يوم" : "Days"}</strong></p>
            <div className={styles.attBoxes}>
              <div><span>{isAr ? "حاضر" : "Present"}</span><strong>25</strong></div>
              <div><span>{isAr ? "غائب" : "Absent"}</span><strong>2</strong></div>
              <div><span>{isAr ? "نصف يوم" : "Halfday"}</span><strong>0</strong></div>
            </div>
            <div className={styles.donut}>
              <ResponsiveContainer width="100%" height={160}>
                <PieChart>
                  <Pie 
                    data={[{v:70},{v:15},{v:5},{v:10}]} 
                    cx="50%" 
                    cy="50%" 
                    innerRadius={50} 
                    outerRadius={65} 
                    dataKey="v" 
                    startAngle={90} 
                    endAngle={-270}
                    stroke="none"
                  >
                    {["#1ABE17","#EA5455","#007AFF","#E2E8F0"].map((c,i)=><Cell key={i} fill={c}/>)}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className={styles.donutTxt}><span>{isAr ? "نسبة الحضور" : "Attendance"}</span><strong>95%</strong></div>
            </div>
            <div className={styles.leg}>
              {[[ "#1ABE17", isAr ? "حاضر" : "Present"],["#EA5455", isAr ? "غائب" : "Absent"],["#007AFF", isAr ? "متأخر" : "Late"],["#E2E8F0", isAr ? "نصف يوم" : "Half Day"]].map(([c,l],i)=>(
                <span key={i}><i style={{background:c}}></i> {l}</span>
              ))}
            </div>
            <div className={styles.last7}>
              <div className={styles.l7h}><strong>{isAr ? "آخر 7 أيام" : "Last 7 Days"}</strong><span>14 May 2024 - 21 May 2024</span></div>
              <div className={styles.wkRow}>
                {["M","T","W","T","F","S","S"].map((d,i)=>(
                  <div key={i} className={`${styles.wkD} ${i<4?styles.wkG:""} ${i===4?styles.wkR:""} ${i>4?styles.wkE:""}`}>
                    {isAr ? ["ن","ث","ر","خ","ج","س","ح"][i] : d}
                  </div>
                ))}
              </div>
            </div>
          </div>
          
          <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px'}}>
            {[
              {n: isAr ? "الجدول الزمني" : "Timetable",i:<Calendar size={18}/>,c:"#F5A524",l:"#F5A524"},
              {n: isAr ? "الحضور" : "Attendance",i:<CalendarCheck size={18}/>,c:"#1E293B",l:"#1E293B"},
            ].map((a,i)=>(
              <div key={i} className={styles.qCard}>
                <div className={styles.qIcon} style={{background:a.c}}>{a.i}</div>
                <span>{a.n}</span>
                <div className={styles.qLine} style={{background:a.l}}></div>
              </div>
            ))}
          </div>
        </div>

        {/* RIGHT: Schedules & Exams */}
        <div className={`${styles.card} ${styles.vFillCard}`}>
          <div className={styles.cHead} style={{borderBottom: '1px solid var(--shell-border, #f1f5f9)', paddingBottom: '16px', marginBottom: '16px'}}>
            <h3>{isAr ? "الجداول" : "Schedules"}</h3>
            <button className={styles.ddBtn} style={{border: 'none', color: '#4C6FFF', background: 'transparent', fontWeight: 600, fontSize: '12px'}}><Plus size={14}/> {isAr ? "إضافة جديد" : "Add New"}</button>
          </div>
          
          <div className={styles.calBox}>
            <div className={styles.calTop}><strong>{isAr ? "يوليو 2024" : "July 2024"}</strong><div className={styles.calNav}><button><ChevronLeft size={14}/></button><button className={styles.calNavAct}><ChevronRight size={14}/></button></div></div>
            <div className={styles.calG} style={{gap: '8px 2px'}}>
              {["S","M","T","W","T","F","S"].map((h,i)=><div key={i} className={styles.calH} style={{color: 'var(--shell-text, #1E293B)', fontWeight: 700}}>{isAr ? ["ح","ن","ث","ر","خ","ج","س"][i] : h}</div>)}
              {[27,28,29,30,31,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,27,19,20,21,22,23,24,25,26,27,28,29,30].map((d,i)=>{
                const isPrev = i < 5;
                const isHighlighted = [6,7,12].includes(d) && !isPrev || (d === 27 && i === 22);
                return (
                  <div key={i} style={{
                    fontSize: '13px', 
                    color: isPrev ? '#CBD5E1' : (isHighlighted ? '#fff' : '#64748B'),
                    background: isHighlighted ? '#4C6FFF' : 'transparent',
                    padding: '6px 0',
                    borderRadius: '6px',
                    fontWeight: isHighlighted ? 500 : 400,
                    cursor: 'pointer'
                  }}>{d}</div>
                );
              })}
            </div>
          </div>
          <div className={styles.exTitle} style={{marginTop: '10px'}}>{isAr ? "الامتحانات" : "Exams"}</div>
          {[
            {q: isAr ? "الربع الأول" : "1st Quarterly",n: isAr ? "الرياضيات" : "Mathematics",t:"06 May 2024",h:"01:30 - 02:15 PM",r: isAr ? "غرفة رقم : 15" : "Room No : 15",d:19},
            {q: isAr ? "الربع الثاني" : "2nd Quarterly",n: isAr ? "الفيزياء" : "Physics",t:"07 May 2024",h:"01:30 - 02:15 PM",r: isAr ? "غرفة رقم : 15" : "Room No : 15",d:20},
          ].map((ex,i)=>(
            <div key={i} className={styles.exCard} style={{background: 'var(--shell-sidebar-bg, #fff)', border: '1px solid var(--shell-border, #F1F5F9)', borderRadius: '8px', padding: '16px', marginBottom: '12px'}}>
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px'}}>
                <strong style={{fontSize: '14px', color: 'var(--shell-text, #1E293B)'}}>{ex.q}</strong>
                <span style={{background: '#FFEBEE', color: '#EA5455', padding: '4px 8px', borderRadius: '4px', fontSize: '11px', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px'}}><Clock size={11}/> {ex.d} {isAr ? "أيام متبقية" : "Days More"}</span>
              </div>
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px'}}>
                <h5 style={{fontSize: '14px', fontWeight: 700, color: 'var(--shell-text, #1E293B)', margin: 0}}>{ex.n}</h5>
                <span style={{fontSize: '12px', color: '#64748B', display: 'flex', alignItems: 'center', gap: '4px'}}><Calendar size={12}/> {ex.t}</span>
              </div>
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                <span style={{fontSize: '12px', color: '#64748B', display: 'flex', alignItems: 'center', gap: '4px'}}><Clock size={12}/> {ex.h}</span>
                <span style={{fontSize: '12px', color: '#4C6FFF'}}>{ex.r}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className={styles.row2}>
        <div className={`${styles.card} ${styles.vFillCard}`}>
          <div className={styles.cHead}><h3>{isAr ? "الأداء" : "Performance"}</h3><button className={styles.ddBtn}><Calendar size={13}/> 2024 - 2025</button></div>
          <ResponsiveContainer width="100%" height={250}>
            <AreaChart data={[{n:"Quarter 1",a:70,b:65},{n:"Quarter 2",a:68,b:62},{n:"Half yearly",a:75,b:60},{n:"Model",a:82,b:78},{n:"Final Exam",a:90,b:85}]}>
              <defs>
                <linearGradient id="pA" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#4C6FFF" stopOpacity={0.1}/><stop offset="95%" stopColor="#4C6FFF" stopOpacity={0}/></linearGradient>
                <linearGradient id="pB" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#00CFE8" stopOpacity={0.1}/><stop offset="95%" stopColor="#00CFE8" stopOpacity={0}/></linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--shell-border, #f1f5f9)"/>
              <XAxis dataKey="n" hide />
              <YAxis axisLine={false} tickLine={false} tick={{fontSize:10,fill:"var(--shell-muted, #94a3b8)"}} />
              <Tooltip />
              <Area type="monotone" dataKey="a" stroke="#4C6FFF" fillOpacity={1} fill="url(#pA)" strokeWidth={2} />
              <Area type="monotone" dataKey="b" stroke="#00CFE8" fillOpacity={1} fill="url(#pB)" strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
          <div className={styles.cLeg}>
            <span><i style={{background:"#4C6FFF"}}></i> {isAr ? "متوسط الدرجات" : "Avg Score"} : 72%</span>
            <span><i style={{background:"#00CFE8"}}></i> {isAr ? "متوسط الحضور" : "Avg. Attendance"} : 95%</span>
          </div>
        </div>

        <div className={`${styles.card} ${styles.vFillCard}`}>
          <div className={styles.cHead}><h3>{isAr ? "الواجبات المنزلية" : "Home Works"}</h3><button className={styles.ddBtn}><Briefcase size={13}/> {isAr ? "كل المواد" : "All Subject"}</button></div>
          {[
            {s: isAr ? "الفيزياء" : "Physics",t: isAr ? "اكتب عن نظرية البندول" : "Write about Theory of Pendulum",d: isAr ? "بواسطة آرون : 16 يونيو 2024" : "Aaron Due by : 16 Jun 2024",p:90,img:"https://i.pravatar.cc/60?u=h1"},
            {s: isAr ? "الكيمياء" : "Chemistry",t: isAr ? "الكيمياء - تغيير العناصر" : "Chemistry - Change of Elements",d: isAr ? "بواسطة هيلانا : 18 يونيو 2024" : "Hellana Due by : 18 Jun 2024",p:65,img:"https://i.pravatar.cc/60?u=h2"},
            {s: isAr ? "الرياضيات" : "Maths",t: isAr ? "الرياضيات - مسائل للحل صفحة 21" : "Maths - Problems to Solve Page 21",d: isAr ? "بواسطة مورجان : 21 يونيو 2024" : "Morgan Due by : 21 Jun 2024",p:30,img:"https://i.pravatar.cc/60?u=h3"},
            {s: isAr ? "الإنجليزية" : "English",t: isAr ? "الإنجليزية - مقدمة المفردات" : "English - Vocabulary Introduction",d: isAr ? "بواسطة دانيال : 21 يونيو 2024" : "Daniel Josua Due by : 21 Jun 2024",p:10,img:"https://i.pravatar.cc/60?u=h4"},
          ].map((h,i)=>(
            <div key={i} className={styles.hwRow}>
              <img src={h.img} alt="" className={styles.hwImg}/>
              <div className={styles.hwMeta}><span><i style={{background:"#f1f5f9",width:6,height:6,borderRadius:"50%",display:"inline-block"}}></i> {h.s}</span><strong>{h.t}</strong><p>{h.d}</p></div>
              <div className={styles.hwPct}>
                <svg viewBox="0 0 36 36"><path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="#f1f5f9" strokeWidth="3"/><path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="#28C76F" strokeWidth="3" strokeDasharray={`${h.p}, 100`}/></svg>
                <span>{h.p}%</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className={styles.row3}>
        <div className={`${styles.card} ${styles.vFillCard}`}>
          <div className={styles.cHead}><h3>{isAr ? "حالة الإجازات" : "Leave Status"}</h3><button className={styles.ddBtn}><Calendar size={13}/> {isAr ? "هذا العام" : "This Year"}</button></div>
          {[
            {n: isAr ? "إجازة طارئة" : "Emergency Leave",d: isAr ? "تاريخ الإجازة : 15 يونيو 2024" : "Leave Date : 15 Jun 2024",s: isAr ? "قيد الانتظار" : "Pending",c:"#4C6FFF",ic:<AlertCircle size={14}/>},
            {n: isAr ? "إجازة مرضية" : "Medical Leave",d: isAr ? "تاريخ الإجازة : 15 يونيو 2024" : "Leave Date : 15 Jun 2024",s: isAr ? "مقبول" : "Approved",c:"#28C76F",ic:<Activity size={14}/>},
            {n: isAr ? "إجازة مرضية" : "Medical Leave",d: isAr ? "تاريخ الإجازة : 15 يونيو 2024" : "Leave Date : 15 Jun 2024",s: isAr ? "مرفوض" : "Declined",c:"#EA5455",ic:<Activity size={14}/>},
            {n: isAr ? "حمى" : "Fever",d: isAr ? "تاريخ الإجازة : 15 يونيو 2024" : "Leave Date : 15 Jun 2024",s: isAr ? "مقبول" : "Approved",c:"#28C76F",ic:<Thermometer size={14}/>},
          ].map((l,i)=>(
            <div key={i} className={styles.lvRow}>
              <div className={styles.lvIcon} style={{color:l.c, background:`${l.c}15`}}>{l.ic}</div>
              <div className={styles.lvMeta}><strong>{l.n}</strong><span>{l.d}</span></div>
              <span className={styles.lvBadge} style={{background:l.c}}>{l.s}</span>
            </div>
          ))}
        </div>

        <div className={`${styles.card} ${styles.vFillCard}`}>
          <div className={styles.cHead} style={{borderBottom: '1px solid var(--shell-border, #f1f5f9)', paddingBottom: '16px', marginBottom: '16px'}}>
            <h3>{isAr ? "نتيجة الامتحان" : "Exam Result"}</h3><button className={styles.ddBtn}><Calendar size={13}/> {isAr ? "الربع الأول" : "1st Quarter"}</button>
          </div>
          <div className={styles.erTags} style={{justifyContent: 'space-between', marginBottom: '24px'}}>
            {[["#F0F3FF","#4C6FFF","Mat : 100"],["#E8F5E9","#28C76F","Phy : 92"],["#FFF8E1","#FF9F43","Che : 90"],["#FFEBEE","#EA5455","Eng : 80"]].map(([bg,c,t],i)=>(
              <span key={i} style={{background:bg, color:c, padding: '6px 12px', borderRadius: '8px', fontSize: '12px', fontWeight: '600'}}>{t}</span>
            ))}
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={[{n:"Mat",v:110,c:"#E9EDF4"},{n:"Phy",v:105,c:"#4C6FFF"},{n:"Che",v:100,c:"#E9EDF4"},{n:"Eng",v:88,c:"#E9EDF4"},{n:"Sci",v:75,c:"#E9EDF4"}]} margin={{top: 0, right: 0, left: -20, bottom: 0}}>
              <XAxis dataKey="n" axisLine={false} tickLine={false} tick={{fontSize:12,fill:"var(--shell-muted, #64748B)"}} dy={10} />
              <YAxis axisLine={false} tickLine={false} tick={{fontSize:12,fill:"var(--shell-muted, #64748B)"}} ticks={[0, 20, 40, 60, 80, 100]} />
              <Bar dataKey="v" radius={[6,6,6,6]} barSize={28}>
                {[{n:"Mat",v:110,c:"#E9EDF4"},{n:"Phy",v:105,c:"#4C6FFF"},{n:"Che",v:100,c:"#E9EDF4"},{n:"Eng",v:88,c:"#E9EDF4"},{n:"Sci",v:75,c:"#E9EDF4"}].map((e,i)=><Cell key={i} fill={e.c}/>)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className={`${styles.card} ${styles.vFillCard}`}>
          <div className={styles.cHead} style={{borderBottom: '1px solid var(--shell-border, #f1f5f9)', paddingBottom: '16px', marginBottom: '16px'}}>
            <h3>{isAr ? "تذكير المصروفات" : "Fees Reminder"}</h3><button className={styles.ddBtn}><Calendar size={13}/> 2024 - 2025</button>
          </div>
          {[
            {n: isAr ? "مصاريف النقل" : "Transport Fees",a: isAr ? "2500 ج.م" : "EGP 2500",d:"25 May 2024",s: isAr ? "آخر موعد" : "Last Date", ic:<Bus size={16}/>, bg:"#F0F3FF", c:"#4C6FFF"},
            {n: isAr ? "مصاريف الكتب" : "Book Fees",a: isAr ? "2500 ج.م" : "EGP 2500",d:"25 May 2024",s: isAr ? "آخر موعد" : "Last Date", ic:<BookOpen size={16}/>, bg:"#E8F5E9", c:"#28C76F"},
            {n: isAr ? "المصاريف الدراسية" : "Tuition",a: isAr ? "2500 ج.م" : "EGP 2500",d:"25 May 2024",s: isAr ? "آخر موعد" : "Last Date", ic:<School size={16}/>, bg:"#F0F3FF", c:"#4C6FFF"},
            {n: isAr ? "الزي المدرسي" : "Uniform",a: isAr ? "2500 + 150 ج.م" : "EGP 2500 + EGP 150",d:"25 May 2024",s: isAr ? "مستحق" : "Due",due:true, ic:<Shirt size={16}/>, bg:"#E0F7FA", c:"#00CFE8"},
            {n: isAr ? "السكن" : "Hostel",a: isAr ? "2500 ج.م" : "EGP 2500",d:"25 May 2024",s: isAr ? "آخر موعد" : "Last Date", ic:<Home size={16}/>, bg:"#FFEBEE", c:"#EA5455"},
          ].map((f,i)=>(
            <div key={i} className={styles.feeRow} style={{borderBottom: 'none', padding: '10px 0'}}>
              <div className={styles.feeIc} style={{background: f.bg, color: f.c, width: '42px', height: '42px', borderRadius: '50%'}}>{f.ic}</div>
              <div className={styles.feeMeta}>
                <strong style={{fontSize: '14px', marginBottom: '4px'}}>{f.n} {f.due && <span style={{background: '#FFEBEE', color: '#EA5455', fontSize: '10px', padding: '2px 8px', borderRadius: '6px', marginLeft: '6px'}}>● {isAr ? "مستحق" : "Due"}</span>}</strong>
                <span style={{fontSize: '12px', color: f.due ? '#EA5455' : '#64748B', fontWeight: '500'}}>{f.a}</span>
              </div>
              <div className={styles.feeR}>
                {f.due ? (
                  <button style={{background: '#4C6FFF', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '6px', fontSize: '12px', fontWeight: '700', cursor: 'pointer'}}>{isAr ? "ادفع الآن" : "Pay now"}</button>
                ) : (
                  <>
                    <span style={{fontSize: '12px', color: 'var(--shell-text, #1E293B)', fontWeight: '700'}}>{f.s}</span>
                    <strong style={{fontSize: '12px', color: 'var(--shell-muted, #64748B)', fontWeight: '500', display: 'block'}}>{f.d}</strong>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className={`${styles.card} ${styles.vFillCard}`}>
        <div className={styles.cHead}><h3>{isAr ? "أعضاء هيئة التدريس" : "Class Faculties"}</h3><div className={styles.calNav}><button><ChevronLeft size={14}/></button><button className={styles.calNavAct}><ChevronRight size={14}/></button></div></div>
        <div className={styles.facGrid}>
          {[
            {n: isAr ? "مستر أحمد" : "Mr Ahmed",s: isAr ? "الكيمياء" : "Chemistry",img:"https://i.pravatar.cc/60?u=t1"},
            {n: isAr ? "مس هيلانا" : "Ms Hellana",s: isAr ? "الإنجليزية" : "English",img:"https://i.pravatar.cc/60?u=t2"},
            {n: isAr ? "مستر محمد" : "Mr Mohamed",s: isAr ? "الفيزياء" : "Physics",img:"https://i.pravatar.cc/60?u=t3"},
            {n: isAr ? "مستر ماجد" : "Mr Maged",s: isAr ? "الإسبانية" : "Spanish",img:"https://i.pravatar.cc/60?u=t4"},
            {n: isAr ? "مس سارة" : "Ms Sara",s: isAr ? "الرياضيات" : "Maths",img:"https://i.pravatar.cc/60?u=t5"},
          ].map((f,i)=>(
            <div key={i} className={styles.facCard}>
              <div className={styles.facTop}><img src={f.img} alt=""/><div><strong>{f.n}</strong><span>{f.s}</span></div></div>
              <div className={styles.facBtns}><button><Mail size={12}/> {isAr ? "إيميل" : "Email"}</button><button><MessageSquare size={12}/> {isAr ? "دردشة" : "Chat"}</button></div>
            </div>
          ))}
        </div>
      </div>
      <Modal 
        isOpen={isEditModalOpen} 
        onClose={() => setIsEditModalOpen(false)} 
        title={isAr ? "تعديل ملف الطالب" : "Edit Student Profile"}
      >
        <form onSubmit={handleEditSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: 600 }}>{isAr ? "الاسم الكامل (بالعربي)" : "Full Name (AR)"}</label>
            <input 
              type="text" 
              value={editForm.fullName} 
              onChange={e => setEditForm({...editForm, fullName: e.target.value})}
              style={{ width: '100%', padding: '12px', borderRadius: '8px', border: '1px solid var(--shell-border, #E9EDF4)', fontSize: '14px', color: 'var(--shell-text, #1E293B)', background: 'var(--shell-main-bg, #F8FAFC)' }}
              required
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: 600 }}>{isAr ? "الاسم الكامل (بالإنجليزي)" : "Full Name (EN)"}</label>
            <input 
              type="text" 
              value={editForm.nameEn} 
              onChange={e => setEditForm({...editForm, nameEn: e.target.value})}
              style={{ width: '100%', padding: '12px', borderRadius: '8px', border: '1px solid var(--shell-border, #E9EDF4)', fontSize: '14px', color: 'var(--shell-text, #1E293B)', background: 'var(--shell-main-bg, #F8FAFC)' }}
            />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: 600 }}>{isAr ? "الفصل" : "Class"}</label>
            <select 
              value={editForm.classId} 
              onChange={e => setEditForm({...editForm, classId: e.target.value})}
              style={{ width: '100%', padding: '12px', borderRadius: '8px', border: '1px solid var(--shell-border, #E9EDF4)', fontSize: '14px', color: 'var(--shell-text, #1E293B)', background: 'var(--shell-main-bg, #F8FAFC)' }}
            >
              <option value="">{isAr ? "غير محدد" : "Unassigned"}</option>
              {classes?.map((c: any) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
          </div>
          
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
            <button type="button" onClick={() => setIsEditModalOpen(false)} style={{ padding: '10px 16px', background: '#F1F5F9', color: '#64748B', border: 'none', borderRadius: '8px', fontWeight: 600, cursor: 'pointer' }}>{isAr ? "إلغاء" : "Cancel"}</button>
            <button type="submit" disabled={updateStudentMutation.isPending} style={{ padding: '10px 16px', background: '#4C6FFF', color: '#fff', border: 'none', borderRadius: '8px', fontWeight: 600, cursor: 'pointer', opacity: updateStudentMutation.isPending ? 0.7 : 1 }}>
              {updateStudentMutation.isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "حفظ التغييرات" : "Save Changes")}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
