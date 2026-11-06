import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';

/// One shadow as the design describes it in CSS: [blur] is the CSS blur
/// radius, and an [inset] shadow falls inside the shape.
@immutable
class NeoShadow {
  const NeoShadow({
    required this.offset,
    required this.blur,
    required this.color,
    this.inset = false,
  });

  final Offset offset;
  final double blur;
  final Color color;
  final bool inset;

  /// The CSS blur radius is twice the Gaussian sigma.
  double get sigma => blur / 2;

  /// Flutter has no inset box shadows; those are painted by `NeuSurface`.
  BoxShadow toBoxShadow() {
    assert(!inset, 'An inset shadow has no BoxShadow equivalent');
    return BoxShadow(
      offset: offset,
      color: color,
      blurRadius: (sigma - 0.5) / 0.57735,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NeoShadow &&
      other.offset == offset &&
      other.blur == blur &&
      other.color == color &&
      other.inset == inset;

  @override
  int get hashCode => Object.hash(offset, blur, color, inset);

  /// Closer to the surface by [factor]: 0 lies flat and casts nothing.
  NeoShadow _scaled(double factor) => NeoShadow(
    offset: offset * factor,
    blur: blur,
    color: color.withValues(alpha: color.a * factor),
    inset: inset,
  );
}

/// The shadows between [from] (t = 0) and [to] (t = 1). Lists of the same
/// kind blend shadow by shadow; otherwise, as a raised surface cannot turn
/// into a sunk one directly, [from] flattens in the first half and [to]
/// grows in the second.
List<NeoShadow> lerpShadows(
  List<NeoShadow> from,
  List<NeoShadow> to,
  double t,
) {
  if (t <= 0) return from;
  if (t >= 1) return to;
  final sameKind =
      from.length == to.length &&
      Iterable<int>.generate(
        from.length,
      ).every((i) => from[i].inset == to[i].inset);
  if (sameKind) {
    return [
      for (var i = 0; i < from.length; i++)
        NeoShadow(
          offset: Offset.lerp(from[i].offset, to[i].offset, t)!,
          blur: lerpDouble(from[i].blur, to[i].blur, t)!,
          color: Color.lerp(from[i].color, to[i].color, t)!,
          inset: from[i].inset,
        ),
    ];
  }
  if (t == 0.5) return const [];
  return t < 0.5
      ? [for (final s in from) s._scaled(1 - 2 * t)]
      : [for (final s in to) s._scaled(2 * t - 1)];
}

/// How far a neumorphic surface stands out (or sinks in): the offset of its
/// shadows and their blur.
enum NeoDepth {
  xs(2, 4),
  sm(3, 7),
  md(4, 9),
  lg(5, 12),
  xl(6, 14);

  const NeoDepth(this.offset, this.blur);

  final double offset;
  final double blur;
}

/// The shadows of the design. Built from the palette, so a dark palette
/// brings its own shadows.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.dark,
    required this.light,
    required this.overlay,
    required this.pressed,
  });

  factory AppShadows.fromPalette(AppPalette palette) => AppShadows(
    dark: palette.shadowDark,
    light: palette.shadowLight,
    overlay: palette.shadowOverlay,
    pressed: palette.shadowPressed,
  );

  final Color dark;
  final Color light;
  final Color overlay;
  final Color pressed;

  List<NeoShadow> raised(NeoDepth depth) => _pair(depth, 0.5, 0.95);

  List<NeoShadow> inset(NeoDepth depth) => _pair(depth, 0.5, 0.9, inset: true);

  /// Only the dark side of [raised], for thin filled bars.
  List<NeoShadow> shade(NeoDepth depth) => [_pair(depth, 0.5, 0.95).first];

  /// A surface filled with the accent: a little darker outside and lit from
  /// the inside.
  List<NeoShadow> raisedAccent(NeoDepth depth) {
    final small = depth.index <= NeoDepth.md.index;
    return [
      ..._pair(depth, 0.6, 0.95),
      NeoShadow(
        offset: small ? const Offset(2, 2) : const Offset(1, 1),
        blur: small ? 4 : 2,
        color: light.withValues(alpha: small ? 0.22 : 0.2),
        inset: true,
      ),
    ];
  }

  /// [raisedAccent] pressed in. The page-tinted shadows of [inset] would wash
  /// out a coloured fill, so it sinks into a dark shade with a faint rim light.
  List<NeoShadow> insetAccent(NeoDepth depth) => [
    NeoShadow(
      offset: Offset(depth.offset + 1, depth.offset + 1),
      blur: depth.blur + 1,
      color: pressed.withValues(alpha: 0.42),
      inset: true,
    ),
    NeoShadow(
      offset: Offset(-(depth.offset - 1), -(depth.offset - 1)),
      blur: depth.blur - 2,
      color: light.withValues(alpha: 0.16),
      inset: true,
    ),
  ];

  /// The globe of the logo, lit from the top left.
  List<NeoShadow> get logo => [
    NeoShadow(
      offset: const Offset(5, 7),
      blur: 10,
      color: dark.withValues(alpha: 0.5),
    ),
    NeoShadow(
      offset: const Offset(-4, -4),
      blur: 8,
      color: light.withValues(alpha: 0.9),
    ),
  ];

  /// Controls floating over the map.
  List<NeoShadow> get mapControl => _drop(8, 22, 0.35);

  /// The bottom navigation over the map.
  List<NeoShadow> get mapNav => _drop(10, 26, 0.4);

  /// Small labels on the map.
  List<NeoShadow> get mapLabel => _drop(4, 12, 0.35);

  /// Markers drawn on the map.
  List<NeoShadow> get marker => _drop(3, 6, 0.35);

  /// A sheet sliding up over the map.
  List<NeoShadow> get sheet => _drop(-10, 30, 0.25);

  List<NeoShadow> _pair(
    NeoDepth depth,
    double darkAlpha,
    double lightAlpha, {
    bool inset = false,
  }) => [
    NeoShadow(
      offset: Offset(depth.offset, depth.offset),
      blur: depth.blur,
      color: dark.withValues(alpha: darkAlpha),
      inset: inset,
    ),
    NeoShadow(
      offset: Offset(-depth.offset, -depth.offset),
      blur: depth.blur,
      color: light.withValues(alpha: lightAlpha),
      inset: inset,
    ),
  ];

  List<NeoShadow> _drop(double dy, double blur, double alpha) => [
    NeoShadow(
      offset: Offset(0, dy),
      blur: blur,
      color: overlay.withValues(alpha: alpha),
    ),
  ];

  @override
  AppShadows copyWith({
    Color? dark,
    Color? light,
    Color? overlay,
    Color? pressed,
  }) => AppShadows(
    dark: dark ?? this.dark,
    light: light ?? this.light,
    overlay: overlay ?? this.overlay,
    pressed: pressed ?? this.pressed,
  );

  @override
  AppShadows lerp(AppShadows? other, double t) {
    if (other == null) return this;
    return AppShadows(
      dark: Color.lerp(dark, other.dark, t)!,
      light: Color.lerp(light, other.light, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      pressed: Color.lerp(pressed, other.pressed, t)!,
    );
  }
}
