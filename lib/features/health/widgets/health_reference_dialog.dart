import 'package:flutter/material.dart';

class HealthReferenceDialog extends StatelessWidget {
  const HealthReferenceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF151B23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFB6FF3B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: Color(0xFFB6FF3B),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Health & Activity References',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(
                context,
                title: 'Tanaka Age-Predicted HRmax',
                formula: 'HRmax = 208 − (0.7 × Age)',
                citation: 'Tanaka H, Monahan KD, Seals DR. (2001). "Age-predicted maximal heart rate revisited." Journal of the American College of Cardiology, 37(1), 153–156. DOI: 10.1016/S0735-1097(00)01054-8.',
                description: 'Replaces the traditional "220 − age" equation with a meta-analytically validated formula across 351 studies and 18,712 subjects. Used to establish physiological training zones 1–5.',
              ),
              const Divider(color: Color(0xFF1C2430), height: 24),
              _section(
                context,
                title: 'Daily Steps & Activity Recommendations',
                formula: 'WHO Standard: 7,500–10,000 steps/day',
                citation: 'World Health Organization (2020). "WHO Guidelines on physical activity and sedentary behaviour." British Journal of Sports Medicine, 54(24), 1451–1462.',
                description: 'Ambulatory movement protects against cardiovascular disease, all-cause mortality, and metabolic slowdown. Step targets provide training context without double-counting resistance exercise.',
              ),
              const Divider(color: Color(0xFF1C2430), height: 24),
              _section(
                context,
                title: 'Adult Sleep Duration & Quality',
                formula: 'Recommended: 7–9 hours/night',
                citation: 'Hirshkowitz M, et al. (2015). "National Sleep Foundation’s sleep time duration recommendations." Sleep Health, 1(1), 40–43.',
                description: 'Slow-wave deep sleep and REM phases stimulate growth hormone release, glycogen replenishment, and neuromuscular tissue repair essential for progressive athletic overload.',
              ),
              const Divider(color: Color(0xFF1C2430), height: 24),
              _section(
                context,
                title: 'Source Attribution & Privacy Guarantee',
                formula: '100% Private On-Device JSON Storage',
                citation: 'FitForge AI Data Protection Standard',
                description: 'All synchronized metrics (steps, heart rate, sleep, active energy) remain strictly sandboxed in private application storage. Every reading displays its authentic origin badge. FitForge never transmits health data to external cloud servers.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String formula,
    required String citation,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0F14),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF1C2430)),
          ),
          child: Text(
            formula,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Color(0xFFB6FF3B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
        ),
        const SizedBox(height: 4),
        Text(
          citation,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
