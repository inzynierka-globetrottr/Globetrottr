import 'package:flutter/material.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_comparison_pane.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_profile_header.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_profile_pane.dart';

/// A friend's screen: their profile first, the comparison with the user on
/// the other tab.
class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({super.key, required this.username});

  final String username;

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  static const _side = 20.0;

  FriendView _view = FriendView.profile;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          _side,
          safe.top + 24,
          _side,
          safe.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            FriendProfileHeader(
              username: widget.username,
              view: _view,
              onView: (view) => setState(() => _view = view),
            ),
            switch (_view) {
              FriendView.comparison => FriendComparisonPane(
                username: widget.username,
              ),
              FriendView.profile => FriendProfilePane(
                username: widget.username,
              ),
            },
          ],
        ),
      ),
    );
  }
}
