import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/invite_row.dart';

/// Received invites folded into one row; tapping it opens the list.
class InvitesCard extends StatefulWidget {
  const InvitesCard({
    super.key,
    required this.invites,
    required this.onAccept,
    required this.onReject,
  });

  final List<FriendshipResponse> invites;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  @override
  State<InvitesCard> createState() => _InvitesCardState();
}

class _InvitesCardState extends State<InvitesCard> {
  static const _duration = Duration(milliseconds: 240);

  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final invites = widget.invites;
    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          _Header(
            invites: invites,
            open: _open,
            onTap: () => setState(() => _open = !_open),
          ),
          AnimatedSize(
            duration: _duration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                    child: Column(
                      children: [
                        for (final invite in invites) ...[
                          const NeuDivider(),
                          InviteRow(
                            invite: invite,
                            onAccept: () => widget.onAccept(invite.username),
                            onReject: () => widget.onReject(invite.username),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.invites,
    required this.open,
    required this.onTap,
  });

  final List<FriendshipResponse> invites;
  final bool open;
  final VoidCallback onTap;

  static const _avatar = 40.0;
  static const _overlap = 12.0;
  static const _shownAvatars = 3;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final shown = invites.take(_shownAvatars).toList();
    return Semantics(
      button: true,
      expanded: open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 16),
            child: Row(
              spacing: 12,
              children: [
                SizedBox(
                  width: _avatar + (shown.length - 1) * (_avatar - _overlap),
                  height: _avatar,
                  child: Stack(
                    children: [
                      for (var i = 0; i < shown.length; i++)
                        Positioned(
                          left: i * (_avatar - _overlap),
                          child: UserAvatarBubble(
                            username: shown[i].username,
                            avatarUrl: shown[i].avatarUrl,
                            size: _avatar,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.friendsInvites(invites.length),
                        style: typography.itemTitle,
                      ),
                      Text(
                        invites.map((i) => i.username).join(', '),
                        style: typography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: open ? 0.25 : 0,
                  duration: _InvitesCardState._duration,
                  child: AppIcon(
                    AppIcons.chevronRight,
                    size: 16,
                    color: context.palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
