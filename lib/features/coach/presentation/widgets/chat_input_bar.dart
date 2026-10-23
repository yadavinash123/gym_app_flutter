import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isSending = false,
    this.placeholder = 'Ask your AI coach...',
    this.onMicTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool isSending;
  final String placeholder;
  final VoidCallback? onMicTap;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.controller.clear();
    widget.onSend(text);
  }

  void _handleMicTap() {
    if (widget.onMicTap != null) {
      widget.onMicTap!();
      return;
    }
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listening... Say your fitness question!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141A22),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
          child: Row(
            children: [
              // Input TextField
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    hintText: widget.placeholder,
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Mic Button
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: _handleMicTap,
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isListening
                      ? const Color(0xFFB6FF3B)
                      : const Color(0xFFA7B0BF),
                  size: 20,
                ),
                tooltip: 'Voice input',
              ),
              const SizedBox(width: 8),

              // Neon Lime Send Button
              GestureDetector(
                onTap: widget.isSending ? null : _submit,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB6FF3B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB6FF3B).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
