import 'package:flutter/material.dart';

class FormattedCoachText extends StatelessWidget {
  const FormattedCoachText({
    super.key,
    required this.text,
    this.isUser = false,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // 1. Clean up reasoning blocks and weird bullet combinations like "*- " or "* - "
    var cleanText = text
        .replaceAll(
          RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'</?think>', caseSensitive: false), '')
        .trim();

    final lines = cleanText.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i].trim();

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Clean ugly bullet syntax: "*- ", "* - ", "*•", "•- ", "**- ", "**• ", "** - "
      line = line
          .replaceAll(RegExp(r'^\s*[*•\-]+\s*[-•*]\s*'), '• ')
          .replaceAll(RegExp(r'^\s*[*]{1,2}\s*[-•]\s*'), '• ')
          .replaceAll(RegExp(r'^\s*[-•]\s*[*]{1,2}\s*'), '• ')
          .replaceAll(RegExp(r'^\s*[*]\s+'), '• ')
          .replaceAll(RegExp(r'^\s*[-]\\s+'), '• ');

      // Skip stray single or double asterisks / bullet markers
      if (line == '•' ||
          line == '-' ||
          line == '*' ||
          line == '• ' ||
          line == '**' ||
          line == '***' ||
          line == '• **' ||
          line == '** •' ||
          line == '****') {
        continue;
      }

      // Skip markdown table dividers (e.g. |---|---| or |---------|)
      if (RegExp(r'^\|[\s\-:|]+\|$').hasMatch(line) ||
          RegExp(r'^\|-+\|$').hasMatch(line) ||
          RegExp(r'^[|\s\-:]{3,}$').hasMatch(line)) {
        continue;
      }

      // Convert Markdown Table rows into clean ChatGPT-style bullet points
      if (line.startsWith('|') && line.endsWith('|')) {
        final cells = line
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty && !c.contains('---'))
            .toList();

        if (cells.isEmpty) continue;

        // Skip generic table header rows
        final firstLower = cells.first.toLowerCase();
        if (cells.length > 1 &&
            (firstLower == 'action' ||
                firstLower == 'zone' ||
                firstLower == 'metric' ||
                firstLower == 'parameter' ||
                firstLower == 'item' ||
                firstLower == 'nutrient')) {
          continue;
        }

        // Format row cleanly as a bullet item without messy asterisks
        final cleanFirst = cells.first
            .replaceAll('**', '')
            .replaceAll('*', '')
            .trim();
        final rest = cells.sublist(1).join(' • ').replaceAll('**', '').trim();
        final bulletContent = cells.length == 1
            ? cleanFirst
            : '**$cleanFirst:** $rest';

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child: Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFFB6FF3B),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _parseInlineSpans(
                        bulletContent,
                        const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFFE6EDF3),
                          height: 1.4,
                        ),
                        boldColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Check for Headers (#, ##, ###) - clean ** completely since header is already bold
      if (line.startsWith('#')) {
        int hashCount = 0;
        while (hashCount < line.length && line[hashCount] == '#') {
          hashCount++;
        }
        final headerText = line
            .substring(hashCount)
            .trim()
            .replaceAll('**', '')
            .replaceAll('*', '');
        final fontSize = hashCount == 1 ? 16.0 : (hashCount == 2 ? 15.0 : 13.5);
        final color = hashCount <= 2
            ? const Color(0xFFB6FF3B)
            : const Color(0xFF00D4FF);

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              headerText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
        continue;
      }

      // Check for Bullet points (starts with '• ')
      if (line.startsWith('• ') || line.startsWith('•')) {
        final content = line.startsWith('• ')
            ? line.substring(2).trim()
            : line.substring(1).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child: Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFFB6FF3B),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _parseInlineSpans(
                        content,
                        const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFFE6EDF3),
                          height: 1.4,
                        ),
                        boldColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Check for Numbered items: 1. or 2.
      final numberMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
      if (numberMatch != null) {
        final numStr = numberMatch.group(1)!;
        final content = numberMatch.group(2)!;
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '$numStr.',
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _parseInlineSpans(
                        content,
                        const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFFE6EDF3),
                          height: 1.4,
                        ),
                        boldColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular paragraph line with full bold/italic/code parsing
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(
            TextSpan(
              children: _parseInlineSpans(
                line,
                const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFFE6EDF3),
                  height: 1.4,
                ),
                boldColor: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  static String _fixUnclosedBold(String input) {
    var result = input;
    final count = '**'.allMatches(result).length;
    if (count % 2 != 0) {
      // If text starts with ** and has no matching closing **, close it before colon or at end
      if (result.startsWith('**')) {
        final colonIdx = result.indexOf(':');
        if (colonIdx != -1) {
          result =
              '${result.substring(0, colonIdx)}**${result.substring(colonIdx)}';
        } else {
          result = '$result**';
        }
      } else {
        // Stray single **, remove it
        result = result.replaceAll('**', '');
      }
    }
    return result;
  }

  static List<InlineSpan> _parseInlineSpans(
    String text,
    TextStyle baseStyle, {
    Color? boldColor,
  }) {
    final fixedText = _fixUnclosedBold(text);
    final spans = <InlineSpan>[];
    // Pattern matches: **bold**, *italic*, `code`
    final pattern = RegExp(r'(\*\*(.+?)\*\*)|(\*(.+?)\*)|(`(.+?)`)');
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(fixedText)) {
      if (match.start > lastMatchEnd) {
        final raw = fixedText
            .substring(lastMatchEnd, match.start)
            .replaceAll('**', '');
        if (raw.isNotEmpty) {
          spans.add(TextSpan(text: raw, style: baseStyle));
        }
      }

      if (match.group(2) != null) {
        // Bold: **text** - remove ** completely and display clean bold text
        final boldContent = match.group(2)!.replaceAll('**', '').trim();
        spans.add(
          TextSpan(
            text: boldContent,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: boldColor ?? Colors.white,
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // Italic: *text*
        final italicContent = match.group(4)!.replaceAll('*', '').trim();
        spans.add(
          TextSpan(
            text: italicContent,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(6) != null) {
        // Code: `text`
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2836),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                match.group(6)!,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF00D4FF),
                ),
              ),
            ),
          ),
        );
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < fixedText.length) {
      final raw = fixedText.substring(lastMatchEnd).replaceAll('**', '');
      if (raw.isNotEmpty) {
        spans.add(TextSpan(text: raw, style: baseStyle));
      }
    }

    return spans;
  }
}
