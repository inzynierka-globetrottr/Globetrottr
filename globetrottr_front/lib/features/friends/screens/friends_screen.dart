import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_card.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/invite_hub_banner.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/search_send_row.dart';
import 'package:go_router/go_router.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(friendsProvider.notifier).loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(
        baseColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Center(
                  child: Text(
                    'Friends',
                    style: AppTextStyles.screenHeaderLarge,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [

                    SearchSendRow(),

                    const SizedBox(height: 24),
                    InviteHubBanner(
                      receivedCount: state.receivedInvites.length,
                      onTap: () => context.push('/friends/invites'),
                    ),

                    const SizedBox(height: 24),
                    Text('YOUR FRIENDS (${state.friends.length})', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 14),
                    ...state.friends.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: FriendCard(friend: f),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const NeuBottomNavbar(
          activeItem: NavbarItem.friends,
        ),
      ),
    );
  }
}