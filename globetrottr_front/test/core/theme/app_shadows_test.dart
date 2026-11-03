import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';

void main() {
  const shadows = AppShadows(
    dark: Color(0xFF8C8374),
    light: Color(0xFFFFFFFF),
    overlay: Color(0xFF14120F),
    pressed: Color(0xFF000000),
  );

  group('NeoShadow', () {
    test(
      'an outer shadow blurs like the CSS blur radius it was taken from',
      () {
        const shadow = NeoShadow(
          offset: Offset(6, 6),
          blur: 14,
          color: Color(0x808C8374),
        );

        final box = shadow.toBoxShadow();

        expect(box.offset, const Offset(6, 6));
        expect(box.color, const Color(0x808C8374));
        expect(box.blurSigma, closeTo(7, 1e-9));
      },
    );

    test('shadows of the same kind blend into each other', () {
      const from = [
        NeoShadow(offset: Offset(2, 2), blur: 4, color: Color(0xFF000000)),
      ];
      const to = [
        NeoShadow(offset: Offset(6, 6), blur: 8, color: Color(0x00000000)),
      ];

      final half = lerpShadows(from, to, 0.5).single;

      expect(half.offset, const Offset(4, 4));
      expect(half.blur, 6);
      expect(half.color.a, closeTo(0.5, 0.01));
      expect(lerpShadows(from, to, 0), from);
      expect(lerpShadows(from, to, 1), to);
    });

    test('a raised surface flattens first and then sinks in', () {
      const raised = [
        NeoShadow(offset: Offset(4, 4), blur: 9, color: Color(0xFF000000)),
      ];
      const sunk = [
        NeoShadow(
          offset: Offset(4, 4),
          blur: 9,
          color: Color(0xFF000000),
          inset: true,
        ),
      ];

      final flattening = lerpShadows(raised, sunk, 0.25).single;
      final sinking = lerpShadows(raised, sunk, 0.75).single;

      expect(flattening.inset, isFalse);
      expect(flattening.offset, const Offset(2, 2));
      expect(flattening.color.a, closeTo(0.5, 0.01));
      expect(lerpShadows(raised, sunk, 0.5), isEmpty);
      expect(sinking.inset, isTrue);
      expect(sinking.offset, const Offset(2, 2));
      expect(sinking.blur, 9);
    });

    test('an inset shadow cannot become a BoxShadow', () {
      const shadow = NeoShadow(
        offset: Offset(4, 4),
        blur: 9,
        color: Color(0x808C8374),
        inset: true,
      );

      expect(shadow.toBoxShadow, throwsA(isA<AssertionError>()));
    });
  });

  group('AppShadows', () {
    test(
      'raised casts the dark shadow down-right and the light one up-left',
      () {
        final raised = shadows.raised(NeoDepth.xl);

        expect(raised, hasLength(2));
        expect(raised[0].offset, const Offset(6, 6));
        expect(raised[0].blur, 14);
        expect(raised[0].color, const Color(0xFF8C8374).withValues(alpha: 0.5));
        expect(raised[1].offset, const Offset(-6, -6));
        expect(raised[1].color, Colors.white.withValues(alpha: 0.95));
        expect(raised.any((s) => s.inset), isFalse);
      },
    );

    test('inset uses the same geometry inside the shape', () {
      final inset = shadows.inset(NeoDepth.md);

      expect(inset.every((s) => s.inset), isTrue);
      expect(inset[0].offset, const Offset(4, 4));
      expect(inset[0].blur, 9);
      expect(inset[1].offset, const Offset(-4, -4));
      expect(inset[1].color, Colors.white.withValues(alpha: 0.9));
    });

    test('an accent fill is raised and lit from the inside', () {
      final accent = shadows.raisedAccent(NeoDepth.md);

      expect(accent.where((s) => !s.inset), hasLength(2));
      expect(
        accent.first.color,
        const Color(0xFF8C8374).withValues(alpha: 0.6),
      );
      expect(accent.where((s) => s.inset), hasLength(1));
    });

    test(
      'a pressed accent fill sinks into darkness, not into the page tint',
      () {
        final pressed = shadows.insetAccent(NeoDepth.md);

        expect(pressed.every((s) => s.inset), isTrue);
        expect(pressed[0].offset, const Offset(5, 5));
        expect(pressed[0].color, Colors.black.withValues(alpha: 0.42));
        expect(pressed[1].offset, const Offset(-3, -3));
        expect(pressed[1].color.a, closeTo(0.16, 0.01));
      },
    );

    test('elements over the map cast one soft shadow straight down', () {
      expect(shadows.mapControl.single.offset, const Offset(0, 8));
      expect(shadows.mapControl.single.blur, 22);
      expect(shadows.mapNav.single.offset, const Offset(0, 10));
    });

    test('follows the palette it was built from', () {
      final fromPalette = AppShadows.fromPalette(AppPalette.light);

      expect(fromPalette.dark, AppPalette.light.shadowDark);
      expect(fromPalette.light, AppPalette.light.shadowLight);
      expect(fromPalette.pressed, AppPalette.light.shadowPressed);
    });
  });
}
