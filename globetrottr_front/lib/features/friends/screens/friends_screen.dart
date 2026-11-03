import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/router/tab_visibility.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
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

    Widget side(Widget child) => Padding(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            side(
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
                    onPressed: () => context.go('/friends/add'),
                    child: const AppIcon(AppIcons.plus),
                  ),
                ],
              ),
            ),
            if (state.errorMessage != null)
              side(
                FormMessage.error(
                  context.localizeErrorMessage(state.errorMessage),
                ),
              ),
            if (state.friends.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  side(SectionHeader(l10n.friendsThisWeek)),
                  const WeeklyStrip(sidePadding: _side),
                ],
              ),
            if (state.receivedInvites.isNotEmpty)
              side(
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
            if (state.friends.isEmpty)
              side(FriendsEmptyCard(onAdd: () => context.go('/friends/add')))
            else
              side(
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
                            friend: friend,
                            onOpen: () =>
                                context.push('/friends/${friend.username}/map'),
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
