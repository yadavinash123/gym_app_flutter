import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/coach_repository.dart';
import '../models/coach_conversation.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/glowing_coach_orb.dart';

class CoachHomeView extends ConsumerStatefulWidget {
  const CoachHomeView({
    super.key,
    required this.onOpenChat,
    required this.onSendPrompt,
  });

  final VoidCallback onOpenChat;
  final ValueChanged<String> onSendPrompt;

  @override
  ConsumerState<CoachHomeView> createState() => _CoachHomeViewState();
}

class _CoachHomeViewState extends ConsumerState<CoachHomeView> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onFeatureCardTapped(String prompt, ConversationCategory category) async {
    await ref.read(coachConversationsProvider.notifier).createConversation(
      title: prompt.length > 28 ? '${prompt.substring(0, 28)}...' : prompt,
      category: category,
      initialPrompt: prompt,
    );
    widget.onSendPrompt(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(coachConversationsProvider);
    final activeId = ref.watch(activeConversationIdProvider);

    String lastChatTitle = 'My 5-Day Muscle Building Plan';
    if (conversationsAsync.hasValue && conversationsAsync.value!.isNotEmpty) {
      final active = conversationsAsync.value!.firstWhere(
        (c) => c.id == activeId,
        orElse: () => conversationsAsync.value!.first,
      );
      lastChatTitle = active.title;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: "FitForge" + Notification Bell
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FitForge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Chat History',
                        icon: const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => context.push('/coach/history'),
                      ),
                      IconButton(
                        tooltip: 'AI Coach Settings',
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => context.push('/coach/settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content Area (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Hero Glowing Orb
                    GlowingCoachOrb(
                      statusText: 'AI Coach • Ready',
                      isOnline: true,
                      onTap: widget.onOpenChat,
                    ),

                    const SizedBox(height: 20),

                    // Hero Greeting Headline
                    const Text(
                      'Hey! Ready to\ncrush your goals?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Your personal AI coach for training,\nnutrition & recovery.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA7B0BF),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4 Quick Action Cards (2x2 Grid)
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: 'Build My\nWorkout',
                            icon: Icons.fitness_center_rounded,
                            iconColor: const Color(0xFFB6FF3B),
                            bgColor: const Color(0xFF192518),
                            onTap: () => _onFeatureCardTapped(
                              'Can you create a 4-day upper lower workout plan for muscle gain?',
                              ConversationCategory.workout,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            title: 'Analyze\nMy Nutrition',
                            icon: Icons.restaurant_rounded,
                            iconColor: const Color(0xFF00D4FF),
                            bgColor: const Color(0xFF102430),
                            onTap: () => _onFeatureCardTapped(
                              'Analyze my daily nutrition and macros against my goals',
                              ConversationCategory.nutrition,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: 'Recovery\nAdvice',
                            icon: Icons.eco_rounded,
                            iconColor: const Color(0xFFC084FC),
                            bgColor: const Color(0xFF261935),
                            onTap: () => _onFeatureCardTapped(
                              'Give me recovery and sleep advice based on my metrics',
                              ConversationCategory.recovery,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            title: 'Ask\nFitness AI',
                            icon: Icons.chat_bubble_rounded,
                            iconColor: const Color(0xFF2DD4BF),
                            bgColor: const Color(0xFF11292B),
                            onTap: () => _onFeatureCardTapped(
                              'What should I focus on in the gym today?',
                              ConversationCategory.advice,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Continue Last Chat Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: widget.onOpenChat,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C2430),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white12,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.schedule_rounded,
                                    color: Color(0xFFB6FF3B),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Continue Last Chat',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        lastChatTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFA7B0BF),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white54,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Input Bar
            ChatInputBar(
              controller: _inputController,
              onSend: (text) {
                _inputController.clear();
                widget.onSendPrompt(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
