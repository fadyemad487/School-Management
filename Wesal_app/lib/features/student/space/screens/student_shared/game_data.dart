import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'game_intro_screen.dart';

class GameData {
  static List<GameIntroStep> getSteps(String gameKey, Color color) {
    switch (gameKey) {
      case 'shadow_signal': // 4-6
        return [
          GameIntroStep(
            description: 'أهلاً بك أيها العميل! مهمتك هي فك الإشارات الغامضة التي تصلنا من أعماق الفضاء.',
            illustration: _buildIllustration(Icons.visibility_rounded, color),
          ),
          GameIntroStep(
            description: 'راقب تسلسل الألوان والرموز بعناية فائقة، ثم أعد إدخالها بدقة متناهية.',
            illustration: _buildIllustration(Icons.code_rounded, color),
          ),
          GameIntroStep(
            description: 'الدقة والتركيز هما سلاحك في هذه المهمة السرية.. ابقَ يقظاً دائماً!',
            illustration: _buildIllustration(Icons.security_rounded, color),
          ),
        ];
      case 'decoder_simulator':
        return [
          GameIntroStep(
            description: 'نظام الحماية في السفينة يحتاج لفك تشفير رقمي.',
            illustration: _buildIllustration(Icons.enhanced_encryption_rounded, color),
          ),
          GameIntroStep(
            description: 'حل المسائل الحسابية والمنطقية التي تظهر على الشاشة.',
            illustration: _buildIllustration(Icons.calculate_rounded, color),
          ),
          GameIntroStep(
            description: 'احذر! الوقت محدود وكل ثانية تقربك من كسر الشفرة.',
            illustration: _buildIllustration(Icons.timer_rounded, color),
          ),
        ];
      case 'captain_radar':
        return [
          GameIntroStep(
            description: 'استخدم الرادار المتطور لمسح الأجسام الغريبة.',
            illustration: _buildIllustration(Icons.radar_rounded, color),
          ),
          GameIntroStep(
            description: 'طابق بين الأجسام المكتشفة ومعلوماتها العلمية الصحيحة.',
            illustration: _buildIllustration(Icons.science_rounded, color),
          ),
          GameIntroStep(
            description: 'اجمع أكبر عدد من البيانات لرفع كفاءة سفينتك.',
            illustration: _buildIllustration(Icons.analytics_rounded, color),
          ),
        ];
      case 'focus_lock':
        return [
          GameIntroStep(
            description: 'ستظهر مجموعة من الأكواد السرية في مربعات.',
            illustration: _buildIllustration(Icons.apps_rounded, color),
          ),
          GameIntroStep(
            description: 'احفظ ترتيب الأرقام أو الحروف جيداً قبل أن تختفي.',
            illustration: _buildIllustration(Icons.visibility_off_rounded, color),
          ),
          GameIntroStep(
            description: 'اضغط على المربعات بالترتيب الصحيح لفتح القفل.',
            illustration: _buildIllustration(Icons.lock_open_rounded, color),
          ),
        ];
      case 'crisis_control':
        return [
          GameIntroStep(
            description: 'واجه المواقف الصعبة والأزمات المفاجئة بهدوء.',
            illustration: _buildIllustration(Icons.warning_rounded, color),
          ),
          GameIntroStep(
            description: 'اتبع تعليمات التنفس لتهدئة ضغط الطاقة في السفينة.',
            illustration: _buildIllustration(Icons.air_rounded, color),
          ),
          GameIntroStep(
            description: 'ثباتك الانفعالي هو المفتاح لعبور الأزمة بسلام.',
            illustration: _buildIllustration(Icons.verified_user_rounded, color),
          ),
        ];
      case 'hawk_eye':
        return [
          GameIntroStep(
            description: 'ركز في الخريطة الفضائية لاكتشاف الأهداف المخفية.',
            illustration: _buildIllustration(Icons.remove_red_eye_rounded, color),
          ),
          GameIntroStep(
            description: 'اضغط على الرموز التي تظهر فجأة قبل أن تتلاشى.',
            illustration: _buildIllustration(Icons.touch_app_rounded, color),
          ),
          GameIntroStep(
            description: 'تجنب المشتتات وحافظ على تركيزك العالي.',
            illustration: _buildIllustration(Icons.track_changes_rounded, color),
          ),
        ];
      case 'critical_choice':
        return [
          GameIntroStep(
            description: 'ستواجه مواقف صعبة تتطلب قراراً سريعاً وحكيماً.',
            illustration: _buildIllustration(Icons.alt_route_rounded, color),
          ),
          GameIntroStep(
            description: 'فكر في عواقب كل اختيار على طاقم السفينة.',
            illustration: _buildIllustration(Icons.group_rounded, color),
          ),
          GameIntroStep(
            description: 'اختياراتك تحدد مسار المهمة ومستقبلك كقائد.',
            illustration: _buildIllustration(Icons.auto_awesome_rounded, color),
          ),
        ];
      case 'social_os':
        return [
          GameIntroStep(
            description: 'تواصل مع أعضاء الفريق والذكاء الاصطناعي للسفينة.',
            illustration: _buildIllustration(Icons.forum_rounded, color),
          ),
          GameIntroStep(
            description: 'اختر الردود الذكية واللطيفة لحل النزاعات بذكاء.',
            illustration: _buildIllustration(Icons.psychology_rounded, color),
          ),
          GameIntroStep(
            description: 'ابنِ تحالفات قوية وواجه التنمر بأسلوب القادة.',
            illustration: _buildIllustration(Icons.shield_rounded, color),
          ),
        ];
      case 'gravity_balance':
        return [
          GameIntroStep(
            description: 'تحكم في توازن السفينة في مناطق انعدام الجاذبية.',
            illustration: _buildIllustration(Icons.balance_rounded, color),
          ),
          GameIntroStep(
            description: 'حافظ على هدوئك لتحريك السفينة بسلاسة.',
            illustration: _buildIllustration(Icons.slow_motion_video_rounded, color),
          ),
          GameIntroStep(
            description: 'تجاوز العقبات دون أن تفقد توازنك النفسي.',
            illustration: _buildIllustration(Icons.spa_rounded, color),
          ),
        ];
      case 'mission_prep':
        return [
          GameIntroStep(
            description: 'قبل الانطلاق، عليك تجهيز حقيبة المهمة بعناية.',
            illustration: _buildIllustration(Icons.inventory_2_rounded, color),
          ),
          GameIntroStep(
            description: 'رتب الأدوات حسب الأولوية والمساحة المتاحة.',
            illustration: _buildIllustration(Icons.reorder_rounded, color),
          ),
          GameIntroStep(
            description: 'التخطيط الجيد هو نصف النجاح في أي مهمة فضائية.',
            illustration: _buildIllustration(Icons.edit_note_rounded, color),
          ),
        ];
      case 'intelligence': // Star/Bridges (1-3)
        return [
          GameIntroStep(
            description: 'استعد لتبني جسور النور بذكاءك! اللعبة دي هتختبر قدرتك على ربط الأشياء ببعضها.',
            illustration: _buildIllustration(Icons.lightbulb_rounded, color),
          ),
          GameIntroStep(
            description: 'كل اللي عليك تعمله إنك توصل النجوم ببعض عشان تنور المجرة وتفتح الأبواب المقفولة.',
            illustration: _buildIllustration(Icons.hub_rounded, color),
          ),
          GameIntroStep(
            description: 'خليك ذكي وسريع، وكل ما تخلص جسر هتاخد بلورات طاقة تكبر بيها قوتك!',
            illustration: _buildIllustration(Icons.auto_awesome_rounded, color),
          ),
        ];
      case 'kindness_journey': // Heart (1-3)
        return [
          GameIntroStep(
            description: 'أهلاً بك في رحلة القلوب الطيبة! هنا هنتعلم إزاي نكون أبطال في تعاملنا مع الآخرين.',
            illustration: _buildIllustration(Icons.favorite_rounded, color),
          ),
          GameIntroStep(
            description: 'هتظهر لك مواقف حقيقية، فكر كويس واختار التصرف اللي يخلي الناس سعيدة.',
            illustration: _buildIllustration(Icons.psychology_alt_rounded, color),
          ),
          GameIntroStep(
            description: 'كل اختيار طيب هتعمله هيخلي قلبك ينور ويكبر، وهتجمع نقاط اللطف العظيمة!',
            illustration: _buildIllustration(Icons.volunteer_activism_rounded, color),
          ),
        ];
      case 'organization': // Bag (1-3)
        return [
          GameIntroStep(
            description: 'البطل الحقيقي هو اللي دايما جاهز! اللعبة دي هتعلمنا إزاي ننظم أدواتنا عشان مننساش حاجة.',
            illustration: _buildIllustration(Icons.backpack_rounded, color),
          ),
          GameIntroStep(
            description: 'شوف الأدوات اللي محتاجها في شنطتك، ورتبها بسرعة قبل ما وقت المهمة يخلص.',
            illustration: _buildIllustration(Icons.checklist_rounded, color),
          ),
          GameIntroStep(
            description: 'الترتيب شطارة، والمنظم دايما بيكسب وقته وبيكون مرتاح في مدرسته وبيته.',
            illustration: _buildIllustration(Icons.check_circle_rounded, color),
          ),
        ];
      case 'sharing':
        return [
          GameIntroStep(
            description: 'المجرة محتاجة نورك عشان ترجع قوية زي زمان.',
            illustration: _buildIllustration(Icons.wb_sunny_rounded, color),
          ),
          GameIntroStep(
            description: 'اسحب خط النور من قلبك ووصله للكواكب المظلمة.',
            illustration: _buildIllustration(Icons.auto_awesome_motion_rounded, color),
          ),
          GameIntroStep(
            description: 'بمشاركتك للنور، هتنشر الخير والسعادة في كل مكان.',
            illustration: _buildIllustration(Icons.favorite_rounded, color),
          ),
        ];
      case 'exploration':
        return [
          GameIntroStep(
            description: 'مهمتك هي بناء جسور من النور بين الكواكب البعيدة.',
            illustration: _buildIllustration(Icons.polyline_rounded, color),
          ),
          GameIntroStep(
            description: 'وصل النقط ببعض عشان تكتشف معلومات علمية جديدة.',
            illustration: _buildIllustration(Icons.lightbulb_rounded, color),
          ),
          GameIntroStep(
            description: 'كل جسر بتبنيه بيقربنا أكتر من فهم أسرار الكون.',
            illustration: _buildIllustration(Icons.public_rounded, color),
          ),
        ];
      case 'cosmic_memory': // Rocket/Clock (1-3)
        return [
          GameIntroStep(
            description: 'ركز كويس يا بطل! اللعبة دي هي اختبار لذاكرتك الحديدية وقدرتك على حفظ الأنماط.',
            illustration: _buildIllustration(Icons.psychology_rounded, color),
          ),
          GameIntroStep(
            description: 'هتظهر لك ألوان وأشكال بالترتيب، حاول تحفظهم ودوس عليهم بنفس الترتيب.',
            illustration: _buildIllustration(Icons.timer_rounded, color),
          ),
          GameIntroStep(
            description: 'كل ما تنجح، التحدي هيكبر والسرعة هتزيد.. وريني ذاكرتك هتوصل لفين!',
            illustration: _buildIllustration(Icons.speed_rounded, color),
          ),
        ];
      case 'captain_calm_v1': // Alien/Yoga (1-3)
        return [
          GameIntroStep(
            description: 'استعد للهدوء والتركيز مع القبطان! اللعبة دي هتساعدك تتحكم في مشاعرك وتكون هادي.',
            illustration: _buildIllustration(Icons.self_improvement_rounded, color),
          ),
          GameIntroStep(
            description: 'خد نفس عميق وخرجه براحة، وركز مع الكائن الفضائي وهو بيعلمك حركات الاسترخاء.',
            illustration: _buildIllustration(Icons.air_rounded, color),
          ),
          GameIntroStep(
            description: 'الهدوء قوة، والبطل الهادي بيقدر يفكر أحسن ويحل أي مشكلة بذكاء.',
            illustration: _buildIllustration(Icons.spa_rounded, color),
          ),
        ];
      default:
        return [
          GameIntroStep(
            description: 'استعد للمهمة القادمة!',
            illustration: _buildIllustration(Icons.rocket_launch_rounded, color),
          ),
        ];
    }
  }

  static Widget _buildIllustration(IconData icon, Color color) {
    return Container(
      width: 150.r,
      height: 150.r,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 80.sp,
        color: color,
      ).animate(onPlay: (c) => c.repeat())
       .shimmer(duration: 2.seconds)
       .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), curve: Curves.easeInOut, duration: 1.seconds),
    );
  }
}
