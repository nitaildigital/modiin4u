import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Help & Support screen – search bar, FAQ accordion list with
/// expandable items, and a "Contact Us" card at the bottom.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _searchController = TextEditingController();
  int _expandedIndex = 2; // "How do I change the app language?" starts expanded

  static const _faqs = <_FaqItem>[
    _FaqItem(
      question: 'How do I edit my profile information?',
      answer:
          'Go to your Profile and tap "Edit Profile." From there, you can '
          'update your name, email, phone number, neighborhood, family status, '
          'and date of birth. Tap "Save Changes" when you\'re done.',
    ),
    _FaqItem(
      question: 'How do I change my password?',
      answer:
          'Go to your Profile → Settings → Change Password. Enter your '
          'current password followed by a new password, then confirm it. '
          'Tap "Change Password" to save.',
    ),
    _FaqItem(
      question: 'How do I change the app language?',
      answer:
          'Go to Settings → Language. Select your preferred language from '
          'the available options. The app will update to your selected language.',
    ),
    _FaqItem(
      question: 'How do I manage my notification settings?',
      answer:
          'Go to Settings → Notifications. You can toggle individual '
          'notification categories like News, Deals, Neighborhood Updates, '
          'and Real Estate Alerts on or off.',
    ),
    _FaqItem(
      question: 'How do I add a place, event, or news item to Favorites?',
      answer:
          'Tap the heart icon on any business, event, apartment listing, or '
          'news article to save it to your Favorites. You can find all your '
          'saved items on the Favorites screen.',
    ),
    _FaqItem(
      question: 'Where can I find my saved Favorites?',
      answer:
          'Go to your Profile and tap "Favorites." You can filter by category '
          '(Restaurants, Events, Bars, Apartments, News) or view all your '
          'saved items at once.',
    ),
    _FaqItem(
      question: 'How can I find businesses in Modiin?',
      answer:
          'Use the Businesses tab on the home screen. You can search by name, '
          'browse categories, or explore the interactive map to discover '
          'restaurants, cafés, shops, and services in Modiin.',
    ),
    _FaqItem(
      question: 'How can I find upcoming events in Modiin?',
      answer:
          'Tap the Events section on the home screen. Browse upcoming events '
          'by date or view them on the events map. Tap any event for full '
          'details including date, location, and description.',
    ),
    _FaqItem(
      question: 'How do I search for apartments in Modiin?',
      answer:
          'Go to the Real Estate section from the home screen. Filter '
          'listings by neighborhood, price range, number of rooms, and size. '
          'You can also browse the map to find apartments by location.',
    ),
  ];

  List<_FaqItem> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _faqs;
    return _faqs
        .where((f) =>
            f.question.toLowerCase().contains(q) ||
            f.answer.toLowerCase().contains(q))
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
                            'Help & Support',
                            style: GoogleFonts.inter(
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        const Icon(
                          IconsaxPlusLinear.search_normal_1,
                          size: 20,
                          color: Color(0xFF6D6D6D),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1F1F1F),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search for help',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6D6D6D),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ═══════════════════════════════════
                // FAQ accordion list
                // ═══════════════════════════════════
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      ...List.generate(filtered.length, (index) {
                        final faq = filtered[index];
                        final originalIndex = _faqs.indexOf(faq);
                        final expanded = originalIndex == _expandedIndex;

                        return _FaqTile(
                          faq: faq,
                          expanded: expanded,
                          onTap: () => setState(() {
                            _expandedIndex =
                                expanded ? -1 : originalIndex;
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
                          children: [
                            // Image placeholder
                            Container(
                              width: 58,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0058B5),
                                    Color(0xFF010A36),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  IconsaxPlusLinear.headphone,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title + subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Still need help?',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0A1230),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contact our support team',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF6D6D6D),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Contact Us button
                            GestureDetector(
                              onTap: () {
                                // TODO: open support email / chat
                              },
                              child: Container(
                                width: 120,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF123A72),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Center(
                                  child: Text(
                                    'Contact Us',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
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
          borderRadius: BorderRadius.circular(expanded ? 8 : 0),
          border: expanded
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFE7E7E7)),
                ),
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          expanded ? FontWeight.w600 : FontWeight.w400,
                      color: const Color(0xFF0A1230),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  expanded
                      ? IconsaxPlusLinear.arrow_up_1
                      : IconsaxPlusLinear.arrow_down_1,
                  size: 20,
                  color: const Color(0xFF6D6D6D),
                ),
              ],
            ),

            // Answer (visible when expanded)
            if (expanded) ...[
              const SizedBox(height: 12),
              Text(
                faq.answer,
                style: GoogleFonts.inter(
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
