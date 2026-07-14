import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FootballHeroCard extends StatelessWidget {
  const FootballHeroCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
    this.content,
    this.compact = false,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;
  final Widget? content;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        gradient: const LinearGradient(
          colors: [AppTheme.navy, AppTheme.fieldGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _PitchPainter())),
          ),
          Positioned(
            right: -26,
            top: -34,
            child: Icon(
              Icons.sports_soccer,
              color: Colors.white.withValues(alpha: 0.08),
              size: 150,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 42 : 48,
                      height: compact ? 42 : 48,
                      decoration: BoxDecoration(
                        color: AppTheme.lime,
                        borderRadius: BorderRadius.circular(compact ? 14 : 16),
                      ),
                      child: Icon(
                        icon,
                        color: AppTheme.navy,
                        size: compact ? 23 : 27,
                      ),
                    ),
                    SizedBox(width: compact ? 11 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow,
                            style: const TextStyle(
                              color: AppTheme.lime,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          SizedBox(height: compact ? 2 : 4),
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 19 : 22,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: compact ? 3 : 5),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: compact ? 12 : null,
                              height: compact ? 1.25 : 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(width: 10),
                      action!,
                    ],
                  ],
                ),
                if (content != null) ...[
                  SizedBox(height: compact ? 12 : 18),
                  content!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final inset = size.shortestSide * 0.12;
    final field = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(field, const Radius.circular(8)),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, field.top),
      Offset(size.width / 2, field.bottom),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.12,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
