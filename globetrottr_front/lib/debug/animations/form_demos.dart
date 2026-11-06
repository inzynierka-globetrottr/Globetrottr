import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/widgets/animated_column.dart';
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
  final _login = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  // The text lives in the controller, which a form reset does not touch.
  void _clear() {
    _login.clear();
    _form.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Field error',
    controls: {
      'Validate': () => _form.currentState!.validate(),
      'Clear': _clear,
    },
    child: Form(
      key: _form,
      child: Column(
        spacing: 18,
        children: [
          NeuTextField(
            controller: _login,
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

class InvitesDemo extends StatefulWidget {
  const InvitesDemo({super.key});

  @override
  State<InvitesDemo> createState() => _InvitesDemoState();
}

class _InvitesDemoState extends State<InvitesDemo> {
  static const _all = ['ola', 'kuba', 'ania'];

  List<String> _invites = _all;

  void _drop(String username) => setState(
    () => _invites = [
      for (final invite in _invites)
        if (invite != username) invite,
    ],
  );

  @override
  Widget build(BuildContext context) => DemoSection(
    title: 'Invites: open, accept or reject',
    controls: {'Reset': () => setState(() => _invites = _all)},
    child: AnimatedColumn(
      children: [
        if (_invites.isNotEmpty)
          InvitesCard(
            key: const ValueKey('invites'),
            invites: [
              for (final username in _invites)
                FriendshipResponse(
                  username: username,
                  status: InviteStatus.pending,
                  isIncomingRequest: true,
                ),
            ],
            onAccept: _drop,
            onReject: _drop,
          ),
      ],
    ),
  );
}
