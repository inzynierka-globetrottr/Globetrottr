import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// Says over a friend's map that their fog could not be loaded, so the
/// fogged map is not read as a friend who has discovered nothing.
class FriendFogErrorNotice extends StatelessWidget {
  const FriendFogErrorNotice({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: NeuSurface(
      shadows: context.shadows.mapControl,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: FormMessage.error(context.l10n.friendFogLoadError),
    ),
  );
}
