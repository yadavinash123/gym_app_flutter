import 'package:flutter/material.dart';

import '../../models/milestone_badge.dart';

class MilestoneGrid extends StatelessWidget {
  const MilestoneGrid({
    super.key,
    required this.milestones,
  });

  final List<MilestoneBadge> milestones;

  @override
  Widget build(BuildContext context) {
    final unlockedCount = milestones.where((m) => m.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MILESTONES & ACHIEVEMENTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Color(0xFFA7B0BF),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB6FF3B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFB6FF3B).withOpacity(0.3),
                ),
              ),
              child: Text(
                '$unlockedCount / ${milestones.length} Unlocked',
                style: const TextStyle(
                  color: Color(0xFFB6FF3B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemCount: milestones.length,
          itemBuilder: (context, index) {
            final milestone = milestones[index];
            return _buildMilestoneTile(context, milestone);
          },
        ),
      ],
    );
  }

  Widget _buildMilestoneTile(BuildContext context, MilestoneBadge badge) {
    final isUnlocked = badge.isUnlocked;
    final primaryColor = isUnlocked ? const Color(0xFFB6FF3B) : const Color(0xFFA7B0BF);

    return InkWell(
      onTap: () => _showBadgeDetailSheet(context, badge),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151B23),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFFB6FF3B).withOpacity(0.35)
                : Colors.white.withOpacity(0.06),
            width: isUnlocked ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFFB6FF3B).withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    badge.iconData,
                    size: 20,
                    color: primaryColor,
                  ),
                ),
                Icon(
                  isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                  size: 16,
                  color: isUnlocked ? const Color(0xFFB6FF3B) : const Color(0xFFA7B0BF).withOpacity(0.5),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : const Color(0xFFA7B0BF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFFA7B0BF).withOpacity(0.8),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: badge.progressPercentage,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUnlocked ? const Color(0xFFB6FF3B) : const Color(0xFF00D4FF),
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUnlocked
                      ? 'Completed'
                      : '${badge.currentValue.toStringAsFixed(0)} / ${badge.targetValue.toStringAsFixed(0)} ${badge.unit}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked
                        ? const Color(0xFFB6FF3B)
                        : const Color(0xFFA7B0BF).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetailSheet(BuildContext context, MilestoneBadge badge) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: badge.isUnlocked
                            ? const Color(0xFFB6FF3B).withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: badge.isUnlocked
                              ? const Color(0xFFB6FF3B)
                              : Colors.white12,
                        ),
                      ),
                      child: Icon(
                        badge.iconData,
                        size: 28,
                        color: badge.isUnlocked
                            ? const Color(0xFFB6FF3B)
                            : const Color(0xFFA7B0BF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            badge.category.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF00D4FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  badge.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA7B0BF),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2430),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(fontSize: 13, color: Color(0xFFA7B0BF)),
                          ),
                          Text(
                            badge.isUnlocked ? 'Unlocked' : 'In Progress',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: badge.isUnlocked
                                  ? const Color(0xFFB6FF3B)
                                  : const Color(0xFF00D4FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress',
                            style: TextStyle(fontSize: 13, color: Color(0xFFA7B0BF)),
                          ),
                          Text(
                            '${badge.currentValue.toStringAsFixed(0)} / ${badge.targetValue.toStringAsFixed(0)} ${badge.unit}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (badge.unlockedAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Achieved Date',
                              style: TextStyle(fontSize: 13, color: Color(0xFFA7B0BF)),
                            ),
                            Text(
                              badge.unlockedAt!.toIso8601String().substring(0, 10),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB6FF3B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
