import 'dart:typed_data';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../core/supabase/supabase_config.dart';
import '../../../core/constants/neighborhoods.dart';
import '../../../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'web_edit_profile_screen.dart';

/// Edit Profile screen – avatar with camera overlay, form fields
/// (name, email, phone, neighborhood, family status, pet, DOB),
/// and a midBlue "Save Changes" button.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _selectedNeighborhood;

  /// Stored as the database key, not the label, so switching language does
  /// not change what is saved. Null until the person answers — the screen
  /// used to open on 'Married' / 'Yes' / '12 May 1990' for everybody.
  String? _familyStatus;
  bool? _hasPet;
  DateTime? _dateOfBirth;
  Uint8List? _avatarBytes;

  /// Kept so the uploaded file keeps its own extension.
  String? _avatarName;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedNeighborhood = user?.neighborhood;
    _familyStatus = user?.familyStatus;
    _hasPet = user?.hasPet;
    _dateOfBirth = user?.dateOfBirth;
  }

  static const _familyStatusKeys = ['single', 'married', 'divorced', 'widowed'];

  static String _familyStatusLabel(L l, String key) => switch (key) {
    'single' => l.single,
    'married' => l.married,
    'divorced' => l.divorced,
    _ => l.widowed,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
        _avatarName = image.name;
      });
    }
  }

  /// Puts the chosen photograph in storage and returns its address.
  ///
  /// The picker has always shown the image straight away, and `_save` never
  /// sent it anywhere — someone picked a photograph, watched it appear, saved,
  /// and found it gone next time. Migration 00026 scopes the `media` bucket to
  /// `avatars/<your id>/`, which is the path built here.
  Future<String?> _uploadAvatar() async {
    final bytes = _avatarBytes;
    if (bytes == null) return null;

    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) return null;

    final dot = (_avatarName ?? '').lastIndexOf('.');
    final raw = dot == -1
        ? '.jpg'
        : (_avatarName ?? '').substring(dot).toLowerCase();
    final ext = const {'.jpg', '.jpeg', '.png', '.webp'}.contains(raw)
        ? raw
        : '.jpg';

    final path = 'avatars/$uid/${DateTime.now().microsecondsSinceEpoch}$ext';

    await SupabaseConfig.client.storage
        .from('media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: switch (ext) {
              '.png' => 'image/png',
              '.webp' => 'image/webp',
              _ => 'image/jpeg',
            },
            upsert: false,
          ),
        );

    return SupabaseConfig.client.storage.from('media').getPublicUrl(path);
  }

  bool _saving = false;

  /// The edit now goes to the database, so the screen stays open until the
  /// write lands rather than closing on an unsaved change.
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final avatarUrl = await _uploadAvatar();

      await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            neighborhood: _selectedNeighborhood,
            avatarUrl: avatarUrl,
            familyStatus: _familyStatus,
            hasPet: _hasPet,
            dateOfBirth: _dateOfBirth,
          );
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'לא ניתן היה לשמור. נסו שוב.',
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final user = ref.watch(authProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.pushReplacement('/login'),
      );
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebEditProfileContent();
        return _buildMobile(context, l, user);
      },
    );
  }

  /// The phone layout, which a laptop was also given — capped at 430px and
  /// centred in white.
  Widget _buildMobile(BuildContext context, L l, UserModel user) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ═══════════════════════════════════
                // Back button + title
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            IconsaxPlusLinear.arrow_left,
                            size: 24,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            l.editProfile,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ═══════════════════════════════════
                // Avatar with camera overlay
                // ═══════════════════════════════════
                GestureDetector(
                  onTap: _pickAvatar,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                            ),
                          ),
                          child: _avatarBytes != null
                              ? ClipOval(
                                  child: Image.memory(
                                    _avatarBytes!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    user.initials,
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                        // Edit icon – bottom-right
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF123A72),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                IconsaxPlusLinear.edit_2,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ═══════════════════════════════════
                // Form fields
                // ═══════════════════════════════════
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        _buildTextField(l.fullName, _nameController),
                        const SizedBox(height: 20),

                        // Email
                        _buildTextField(l.email, _emailController),
                        const SizedBox(height: 20),

                        // Phone
                        _buildTextField(
                          l.phone,
                          _phoneController,
                          placeholder: l.enterYourPhone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),

                        // Neighborhood (dropdown)
                        _buildDropdownField(
                          label: l.neighborhood,
                          value: _selectedNeighborhood,
                          options: neighborhoods.map((n) => n.name).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedNeighborhood = val),
                        ),
                        const SizedBox(height: 20),

                        // Family Status + Pet (side by side)
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: l.familyStatus,
                                value: _familyStatus == null
                                    ? null
                                    : _familyStatusLabel(l, _familyStatus!),
                                options: _familyStatusKeys
                                    .map((k) => _familyStatusLabel(l, k))
                                    .toList(),
                                onChanged: (val) => setState(() {
                                  _familyStatus = _familyStatusKeys.firstWhere(
                                    (k) => _familyStatusLabel(l, k) == val,
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildDropdownField(
                                label: l.doYouHaveAPet,
                                value: _hasPet == null
                                    ? null
                                    : (_hasPet! ? l.yes : l.no),
                                options: [l.yes, l.no],
                                onChanged: (val) =>
                                    setState(() => _hasPet = val == l.yes),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Date of Birth
                        _buildDateField(
                          l.dateOfBirth,
                          _dateOfBirth == null
                              ? ''
                              : '${_dateOfBirth!.day} '
                                    '${l.monthShort(_dateOfBirth!.month)} '
                                    '${_dateOfBirth!.year}',
                        ),
                        const SizedBox(height: 32),

                        // ═══════════════════════════════════
                        // Save button
                        // ═══════════════════════════════════
                        GestureDetector(
                          onTap: _save,
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF123A72),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Center(
                              child: Text(
                                l.saveChanges,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Text input field
  // ═══════════════════════════════════════════════
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? placeholder,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4F4F4F),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC6C6C6)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F1F1F),
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6D6D6D),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Dropdown field with chevron
  // ═══════════════════════════════════════════════
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4F4F4F),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC6C6C6)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : null,
              isExpanded: true,
              hint: Text(
                L.of(context).selectHint,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
              icon: const Icon(
                IconsaxPlusLinear.arrow_down_1,
                size: 20,
                color: Color(0xFF6D6D6D),
              ),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF000000),
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Date field with calendar icon
  // ═══════════════════════════════════════════════
  Widget _buildDateField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4F4F4F),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dateOfBirth ?? DateTime(1990),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
            );
            if (date != null) setState(() => _dateOfBirth = date);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFC6C6C6)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? L.of(context).selectHint : value,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: value.isEmpty
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF000000),
                    ),
                  ),
                ),
                const Icon(
                  IconsaxPlusLinear.calendar_1,
                  size: 20,
                  color: Color(0xFF6D6D6D),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
