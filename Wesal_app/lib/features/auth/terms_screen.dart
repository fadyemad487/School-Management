import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../main.dart';
import '../../core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
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
                      const Color(0xFF1D4ED8).withOpacity(0.2),
                      const Color(0xFF7C3AED).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFF1D4ED8).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gavel_rounded, color: const Color(0xFF818CF8), size: 18.r),
                    SizedBox(width: 8.w),
                    Text(
                      isArabic ? 'آخر تحديث: مايو 2026' : 'Last Updated: May 2026',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF818CF8),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 28.h),

            // Introduction
            _buildSectionCard(
              context: context,
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: isArabic ? 'مقدمة' : 'Introduction',
              content: isArabic
                  ? 'مرحباً بك في تطبيق "WeCircle" التعليمي. باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بالشروط والأحكام التالية. يرجى قراءتها بعناية قبل استخدام خدماتنا.\n\nتطبيق WeCircle هو منصة تعليمية متكاملة تهدف إلى تسهيل التواصل بين أولياء الأمور والمعلمين والمدرسة لضمان بيئة تعليمية آمنة وفعّالة.'
                  : 'Welcome to the "WeCircle" educational application. By using this application, you agree to comply with and be bound by the following terms and conditions. Please read them carefully before using our services.\n\nWeCircle is an integrated educational platform that aims to facilitate communication between parents, teachers, and the school administration to ensure a safe and efficient learning environment.',
            ),
            SizedBox(height: 16.h),

            // Account Registration
            _buildSectionCard(
              context: context,
              icon: Icons.person_add_alt_1_rounded,
              iconColor: const Color(0xFF10B981),
              title: isArabic ? 'إنشاء الحساب والتسجيل' : 'Account Registration',
              content: isArabic
                  ? '• يتم إنشاء حسابات المستخدمين (أولياء الأمور، المعلمين، الطلاب، السائقين) بواسطة إدارة المدرسة عبر لوحة التحكم.\n\n• يتحمل المستخدم مسؤولية الحفاظ على سرية بيانات الدخول الخاصة به (معرّف الدخول وكلمة المرور).\n\n• يجب عدم مشاركة بيانات الحساب مع أي شخص آخر.\n\n• يحق للمدرسة تعطيل أو حذف أي حساب في حالة مخالفة الشروط.'
                  : '• User accounts (parents, teachers, students, drivers) are created by the school administration via the control panel.\n\n• The user is responsible for maintaining the confidentiality of their login credentials (login ID and password).\n\n• Account details must not be shared with any other person.\n\n• The school reserves the right to disable or delete any account in case of violation of terms.',
            ),
            SizedBox(height: 16.h),

            // Usage Rules
            _buildSectionCard(
              context: context,
              icon: Icons.rule_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: isArabic ? 'قواعد الاستخدام' : 'Usage Rules',
              content: isArabic
                  ? '• يلتزم المستخدم باستخدام التطبيق للأغراض التعليمية المشروعة فقط.\n\n• يُمنع استخدام التطبيق لنشر محتوى مسيء أو غير لائق أو مخالف للآداب العامة.\n\n• يُمنع محاولة الوصول غير المصرح به إلى بيانات مستخدمين آخرين أو أنظمة المدرسة.\n\n• يُمنع استخدام التطبيق لأي أنشطة تجارية أو إعلانية غير مصرح بها.\n\n• يجب الإبلاغ فوراً عن أي سلوك مشبوه أو خرق أمني يلاحظه المستخدم.'
                  : '• The user agrees to use the application solely for legitimate educational purposes.\n\n• It is strictly forbidden to use the application to publish offensive, inappropriate, or unethical content.\n\n• Unauthorized attempts to access data of other users or school systems are prohibited.\n\n• Using the application for unauthorized commercial or promotional activities is prohibited.\n\n• Users must report any suspicious behavior or security breach immediately.',
            ),
            SizedBox(height: 16.h),

            // Data & Privacy
            _buildSectionCard(
              context: context,
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: isArabic ? 'البيانات والخصوصية' : 'Data & Privacy',
              content: isArabic
                  ? '• نحرص على حماية بياناتك الشخصية وبيانات أبنائك وفقاً لأعلى معايير الأمان.\n\n• لا يتم مشاركة البيانات الشخصية مع أي أطراف خارجية دون موافقتك الصريحة.\n\n• يتم تشفير جميع البيانات المنقولة بين التطبيق والخوادم باستخدام بروتوكولات أمان متقدمة.\n\n• يحق لك طلب حذف بياناتك الشخصية في أي وقت عبر التواصل مع إدارة المدرسة.'
                  : '• We care about protecting your personal data and your children\'s data in accordance with the highest security standards.\n\n• Personal data is never shared with external parties without your explicit consent.\n\n• All data transmitted between the app and servers is encrypted using advanced security protocols.\n\n• You have the right to request deletion of your personal data at any time by contacting the school administration.',
            ),
            SizedBox(height: 16.h),

            // Intellectual Property
            _buildSectionCard(
              context: context,
              icon: Icons.copyright_rounded,
              iconColor: const Color(0xFFEC4899),
              title: isArabic ? 'الملكية الفكرية' : 'Intellectual Property',
              content: isArabic
                  ? '• جميع حقوق الملكية الفكرية لتطبيق WeCircle محفوظة بالكامل.\n\n• يشمل ذلك التصميمات والشعارات والأيقونات والنصوص البرمجية والمحتوى التعليمي.\n\n• يُمنع نسخ أو تعديل أو توزيع أي جزء من التطبيق دون إذن كتابي مسبق.\n\n• العلامة التجارية "WeCircle" وشعارها مسجلة ومحمية بموجب القانون.'
                  : '• All intellectual property rights of the WeCircle app are fully reserved.\n\n• This includes designs, logos, icons, source code, and educational content.\n\n• Copying, modifying, or distributing any part of the application without prior written permission is prohibited.\n\n• The trademark "WeCircle" and its logo are registered and protected by law.',
            ),
            SizedBox(height: 16.h),

            // Responsibilities
            _buildSectionCard(
              context: context,
              icon: Icons.balance_rounded,
              iconColor: const Color(0xFF14B8A6),
              title: isArabic ? 'حدود المسؤولية' : 'Limitation of Liability',
              content: isArabic
                  ? '• نسعى لتوفير خدمة مستقرة وموثوقة، لكننا لا نضمن خلو التطبيق من الأعطال التقنية بشكل كامل.\n\n• لا نتحمل المسؤولية عن أي أضرار ناتجة عن سوء استخدام التطبيق أو مشاركة بيانات الدخول مع الغير.\n\n• تقع مسؤولية التحقق من صحة المعلومات المعروضة على عاتق المستخدم والمدرسة بشكل مشترك.\n\n• نحتفظ بالحق في تحديث هذه الشروط في أي وقت مع إخطار المستخدمين بالتغييرات الجوهرية.'
                  : '• We strive to provide a stable and reliable service, but we do not guarantee that the application will be completely free of technical glitches.\n\n• We are not liable for any damages resulting from misuse of the app or sharing login details with others.\n\n• Verified correctness of the displayed information is a joint responsibility of the user and the school.\n\n• We reserve the right to update these terms at any time and will notify users of major changes.',
            ),
            SizedBox(height: 16.h),

            // Contact
            _buildSectionCard(
              context: context,
              icon: Icons.support_agent_rounded,
              iconColor: const Color(0xFF3B82F6),
              title: isArabic ? 'التواصل معنا' : 'Contact Us',
              content: isArabic
                  ? 'في حالة وجود أي استفسارات أو ملاحظات حول هذه الشروط والأحكام، يمكنك التواصل معنا عبر:\n\n📧 البريد الإلكتروني: FadyEmad487@gmail.com\n📞 الهاتف: 01201088003\n🏢 العنوان: القاهرة، مصر'
                  : 'If you have any questions or feedback regarding these terms and conditions, you can reach us via:\n\n📧 Email: FadyEmad487@gmail.com\n📞 Phone: 01201088003\n🏢 Address: Cairo, Egypt',
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
                    isArabic ? '© 2026 WeCircle — جميع الحقوق محفوظة' : '© 2026 WeCircle — All Rights Reserved',
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
