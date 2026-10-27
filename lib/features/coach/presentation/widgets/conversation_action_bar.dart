import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConversationActionBar extends StatefulWidget {
  const ConversationActionBar({
    super.key,
    required this.content,
    required this.onRegenerate,
    this.isLiked,
    this.onLikeChanged,
  });

  final String content;
  final VoidCallback onRegenerate;
  final bool? isLiked;
  final ValueChanged<bool?>? onLikeChanged;

  @override
  State<ConversationActionBar> createState() => _ConversationActionBarState();
}

class _ConversationActionBarState extends State<ConversationActionBar> {
  late bool? _liked = widget.isLiked;

  @override
  void didUpdateWidget(covariant ConversationActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _liked = widget.isLiked;
    }
  }

  void _toggleLike(bool like) {
    setState(() {
      if (_liked == like) {
        _liked = null;
      } else {
        _liked = like;
      }
    });
    widget.onLikeChanged?.call(_liked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _liked == true
              ? 'Thank you for your feedback!'
              : (_liked == false ? 'Feedback recorded' : 'Feedback cleared'),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy button
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Copy',
            icon: const Icon(
              Icons.copy_rounded,
              size: 15,
              color: Color(0xFFA7B0BF),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Thumbs Up
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Good response',
            icon: Icon(
              _liked == true
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              size: 15,
              color: _liked == true
                  ? const Color(0xFFB6FF3B)
                  : const Color(0xFFA7B0BF),
            ),
            onPressed: () => _toggleLike(true),
          ),
          const SizedBox(width: 8),

          // Thumbs Down
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Needs improvement',
            icon: Icon(
              _liked == false
                  ? Icons.thumb_down_alt_rounded
                  : Icons.thumb_down_alt_outlined,
              size: 15,
              color: _liked == false
                  ? Colors.redAccent
                  : const Color(0xFFA7B0BF),
            ),
            onPressed: () => _toggleLike(false),
          ),
          const SizedBox(width: 8),

          // Regenerate
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Regenerate',
            icon: const Icon(
              Icons.refresh_rounded,
              size: 16,
              color: Color(0xFFA7B0BF),
            ),
            onPressed: widget.onRegenerate,
          ),
        ],
      ),
    );
  }
}
