import 'package:flutter/material.dart';
import '../utils/student_responsive.dart';

/// Dark space scaffold with correct safe areas for all phone sizes.
class StudentSpaceScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final Color backgroundColor;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const StudentSpaceScaffold({
    super.key,
    this.scaffoldKey,
    required this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.extendBody = true,
    this.backgroundColor = const Color(0xFF03001C),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      drawer: drawer,
      appBar: appBar,
      body: SafeArea(
        top: true,
        bottom: bottomNavigationBar == null,
        left: true,
        right: true,
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Wraps pushed student routes (profile, chatbot, games) for consistent insets.
class StudentRouteShell extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const StudentRouteShell({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? const Color(0xFF03001C),
      child: SafeArea(
        child: child,
      ),
    );
  }
}

/// Bottom padding for scroll views above student bottom nav.
SliverToBoxAdapter studentScrollBottomSpacer(BuildContext context) {
  return SliverToBoxAdapter(
    child: SizedBox(height: StudentResponsive.scrollBottomPadding(context)),
  );
}
