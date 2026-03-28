import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../../../data/models/group_category_model.dart';
import '../../../data/services/group_service.dart';
import '../controllers/groupe_controller.dart';

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _formKey = GlobalKey<FormState>();
  final _groupService = GroupService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '50');
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isPublic = false;
  bool _isDiscoverable = true;
  GroupCategoryModel? _selectedCategory;
  List<GroupCategoryModel> _categories = [];
  File? _avatarImage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _groupService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // Silently fail
    }
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
          _avatarImage = File(pickedFile.path);
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
          _avatarImage = File(pickedFile.path);
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

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final maxMembers = int.tryParse(_maxMembersController.text.trim());

      final group = await _groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        categoryId: _selectedCategory?.id,
        isPublic: _isPublic,
        isDiscoverable: _isDiscoverable,
        maxMembers: maxMembers,
        avatarFile: _avatarImage,
      );

      // Ajouter le groupe créé à la liste "Mes groupes"
      final groupeController = Get.find<GroupeController>();
      groupeController.myGroups.insert(0, group);

      // Retour en arrière avec succès
      Get.back();

      Get.snackbar(
        'Succès',
        'Groupe créé avec succès!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.successColor,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de la création du groupe.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Créer un groupe',
          style: context.textStyle(FontSizeType.h5).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: context.primaryTextColor,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.horizontalPadding * 2),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo du groupe (optionnelle)
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _avatarImage == null
                          ? AppThemeSystem.tertiaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: AppThemeSystem.tertiaryColor,
                        width: 3,
                      ),
                    ),
                    child: _avatarImage != null
                        ? ClipOval(
                            child: Image.file(
                              _avatarImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 40,
                                color: AppThemeSystem.tertiaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ajouter photo',
                                style: context.textStyle(FontSizeType.caption).copyWith(
                                  color: AppThemeSystem.tertiaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Nom du groupe
              Text(
                'Nom du groupe *',
                style: context.textStyle(FontSizeType.subtitle2).copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ex: Développeurs Flutter',
                  hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppThemeSystem.grey800.withValues(alpha: 0.4)
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
                style: context.textStyle(FontSizeType.body2),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  if (value.trim().length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                'Description',
                style: context.textStyle(FontSizeType.subtitle2).copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Décrivez votre groupe...',
                  hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppThemeSystem.grey800.withValues(alpha: 0.4)
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
                style: context.textStyle(FontSizeType.body2),
                maxLines: 4,
                maxLength: 500,
              ),

              const SizedBox(height: 20),

              // Catégorie
              Text(
                'Catégorie',
                style: context.textStyle(FontSizeType.subtitle2).copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<GroupCategoryModel>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  hintText: 'Sélectionnez une catégorie',
                  hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppThemeSystem.grey800.withValues(alpha: 0.4)
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
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: context.primaryTextColor,
                ),
                dropdownColor: context.surfaceColor,
                items: _categories.map((category) {
                  return DropdownMenuItem<GroupCategoryModel>(
                    value: category,
                    child: Row(
                      children: [
                        if (category.iconData != null)
                          Icon(
                            category.iconData,
                            size: 20,
                            color: _parseColor(category.color ?? '#9E9E9E'),
                          )
                        else
                          Text(
                            category.emojiIcon,
                            style: const TextStyle(fontSize: 18),
                          ),
                        const SizedBox(width: 12),
                        Text(
                          category.name,
                          style: context.textStyle(FontSizeType.body2),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Nombre maximum de membres
              Text(
                'Nombre maximum de membres',
                style: context.textStyle(FontSizeType.subtitle2).copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _maxMembersController,
                decoration: InputDecoration(
                  hintText: '50',
                  hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                  prefixIcon: const Icon(
                    Icons.people_outline_rounded,
                    color: AppThemeSystem.tertiaryColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppThemeSystem.grey800.withValues(alpha: 0.4)
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
                style: context.textStyle(FontSizeType.body2),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nombre de membres est requis';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  if (number < 2) {
                    return 'Le minimum est de 2 membres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Type de groupe (Public/Privé)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppThemeSystem.grey800.withValues(alpha: 0.3)
                      : AppThemeSystem.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppThemeSystem.grey700.withValues(alpha: 0.3)
                        : AppThemeSystem.grey200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type de groupe',
                      style: context.textStyle(FontSizeType.subtitle2).copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isPublic = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: !_isPublic
                                    ? AppThemeSystem.tertiaryColor.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !_isPublic
                                      ? AppThemeSystem.tertiaryColor
                                      : context.borderColor,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    color: !_isPublic
                                        ? AppThemeSystem.tertiaryColor
                                        : context.secondaryTextColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Privé',
                                    style: context.textStyle(FontSizeType.body2).copyWith(
                                      fontWeight: !_isPublic ? FontWeight.w600 : FontWeight.normal,
                                      color: !_isPublic
                                          ? AppThemeSystem.tertiaryColor
                                          : context.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isPublic = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _isPublic
                                    ? AppThemeSystem.successColor.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isPublic
                                      ? AppThemeSystem.successColor
                                      : context.borderColor,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.public_rounded,
                                    color: _isPublic
                                        ? AppThemeSystem.successColor
                                        : context.secondaryTextColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Public',
                                    style: context.textStyle(FontSizeType.body2).copyWith(
                                      fontWeight: _isPublic ? FontWeight.w600 : FontWeight.normal,
                                      color: _isPublic
                                          ? AppThemeSystem.successColor
                                          : context.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Option pour les groupes privés : apparaître dans la recherche
              if (!_isPublic) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppThemeSystem.grey800.withValues(alpha: 0.3)
                        : AppThemeSystem.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppThemeSystem.grey700.withValues(alpha: 0.3)
                          : AppThemeSystem.grey200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Apparaître dans la recherche',
                              style: context.textStyle(FontSizeType.subtitle2).copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Les utilisateurs peuvent trouver ce groupe privé dans la recherche, mais doivent utiliser un code pour rejoindre.',
                              style: context.textStyle(FontSizeType.caption).copyWith(
                                color: context.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isDiscoverable,
                        onChanged: (value) {
                          setState(() {
                            _isDiscoverable = value;
                          });
                        },
                        activeColor: AppThemeSystem.tertiaryColor,
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: context.sectionSpacing),

              // Bouton de création
              Container(
                width: double.infinity,
                height: context.buttonHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppThemeSystem.tertiaryColor,
                      AppThemeSystem.primaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _createGroup,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Créer le groupe',
                              style: context.textStyle(FontSizeType.button).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Parser la couleur hexadécimale
  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppThemeSystem.grey500;
    }
  }
}
