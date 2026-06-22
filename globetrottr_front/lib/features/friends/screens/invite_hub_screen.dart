import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/received_invite_card.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/sent_invite_card.dart';
import 'package:go_router/go_router.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_segmented_control.dart';

enum InviteTab { received, sent }

class InviteHubScreen extends ConsumerStatefulWidget {
  const InviteHubScreen({super.key});

  @override
  ConsumerState<InviteHubScreen> createState() => _InviteHubScreenState();
}

class _InviteHubScreenState extends ConsumerState<InviteHubScreen> {
  InviteTab _selectedTab = InviteTab.received;

  // TODO: handle it differently than a snackbar
  Future<void> _handleAccept(String username) async {
    try {
      await ref.read(friendsProvider.notifier).acceptInvite(username);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong.')),
      );
    }
  }

  Future<void> _handleDeleteRelationship(String username) async {
    try {
      await ref.read(friendsProvider.notifier).deleteRelationship(username);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(baseColor: AppColors.background),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Row(
                  children: [
                    NeuIconButton(
                      onPressed: () => context.pop(),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.accentBlue,
                        size: 22,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Friend Requests',
                          style: AppTextStyles.screenHeaderLarge,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: NeuSegmentedControl<InviteTab>(
                  selected: _selectedTab,
                  onChanged: (tab) => setState(() => _selectedTab = tab),
                  segments: const [
                    NeuSegment(label: 'Received', value: InviteTab.received),
                    NeuSegment(label: 'Sent', value: InviteTab.sent),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab == InviteTab.received ? 0 : 1,
                  children: [
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      itemCount: state.receivedInvites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => ReceivedInviteCard(
                        invite: state.receivedInvites[index],
                        onAccept: () => _handleAccept(state.receivedInvites[index].username),
                        onDecline: () => _handleDeleteRelationship(state.receivedInvites[index].username),
                      ),
                    ),
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      itemCount: state.sentInvites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => SentInviteCard(
                        invite: state.sentInvites[index],
                        onCancel: () => _handleDeleteRelationship(state.sentInvites[index].username),
                      ),
                    ),
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
