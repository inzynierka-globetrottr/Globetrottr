import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:globetrottr_front/debug/animations/form_demos.dart';
import 'package:globetrottr_front/debug/animations/transition_picker.dart';
import 'package:globetrottr_front/debug/animations/value_demos.dart';

/// Every animation of the app on real components, with controls that change
/// their values, so each one can be judged without backend data.
class AnimationsScreen extends StatefulWidget {
  const AnimationsScreen({super.key});

  static const slowMotion = 5.0;

  @override
  State<AnimationsScreen> createState() => _AnimationsScreenState();
}

class _AnimationsScreenState extends State<AnimationsScreen> {
  bool _slow = false;
  bool _noMotion = false;

  void _setSlow(bool slow) {
    setState(() => _slow = slow);
    timeDilation = slow ? AnimationsScreen.slowMotion : 1;
  }

  @override
  void dispose() {
    timeDilation = 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animations')),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: _noMotion),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            const TransitionPicker(),
            SwitchListTile(
              title: const Text('Slow motion x5'),
              subtitle: const Text('Every animation in the app, until closed'),
              value: _slow,
              onChanged: _setSlow,
            ),
            SwitchListTile(
              title: const Text('Remove animations'),
              subtitle: const Text('Like the system setting, this screen only'),
              value: _noMotion,
              onChanged: (value) => setState(() => _noMotion = value),
            ),
            const ButtonsDemo(),
            const NumberDemo(),
            const RingDemo(),
            const RouteBarDemo(),
            const StepsDemo(),
            const FormMessageDemo(),
            const FieldErrorDemo(),
            const InvitesDemo(),
          ],
        ),
      ),
    );
  }
}
