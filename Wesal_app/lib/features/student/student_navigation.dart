import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_game_state.dart';
import 'utils/student_responsive.dart';
import 'widgets/student_space_scaffold.dart';

/// Pushes a route that keeps access to the same [StudentGameState] instance.
void pushWithStudentGameState(BuildContext context, Widget child, {bool wrapSafeRoute = false}) {
  final gameState = context.read<StudentGameState>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentResponsiveScope(
        child: ChangeNotifierProvider<StudentGameState>.value(
          value: gameState,
          child: wrapSafeRoute ? StudentRouteShell(child: child) : child,
        ),
      ),
    ),
  );
}
