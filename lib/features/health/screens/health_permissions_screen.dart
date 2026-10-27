import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/health_repository.dart';
import '../models/health_permission.dart';

class HealthPermissionsScreen extends ConsumerWidget {
  const HealthPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(healthPermissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Health Permissions & Privacy')),
      body: permissionsAsync.when(
        loading: () => const Center(child: Text('Loading permissions...')),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Unable to load permissions: $err'),
              TextButton(
                onPressed: () => ref.invalidate(healthPermissionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (permissions) {
          final grantedCount = permissions.where((p) => p.isGranted).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151B23),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1C2430)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4FF)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Color(0xFF00D4FF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Data Stays On Your Phone',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$grantedCount of ${permissions.length} metrics permitted',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFA7B0BF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'FitForge requests access only to contextualize recovery, cardio readiness, and energy expenditure. Data is read on-demand and stored exclusively in private local JSON files.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA7B0BF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB6FF3B),
                                side: const BorderSide(
                                  color: Color(0xFFB6FF3B),
                                ),
                              ),
                              onPressed: () => ref
                                  .read(healthPermissionsProvider.notifier)
                                  .grantAll(),
                              child: const Text('Grant All'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                              ),
                              onPressed: () => ref
                                  .read(healthPermissionsProvider.notifier)
                                  .revokeAll(),
                              child: const Text('Revoke All'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Granular Metric Permissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ...permissions.map((perm) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151B23),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1C2430)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: perm.metric.color.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                perm.metric.icon,
                                color: perm.metric.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    perm.metric.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    perm.mode == HealthAccessMode.readWrite
                                        ? 'Read & Write'
                                        : 'Read Only',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFA7B0BF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: perm.isGranted,
                              activeThumbColor: const Color(0xFFB6FF3B),
                              onChanged: (enabled) {
                                ref
                                    .read(healthPermissionsProvider.notifier)
                                    .setPermission(
                                      perm.metric,
                                      enabled
                                          ? HealthPermissionStatus.granted
                                          : HealthPermissionStatus.denied,
                                    );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          perm.metric.justification,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA7B0BF),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
