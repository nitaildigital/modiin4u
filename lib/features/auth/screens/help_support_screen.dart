import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/web_chrome.dart' show kContactEmail;
import '../widgets/m_account_widgets.dart';
import 'web_help_support_screen.dart';

/// Help & Support screen – search bar, FAQ accordion list with
/// expandable items, and a "Contact Us" card at the bottom.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _searchController = TextEditingController();

  /// Which question is open, held by its text rather than by its position.
  /// The list is rebuilt in the reader's language on every build, so an index
  /// into it would point at a different question once the search narrows it.
  String? _expandedQuestion;

  /// The questions, in the reader's language.
  ///
  /// Two of the answers described screens that do not exist. One sent people
  /// to "Settings → Notifications" to toggle News, Deals, Neighbourhood
  /// Updates and Real Estate Alerts: Settings has no such row, nothing reads
  /// the `NotificationPreferences` model, and there is no preferences screen
  /// anywhere. That question is gone rather than answered wrongly. Another
  /// listed the Favourites filters as Restaurants, Events, Bars, Apartments
  /// and News; the real ones are businesses, events, news and property.
  static List<_FaqItem> _faqsFor(L l) => [
    _FaqItem(question: l.helpQEditProfile, answer: l.helpAEditProfile),
    _FaqItem(question: l.helpQPassword, answer: l.helpAPassword),
    _FaqItem(question: l.helpQLanguage, answer: l.helpALanguage),
    _FaqItem(question: l.helpQFavorites, answer: l.helpAFavorites),
    _FaqItem(question: l.helpQFindFavorites, answer: l.helpAFindFavorites),
    _FaqItem(question: l.helpQBusinesses, answer: l.helpABusinesses),
    _FaqItem(question: l.helpQEvents, answer: l.helpAEvents),
    _FaqItem(question: l.helpQRealEstate, answer: l.helpARealEstate),
    _FaqItem(question: l.helpQAccount, answer: l.helpAAccount),
  ];

  List<_FaqItem> _filteredFor(L l) {
    final q = _searchController.text.toLowerCase();
    final faqs = _faqsFor(l);
    if (q.isEmpty) return faqs;
    return faqs
        .where(
          (f) =>
              f.question.toLowerCase().contains(q) ||
              f.answer.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
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
          return const WebHelpSupportContent();
        }
        return _buildMobile(context);
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    final l = L.of(context);
    final filtered = _filteredFor(l);

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
                            l.helpTitle,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F1F1F),
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
                              hintText: l.helpSearchHint,
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
                const SizedBox(height: 10),

                // ═══════════════════════════════════
                // FAQ accordion list
                // ═══════════════════════════════════
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    children: [
                      // Searching for something with no answer used to leave
                      // a blank page under the box, which reads as a fault.
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            l.helpNoResults,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              color: const Color(0xFF6D6D6D),
                            ),
                          ),
                        ),
                      ...List.generate(filtered.length, (index) {
                        final faq = filtered[index];
                        final expanded = faq.question == _expandedQuestion;

                        return _FaqTile(
                          faq: faq,
                          expanded: expanded,
                          onTap: () => setState(() {
                            _expandedQuestion = expanded ? null : faq.question;
                          }),
                        );
                      }),

                      const SizedBox(height: 24),

                      // ═══════════════════════════════════
                      // Contact support card
                      // ═══════════════════════════════════
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F5FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/m_account_support.webp',
                              width: 58,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.helpContactTitle,
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l.helpContactBody,
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF6D6D6D),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    // The address the site footer has always
                                    // published, named in web_chrome.dart.
                                    onTap: () => launchUrl(
                                      Uri(
                                        scheme: 'mailto',
                                        path: kContactEmail,
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF123A72),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        l.helpContactButton,
                                        style: TextStyle(
                                          fontFamily: AppFonts.inter,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
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

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

// ═══════════════════════════════════════════════
// FAQ accordion tile
// ═══════════════════════════════════════════════

class _FaqTile extends StatelessWidget {
  final _FaqItem faq;
  final bool expanded;
  final VoidCallback onTap;

  const _FaqTile({
    required this.faq,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(
          color: expanded ? const Color(0xFFF0F5FD) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question row
            Row(
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: expanded ? FontWeight.w600 : FontWeight.w400,
                      color: const Color(0xFF0A1230),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Transform.flip(
                  flipY: expanded,
                  child: SvgPicture.asset(
                    'assets/icons/m_account_chevron.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ],
            ),

            // Answer (visible when expanded)
            if (expanded) ...[
              const SizedBox(height: 12),
              Text(
                faq.answer,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
