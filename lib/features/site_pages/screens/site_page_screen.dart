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
class SitePageScreen extends ConsumerWidget {
  final String slug;
  const SitePageScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebSitePageContent(slug: slug);
        }
        return _buildMobile(context, ref);
      },
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final wantHebrew = Localizations.localeOf(context).languageCode == 'he';
    final async = ref.watch(sitePageProvider(slug));
    final page = async.valueOrNull;
    final contentHebrew = page?.contentIsHebrew(wantHebrew);
    final title = contentHebrew == null
        ? sitePageFallbackTitle(l, slug)
        : page!.title(contentHebrew);

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
                const SizedBox(height: 20),
                Expanded(
                  child: async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _error(context, ref, l),
                    data: (_) => ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        MediaQuery.paddingOf(context).bottom + 24,
                      ),
                      children: [
                        if (contentHebrew == null)
                          SitePageComingSoon(
                            message: l.sitePageComingSoon,
                            fontSize: 14,
                          )
                        else
                          // Laid out in the language it was written in,
                          // which is the other one when the client has
                          // written only that.
                          Directionality(
                            textDirection: contentHebrew
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (page!.updatedAt != null) ...[
                                  Text(
                                    lookupL(
                                      Locale(contentHebrew ? 'he' : 'en'),
                                    ).sitePageLastUpdated(
                                      sitePageDate(page.updatedAt!),
                                    ),
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 12,
                                      color: MAccountColors.label,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                SitePageBody(
                                  text: page.body(contentHebrew),
                                  fontSize: 14,
                                  lineHeight: 1.6,
                                ),
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
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: MAccountColors.value,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.invalidate(sitePageProvider(slug)),
            child: Text(l.tryAgain),
          ),
        ],
      ),
    );
  }
}
