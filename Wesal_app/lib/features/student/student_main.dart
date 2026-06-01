import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_game_state.dart';
import 'screens/student_welcome_choice_screen.dart';
import 'space/screens/student1-3/student_dashboard.dart';
import 'space/screens/student4-6/student_dashboard_group_b.dart';
import 'space/screens/student_shared/student_chatbot_screen.dart';
import 'space/state_manager.dart';
import 'screens/student_profile_screen.dart';
import 'student_navigation.dart';
import 'utils/student_responsive.dart';

class StudentMain extends StatelessWidget {
  const StudentMain({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentGameState(),
      child: const StudentResponsiveScope(
        child: _StudentMainGate(),
      ),
    );
  }
}

class _StudentMainGate extends StatefulWidget {
  const _StudentMainGate();

  @override
  State<_StudentMainGate> createState() => _StudentMainGateState();
}

class _StudentMainGateState extends State<_StudentMainGate> {
  /// null = show welcome; otherwise show dashboard tab or overlay routes handle chat/profile.
  StudentEntryIntent? _intent;

  void _onWelcomeChoice(StudentEntryIntent intent) {
    if (intent == StudentEntryIntent.chatbot) {
      final isGroupB = AppStateManager().selectedGradeLevel.value == '4-6';
      pushWithStudentGameState(context, StudentChatbotScreen(isGroupB: isGroupB));
      return;
    }
    if (intent == StudentEntryIntent.profile) {
      pushWithStudentGameState(context, const StudentProfileScreen());
      return;
    }
    setState(() => _intent = intent);
  }

  @override
  Widget build(BuildContext context) {
    if (_intent == null) {
      return StudentWelcomeChoiceScreen(onChoice: _onWelcomeChoice);
    }

    final initialTab = _intent == StudentEntryIntent.tasks ? 1 : 0;
    return StudentSpaceRouter(initialTab: initialTab);
  }
}

/// Resolves grade band dashboard (1-3 vs 4-6) after welcome flow.
class StudentSpaceRouter extends StatelessWidget {
  final int initialTab;
  const StudentSpaceRouter({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppStateManager().selectedGradeLevel,
      builder: (context, band, _) {
        if (band == '4-6') {
          return StudentDashboardGroupBScreen(initialTab: initialTab);
        }
        return StudentDashboardScreen(initialTab: initialTab);
      },
    );
  }
}
