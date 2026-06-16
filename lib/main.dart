import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  final prefs = await SharedPreferences.getInstance();
  final bool showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: CekLabelApp(showOnboarding: showOnboarding),
    ),
  );
}

class CekLabelApp extends StatelessWidget {
  final bool showOnboarding;
  const CekLabelApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'CekLabel',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.mode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F4F7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4ECDC4),
          secondary: Color(0xFF44A08D),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Color(0xFF1A1A2E),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4ECDC4),
          secondary: Color(0xFF44A08D),
          surface: Color(0xFF1A1A2E),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0F),
          elevation: 0,
        ),
      ),
      builder: (context, child) {
        // Update system UI when theme changes
        final brightness = Theme.of(context).brightness;
        ThemeProvider.updateSystemUI(brightness);
        return child!;
      },
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
