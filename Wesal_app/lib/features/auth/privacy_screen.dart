import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../main.dart';
import '../../core/theme/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              isArabic ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_ios_rounded,
              color: AppColors.textDark,
              size: 18.r,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
          style: GoogleFonts.cairo(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Badge
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.2),
                      const Color(0xFF14B8A6).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, color: const Color(0xFF34D399), size: 18.r),
                    SizedBox(width: 8.w),
                    Text(
                      isArabic ? 'بياناتك في أمان تام' : 'Your Data is Fully Safe',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF34D399),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 28.h),

            // Our Commitment
            _buildSectionCard(
              context: context,
              icon: Icons.lock_outline_rounded,
              iconColor: const Color(0xFF10B981),
              title: isArabic ? 'التزامنا بالخصوصية' : 'Our Commitment to Privacy',
              content: isArabic
                  ? 'نحن في WeCircle نولي أهمية قصوى لخصوصية وأمان بياناتك الشخصية وبيانات أبنائك. تهدف هذه السياسة إلى توضيح كيفية جمع البيانات واستخدامها وحمايتها أثناء استخدامك لتطبيقنا.\n\nنلتزم بجميع القوانين والتشريعات المحلية والدولية المتعلقة بحماية البيانات الشخصية.'
                  : 'We at WeCircle give the utmost importance to the privacy and security of your personal data and your children\'s data. This policy aims to clarify how we collect, use, and protect data during your use of our app.\n\nWe comply with all local and international laws and regulations regarding personal data protection.',
            ),
            SizedBox(height: 16.h),

            // Data Collection
            _buildSectionCard(
              context: context,
              icon: Icons.data_usage_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: isArabic ? 'البيانات التي نجمعها' : 'Data We Collect',
              content: isArabic
                  ? '🔹 بيانات الحساب: الاسم الكامل، معرّف الدخول، والدور في النظام (ولي أمر، معلم، طالب، سائق).\n\n🔹 بيانات الطلاب: الاسم، الصف الدراسي، سجلات الحضور والغياب، الدرجات، والسلوك.\n\n🔹 بيانات الاستخدام: سجلات الدخول، وقت آخر نشاط، وإعدادات التطبيق.\n\n🔹 بيانات الجهاز: نوع الجهاز ونظام التشغيل لتحسين أداء التطبيق.'
                  : '🔹 Account Data: Full name, login ID, and role in the system (parent, teacher, student, driver).\n\n🔹 Students Data: Name, class grade, attendance records, grades, and behavior logs.\n\n🔹 Usage Data: Login history, last active time, and application preferences.\n\n🔹 Device Data: Device type and operating system version to optimize application performance.',
            ),
            SizedBox(height: 16.h),

            // Data Usage
            _buildSectionCard(
              context: context,
              icon: Icons.settings_suggest_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: isArabic ? 'كيف نستخدم بياناتك' : 'How We Use Your Data',
              content: isArabic
                  ? '✅ توفير الخدمات التعليمية: عرض الحضور والغياب والدرجات والواجبات.\n\n✅ التواصل: إرسال الإشعارات المهمة حول أداء الطالب والأحداث المدرسية.\n\n✅ التحسين المستمر: تحليل بيانات الاستخدام لتطوير تجربة التطبيق.\n\n✅ الأمان: الكشف عن الأنشطة المشبوهة وحماية الحسابات من الاختراق.\n\n❌ لا نبيع أو نؤجر بياناتك لأي أطراف خارجية أبداً.'
                  : '✅ Providing Educational Services: Showing attendance, grades, homework, and behavior records.\n\n✅ Communication: Sending key push notifications regarding student performance and school events.\n\n✅ Continuous Improvement: Analyzing usage metrics to enhance application workflows.\n\n✅ Security: Detecting suspicious behavior and preventing unauthorized account access.\n\n❌ We NEVER sell or rent your personal data to any external parties.',
            ),
            SizedBox(height: 16.h),

            // Data Protection
            _buildSectionCard(
              context: context,
              icon: Icons.security_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: isArabic ? 'حماية البيانات' : 'Data Protection & Security',
              content: isArabic
                  ? '🛡️ التشفير: جميع البيانات مشفّرة أثناء النقل باستخدام بروتوكول TLS/SSL.\n\n🛡️ تشفير كلمات المرور: يتم تخزين كلمات المرور باستخدام خوارزمية SHA-256 ولا يمكن استرجاعها.\n\n🛡️ العزل: كل مدرسة معزولة تماماً عن المدارس الأخرى في النظام (Multi-Tenant Architecture).\n\n🛡️ التحكم في الوصول: يتم منح صلاحيات محددة لكل دور بناءً على مبدأ الحد الأدنى من الصلاحيات.'
                  : '🛡️ Encryption: All personal data is encrypted in transit using the advanced TLS/SSL protocol.\n\n🛡️ Password Hashing: Passwords are securely stored using the SHA-256 algorithm and cannot be retrieved.\n\n🛡️ Isolation: Every school database is completely isolated from other schools in our multi-tenant cloud architecture.\n\n🛡️ Access Control: Strict role-based permissions ensure minimum required access to features.',
            ),
            SizedBox(height: 16.h),

            // Children's Privacy
            _buildSectionCard(
              context: context,
              icon: Icons.child_care_rounded,
              iconColor: const Color(0xFFEC4899),
              title: isArabic ? 'خصوصية الأطفال' : 'Children\'s Privacy',
              content: isArabic
                  ? '👦 نحرص بشكل خاص على حماية بيانات الأطفال والطلاب دون سن 18 عاماً.\n\n👦 لا يتم جمع أي بيانات شخصية من الأطفال مباشرة؛ بل يتم إدخالها بواسطة المدرسة وأولياء الأمور فقط.\n\n👦 يحق لولي الأمر الاطلاع على جميع البيانات المتعلقة بأبنائه وطلب تعديلها أو حذفها.\n\n👦 تُستخدم بيانات الأطفال حصرياً للأغراض التعليمية والإدارية المعتمدة.'
                  : '👦 We are deeply committed to protecting the privacy of children and students under 18.\n\n👦 No personal data is gathered from children directly; it is exclusively provided by schools and parents.\n\n👦 Parents have the absolute right to view, modify, or delete any data regarding their children.\n\n👦 Children\'s data is used strictly for authorized educational and administrative services.',
            ),
            SizedBox(height: 16.h),

            // User Rights
            _buildSectionCard(
              context: context,
              icon: Icons.how_to_reg_rounded,
              iconColor: const Color(0xFF14B8A6),
              title: isArabic ? 'حقوقك كمستخدم' : 'Your Rights as a User',
              content: isArabic
                  ? '📋 حق الوصول: يحق لك طلب نسخة من جميع بياناتك الشخصية المخزنة لدينا.\n\n📋 حق التصحيح: يحق لك تصحيح أي بيانات غير دقيقة أو غير كاملة.\n\n📋 حق الحذف: يحق لك طلب حذف بياناتك الشخصية من أنظمتنا.\n\n📋 حق الاعتراض: يحق لك الاعتراض على معالجة بياناتك لأغراض معينة.\n\n📋 حق النقل: يحق لك طلب نقل بياناتك بصيغة قابلة للإراءة.'
                  : '📋 Access: You have the right to request a copy of all your personal data stored on our servers.\n\n📋 Rectification: You have the right to correct any inaccurate or incomplete details.\n\n📋 Deletion: You can request the permanent removal of your personal data from our systems.\n\n📋 Objection: You have the right to object to the processing of your data for specific purposes.\n\n📋 Portability: You can request transmission of your data in a readable digital format.',
            ),
            SizedBox(height: 16.h),

            // Contact
            _buildSectionCard(
              context: context,
              icon: Icons.mail_outline_rounded,
              iconColor: const Color(0xFF6366F1),
              title: isArabic ? 'التواصل بشأن الخصوصية' : 'Privacy Inquiries',
              content: isArabic
                  ? 'إذا كانت لديك أي أسئلة أو مخاوف بشأن سياسة الخصوصية، أو إذا كنت ترغب في ممارسة أي من حقوقك، يرجى التواصل معنا:\n\n📧 FadyEmad487@gmail.com\n📞 01201088003\n\nسنرد على جميع الطلبات خلال 30 يوم عمل كحد أقصى.'
                  : 'If you have any questions or concerns regarding our privacy policies, or wish to exercise your rights, please reach us at:\n\n📧 FadyEmad487@gmail.com\n📞 01201088003\n\nWe will reply to all user inquiries within a maximum of 30 business days.',
            ),

            SizedBox(height: 32.h),

            // Footer
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    isArabic ? '© 2026 WeCircle — خصوصيتك أولويتنا' : '© 2026 WeCircle — Your Privacy is Our Priority',
                    style: GoogleFonts.cairo(
                      color: AppColors.textLight,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    final isArabic = WeCircleApp.getLocale(context).languageCode == 'ar';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 20.r),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: AppColors.textDark,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            content,
            style: GoogleFonts.cairo(
              color: AppColors.textMedium,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              height: 1.8,
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
    );
  }
}
