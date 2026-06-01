export type OverviewAnnouncement = {
  id: string;
  title: string;
  excerpt: string;
  audience: string;
  createdAt: string;
};

export type OverviewNotification = {
  id: string;
  type: string;
  title: string;
  message: string;
  createdAt: string;
};

export type OverviewAttendancePoint = {
  date: string;
  rate: number;
  count: number;
};

export type OverviewRevenuePoint = {
  month: string;
  amount: number;
};

export type OverviewClassRates = {
  classId: string;
  label: string;
  passRate: number;
  failRate: number;
  samples: number;
};

export type OverviewLeaveRequest = {
  id: string;
  studentId?: string;
  teacherId?: string;
  type: string;
  reason?: string;
  startDate: string;
  endDate: string;
  applyDate: string;
  status: string;
  student?: { nameAr?: string; nameEn?: string; photo?: string; user?: { fullName: string } };
  teacher?: { nameAr?: string; nameEn?: string; photo?: string; user?: { fullName: string } };
};

export type DashboardOverview = {
  totalStudents: number;
  activeStudents: number;
  inactiveStudents: number;
  studentChange: number;

  totalTeachers: number;
  activeTeachers: number;
  inactiveTeachers: number;
  teacherChange: number;

  totalDrivers: number;
  activeDrivers: number;
  inactiveDrivers: number;
  driverChange: number;

  totalSubjects: number;
  activeSubjects: number;
  inactiveSubjects: number;
  subjectChange: number;

  totalClasses: number;
  totalRevenue: number;
  totalSchools?: number;

  attendanceRateToday: number;
  attendanceStats: {
    students: { present: number; absent: number; late: number; emergency: number };
    teachers: { present: number; absent: number; late: number; emergency: number };
    drivers: { present: number; absent: number; late: number; emergency: number };
  };
  absentStudentsToday: number;
  attendanceMarkedToday: number;

  pendingFeesCount: number;
  pendingFeesAmount: number;

  activeBuses: number;
  homeworkSentToday: number;

  latestAnnouncements: OverviewAnnouncement[];
  latestNotifications: OverviewNotification[];
  academicClasses: { id: string; name: string; section: string; capacity: number; studentsCount: number; room: string | null; floor: string | null }[];
  pendingLeaves: OverviewLeaveRequest[];
  upcomingEvents: any[];
  totalEarnings: number;
  totalExpenses: number;
  totalFines: number;
  unpaidStudents: { count: number; recent: { student: { id: string; photo: string | null; user: { fullName: string } } }[] };
  platformPerformance: { high: number; medium: number; low: number };

  attendanceTrend30d: OverviewAttendancePoint[];
  monthlyRevenue: OverviewRevenuePoint[];
  feesCollectionTrend: Array<{ name: string; total: number; collected: number }>;
  classSuccessVsFail: OverviewClassRates[];

  meta?: {
    busesModule?: string;
    homeworkModule?: string;
    classChartNote?: string;
  };
};
