import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An original, code-drawn bookplate; catalogue artwork always comes from sources.
class ReadingRoom extends StatelessWidget {
  final int titles, unread;
  final VoidCallback onBrowse, onLibrary;
  const ReadingRoom({
    super.key,
    required this.titles,
    required this.unread,
    required this.onBrowse,
    required this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .055),
        border: Border.all(color: scheme.primary.withValues(alpha: .16)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: 34,
            child: ExcludeSemantics(
              child: CustomPaint(
                size: const Size(138, 150),
                painter: _BookplatePainter(
                  scheme.primary.withValues(alpha: .20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR COLLECTION',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'The reading\nroom.',
                  style: TextStyle(
                    fontFamily: 'Newsreader',
                    fontSize: 46,
                    height: 1.04,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  titles == 0
                      ? 'Build a library of your own.'
                      : '$titles ${titles == 1 ? 'title' : 'titles'} · $unread unread chapters',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    TextButton.icon(
                      onPressed: titles == 0 ? onBrowse : onLibrary,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.centerLeft,
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        titles == 0 ? 'Explore sources' : 'Open library',
                      ),
                    ),
                    if (titles > 0)
                      TextButton(
                        onPressed: onBrowse,
                        child: const Text('Discover more'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookplatePainter extends CustomPainter {
  final Color color;
  const _BookplatePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.save();
    canvas.translate(size.width * .45, size.height * .55);
    canvas.rotate(-math.pi / 12);
    for (var i = 0; i < 5; i++) {
      final inset = i * 5.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-44 + inset, -54 + inset / 2, 82, 114 - inset),
          const Radius.circular(8),
        ),
        ink,
      );
    }
    canvas.drawLine(const Offset(-28, -47), const Offset(-28, 52), ink);
    canvas.drawCircle(const Offset(15, -12), 18, ink);
    canvas.drawLine(const Offset(-4, 25), const Offset(35, 25), ink);
    canvas.drawLine(const Offset(1, 32), const Offset(30, 32), ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BookplatePainter oldDelegate) =>
      oldDelegate.color != color;
}
