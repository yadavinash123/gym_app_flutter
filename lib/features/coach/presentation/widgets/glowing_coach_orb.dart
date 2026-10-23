import 'package:flutter/material.dart';

class GlowingCoachOrb extends StatefulWidget {
  const GlowingCoachOrb({
    super.key,
    this.statusText = 'AI Coach • Ready',
    this.isOnline = true,
    this.onTap,
  });

  final String statusText;
  final bool isOnline;
  final VoidCallback? onTap;

  @override
  State<GlowingCoachOrb> createState() => _GlowingCoachOrbState();
}

class _GlowingCoachOrbState extends State<GlowingCoachOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00D4FF).withValues(alpha: 0.28),
                    const Color(0xFFB6FF3B).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.4, 0.75, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB6FF3B).withValues(alpha: 0.2),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFF00D4FF),
                        Color(0xFFB6FF3B),
                        Color(0xFF00E5FF),
                        Color(0xFFB6FF3B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB6FF3B).withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3), // Border thickness
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B1015),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: Color(0xFF00D4FF),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Status Badge Pill: "🟢 AI Coach • Ready"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF151C24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFB6FF3B).withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB6FF3B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB6FF3B).withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
