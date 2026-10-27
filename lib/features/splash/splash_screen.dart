import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../profile/profile_repository.dart';
import '../../shared/widgets/page_body.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _checkAndNavigate(AsyncValue profile) {
    if (_navigated) return;
    if (profile.hasValue) {
      _navigated = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        final target = profile.value == null ? '/onboarding' : '/home';
        context.go(target);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (profile.hasValue && !_navigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndNavigate(profile);
      });
    }

    if (profile.hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F14),
        body: PageBody(
          children: [
            const SizedBox(height: 60),
            const InfoCard(
              title: 'Unable to open your profile',
              message: 'Existing data has been preserved. Please retry.',
              icon: Icons.error_outline,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                _navigated = false;
                ref.invalidate(profileProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon Branding with Glowing Border
                  Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      color: const Color(0xFF151B23),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.6),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/branding/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.fitness_center_rounded,
                        size: 64,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // App Title
                  const Text(
                    'FITFORGE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tagline with neon accent
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 2,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI FITNESS & PHYSIQUE ENGINE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 16,
                          height: 2,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Sleek subtle loading indicator
                  SizedBox(
                    width: 48,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        backgroundColor: const Color(0xFF1C2430),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
