import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'features/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://xbpwsdpswcxhogzaalqn.supabase.co',
    anonKey: 'sb_publishable_R_8ep0PEq7BerXCGbeG68Q_223uP3Ox',
  );

  // Load preferences before running the app to eliminate startup race conditions!
  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('app_lang') ?? 'ar';
  final theme = prefs.getString('app_theme') ?? 'light';

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(WeCircleApp(initialLang: lang, initialTheme: theme));
}

class WeCircleApp extends StatefulWidget {
  final String initialLang;
  final String initialTheme;

  const WeCircleApp({
    super.key,
    required this.initialLang,
    required this.initialTheme,
  });

  static void setLocale(BuildContext context, Locale newLocale) {
    _WeCircleAppState? state = context.findAncestorStateOfType<_WeCircleAppState>();
    state?.setLocale(newLocale);
  }

  static void setThemeMode(BuildContext context, ThemeMode newThemeMode) {
    _WeCircleAppState? state = context.findAncestorStateOfType<_WeCircleAppState>();
    state?.setThemeMode(newThemeMode);
  }

  static Locale getLocale(BuildContext context) {
    _WeCircleAppState? state = context.findAncestorStateOfType<_WeCircleAppState>();
    return state?._locale ?? const Locale('ar');
  }

  static ThemeMode getThemeMode(BuildContext context) {
    _WeCircleAppState? state = context.findAncestorStateOfType<_WeCircleAppState>();
    return state?._themeMode ?? ThemeMode.light;
  }

  @override
  State<WeCircleApp> createState() => _WeCircleAppState();
}

class _WeCircleAppState extends State<WeCircleApp> {
  late Locale _locale;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    // Initialize synchronously with cached values to prevent flash of default locale
    _locale = Locale(widget.initialLang);
    if (widget.initialTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (widget.initialTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', locale.languageCode);
  }

  void setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'WeCircle',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          locale: _locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: _locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: AppBackgroundScope(
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          onGenerateRoute: (settings) {
            // Ignore Supabase deep link route so it doesn't crash the navigator
            if (settings.name != null && settings.name!.contains('login-callback')) {
              // We return a route that immediately pops itself so the user stays on the login screen
              return PageRouteBuilder(
                pageBuilder: (context, _, __) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  });
                  return const SizedBox.shrink();
                },
                opaque: false,
                transitionDuration: Duration.zero,
              );
            }
            return null;
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
