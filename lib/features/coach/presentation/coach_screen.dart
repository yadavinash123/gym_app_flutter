import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/coach_repository.dart';
import 'coach_conversation_view.dart';
import 'coach_home_view.dart';

enum CoachViewMode {
  home,
  conversation,
}

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({
    super.key,
    this.initialViewMode = CoachViewMode.home,
  });

  final CoachViewMode initialViewMode;

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  late CoachViewMode _currentMode = widget.initialViewMode;
  String? _pendingPrompt;

  void _openChat([String? prompt]) {
    setState(() {
      _currentMode = CoachViewMode.conversation;
      _pendingPrompt = prompt;
    });
  }

  void _backToHome() {
    setState(() {
      _currentMode = CoachViewMode.home;
      _pendingPrompt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentMode == CoachViewMode.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentMode == CoachViewMode.conversation) {
          _backToHome();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _currentMode == CoachViewMode.home
            ? CoachHomeView(
                key: const ValueKey('CoachHomeView'),
                onOpenChat: () => _openChat(),
                onSendPrompt: (prompt) => _openChat(prompt),
              )
            : CoachConversationView(
                key: ValueKey(
                  'CoachConversationView_${ref.watch(activeConversationIdProvider)}_${_pendingPrompt ?? ""}',
                ),
                initialPrompt: _pendingPrompt,
                onBack: _backToHome,
              ),
      ),
    );
  }
}
