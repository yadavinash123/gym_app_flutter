import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/coach_repository.dart';
import '../models/ai_provider.dart';
import '../models/coach_message.dart';
import '../models/coach_persona.dart';
import 'consent_preview_dialog.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(coachMessagesProvider);
    final personaAsync = ref.watch(coachPersonaProvider);
    final credentialsAsync = ref.watch(coachCredentialsProvider);
    final consentAsync = ref.watch(coachConsentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        title: const Text(
          'AI COACH',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            tooltip: 'Inspect Prompt Payload',
            icon: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF00D4FF)),
            onPressed: () {
              final persona = personaAsync.value ?? CoachPersona.scientific;
              showDialog(
                context: context,
                builder: (_) => ConsentPreviewDialog(persona: persona),
              );
            },
          ),
          IconButton(
            tooltip: 'Coach & AI Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/coach/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Status & Persona Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF151B23),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Active Provider Badge
                Flexible(
                  child: credentialsAsync.when(
                    data: (creds) {
                      final isOnline = creds.isConfigured && creds.provider != AiProvider.offline;
                      final color = isOnline ? creds.provider.brandColor : const Color(0xFFB6FF3B);
                      return InkWell(
                        onTap: () => context.push('/coach/settings'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOnline ? creds.provider.icon : Icons.offline_bolt_outlined,
                                size: 14,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  isOnline ? creds.provider.displayName : 'Offline Coach',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),

                const SizedBox(width: 6),

                // Persona Selector Menu
                Flexible(
                  child: personaAsync.when(
                    data: (currentPersona) => PopupMenuButton<CoachPersona>(
                      tooltip: 'Change Persona',
                      color: const Color(0xFF1C2430),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      initialValue: currentPersona,
                      onSelected: (p) => ref.read(coachPersonaProvider.notifier).setPersona(p),
                      itemBuilder: (context) => CoachPersona.values.map((p) {
                        final isSelected = p == currentPersona;
                        return PopupMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Icon(p.icon, size: 18, color: isSelected ? const Color(0xFFB6FF3B) : Colors.white70),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.displayName,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFFB6FF3B) : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2430),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(currentPersona.icon, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                currentPersona.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.white),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),

          // Privacy Sub-banner (if sharing active)
          consentAsync.when(
            data: (consent) {
              final activeCount = consent.activeShareCount;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: const Color(0xFF10161E),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF00D4FF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activeCount > 0
                            ? '$activeCount privacy stream${activeCount > 1 ? "s" : ""} included in context (Zero PII)'
                            : 'All personal context redacted (Zero sharing)',
                        style: const TextStyle(fontSize: 10, color: Color(0xFFA7B0BF)),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final persona = personaAsync.value ?? CoachPersona.scientific;
                        showDialog(
                          context: context,
                          builder: (_) => ConsentPreviewDialog(persona: persona),
                        );
                      },
                      child: const Text(
                        'Inspect',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D4FF),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // 2. Chat Message List
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isSending) {
                      return _buildThinkingBubble();
                    }
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Failed to load chat history: $err', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),

          // 3. Quick Suggestion Prompt Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildPromptChip('Check today\'s macro balance'),
                  const SizedBox(width: 8),
                  _buildPromptChip('Recovery & readiness assessment'),
                  const SizedBox(width: 8),
                  _buildPromptChip('Today\'s workout recommendation'),
                  const SizedBox(width: 8),
                  _buildPromptChip('How to overload safely?'),
                  const SizedBox(width: 8),
                  _buildPromptChip('Explain Tanaka HR zones'),
                ],
              ),
            ),
          ),

          // 4. Input Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF151B23),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask your coach anything...',
                        hintStyle: const TextStyle(color: Color(0xFFA7B0BF), fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF1C2430),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFB6FF3B),
                      foregroundColor: Colors.black,
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.send, size: 20),
                    onPressed: _isSending ? null : () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return ActionChip(
      backgroundColor: const Color(0xFF1C2430),
      side: const BorderSide(color: Colors.white12),
      label: Text(
        prompt,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      onPressed: _isSending ? null : () => _sendMessage(prompt),
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
            child: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFB6FF3B)),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB6FF3B)),
                ),
                SizedBox(width: 10),
                Text(
                  'Coach is analyzing your data...',
                  style: TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(CoachMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: message.offlineGenerated
                      ? const Color(0xFFB6FF3B).withValues(alpha: 0.2)
                      : const Color(0xFF00D4FF).withValues(alpha: 0.2),
                  child: Icon(
                    message.offlineGenerated ? Icons.fitness_center : Icons.auto_awesome,
                    size: 16,
                    color: message.offlineGenerated ? const Color(0xFFB6FF3B) : const Color(0xFF00D4FF),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1C2430) : const Color(0xFF151B23),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUser
                          ? const Color(0xFFB6FF3B).withValues(alpha: 0.4)
                          : Colors.white12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header metadata on Assistant messages
                      if (!isUser) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (message.offlineGenerated
                                            ? const Color(0xFFB6FF3B)
                                            : const Color(0xFF00D4FF))
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    message.offlineGenerated
                                        ? 'Offline Engine'
                                        : (message.modelName ?? 'Online AI'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: message.offlineGenerated
                                          ? const Color(0xFFB6FF3B)
                                          : const Color(0xFF00D4FF),
                                    ),
                                  ),
                                ),
                                if (message.tokensUsed != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '${message.tokensUsed} tokens',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFFA7B0BF)),
                                  ),
                                ],
                              ],
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.copy, size: 14, color: Colors.white54),
                              tooltip: 'Copy response',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: message.content));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Message copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Message Body (Markdown formatted)
                      _renderFormattedContent(message.content, isUser),
                    ],
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 12),
            ],
          ),

          // Render follow-up suggestions chips if present
          if (!isUser && message.suggestedActions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.suggestedActions.map((action) {
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFF10161E),
                    side: const BorderSide(color: Colors.white12),
                    label: Text(
                      action,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF00D4FF)),
                    ),
                    onPressed: _isSending ? null : () => _sendMessage(action),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _renderFormattedContent(String rawText, bool isUser) {
    final lines = rawText.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.substring(4),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB6FF3B),
            ),
          ),
        ));
      } else if (line.startsWith('#### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(
            line.substring(5),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00D4FF),
            ),
          ),
        ));
      } else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        final text = line.trim().substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Color(0xFFB6FF3B), fontSize: 13)),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                ),
              ),
            ],
          ),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else {
        widgets.add(Text(
          line,
          style: TextStyle(
            fontSize: 13,
            color: isUser ? Colors.white : const Color(0xFFE6EDF3),
            height: 1.4,
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
