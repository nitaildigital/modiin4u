import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/m_account_widgets.dart';
import 'web_change_language_screen.dart';

/// Change Language screen – search bar, list of languages with flag
/// emoji + radio buttons, and a midBlue "Save" pill button.
class ChangeLanguageScreen extends ConsumerStatefulWidget {
  const ChangeLanguageScreen({super.key});

  @override
  ConsumerState<ChangeLanguageScreen> createState() =>
      _ChangeLanguageScreenState();
}

class _ChangeLanguageScreenState extends ConsumerState<ChangeLanguageScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  /// Only the two the app is actually translated into.
  ///
  /// The list used to offer eight — Spanish, French, German, Italian, Russian,
  /// Korean — none of which exist. Choosing one did nothing, which is worse
  /// than not offering it.
  static const _languages = <_LanguageItem>[
    _LanguageItem(
      'English (United States)',
      'assets/icons/m_account_flag_us.svg',
      'en',
    ),
    _LanguageItem('עברית (Hebrew)', 'assets/icons/m_account_flag_il.svg', 'he'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    final code = ref.read(localeProvider).languageCode;
    _selectedIndex = _languages.indexWhere((l) => l.code == code).clamp(0, 1);
  }

  void _apply() {
    final code = _languages[_selectedIndex].code;
    ref
        .read(localeProvider.notifier)
        .setLocale(supportedLocales.firstWhere((l) => l.languageCode == code));
    context.pop();
  }

  List<_LanguageItem> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _languages;
    return _languages.where((l) => l.name.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebChangeLanguageContent();
        }
        return _buildMobile(context);
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    final filtered = _filtered;

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
                      const MBackArrow(color: Color(0xFF3D3D3D)),
                      Expanded(
                        child: Center(
                          child: Text(
                            mTr(context, 'Change Language', 'שינוי שפה'),
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
                const SizedBox(height: 20),

                // ═══════════════════════════════════
                // Search bar (pill shape)
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        SvgPicture.asset(
                          'assets/icons/m_account_search.svg',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1F1F1F),
                            ),
                            decoration: InputDecoration(
                              hintText: mTr(context, 'Search', 'חיפוש'),
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6D6D6D),
                              ),
                              // The app theme fills fields grey and rings them on focus;
                              // this one sits inside its own bordered box.
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 39),

                // ═══════════════════════════════════
                // Language list
                // ═══════════════════════════════════
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final lang = filtered[index];
                      final originalIndex = _languages.indexOf(lang);
                      final selected = originalIndex == _selectedIndex;

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedIndex = originalIndex),
                        child: Container(
                          height: 57,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE7E7E7)),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Round flag, from the design
                              ClipOval(
                                child: SvgPicture.asset(
                                  lang.flag,
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Language name
                              Expanded(
                                child: Text(
                                  lang.name,
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0A1230),
                                  ),
                                ),
                              ),

                              // Radio button
                              _RadioDot(selected: selected),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ═══════════════════════════════════
                // Save button (pinned bottom)
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: GestureDetector(
                    onTap: _apply,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF123A72),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          mTr(context, 'Update Language', 'עדכון שפה'),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Data model
// ═══════════════════════════════════════════════

class _LanguageItem {
  /// The locale it maps to.
  final String code;

  final String name;

  /// The flag's SVG under `assets/icons/`.
  final String flag;
  const _LanguageItem(this.name, this.flag, this.code);
}

// ═══════════════════════════════════════════════
// Custom radio dot
// ═══════════════════════════════════════════════

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF123A72) : const Color(0xFFD1D1D1),
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
                  color: Color(0xFF123A72),
                ),
              ),
            )
          : null,
    );
  }
}
