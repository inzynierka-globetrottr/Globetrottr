import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/router/tab_visibility.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/router/friend_routes.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/animated_column.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_list_card.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_action.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_row.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friends_empty_card.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/invites_card.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/weekly_strip.dart';
import 'package:globetrottr_front/features/profile/provider/profile_provider.dart';
import 'package:go_router/go_router.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with TabVisibility {
  static const _side = 20.0;

  @override
  void onTabShown() {
    ref.read(friendsProvider.notifier).loadAll();
    if (ref.read(profileProvider).profile == null) {
      ref.read(profileProvider.notifier).loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(friendsProvider);
    final notifier = ref.read(friendsProvider.notifier);
    final padding = MediaQuery.paddingOf(context);

    Widget side(String key, Widget child) => Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.symmetric(horizontal: _side),
      child: child,
    );

    return Scaffold(
      // The padding includes the floating navigation, which the list scrolls
      // on under.
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: padding.top + 1,
          bottom: padding.bottom + 20,
        ),
        // Sections that come with the data or go away unfold and fold; the
        // first data only fades in, as nothing below has to move.
        child: AnimatedColumn(
          spacing: 16,
          appearing: !state.hasLoaded,
          children: [
            side(
              'title',
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      l10n.friendsTitle,
                      style: context.typography.headline,
                    ),
                  ),
                  NeuIconButton(
                    size: 50,
                    depth: NeoDepth.lg,
                    fill: NeuFill.accent,
                    semanticLabel: l10n.friendsAdd,
                    onPressed: () => context.go(FriendRoutes.add),
                    child: const AppIcon(AppIcons.plus),
                  ),
                ],
              ),
            ),
            if (state.errorMessage != null)
              side(
                'error',
                FormMessage.error(
                  context.localizeErrorMessage(state.errorMessage),
                ),
              ),
            if (state.friends.isNotEmpty)
              Column(
                key: const ValueKey('weekly'),
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  side('weeklyTitle', SectionHeader(l10n.friendsThisWeek)),
                  const WeeklyStrip(sidePadding: _side),
                ],
              ),
            if (state.receivedInvites.isNotEmpty)
              side(
                'invites',
                InvitesCard(
                  invites: state.receivedInvites,
                  onAccept: (username) => runFriendAction(
                    context,
                    () => notifier.acceptInvite(username),
                  ),
                  onReject: (username) => runFriendAction(
                    context,
                    () => notifier.deleteRelationship(username),
                  ),
                ),
              ),
            if (state.friends.isEmpty && state.hasLoaded)
              side(
                'empty',
                FriendsEmptyCard(onAdd: () => context.go(FriendRoutes.add)),
              )
            else if (state.friends.isNotEmpty)
              side(
                'friends',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    SectionHeader(
                      l10n.friendsYourFriends(state.friends.length),
                    ),
                    NeuListCard(
                      rows: [
                        for (final friend in state.friends)
                          FriendRow(
                            key: ValueKey(friend.username),
                            friend: friend,
                            onOpen: () => context.go(
                              FriendRoutes.profile(friend.username),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
