import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/coach_repository.dart';
import '../models/coach_conversation.dart';
import 'widgets/conversation_card.dart';

class CoachHistoryScreen extends ConsumerStatefulWidget {
  const CoachHistoryScreen({
    super.key,
    this.onSelectConversation,
  });

  final ValueChanged<String>? onSelectConversation;

  @override
  ConsumerState<CoachHistoryScreen> createState() => _CoachHistoryScreenState();
}

class _CoachHistoryScreenState extends ConsumerState<CoachHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startNewChat() async {
    final id = await ref.read(coachConversationsProvider.notifier).createConversation(
      title: 'New Conversation',
      category: ConversationCategory.workout,
    );
    if (!mounted) return;
    if (widget.onSelectConversation != null) {
      widget.onSelectConversation!(id);
    }
    Navigator.of(context).pop(id);
  }

  void _selectChat(String id) {
    ref.read(activeConversationIdProvider.notifier).setActive(id);
    if (widget.onSelectConversation != null) {
      widget.onSelectConversation!(id);
    }
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(coachConversationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Your Conversations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: conversationsAsync.when(
        data: (allConversations) {
          final filtered = _searchQuery.isEmpty
              ? allConversations
              : allConversations.where((c) {
                  return c.title.toLowerCase().contains(_searchQuery) ||
                      c.lastMessageSnippet.toLowerCase().contains(_searchQuery);
                }).toList();

          final todayList = filtered.where((c) => c.isToday).toList();
          final yesterdayList = filtered.where((c) => c.isYesterday).toList();
          final prev7DaysList = filtered.where((c) => c.isPrevious7Days).toList();
          final olderList = filtered.where((c) => c.isOlder).toList();

          return Column(
            children: [
              // Search & + New Chat Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF151C24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF8B949E),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: const InputDecoration(
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  hintText: 'Search conversations...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // + New Chat Lime Pill Button
                    GestureDetector(
                      onTap: _startNewChat,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB6FF3B),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB6FF3B).withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'New Chat',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Grouped Section List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No conversations yet'
                                  : 'No conversations matching "$_searchQuery"',
                              style: const TextStyle(
                                color: Color(0xFFA7B0BF),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: [
                          if (todayList.isNotEmpty) ...[
                            _buildSectionHeader('Today'),
                            ...todayList.map((c) => ConversationCard(
                                  conversation: c,
                                  onTap: () => _selectChat(c.id),
                                  onDelete: () => ref
                                      .read(coachConversationsProvider.notifier)
                                      .deleteConversation(c.id),
                                  onRename: (title) => ref
                                      .read(coachConversationsProvider.notifier)
                                      .renameConversation(c.id, title),
                                )),
                          ],
                          if (yesterdayList.isNotEmpty) ...[
                            _buildSectionHeader('Yesterday'),
                            ...yesterdayList.map((c) => ConversationCard(
                                  conversation: c,
                                  onTap: () => _selectChat(c.id),
                                  onDelete: () => ref
                                      .read(coachConversationsProvider.notifier)
                                      .deleteConversation(c.id),
                                  onRename: (title) => ref
                                      .read(coachConversationsProvider.notifier)
                                      .renameConversation(c.id, title),
                                )),
                          ],
                          if (prev7DaysList.isNotEmpty) ...[
                            _buildSectionHeader('Previous 7 Days'),
                            ...prev7DaysList.map((c) => ConversationCard(
                                  conversation: c,
                                  onTap: () => _selectChat(c.id),
                                  onDelete: () => ref
                                      .read(coachConversationsProvider.notifier)
                                      .deleteConversation(c.id),
                                  onRename: (title) => ref
                                      .read(coachConversationsProvider.notifier)
                                      .renameConversation(c.id, title),
                                )),
                          ],
                          if (olderList.isNotEmpty) ...[
                            _buildSectionHeader('Older'),
                            ...olderList.map((c) => ConversationCard(
                                  conversation: c,
                                  onTap: () => _selectChat(c.id),
                                  onDelete: () => ref
                                      .read(coachConversationsProvider.notifier)
                                      .deleteConversation(c.id),
                                  onRename: (title) => ref
                                      .read(coachConversationsProvider.notifier)
                                      .renameConversation(c.id, title),
                                )),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFB6FF3B)),
        ),
        error: (err, _) => Center(
          child: Text(
            'Failed to load conversations: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
