import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';

class ProfileAvatar extends ConsumerWidget {
  final String? avatarUrl;
  final String username;
  final bool isUploading;
  final Function(String filePath)? onAvatarSelected;

  const ProfileAvatar({
    super.key,
    required this.username,
    this.avatarUrl,
    this.isUploading = false,
    this.onAvatarSelected,
  });

  Future<void> _pickAndUploadImage(BuildContext context) async {
    if (isUploading) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null && onAvatarSelected != null) {
        onAvatarSelected!(pickedFile.path);
      }
    } catch (e) {
      print('Failed to select image: ${e.toString()}');
      if (context.mounted) {
        // TODO: show error differently than with a snack bar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String fallbackLetter = username.isNotEmpty 
        ? username[0].toUpperCase() 
        : 'T';

    return GestureDetector(
      onTap: () => _pickAndUploadImage(context),
      child: Center(
        child: SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              
              Positioned.fill(
                child: Neumorphic(
                  padding: const EdgeInsets.all(6),
                  style: const NeumorphicStyle(
                    shape: NeumorphicShape.flat,
                    boxShape: NeumorphicBoxShape.circle(),
                    depth: -4,
                    intensity: 1,
                    shadowLightColorEmboss: AppColors.neuLight,
                    shadowDarkColorEmboss: AppColors.neuShadow,
                    color: AppColors.background,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ClipOval(
                          child: Image.network(
                            avatarUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildFallback(fallbackLetter),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        _buildFallback(fallbackLetter),

                      if (isUploading)
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: -2,
                right: -2,
                child: Neumorphic(
                  style: const NeumorphicStyle(
                    shape: NeumorphicShape.flat,
                    boxShape: NeumorphicBoxShape.circle(),
                    depth: 3,
                    intensity: 0.9,
                    shadowLightColor: AppColors.neuLight,
                    shadowDarkColor: AppColors.neuShadow,
                    color: AppColors.background,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(String letter) {
    return Center(
      child: Text(
        letter,
        style: AppTextStyles.screenHeaderLarge.copyWith(
          color: AppColors.accentBlue,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}