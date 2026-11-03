import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';

/// Runs an action on a friend (accept, reject, undo) and reports a failure
/// under the screen.
Future<void> runFriendAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on AppException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.localizeErrorMessage(e.message))),
    );
  }
}
