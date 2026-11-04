import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/features/profile/provider/profile_provider.dart';
import 'package:image_picker/image_picker.dart';

/// Lets the user pick a picture from the gallery; the path of the picture,
/// or null when the user cancels.
final avatarImagePickerProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    return picked?.path;
  },
);

/// Picks a picture and uploads it as the avatar. Upload errors land in the
/// profile state; only a failure of the picker itself is shown here.
Future<void> pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
  if (ref.read(profileProvider).isUploadingAvatar) return;
  final String? path;
  try {
    path = await ref.read(avatarImagePickerProvider)();
  } catch (e) {
    debugPrint('Failed to select image: $e');
    if (context.mounted) {
      // TODO: show error differently than with a snack bar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileImageSelectError(e.toString())),
          backgroundColor: context.palette.danger,
        ),
      );
    }
    return;
  }
  if (path == null || !context.mounted) return;
  await ref.read(profileProvider.notifier).uploadAvatar(path);
}
