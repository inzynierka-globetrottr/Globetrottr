import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/validators.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_back_button.dart';
import 'package:globetrottr_front/core/widgets/neu_list_card.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_action.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/sent_invite_row.dart';

/// Invites a friend by their exact nickname and lists the invites waiting
/// for an answer.
class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _nickname = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(friendsProvider.notifier)
          .sendInvite(_nickname.text.trim());
      _nickname.clear();
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sent = ref.watch(friendsProvider.select((s) => s.sentInvites));
    final notifier = ref.read(friendsProvider.notifier);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, top + 1, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18,
          children: [
            Row(
              spacing: 12,
              children: [
                const NeuBackButton(),
                Expanded(
                  child: Text(l10n.friendsAdd, style: context.typography.title),
                ),
              ],
            ),
            Form(
              key: _formKey,
              child: NeuTextField(
                label: l10n.friendsNicknameLabel,
                placeholder: l10n.friendsNicknamePlaceholder,
                leadingIcon: AppIcons.fieldUser,
                controller: _nickname,
                validator: (value) => validateUsername(value, l10n),
              ),
            ),
            if (_error != null)
              FormMessage.error(context.localizeErrorMessage(_error)),
            NeuPrimaryButton(
              label: l10n.friendsSendInvite,
              isLoading: _sending,
              onPressed: _send,
            ),
            if (sent.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  SectionHeader(l10n.friendsSent),
                  NeuListCard(
                    rows: [
                      for (final invite in sent)
                        SentInviteRow(
                          invite: invite,
                          onUndo: () => runFriendAction(
                            context,
                            () => notifier.deleteRelationship(invite.username),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
