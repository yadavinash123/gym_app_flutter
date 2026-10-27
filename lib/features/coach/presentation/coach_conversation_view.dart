import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/coach_repository.dart';
import '../models/ai_provider.dart';
import '../models/coach_message.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/conversation_action_bar.dart';
import 'widgets/formatted_coach_text.dart';
import 'widgets/workout_plan_card.dart';

class CoachConversationView extends ConsumerStatefulWidget {
  const CoachConversationView({
    super.key,
    required this.onBack,
    this.initialPrompt,
  });

  final VoidCallback onBack;
  final String? initialPrompt;

  @override
  ConsumerState<CoachConversationView> createState() =>
      _CoachConversationViewState();
}

class _CoachConversationViewState extends ConsumerState<CoachConversationView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialPrompt);
      });
    }
  }

  @override
  void didUpdateWidget(covariant CoachConversationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPrompt != null &&
        widget.initialPrompt!.isNotEmpty &&
        widget.initialPrompt != oldWidget.initialPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialPrompt);
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (presetText == null) {
      _inputController.clear();
    }

    setState(() => _isSending = true);
    _scrollToBottom();

    final persona = await ref.read(coachPersonaProvider.future);
    await ref.read(coachMessagesProvider.notifier).send(text, persona);

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _openHistory() async {
    final selectedId = await context.push<String>('/coach/history');
    if (selectedId != null && mounted) {
      _scrollToBottom();
    }
  }

  void _openSettings() {
    context.push('/coach/settings');
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(coachMessagesProvider);
    final credentialsAsync = ref.watch(coachCredentialsProvider);

    final isOnline =
        credentialsAsync.value?.isConfigured == true &&
        credentialsAsync.value?.provider != AiProvider.offline;

    // Determine current suggested prompt chips
    List<String> promptChips = const [
      'Show Day 2',
      'Add rest times',
      'Make it home gym',
    ];
    if (messagesAsync.hasValue && messagesAsync.value!.isNotEmpty) {
      final lastAssistant = messagesAsync.value!.lastWhere(
        (m) => m.isAssistant,
        orElse: () => messagesAsync.value!.last,
      );
      if (lastAssistant.suggestedActions.isNotEmpty) {
        promptChips = lastAssistant.suggestedActions;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: widget.onBack,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Circular Avatar with dumbbell icon + green glowing ring
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Color(0xFF00D4FF),
                    Color(0xFFB6FF3B),
                    Color(0xFF00D4FF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB6FF3B).withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0B0F14),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFFB6FF3B),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Title & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'FitForge AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AI Coach • ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFFB6FF3B)
                                : const Color(0xFF00D4FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Online' : 'Ready',
                          style: TextStyle(
                            color: isOnline
                                ? const Color(0xFFB6FF3B)
                                : const Color(0xFF00D4FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Conversations History',
            icon: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: _openHistory,
          ),
          IconButton(
            tooltip: 'AI Coach Settings',
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 22,
            ),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isSending) {
                      return _buildThinkingBubble();
                    }
                    final msg = messages[index];
                    return _buildMessageItem(msg);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFB6FF3B)),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading chat: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),

          // Suggested Prompts Row (Horizontal Scroll)
          if (promptChips.isNotEmpty)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: promptChips.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final prompt = promptChips[idx];
                  return ActionChip(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    backgroundColor: const Color(0xFF151C24),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    label: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: _isSending ? null : () => _sendMessage(prompt),
                  );
                },
              ),
            ),

          // Bottom Input Bar
          ChatInputBar(
            controller: _inputController,
            isSending: _isSending,
            onSend: (text) => _sendMessage(text),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFB6FF3B).withValues(alpha: 0.2),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Color(0xFFB6FF3B),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF151B23),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFB6FF3B),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Coach is analyzing your workout & data...',
                  style: TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(CoachMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.86,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFFB6FF3B) // Lime green bubble for user
                        : const Color(0xFF141A22), // Dark slate for AI
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    border: Border.all(
                      color: isUser
                          ? const Color(0xFFB6FF3B)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFFB6FF3B).withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formatted Text Content (Markdown + Clean Bullet Syntax)
                      FormattedCoachText(text: message.content, isUser: isUser),

                      // User Message Timestamp & Done Checkmark
                      if (isUser) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 14,
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ],

                      // Embedded Structured Workout Plan Card
                      if (message.workoutPlan != null)
                        WorkoutPlanCard(data: message.workoutPlan!),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Action toolbar for assistant messages (Copy, Like, Dislike, Regenerate)
          if (!isUser)
            ConversationActionBar(
              content: message.content,
              isLiked: message.isLiked,
              onLikeChanged: (liked) => ref
                  .read(coachMessagesProvider.notifier)
                  .toggleLike(message.id, liked),
              onRegenerate: () => _sendMessage(message.content),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$minute $period';
  }
}
