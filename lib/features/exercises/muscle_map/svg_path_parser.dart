import 'dart:ui';
import 'package:flutter/material.dart';

/// A robust SVG path data parser for Flutter Path objects.
/// Supports M, m, L, l, H, h, V, v, C, c, S, s, Q, q, T, t, A, a, Z, z commands.
/// Accurately handles concatenated numbers (e.g. 10.5.6 -> 10.5, 0.6) and
/// arc command binary flag concatenation (e.g. 01-2.3 -> 0, 1, -2.3).
class SvgPathParser {
  static Path parse(String pathData) {
    final path = Path();
    if (pathData.trim().isEmpty) return path;

    final tokens = _tokenize(pathData);
    int index = 0;

    double currentX = 0;
    double currentY = 0;
    double startX = 0;
    double startY = 0;
    double lastControlX = 0;
    double lastControlY = 0;
    String lastCommand = '';

    while (index < tokens.length) {
      final token = tokens[index];
      if (_isCommand(token)) {
        lastCommand = token;
        index++;
      }

      switch (lastCommand) {
        case 'M':
          currentX = double.parse(tokens[index++]);
          currentY = double.parse(tokens[index++]);
          startX = currentX;
          startY = currentY;
          path.moveTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          lastCommand = 'L'; // subsequent coordinates are lineTo
          break;

        case 'm':
          currentX += double.parse(tokens[index++]);
          currentY += double.parse(tokens[index++]);
          startX = currentX;
          startY = currentY;
          path.moveTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          lastCommand = 'l';
          break;

        case 'L':
          currentX = double.parse(tokens[index++]);
          currentY = double.parse(tokens[index++]);
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          break;

        case 'l':
          currentX += double.parse(tokens[index++]);
          currentY += double.parse(tokens[index++]);
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          break;

        case 'H':
          currentX = double.parse(tokens[index++]);
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          break;

        case 'h':
          currentX += double.parse(tokens[index++]);
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          break;

        case 'V':
          currentY = double.parse(tokens[index++]);
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          break;

        case 'v':
          currentY += double.parse(tokens[index++]);
          path.lineTo(currentX, currentY);
          lastControlX = currentX;
          lastControlY = currentY;
          break;

        case 'C':
          final x1 = double.parse(tokens[index++]);
          final y1 = double.parse(tokens[index++]);
          final x2 = double.parse(tokens[index++]);
          final y2 = double.parse(tokens[index++]);
          currentX = double.parse(tokens[index++]);
          currentY = double.parse(tokens[index++]);
          path.cubicTo(x1, y1, x2, y2, currentX, currentY);
          lastControlX = x2;
          lastControlY = y2;
          break;

        case 'c':
          final x1 = currentX + double.parse(tokens[index++]);
          final y1 = currentY + double.parse(tokens[index++]);
          final x2 = currentX + double.parse(tokens[index++]);
          final y2 = currentY + double.parse(tokens[index++]);
          currentX += double.parse(tokens[index++]);
          currentY += double.parse(tokens[index++]);
          path.cubicTo(x1, y1, x2, y2, currentX, currentY);
          lastControlX = x2;
          lastControlY = y2;
          break;

        case 'S':
          double x1 = currentX;
          double y1 = currentY;
          if (lastCommand == 'C' ||
              lastCommand == 'c' ||
              lastCommand == 'S' ||
              lastCommand == 's') {
            x1 = 2 * currentX - lastControlX;
            y1 = 2 * currentY - lastControlY;
          }
          final x2 = double.parse(tokens[index++]);
          final y2 = double.parse(tokens[index++]);
          currentX = double.parse(tokens[index++]);
          currentY = double.parse(tokens[index++]);
          path.cubicTo(x1, y1, x2, y2, currentX, currentY);
          lastControlX = x2;
          lastControlY = y2;
          break;

        case 's':
          double x1 = currentX;
          double y1 = currentY;
          if (lastCommand == 'C' ||
              lastCommand == 'c' ||
              lastCommand == 'S' ||
              lastCommand == 's') {
            x1 = 2 * currentX - lastControlX;
            y1 = 2 * currentY - lastControlY;
          }
          final x2 = currentX + double.parse(tokens[index++]);
          final y2 = currentY + double.parse(tokens[index++]);
          currentX += double.parse(tokens[index++]);
          currentY += double.parse(tokens[index++]);
          path.cubicTo(x1, y1, x2, y2, currentX, currentY);
          lastControlX = x2;
          lastControlY = y2;
          break;

        case 'Q':
          final x1 = double.parse(tokens[index++]);
          final y1 = double.parse(tokens[index++]);
          currentX = double.parse(tokens[index++]);
          currentY = double.parse(tokens[index++]);
          path.quadraticBezierTo(x1, y1, currentX, currentY);
          lastControlX = x1;
          lastControlY = y1;
          break;

        case 'q':
          final x1 = currentX + double.parse(tokens[index++]);
          final y1 = currentY + double.parse(tokens[index++]);
          currentX += double.parse(tokens[index++]);
          currentY += double.parse(tokens[index++]);
          path.quadraticBezierTo(x1, y1, currentX, currentY);
          lastControlX = x1;
          lastControlY = y1;
          break;

        case 'T':
          double x1 = currentX;
          double y1 = currentY;
          if (lastCommand == 'Q' ||
              lastCommand == 'q' ||
              lastCommand == 'T' ||
              lastCommand == 't') {
            x1 = 2 * currentX - lastControlX;
            y1 = 2 * currentY - lastControlY;
          }
          currentX = double.parse(tokens[index++]);
          currentY = double.parse(tokens[index++]);
          path.quadraticBezierTo(x1, y1, currentX, currentY);
          lastControlX = x1;
          lastControlY = y1;
          break;

        case 't':
          double x1 = currentX;
          double y1 = currentY;
          if (lastCommand == 'Q' ||
              lastCommand == 'q' ||
              lastCommand == 'T' ||
              lastCommand == 't') {
            x1 = 2 * currentX - lastControlX;
            y1 = 2 * currentY - lastControlY;
          }
          currentX += double.parse(tokens[index++]);
          currentY += double.parse(tokens[index++]);
          path.quadraticBezierTo(x1, y1, currentX, currentY);
          lastControlX = x1;
          lastControlY = y1;
          break;

        case 'A':
        case 'a':
          final isRelative = lastCommand == 'a';
          final rx = double.parse(tokens[index++]).abs();
          final ry = double.parse(tokens[index++]).abs();
          final rotation = double.parse(tokens[index++]);
          final largeArc = double.parse(tokens[index++]) != 0;
          final sweep = double.parse(tokens[index++]) != 0;
          final endXRaw = double.parse(tokens[index++]);
          final endYRaw = double.parse(tokens[index++]);
          final targetX = isRelative ? currentX + endXRaw : endXRaw;
          final targetY = isRelative ? currentY + endYRaw : endYRaw;

          if (rx == 0 || ry == 0) {
            path.lineTo(targetX, targetY);
          } else {
            path.arcToPoint(
              Offset(targetX, targetY),
              radius: Radius.elliptical(rx, ry),
              rotation: rotation,
              largeArc: largeArc,
              clockwise: sweep,
            );
          }
          currentX = targetX;
          currentY = targetY;
          lastControlX = currentX;
          lastControlY = currentY;
          break;

        case 'Z':
        case 'z':
          path.close();
          currentX = startX;
          currentY = startY;
          lastControlX = startX;
          lastControlY = startY;
          break;

        default:
          index++;
          break;
      }
    }

    return path;
  }

