import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../providers/site_page_provider.dart';
import '../widgets/site_page_body.dart';
import '../widgets/site_page_parts.dart';
import 'web_site_page_screen.dart';

/// An information page the client writes in the panel (עמודי מידע) — About
/// Us at /about, the Accessibility Statement at /accessibility.
///
/// Until he publishes one, it says the content will be published soon: the
/// words are his to write, and nothing is shown in their place.
class SitePageScreen extends ConsumerStatefulWidget {
  final String slug;
  const SitePageScreen({super.key, required this.slug});

  @override
  ConsumerState<SitePageScreen> createState() => _SitePageScreenState();
}

class _SitePageScreenState extends ConsumerState<SitePageScreen> {
  bool? _selectedHebrew;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebSitePageContent(slug: widget.slug);
        }
        return _buildMobile(context);
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    final l = L.of(context);
    final localeHebrew = Localizations.localeOf(context).languageCode == 'he';
    final async = ref.watch(sitePageProvider(widget.slug));
    final page = async.valueOrNull;

    final hasBoth = (page?.bodyHe.isNotEmpty ?? false) && (page?.bodyEn.isNotEmpty ?? false);

    final bool currentHebrew;
    if (_selectedHebrew != null) {
      currentHebrew = _selectedHebrew!;
    } else if (widget.slug == 'terms') {
      // The authoritative terms and conditions document is in Hebrew
      currentHebrew = true;
    } else {
      currentHebrew = page?.contentIsHebrew(localeHebrew) ?? localeHebrew;
    }

    final title = page == null ? sitePageFallbackTitle(l, widget.slug) : page.title(currentHebrew);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      const MBackArrow(color: Color(0xFF3D3D3D)),
                      Expanded(
                        child: Center(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                if (hasBoth) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedHebrew = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: currentHebrew ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: currentHebrew
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.slug == 'terms' ? 'עברית (תקנון)' : 'עברית',
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 13,
                                      fontWeight: currentHebrew ? FontWeight.w600 : FontWeight.w500,
                                      color: currentHebrew ? const Color(0xFF1F1F1F) : const Color(0xFF6D6D6D),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedHebrew = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: !currentHebrew ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: !currentHebrew
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.slug == 'terms' ? 'English (EULA)' : 'English',
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 13,
                                      fontWeight: !currentHebrew ? FontWeight.w600 : FontWeight.w500,
                                      color: !currentHebrew ? const Color(0xFF1F1F1F) : const Color(0xFF6D6D6D),
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
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: async.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _error(context, ref, l),
                    data: (_) => ListView(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 24),
                      children: [
                        if (page == null || (currentHebrew ? page.bodyHe.isEmpty : page.bodyEn.isEmpty)) ...[
                          SitePageComingSoon(message: l.sitePageComingSoon, fontSize: 14),
                          if (widget.slug == 'delete-account') ...[
                            const SizedBox(height: 24),
                            SiteDeletionRequestButton(hebrew: currentHebrew, fontSize: 14),
                          ],
                        ] else
                          Directionality(
                            textDirection: currentHebrew ? TextDirection.rtl : TextDirection.ltr,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (page.updatedAt != null) ...[
                                  Text(
                                    lookupL(
                                      Locale(currentHebrew ? 'he' : 'en'),
                                    ).sitePageLastUpdated(sitePageDate(page.updatedAt!)),
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 12,
                                      color: MAccountColors.label,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                SitePageBody(text: page.body(currentHebrew), fontSize: 14, lineHeight: 1.6),
                                if (widget.slug == 'delete-account') ...[
                                  const SizedBox(height: 28),
                                  SiteDeletionRequestButton(hebrew: currentHebrew, fontSize: 14),
                                ],
                              ],
                            ),
                          ),
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

  Widget _error(BuildContext context, WidgetRef ref, L l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.sitePageLoadError,
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: MAccountColors.value),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => ref.invalidate(sitePageProvider(widget.slug)), child: Text(l.tryAgain)),
        ],
      ),
    );
  }
}
