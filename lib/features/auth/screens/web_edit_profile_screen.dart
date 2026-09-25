import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../core/supabase/supabase_config.dart';

import '../../../core/constants/neighborhoods.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
// Web Edit Profile — desktop profile form
//
// A form does not want the full 1600: the column stays at 720 and the short
// answers pair across it, which is the one thing the extra width buys here.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kFieldBorder = Color(0xFFC6C6C6);
const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);
const _kLabel = Color(0xFF4F4F4F);

const _kFieldGap = 20.0;

/// The avatar gradient the mobile screen uses.
const _kAvatarGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0058B5), Color(0xFF010A36)],
);

class WebEditProfileContent extends ConsumerStatefulWidget {
  const WebEditProfileContent({super.key});

  @override
  ConsumerState<WebEditProfileContent> createState() =>
      _WebEditProfileContentState();
}

class _WebEditProfileContentState extends ConsumerState<WebEditProfileContent> {
  bool _isHebrew = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String? _selectedNeighborhood;

  /// Stored as the database key, not the label, so switching language does
  /// not change what is saved.
  String? _familyStatus;
  bool? _hasPet;
  DateTime? _dateOfBirth;
  Uint8List? _avatarBytes;

  /// Kept so the uploaded file keeps its own extension.
  String? _avatarName;
  bool _saving = false;

  static const _familyStatusKeys = ['single', 'married', 'divorced', 'widowed'];

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  String _familyStatusLabel(String key) => switch (key) {
    'single' => _t('Single', 'יחיד'),
    'married' => _t('Married', 'נשוי'),
    'divorced' => _t('Divorced', 'גרוש'),
    _ => _t('Widowed', 'אלמן'),
  };

  List<String> get _monthNames => _isHebrew
      ? const [
          'ינו',
          'פבר',
          'מרץ',
          'אפר',
          'מאי',
          'יונ',
          'יול',
          'אוג',
          'ספט',
          'אוק',
          'נוב',
          'דצמ',
        ]
      : const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

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
      if (mounted) {
        setState(() {
          _avatarBytes = bytes;
          _avatarName = image.name;
        });
      }
    }
  }

  /// Puts the chosen photograph in storage and returns its address. The
  /// picker showed the image and `_save` never sent it anywhere; migration
  /// 00026 scopes the `media` bucket to `avatars/<your id>/`.
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

  /// The edit goes to the database, so the page stays open until the write
  /// lands rather than leaving on an unsaved change.
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
      if (mounted) _leave();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Could not save. Try again.', 'לא ניתן היה לשמור. נסו שוב.'),
            style: TextStyle(fontFamily: AppFonts.inter),
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

  /// A browser tab opened straight on /edit-profile has nothing to pop back
  /// to, so it goes to the profile page instead.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    // The wrapper screen sends a signed-out visitor to sign in; a null here
    // means that redirect is still a frame away.
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: null,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    WebSection(
                      child: Center(
                        child: SizedBox(
                          width: 720,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(user.initials),
                              const SizedBox(height: 32),
                              _buildFormCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                    WebFooter(isHebrew: _isHebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER — the avatar beside the title, not above it
  // ─────────────────────────────────────────────
  Widget _buildHeader(String initials) {
    return Row(
      children: [
        _buildAvatar(initials),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Edit Profile', 'עריכת פרופיל'),
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: _kHeading,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t(
                  'Your details, and the picture people see beside your name.',
                  'הפרטים שלכם, והתמונה שמופיעה ליד השם.',
                ),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _kGreyText,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String initials) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _pickAvatar,
        child: SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _kAvatarGradient,
                ),
                child: _avatarBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _avatarBytes!,
                          fit: BoxFit.cover,
                          width: 104,
                          height: 104,
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      IconsaxPlusLinear.edit_2,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FORM
  // ─────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  _t('Full Name', 'שם מלא'),
                  _nameController,
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(
                child: _buildTextField(_t('Email', 'אימייל'), _emailController),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  _t('Phone', 'טלפון'),
                  _phoneController,
                  placeholder: _t('Enter your phone', 'הזינו טלפון'),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(
                child: _buildDropdownField(
                  label: _t('Neighborhood', 'שכונה'),
                  value: _selectedNeighborhood,
                  options: neighborhoods.map((n) => n.name).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedNeighborhood = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: _t('Family Status', 'מצב משפחתי'),
                  value: _familyStatus == null
                      ? null
                      : _familyStatusLabel(_familyStatus!),
                  options: _familyStatusKeys.map(_familyStatusLabel).toList(),
                  onChanged: (val) => setState(() {
                    _familyStatus = _familyStatusKeys.firstWhere(
                      (k) => _familyStatusLabel(k) == val,
                    );
                  }),
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(
                child: _buildDropdownField(
                  label: _t('Do you have a pet?', 'יש לכם חיית מחמד?'),
                  value: _hasPet == null
                      ? null
                      : (_hasPet! ? _t('Yes', 'כן') : _t('No', 'לא')),
                  options: [_t('Yes', 'כן'), _t('No', 'לא')],
                  onChanged: (val) =>
                      setState(() => _hasPet = val == _t('Yes', 'כן')),
                ),
              ),
              const SizedBox(width: _kFieldGap),
              Expanded(child: _buildDateField()),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              SizedBox(
                width: 220,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.midBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.midBlue.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _t('Save Changes', 'שמירת שינויים'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _saving ? null : _leave,
                  child: Text(
                    _t('Cancel', 'ביטול'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kGreyText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _kLabel,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? placeholder,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kFieldBorder),
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
                color: _kGreyText,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kFieldBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : null,
              isExpanded: true,
              hint: Text(
                _t('Select', 'בחרו'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
              icon: const Icon(
                IconsaxPlusLinear.arrow_down_1,
                size: 20,
                color: _kGreyText,
              ),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              items: options
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
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

  Widget _buildDateField() {
    final date = _dateOfBirth;
    final value = date == null
        ? ''
        : '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(_t('Date of Birth', 'תאריך לידה')),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth ?? DateTime(1990),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dateOfBirth = picked);
            },
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _kFieldBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isEmpty ? _t('Select', 'בחרו') : value,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: value.isEmpty
                            ? const Color(0xFF9E9E9E)
                            : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    IconsaxPlusLinear.calendar_1,
                    size: 18,
                    color: _kGreyText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
