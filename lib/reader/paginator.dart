// lib/reader/paginator.dart
import 'dart:math';
import 'package:flutter/material.dart';

class Paginator {
  static List<String> paginate({
    required String text,
    required TextStyle style,
    required Size pageSize,
    required TextDirection textDirection,
  }) {
    final pages = <String>[];
    final painter = TextPainter(textDirection: textDirection);
    final maxW = max(120.0, pageSize.width);
    final maxH = max(160.0, pageSize.height);

    int start = 0;
    final total = text.length;
    while (start < total) {
      int low = start + 1, high = total, best = start + 1;
      while (low <= high) {
        final mid = (low + high) >> 1;
        painter.text = TextSpan(text: text.substring(start, mid), style: style);
        painter.layout(maxWidth: maxW);
        if (painter.size.height <= maxH) {
          best = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      int end = best;
      if (end < total) {
        // back up to a whitespace boundary if we can
        final chunk = text.substring(start, end);
        final idx = chunk.lastIndexOf(RegExp(r'\s'));
        if (idx > 0) end = start + idx;
      }

      final page = text.substring(start, end).trimRight();
      if (page.isEmpty) break;
      pages.add(page);

      // move past any trailing whitespace/newlines so we don’t loop
      final ws = RegExp(r'^\s+');
      final rest = text.substring(end);
      final m = ws.firstMatch(rest);
      start = end + (m?.group(0)?.length ?? 0);
    }

    return pages.isEmpty ? [text] : pages;
  }
}
