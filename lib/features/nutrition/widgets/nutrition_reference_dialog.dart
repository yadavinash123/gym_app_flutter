import 'package:flutter/material.dart';
import '../models/nutrition_targets.dart';

class NutritionReferenceDialog extends StatelessWidget {
  const NutritionReferenceDialog({super.key, required this.targets});

  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF151B23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.menu_book_outlined, color: Color(0xFFB6FF3B)),
          SizedBox(width: 10),
          Text(
            'Calculation Reference',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2430),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                targets.explanation,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scientific Foundations',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF00D4FF),
              ),
            ),
            const SizedBox(height: 8),
            _refItem(
              'Energy Expenditure (BMR)',
              'Mifflin et al., 1990 (AJCN). Standard formula: 10 × weight (kg) + 6.25 × height (cm) - 5 × age ± sex coefficient.',
            ),
            _refItem(
              'Protein Intake',
              'Jäger et al., 2017 (ISSN Position Stand). 1.4 - 2.0 g/kg/day for active exercising individuals.',
            ),
            _refItem(
              'Hydration Baseline',
              'European Food Safety Authority (EFSA) & general sports science guidelines: ~30-35 ml per kg bodyweight.',
            ),
            _refItem(
              'Food Composition Data',
              'ICMR-NIN Indian Food Composition Tables (IFCT 2017) & USDA FoodData Central.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2214),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6B4C1B)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFFFB800), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These calculations are educational estimates, not medical prescriptions. If you have medical conditions or specific dietary requirements, follow guidance from a qualified dietitian or healthcare provider.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFFFE082)),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _refItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
          ),
        ],
      ),
    );
  }
}