  static bool _isCommand(String token) {
    if (token.length != 1) return false;
    const cmds = 'MmLlHhVvCcSsQqTtAaZz';
    return cmds.contains(token);
  }

  static List<String> _tokenize(String pathData) {
    int i = 0;
    final n = pathData.length;
    final rawTokens = <String>[];

    while (i < n) {
      final c = pathData[i];
      if (c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == ',') {
        i++;
        continue;
      }
      if (_isCommand(c)) {
        rawTokens.add(c);
        i++;
        continue;
      }

      // Read number (handling negative signs, decimal points, and scientific notation)
      final start = i;
      if (pathData[i] == '+' || pathData[i] == '-') {
        i++;
      }
      bool hasDot = false;
      while (i < n) {
        final ch = pathData[i];
        if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
          // digit 0-9
          i++;
        } else if (ch == '.') {
          if (hasDot) break; // second dot starts next number (e.g. 10.5.6)
          hasDot = true;
          i++;
        } else if (ch == 'e' || ch == 'E') {
          i++;
          if (i < n && (pathData[i] == '+' || pathData[i] == '-')) {
            i++;
          }
        } else {
          break;
        }
      }
      rawTokens.add(pathData.substring(start, i));
    }

    // Secondary pass to split concatenated arc flags:
    // In SVG arc syntax, flags are strictly single digits '0' or '1' (e.g. 01, 011.5, 00.5)
    final expanded = <String>[];
    int idx = 0;
    String cmd = '';
    int arcParamIdx = 0;

    while (idx < rawTokens.length) {
      final t = rawTokens[idx];
      if (_isCommand(t)) {
        cmd = t;
        arcParamIdx = 0;
        expanded.add(t);
        idx++;
        continue;
      }

      if (cmd == 'A' || cmd == 'a') {
        // arc params: 0:rx, 1:ry, 2:rot, 3:large-arc-flag, 4:sweep-flag, 5:x, 6:y
        if (arcParamIdx == 3) {
          if (t.length > 1 && (t[0] == '0' || t[0] == '1')) {
            expanded.add(t[0]);
            arcParamIdx++;
            final rest = t.substring(1);
            if (arcParamIdx == 4 && rest.isNotEmpty && (rest[0] == '0' || rest[0] == '1')) {
              expanded.add(rest[0]);
              arcParamIdx++;
              final rest2 = rest.substring(1);
              if (rest2.isNotEmpty) {
                expanded.add(rest2);
                arcParamIdx++;
              }
            } else {
              expanded.add(rest);
              arcParamIdx++;
            }
            idx++;
            continue;
          }
        } else if (arcParamIdx == 4) {
          if (t.length > 1 && (t[0] == '0' || t[0] == '1')) {
            expanded.add(t[0]);
            arcParamIdx++;
            expanded.add(t.substring(1));
            arcParamIdx++;
            idx++;
            continue;
          }
        }
        arcParamIdx = (arcParamIdx + 1) % 7;
      }

      expanded.add(t);
      idx++;
    }

    return expanded;
  }
}
