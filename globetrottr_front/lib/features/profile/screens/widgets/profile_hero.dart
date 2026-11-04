import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/level_avatar.dart';
import 'package:globetrottr_front/features/quests/provider/quest_level_provider.dart';

/// The top of a profile: the avatar and the name. Tapping either grows the
/// avatar and unfolds [details] below.
class ProfileHero extends StatefulWidget {
  const ProfileHero({
    super.key,
    required this.username,
    required this.level,
    required this.details,
    this.avatarUrl,
    this.isUploading = false,
  });

  final String username;
  final String? avatarUrl;

  /// A new picture is being uploaded.
  final bool isUploading;
  final QuestLevel level;
  final Widget details;

  @override
  State<ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<ProfileHero>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 240);
  static const _grownScale = 1.12;

  /// Room for the shadows of [ProfileHero.details] on its sides.
  static const _shadowBleed = 24.0;

  late final _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );
  late final _open = CurvedAnimation(parent: _controller, curve: Curves.ease);

  bool get _isOpen => _controller.status.isForwardOrCompleted;

  void _toggle() => _isOpen ? _controller.reverse() : _controller.forward();

  @override
  void dispose() {
    _open.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final level = widget.level;
    final label = context.l10n.profileShowDetails(
      level.level?.toString() ?? context.l10n.friendsLevelUnknown,
    );

    Widget toggle(Widget child) => AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Semantics(
        button: true,
        expanded: _isOpen,
        label: label,
        excludeSemantics: true,
        child: child,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: child,
      ),
    );

    return Column(
      children: [
        toggle(
          ScaleTransition(
            scale: Tween(begin: 1.0, end: _grownScale).animate(_open),
            child: LevelAvatar(
              username: widget.username,
              avatarUrl: widget.avatarUrl,
              isUploading: widget.isUploading,
              level: level.level,
              fill: level.fill,
            ),
          ),
        ),
        const SizedBox(height: 14),
        toggle(
          Padding(
            // Balances the chevron, so the name stays centred.
            padding: const EdgeInsets.only(left: 26),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Flexible(
                  child: Text(
                    widget.username,
                    style: context.typography.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 0.5).animate(_open),
                  child: AppIcon(
                    AppIcons.chevronDown,
                    size: 20,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          clipper: const _VerticalClipper(_shadowBleed),
          child: AnimatedBuilder(
            animation: _open,
            builder: (context, child) => _open.value == 0
                ? const SizedBox(width: double.infinity)
                : Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _open.value,
                    child: child,
                  ),
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 14),
              child: widget.details,
            ),
          ),
        ),
      ],
    );
  }
}

/// Clips only the top and the bottom, so shadows on the sides stay visible.
class _VerticalClipper extends CustomClipper<Rect> {
  const _VerticalClipper(this.bleed);

  final double bleed;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-bleed, 0, size.width + bleed, size.height);

  @override
  bool shouldReclip(_VerticalClipper oldClipper) => oldClipper.bleed != bleed;
}
