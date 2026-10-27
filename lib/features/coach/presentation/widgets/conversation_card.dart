import 'package:flutter/material.dart';

import '../../models/coach_conversation.dart';

class ConversationCard extends StatelessWidget {
  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  final CoachConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: conversation.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151B23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rename Conversation',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1C2430),
            hintText: 'Conversation title',
            hintStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB6FF3B),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                onRename(newTitle);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = conversation.category;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141A22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Squircle Category Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: category.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.iconColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      category.icon,
                      color: category.iconColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            conversation.timeFormatted,
                            style: const TextStyle(
                              color: Color(0xFF8B949E),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessageSnippet.isNotEmpty
                            ? conversation.lastMessageSnippet
                            : 'No messages yet',
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

                const SizedBox(width: 4),

                // 3-dots Menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF6E7681),
                    size: 18,
                  ),
                  color: const Color(0xFF1C2430),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val == 'rename') {
                      _showRenameDialog(context);
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Colors.white70,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Rename',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
