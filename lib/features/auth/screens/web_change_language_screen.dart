import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Change Language — desktop
//
// Two choices and a Save button, in a card the width of a form. The phone
// screen puts a search box above the list; over two items it filters
// nothing, so at this width the two simply sit there to be read.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);

const _kCardWidth = 520.0;

/// Only the two the app is actually translated into — the same pair the phone
/// screen offers, for the same reason.
const _languages = <_LanguageItem>[
  _LanguageItem(name: 'עברית', english: 'Hebrew', flag: '🇮🇱', code: 'he'),
  _LanguageItem(name: 'English', english: 'English', flag: '🇺🇸', code: 'en'),
];

class WebChangeLanguageContent extends ConsumerStatefulWidget {
  const WebChangeLanguageContent({super.key});

  @override
  ConsumerState<WebChangeLanguageContent> createState() =>
      _WebChangeLanguageContentState();
}

class _WebChangeLanguageContentState
    extends ConsumerState<WebChangeLanguageContent> {
  bool _isHebrew = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final code = ref.read(localeProvider).languageCode;
    _selectedIndex = _languages.indexWhere((l) => l.code == code).clamp(0, 1);
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// Writes the choice through the same provider the phone screen uses.
  void _apply() {
    final code = _languages[_selectedIndex].code;
    ref
        .read(localeProvider.notifier)
        .setLocale(supportedLocales.firstWhere((l) => l.languageCode == code));
    _back();
  }

  /// A browser tab opened straight on /change-language has nothing to pop
  /// back to, so it falls back to the page the row lives on.
  void _back() => context.canPop() ? context.pop() : context.go('/settings');

  @override
  Widget build(BuildContext context) {
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
                          width: _kCardWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBackLink(),
                              const SizedBox(height: 24),
                              _buildCard(),
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

  Widget _buildBackLink() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _back,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isHebrew
                  ? IconsaxPlusLinear.arrow_right_3
                  : IconsaxPlusLinear.arrow_left,
              size: 20,
              color: AppColors.midBlue,
            ),
            const SizedBox(width: 8),
            Text(
              _t('Back to Settings', 'חזרה להגדרות'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.midBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.midBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.global,
              size: 32,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _t('Language', 'שפה'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: _kHeading,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              'The app and this site are shown in the language you choose.',
              'האפליקציה והאתר יוצגו בשפה שתבחרו.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(_languages.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _languages.length - 1 ? 0 : 12,
              ),
              child: _LanguageOption(
                item: _languages[index],
                selected: index == _selectedIndex,
                onTap: () => setState(() => _selectedIndex = index),
              ),
            );
          }),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: Text(
                _t('Save', 'שמירה'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════

class _LanguageItem {
  final String name, english, flag;

  /// The locale it maps to.
  final String code;

  const _LanguageItem({
    required this.name,
    required this.english,
    required this.flag,
    required this.code,
  });
}

// ═══════════════════════════════════════════════
// OPTION ROW
// ═══════════════════════════════════════════════

class _LanguageOption extends StatefulWidget {
  final _LanguageItem item;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_LanguageOption> createState() => _LanguageOptionState();
}

class _LanguageOptionState extends State<_LanguageOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.midBlue.withValues(alpha: 0.04)
                : (_hovered ? AppColors.surfaceLight : Colors.white),
            border: Border.all(
              color: selected ? AppColors.midBlue : _kBorder,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(widget.item.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.english,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: _kGreyText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.midBlue
                        : const Color(0xFFD1D1D1),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.midBlue,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
