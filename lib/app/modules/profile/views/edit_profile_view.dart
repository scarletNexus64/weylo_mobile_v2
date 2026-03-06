import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../controllers/profile_controller.dart';

class EditProfileView extends GetView<ProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final firstNameController = TextEditingController(
      text: controller.user.value?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: controller.user.value?.lastName ?? '',
    );
    final usernameController = TextEditingController(
      text: controller.user.value?.username ?? '',
    );
    final bioController = TextEditingController(
      text: controller.user.value?.bio ?? '',
    );
    final emailController = TextEditingController(
      text: controller.user.value?.email ?? '',
    );
    final phoneController = TextEditingController(
      text: controller.user.value?.phone ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppThemeSystem.darkBackgroundColor
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => TextButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        await controller.updateProfile(
                          firstName: firstNameController.text.trim().isEmpty
                              ? null
                              : firstNameController.text.trim(),
                          lastName: lastNameController.text.trim().isEmpty
                              ? null
                              : lastNameController.text.trim(),
                          username: usernameController.text.trim().isEmpty
                              ? null
                              : usernameController.text.trim(),
                          bio: bioController.text.trim().isEmpty
                              ? null
                              : bioController.text.trim(),
                          email: emailController.text.trim().isEmpty
                              ? null
                              : emailController.text.trim(),
                          phone: phoneController.text.trim().isEmpty
                              ? null
                              : phoneController.text.trim(),
                        );
                        // Go back if successful
                        if (!controller.isLoading.value) {
                          Get.back();
                        }
                      },
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Sauvegarder',
                        style: context.textStyle(FontSizeType.body1).copyWith(
                          color: AppThemeSystem.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar section
            Center(
              child: Stack(
                children: [
                  Obx(() {
                    final user = controller.user.value;
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: AppThemeSystem.primaryColor,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    );
                  }),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemeSystem.primaryColor,
                            AppThemeSystem.secondaryColor,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: controller.showAvatarPicker,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // First Name
            Text(
              'Prénom',
              style: context.textStyle(FontSizeType.body2).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                hintText: 'Votre prénom',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppThemeSystem.grey800
                    : AppThemeSystem.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Last Name
            Text(
              'Nom',
              style: context.textStyle(FontSizeType.body2).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                hintText: 'Votre nom',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppThemeSystem.grey800
                    : AppThemeSystem.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Username
            Text(
              'Nom d\'utilisateur',
              style: context.textStyle(FontSizeType.body2).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: 'Votre nom d\'utilisateur',
                prefixText: '@',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppThemeSystem.grey800
                    : AppThemeSystem.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bio
            Text(
              'Bio',
              style: context.textStyle(FontSizeType.body2).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bioController,
              maxLines: 4,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Parlez de vous...',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppThemeSystem.grey800
                    : AppThemeSystem.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Email
            Text(
              'Email',
              style: context.textStyle(FontSizeType.body2).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'votre@email.com',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppThemeSystem.grey800
                    : AppThemeSystem.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Phone
            Text(
              'Téléphone',
              style: context.textStyle(FontSizeType.body2).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+237 6XX XXX XXX',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppThemeSystem.grey800
                    : AppThemeSystem.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
