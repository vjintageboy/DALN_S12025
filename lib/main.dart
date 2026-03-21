import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'views/auth/welcome_page.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/mood_provider.dart';
import 'core/providers/chatbot_provider.dart';
import 'core/services/localization_service.dart';
import 'core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env.example (tracked in repo).
  // To use custom values, create a .env file: cp .env.example .env
  await dotenv.load(fileName: '.env.example');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moodiki',
      theme: AppTheme.lightTheme,

      // Localization configuration
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('vi'), // Vietnamese
      ],

      // Use key to force rebuild when auth status changes
      home: AuthWrapper(key: ValueKey(authProvider.status)),
    );
  }
}

// ============================================================================
// AUTH WRAPPER - Temporarily mocked
// ============================================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporarily always show OnboardingPage since Firebase Auth is removed
    return const OnboardingPage();
  }
}

// ============================================================================
// THEME CONFIGURATION
// ============================================================================
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// ============================================================================
// CONSTANTS & CONFIGURATION
// ============================================================================
// Local constants used in main.dart
class AppConstants {
  static const animationDuration = Duration(milliseconds: 600);
  static const pageTransitionDuration = Duration(milliseconds: 400);
  static const splashLogoScale = 0.35;
  static const quoteLogoSize = 80.0;
  static const horizontalPadding = 28.0;
}

// ============================================================================
// ONBOARDING PAGE WITH ENHANCED UX
// ============================================================================
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
    )..forward();

    _controller.addListener(() {
      final page = _controller.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    if (_isNavigating) return;
    _isNavigating = true;

    HapticFeedback.mediumImpact();

    if (_currentPage < 2) {
      await _controller.nextPage(
        duration: AppConstants.pageTransitionDuration,
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _fadeController.reverse();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const WelcomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: AppConstants.animationDuration,
          ),
        );
      }
    }

    _isNavigating = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: _navigateToNext,
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const SplashScreen(),
                QuoteScreen(
                  backgroundColor: AppColors.quoteBackground1,
                  quote:
                      '"Giữa mùa đông giá lạnh, tôi nhận ra bên trong mình vẫn có một mùa hè bất khuất."',
                  author: 'ALBERT CAMUS',
                ),
                QuoteScreen(
                  backgroundColor: AppColors.quoteBackground2,
                  quote:
                      '"Cảm xúc chỉ là những vị khách. Hãy để chúng đến rồi đi."',
                  author: 'MOOJI',
                ),
              ],
            ),
          ),
          // Page Indicators
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: _PageIndicators(currentPage: _currentPage),
          ),
          // Skip Button (only on quote screens)
          if (_currentPage > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: _SkipButton(onPressed: _navigateToNext),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAGE INDICATORS
// ============================================================================
class _PageIndicators extends StatelessWidget {
  final int currentPage;

  const _PageIndicators({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.white : AppColors.white70,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// SKIP BUTTON
// ============================================================================
class _SkipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SkipButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white70, width: 1),
          ),
          child: const Text(
            'Bỏ qua',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SPLASH SCREEN
// ============================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: AppColors.splashBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: size.width * AppConstants.splashLogoScale,
                          height: size.width * AppConstants.splashLogoScale,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppColors.primaryPurple,
                            AppColors.primaryPurple.withValues(alpha: 0.8),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'MOODIKI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hành trình chăm sóc cảm xúc',
                        style: TextStyle(
                          color: AppColors.primaryPurple.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// QUOTE SCREEN
// ============================================================================
class QuoteScreen extends StatefulWidget {
  final Color backgroundColor;
  final String quote;
  final String author;

  const QuoteScreen({
    super.key,
    required this.backgroundColor,
    required this.quote,
    required this.author,
  });

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.backgroundColor,
            widget.backgroundColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.horizontalPadding,
            24,
            AppConstants.horizontalPadding,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'app_logo',
                child: Container(
                  width: AppConstants.quoteLogoSize,
                  height: AppConstants.quoteLogoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.white.withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Larger, more readable quote text with subtle shadow for contrast
                          Text(
                            widget.quote,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: size.width * 0.09,
                              height: 1.6,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  offset: const Offset(0, 3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Author pill: increased padding and contrast
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '— ${widget.author}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
