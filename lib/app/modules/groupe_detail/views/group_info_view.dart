import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/group_model.dart';
import '../../../widgets/app_theme_system.dart';
import '../../../widgets/group_avatar.dart';
import '../controllers/groupe_detail_controller.dart';

class GroupInfoView extends StatefulWidget {
  final GroupModel group;

  const GroupInfoView({super.key, required this.group});

  @override
  State<GroupInfoView> createState() => _GroupInfoViewState();
}

class _GroupInfoViewState extends State<GroupInfoView> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxMembersController;
  final _imagePicker = ImagePicker();

  File? _newAvatarImage;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description ?? '');
    _maxMembersController = TextEditingController(text: widget.group.maxMembers.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    _showImageSourceBottomSheet();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _newAvatarImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de sélectionner l\'image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _newAvatarImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de prendre la photo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
    }
  }

  void _showImageSourceBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          context.horizontalPadding * 2,
          context.elementSpacing * 2,
          context.horizontalPadding * 2,
          MediaQuery.of(context).viewPadding.bottom + context.elementSpacing * 2,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              context.borderRadius(BorderRadiusType.large).topLeft.x,
            ),
            topRight: Radius.circular(
              context.borderRadius(BorderRadiusType.large).topRight.x,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de défilement
            Container(
              width: deviceType == DeviceType.mobile ? 40 : 60,
              height: deviceType == DeviceType.mobile ? 4 : 5,
              margin: EdgeInsets.only(bottom: context.elementSpacing),
              decoration: BoxDecoration(
                color: isDark
                    ? AppThemeSystem.grey700
                    : AppThemeSystem.grey300,
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            // Titre
            Text(
              'Choisir une photo',
              style: context.textStyle(FontSizeType.h5).copyWith(
                fontWeight: FontWeight.bold,
                color: context.primaryTextColor,
              ),
            ),

            SizedBox(height: context.elementSpacing * 1.5),

            // Option Galerie
            _buildImageSourceOption(
              context: context,
              icon: Icons.photo_library_rounded,
              title: 'Galerie',
              subtitle: 'Choisir une photo existante',
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
              isDark: isDark,
            ),

            SizedBox(height: context.elementSpacing),

            // Option Caméra
            _buildImageSourceOption(
              context: context,
              icon: Icons.camera_alt_rounded,
              title: 'Caméra',
              subtitle: 'Prendre une nouvelle photo',
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
              isDark: isDark,
            ),

            SizedBox(height: context.elementSpacing),

            // Bouton Annuler
            Container(
              width: double.infinity,
              height: context.buttonHeight,
              decoration: BoxDecoration(
                color: isDark
                    ? AppThemeSystem.grey800.withValues(alpha: 0.5)
                    : AppThemeSystem.grey100,
                borderRadius: context.borderRadius(BorderRadiusType.medium),
                border: Border.all(
                  color: isDark
                      ? AppThemeSystem.grey700
                      : AppThemeSystem.grey300,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: context.borderRadius(BorderRadiusType.medium),
                  child: Center(
                    child: Text(
                      'Annuler',
                      style: context.textStyle(FontSizeType.button).copyWith(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? AppThemeSystem.grey800.withValues(alpha: 0.6)
                : Colors.white,
            isDark
                ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                : AppThemeSystem.grey50,
          ],
        ),
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: Border.all(
          color: isDark
              ? AppThemeSystem.grey700.withValues(alpha: 0.5)
              : AppThemeSystem.grey300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: context.borderRadius(BorderRadiusType.medium),
          child: Padding(
            padding: EdgeInsets.all(context.elementSpacing * 1.5),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.elementSpacing),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppThemeSystem.tertiaryColor,
                        AppThemeSystem.secondaryColor,
                      ],
                    ),
                    borderRadius: context.borderRadius(BorderRadiusType.medium),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: context.deviceType == DeviceType.mobile ? 24 : 28,
                  ),
                ),
                SizedBox(width: context.elementSpacing * 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textStyle(FontSizeType.subtitle1).copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.primaryTextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: context.textStyle(FontSizeType.body2).copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.secondaryTextColor,
                  size: context.deviceType == DeviceType.mobile ? 24 : 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Erreur',
        'Le nom du groupe ne peut pas être vide',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
      return;
    }

    final controller = Get.find<GroupeDetailController>();

    // TODO: Implement update with avatar upload
    // For now, just update name and description
    await controller.updateGroupInfo(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      maxMembers: int.tryParse(_maxMembersController.text.trim()),
      avatarFile: _newAvatarImage,
    );

    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCreator = widget.group.isCreator;

    return Scaffold(
      backgroundColor: isDark ? AppThemeSystem.darkBackgroundColor : AppThemeSystem.grey100,
      appBar: AppBar(
        title: const Text('Informations du groupe'),
        actions: [
          if (isCreator)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _saveChanges();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          context.horizontalPadding * 2,
          context.verticalPadding,
          context.horizontalPadding * 2,
          MediaQuery.of(context).viewPadding.bottom + context.verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: GestureDetector(
                onTap: isCreator && _isEditing ? _pickImage : null,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppThemeSystem.tertiaryColor,
                          width: 3,
                        ),
                      ),
                      child: _newAvatarImage != null
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: FileImage(_newAvatarImage!),
                            )
                          : GroupAvatar(
                              group: widget.group,
                              radius: 60,
                            ),
                    ),
                    if (isCreator && _isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppThemeSystem.tertiaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.sectionSpacing),

            // Name
            _buildInfoCard(
              context,
              title: 'Nom du groupe',
              child: _isEditing && isCreator
                  ? TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nom du groupe',
                      ),
                      maxLength: 100,
                    )
                  : Text(
                      widget.group.name,
                      style: context.textStyle(FontSizeType.h6).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            SizedBox(height: context.elementSpacing),

            // Description
            _buildInfoCard(
              context,
              title: 'Description',
              child: _isEditing && isCreator
                  ? TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Description du groupe',
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    )
                  : Text(
                      widget.group.description ?? 'Aucune description',
                      style: context.textStyle(FontSizeType.body1).copyWith(
                        color: AppThemeSystem.grey600,
                      ),
                    ),
            ),

            SizedBox(height: context.elementSpacing),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.people,
                    label: 'Membres',
                    value: '${widget.group.membersCount}',
                  ),
                ),
                SizedBox(width: context.elementSpacing),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.message,
                    label: 'Messages',
                    value: '${widget.group.messagesCount ?? 0}',
                  ),
                ),
              ],
            ),

            SizedBox(height: context.elementSpacing),

            // Max Members
            _buildInfoCard(
              context,
              title: 'Limite de membres',
              child: _isEditing && isCreator
                  ? TextField(
                      controller: _maxMembersController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nombre maximum de membres',
                      ),
                      keyboardType: TextInputType.number,
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.group,
                          color: AppThemeSystem.tertiaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.group.maxMembers} membres max',
                          style: context.textStyle(FontSizeType.body1),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: context.elementSpacing),

            // Visibility
            _buildInfoCard(
              context,
              title: 'Visibilité',
              child: Row(
                children: [
                  Icon(
                    widget.group.isPublic ? Icons.public : Icons.lock,
                    color: AppThemeSystem.tertiaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.group.isPublic ? 'Groupe public' : 'Groupe privé',
                    style: context.textStyle(FontSizeType.body1),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.elementSpacing),

            // Posting Permission (Admin/Creator only)
            if (isCreator || widget.group.isAdmin)
              GetBuilder<GroupeDetailController>(
                builder: (controller) => Obx(() {
                  final currentGroup = controller.group.value ?? widget.group;
                  return _buildInfoCard(
                    context,
                    title: 'Qui peut poster',
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'everyone',
                          groupValue: currentGroup.postingPermission,
                          onChanged: isCreator || currentGroup.isAdmin
                              ? (value) {
                                  if (value != null) {
                                    controller.updatePostingPermission(value);
                                  }
                                }
                              : null,
                          title: const Text('Tout le monde'),
                          subtitle: const Text('Tous les membres peuvent poster'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<String>(
                          value: 'admins_only',
                          groupValue: currentGroup.postingPermission,
                          onChanged: isCreator || currentGroup.isAdmin
                              ? (value) {
                                  if (value != null) {
                                    controller.updatePostingPermission(value);
                                  }
                                }
                              : null,
                          title: const Text('Administrateurs seulement'),
                          subtitle: const Text('Seuls les admins peuvent poster'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  );
                }),
              ),

            SizedBox(height: context.elementSpacing),

            // Invite Code
            _buildInfoCard(
              context,
              title: 'Code d\'invitation',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.group.inviteCode,
                      style: context.textStyle(FontSizeType.body1).copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      // TODO: Copy to clipboard
                      Get.snackbar(
                        'Succès',
                        'Code copié dans le presse-papier',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppThemeSystem.successColor,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: context.elementSpacing),

            // Created Date
            _buildInfoCard(
              context,
              title: 'Créé le',
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppThemeSystem.tertiaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(widget.group.createdAt),
                    style: context.textStyle(FontSizeType.body1),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.sectionSpacing),

            // Action Buttons
            if (isCreator) ...[
              _buildActionButton(
                context,
                label: 'Supprimer le groupe',
                icon: Icons.delete,
                color: Colors.red,
                onPressed: () {
                  Get.back();
                  _showDeleteConfirmation(context);
                },
              ),
            ] else ...[
              _buildActionButton(
                context,
                label: 'Signaler le groupe',
                icon: Icons.flag,
                color: Colors.orange,
                onPressed: () {
                  Get.back();
                  _showReportDialog(context);
                },
              ),
              SizedBox(height: context.elementSpacing),
              _buildActionButton(
                context,
                label: 'Quitter le groupe',
                icon: Icons.exit_to_app,
                color: Colors.grey,
                onPressed: () {
                  Get.back();
                  _showLeaveConfirmation(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.elementSpacing * 1.3),
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textStyle(FontSizeType.caption).copyWith(
              color: AppThemeSystem.grey600,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.elementSpacing * 0.7),
          child,
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String label, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Container(
      padding: EdgeInsets.all(context.elementSpacing * 1.3),
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppThemeSystem.tertiaryColor,
            size: deviceType == DeviceType.mobile ? 28 : 32,
          ),
          SizedBox(height: context.elementSpacing * 0.7),
          Text(
            value,
            style: context.textStyle(FontSizeType.h5).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.elementSpacing * 0.3),
          Text(
            label,
            style: context.textStyle(FontSizeType.caption).copyWith(
              color: AppThemeSystem.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final deviceType = context.deviceType;

    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: color,
          size: deviceType == DeviceType.mobile ? 20 : 24,
        ),
        label: Text(
          label,
          style: context.textStyle(FontSizeType.button).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: context.borderRadius(BorderRadiusType.medium),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showDeleteConfirmation(BuildContext context) {
    final controller = Get.find<GroupeDetailController>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le groupe ?'),
          content: const Text(
            'Cette action est irréversible. Le groupe et tous ses messages seront supprimés définitivement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.deleteGroup();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    final controller = Get.find<GroupeDetailController>();
    String selectedReason = 'spam';
    final descriptionController = TextEditingController();

    final reasons = {
      'spam': 'Spam',
      'harassment': 'Harcèlement',
      'inappropriate_content': 'Contenu inapproprié',
      'hate_speech': 'Discours haineux',
      'violence': 'Violence',
      'other': 'Autre',
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Signaler le groupe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Raison du signalement :'),
                    const SizedBox(height: 12),
                    ...reasons.entries.map((entry) {
                      return RadioListTile<String>(
                        title: Text(entry.value),
                        value: entry.key,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedReason = value;
                            });
                          }
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                        hintText: 'Donnez plus de détails...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 1000,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    controller.reportGroup(
                      selectedReason,
                      descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Signaler'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLeaveConfirmation(BuildContext context) {
    final controller = Get.find<GroupeDetailController>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quitter le groupe ?'),
          content: const Text('Vous ne recevrez plus les messages de ce groupe.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.leaveGroup();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );
  }
}
