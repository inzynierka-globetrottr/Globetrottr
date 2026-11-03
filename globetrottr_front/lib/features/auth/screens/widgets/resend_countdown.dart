import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/time/clock.dart';

/// "Resend in 0:42" counting down to [availableAt], then a link that sends
/// the code again.
class ResendCountdown extends ConsumerStatefulWidget {
  const ResendCountdown({
    super.key,
    required this.availableAt,
    required this.onResend,
  });

  final DateTime? availableAt;
  final VoidCallback? onResend;

  @override
  ConsumerState<ResendCountdown> createState() => _ResendCountdownState();
}

class _ResendCountdownState extends ConsumerState<ResendCountdown> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  static String _format(Duration left) {
    final seconds = left.inSeconds % 60;
    return '${left.inMinutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final availableAt = widget.availableAt;
    final left = availableAt?.difference(ref.read(clockProvider)());
    final style = typography.action.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    if (left != null && left > Duration.zero) {
      // Rounded up, so the last second shows 0:01 rather than 0:00.
      final shown = Duration(seconds: (left.inMilliseconds / 1000).ceil());
      return Text(context.l10n.authResendIn(_format(shown)), style: style);
    }
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onResend,
        child: Text(
          context.l10n.authResend,
          style: style.copyWith(color: context.palette.accent),
        ),
      ),
    );
  }
}
