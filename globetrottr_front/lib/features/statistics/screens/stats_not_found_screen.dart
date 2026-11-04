import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_back_button.dart';

/// Shown for a region link that leads nowhere.
class StatsNotFoundScreen extends StatelessWidget {
  const StatsNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NeuBackButton(),
              Expanded(
                child: Center(
                  child: Text(
                    context.l10n.errorNotFound,
                    style: context.typography.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
