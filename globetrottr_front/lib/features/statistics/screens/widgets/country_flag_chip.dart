import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

class CountryFlagChip extends StatelessWidget {
  const CountryFlagChip({
    super.key,
    required this.countryCode,
    this.showCodeLabel = true,
  });

  /// Null for a region without an ISO code; it gets a plain chip.
  final String? countryCode;
  final bool showCodeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    final code = countryCode?.toUpperCase() ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: palette.background,
            boxShadow: [
              for (final s in context.shadows.shade(NeoDepth.xs))
                s.toBoxShadow(),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildFlag(context, code),
        ),
        if (showCodeLabel && code.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            code,
            style: typography.micro.copyWith(
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlag(BuildContext context, String code) {
    final palette = context.palette;
    final typography = context.typography;

    switch (code) {
      case 'PL':
        return const Column(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
            Expanded(child: ColoredBox(color: Color(0xFFDC143C))),
          ],
        );
      case 'FR':
        return const Row(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF002654))),
            Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
            Expanded(child: ColoredBox(color: Color(0xFFED2939))),
          ],
        );
      case 'IT':
        return const Row(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF009246))),
            Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
            Expanded(child: ColoredBox(color: Color(0xFFCE2B37))),
          ],
        );
      case 'DE':
        return const Column(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF000000))),
            Expanded(child: ColoredBox(color: Color(0xFFDD0000))),
            Expanded(child: ColoredBox(color: Color(0xFFFFCE00))),
          ],
        );
      case 'UA':
        return const Column(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF005BBB))),
            Expanded(child: ColoredBox(color: Color(0xFFFFD500))),
          ],
        );
      case 'AT':
        return const Column(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFFED2939))),
            Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
            Expanded(child: ColoredBox(color: Color(0xFFED2939))),
          ],
        );
      case 'HU':
        return const Column(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFFCE2939))),
            Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
            Expanded(child: ColoredBox(color: Color(0xFF477050))),
          ],
        );
      case 'NL':
        return const Column(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFFC8102E))),
            Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
            Expanded(child: ColoredBox(color: Color(0xFF003DA5))),
          ],
        );
      case 'BE':
        return const Row(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF000000))),
            Expanded(child: ColoredBox(color: Color(0xFFFFD100))),
            Expanded(child: ColoredBox(color: Color(0xFFFF0F21))),
          ],
        );
      case 'CZ':
        return const CustomPaint(
          painter: _CzechFlagPainter(),
        );
      case 'SK':
        return const CustomPaint(
          painter: _SlovakFlagPainter(),
        );
      default:
        return Container(
          color: palette.background,
          alignment: Alignment.center,
          child: Text(
            code,
            style: typography.micro.copyWith(
              color: palette.text,
            ),
          ),
        );
    }
  }
}

class _CzechFlagPainter extends CustomPainter {
  const _CzechFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    final redPaint = Paint()..color = const Color(0xFFD7141A);
    final bluePaint = Paint()..color = const Color(0xFF11457E);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 2),
      whitePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
      redPaint,
    );

    final triangle = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(triangle, bluePaint);
  }

  @override
  bool shouldRepaint(_CzechFlagPainter oldDelegate) => false;
}

class _SlovakFlagPainter extends CustomPainter {
  const _SlovakFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripeHeight = size.height / 3;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, stripeHeight),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight, size.width, stripeHeight),
      Paint()..color = const Color(0xFF0B4EA2),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight * 2, size.width, stripeHeight),
      Paint()..color = const Color(0xFFEE1C25),
    );
  }

  @override
  bool shouldRepaint(_SlovakFlagPainter oldDelegate) => false;
}
