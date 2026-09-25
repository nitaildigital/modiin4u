import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Help & Support — desktop
//
// The same nine questions the phone screen answers, in a column wide enough
// that an open answer is two or three lines rather than seven. The search box
// runs the full width of that column, and the contact card sits at the end
// where a reader who found no answer arrives.
//
// The accordion stays one column: two columns of it reflow every time a
// question opens, and the reader loses their place.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);
const _kExpandedBg = Color(0xFFF0F5FD);

const _kColumnWidth = 800.0;

class WebHelpSupportContent extends StatefulWidget {
  const WebHelpSupportContent({super.key});

  @override
  State<WebHelpSupportContent> createState() => _WebHelpSupportContentState();
}

class _WebHelpSupportContentState extends State<WebHelpSupportContent> {
  bool _isHebrew = false;
  final _searchController = TextEditingController();

  /// Which question is open, held by its text rather than by its position:
  /// the list is rebuilt on every build, so an index into it would point at a
  /// different question once the search narrows it.
  String? _expandedQuestion;

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

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The questions and answers were translated into the ARB, so they are read
  /// from there rather than written out twice here. The navbar's toggle is
  /// this page's own rather than the app's locale, so both tables are held
  /// and the page reads whichever one it is currently being read in — built
  /// once each, not on every frame.
  static final _en = lookupL(const Locale('en'));
  static final _he = lookupL(const Locale('he'));

  L get _l => _isHebrew ? _he : _en;

  List<_FaqItem> _faqs(L l) => [
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

  List<_FaqItem> _filtered(L l) {
    final q = _searchController.text.toLowerCase();
    final faqs = _faqs(l);
    if (q.isEmpty) return faqs;
    return faqs
        .where(
          (f) =>
              f.question.toLowerCase().contains(q) ||
              f.answer.toLowerCase().contains(q),
        )
        .toList();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/settings');

  @override
  Widget build(BuildContext context) {
    final l = _l;
    final filtered = _filtered(l);

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
                          width: _kColumnWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBackLink(),
                              const SizedBox(height: 24),
                              _buildHeader(l),
                              const SizedBox(height: 32),
                              _buildSearchBar(l),
                              const SizedBox(height: 32),
                              if (filtered.isEmpty)
                                _buildNoResults(l)
                              else
                                ...filtered.map(
                                  (faq) => _FaqTile(
                                    faq: faq,
                                    expanded: faq.question == _expandedQuestion,
                                    onTap: () => setState(() {
                                      _expandedQuestion =
                                          faq.question == _expandedQuestion
                                          ? null
                                          : faq.question;
                                    }),
                                  ),
                                ),
                              const SizedBox(height: 40),
                              _buildContactCard(l),
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

  Widget _buildHeader(L l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.helpTitle,
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
          _t('The questions we are asked most often.', 'השאלות הנפוצות ביותר.'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(L l) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 20,
            color: _kGreyText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                color: const Color(0xFF1F1F1F),
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: l.helpSearchHint,
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  color: _kGreyText,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _searchController.clear,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    IconsaxPlusLinear.close_circle,
                    size: 20,
                    color: _kGreyText,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  /// Searching for something with no answer used to leave a blank page under
  /// the box, which reads as a fault.
  Widget _buildNoResults(L l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        l.helpNoResults,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 15,
          color: _kGreyText,
        ),
      ),
    );
  }

  Widget _buildContactCard(L l) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
            child: const Center(
              child: Icon(
                IconsaxPlusLinear.headphone,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.helpContactTitle,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.helpContactBody,
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
          const SizedBox(width: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              // The address the site footer has always published, named in
              // web_chrome.dart — the same handler the phone screen uses.
              onPressed: () =>
                  launchUrl(Uri(scheme: 'mailto', path: kContactEmail)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: Text(
                l.helpContactButton,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
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

class _FaqItem {
  final String question, answer;
  const _FaqItem({required this.question, required this.answer});
}

// ═══════════════════════════════════════════════
// ACCORDION TILE
// ═══════════════════════════════════════════════

class _FaqTile extends StatefulWidget {
  final _FaqItem faq;
  final bool expanded;
  final VoidCallback onTap;

  const _FaqTile({
    required this.faq,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final expanded = widget.expanded;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: expanded
                ? _kExpandedBg
                : (_hovered ? AppColors.surfaceLight : Colors.white),
            borderRadius: BorderRadius.circular(expanded ? 10 : 0),
            border: expanded
                ? null
                : const Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: expanded
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: const Color(0xFF0A1230),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    expanded
                        ? IconsaxPlusLinear.arrow_up_1
                        : IconsaxPlusLinear.arrow_down_1,
                    size: 20,
                    color: _kGreyText,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 14),
                Text(
                  widget.faq.answer,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
