import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_pill_button.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/debug/animations/demo_section.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:globetrottr_front/features/friends/data/invite_status.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/invites_card.dart';

void _nothing() {}

class ButtonsDemo extends StatelessWidget {
  const ButtonsDemo({super.key});

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Pressing buttons',
    child: Column(
      spacing: 18,
      children: [
        const NeuPrimaryButton(label: 'Primary', onPressed: _nothing),
        const NeuButton(onPressed: _nothing, child: Text('Page button')),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final fill in NeuFill.values)
              NeuIconButton(
                fill: fill,
                onPressed: _nothing,
                child: const AppIcon(AppIcons.chevronRight, size: 18),
              ),
            const NeuPillButton(label: 'Pill', onPressed: _nothing),
          ],
        ),
      ],
    ),
  );
}

class FormMessageDemo extends StatefulWidget {
  const FormMessageDemo({super.key});

  @override
  State<FormMessageDemo> createState() => _FormMessageDemoState();
}

class _FormMessageDemoState extends State<FormMessageDemo> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Form message',
    controls: {'Show / hide': () => setState(() => _shown = !_shown)},
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        if (_shown) const FormMessage.error('Wrong login or password'),
        const NeuPrimaryButton(label: 'Sign in', onPressed: _nothing),
      ],
    ),
  );
}

class FieldErrorDemo extends StatefulWidget {
  const FieldErrorDemo({super.key});

  @override
  State<FieldErrorDemo> createState() => _FieldErrorDemoState();
}

class _FieldErrorDemoState extends State<FieldErrorDemo> {
  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Field error',
    controls: {
      'Validate': () => _form.currentState!.validate(),
      'Clear': () => _form.currentState!.reset(),
    },
    child: Form(
      key: _form,
      child: Column(
        spacing: 18,
        children: [
          NeuTextField(
            label: 'Login',
            placeholder: 'Leave empty and validate',
            validator: (value) =>
                (value ?? '').isEmpty ? 'Enter your login' : null,
          ),
          const NeuPrimaryButton(label: 'Below the field', onPressed: _nothing),
        ],
      ),
    ),
  );
}

class InvitesDemo extends StatelessWidget {
  const InvitesDemo({super.key});

  static const _invites = [
    FriendshipResponse(
      username: 'ola',
      status: InviteStatus.pending,
      isIncomingRequest: true,
    ),
    FriendshipResponse(
      username: 'kuba',
      status: InviteStatus.pending,
      isIncomingRequest: true,
    ),
  ];

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Folding card',
    child: InvitesCard(
      invites: _invites,
      onAccept: (_) {},
      onReject: (_) {},
    ),
  );
}
