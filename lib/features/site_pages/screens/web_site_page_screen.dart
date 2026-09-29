import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/site_page_provider.dart';
import '../widgets/site_page_body.dart';
import '../widgets/site_page_parts.dart';

// ═══════════════════════════════════════════════════════════
// Web information page — desktop (About Us, Accessibility Statement)
//
// Laid out like the Terms page beside it: the site's navbar and footer, and
// the text in one column at a readable measure. The text is the client's,
// from the panel's עמודי מידע; until he publishes it the page says it is
// coming and shows nothing in its place.
// ═══════════════════════════════════════════════════════════

const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);

/// About 75 characters a line at 16px, which is what long prose wants.
const _kColumnWidth = 720.0;

class WebSitePageContent extends ConsumerStatefulWidget {
  final String slug;
  const WebSitePageContent({super.key, required this.slug});

  @override
  ConsumerState<WebSitePageContent> createState() =>
      _WebSitePageContentState();
}

class _WebSitePageContentState extends ConsumerState<WebSitePageContent>
    with WebLanguageState<WebSitePageContent> {
  bool get _isHebrew => webIsHebrew.value;

  /// The navbar's toggle is this page's language, not the app's locale, so
  /// both string tables are held and the page reads the one it is in.
  static final _en = lookupL(const Locale('en'));
  static final _he = lookupL(const Locale('he'));
  L _lFor(bool hebrew) => hebrew ? _he : _en;

  void _back() => context.canPop() ? context.pop() : context.go('/');

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sitePageProvider(widget.slug));

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(isHebrew: _isHebrew, activeId: null),
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
                              async.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 80),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (_, _) => _buildError(),
                                data: _buildPage,
                              ),
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
              _lFor(_isHebrew).sitePageBack,
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

  Widget _title(String text) => Text(
    text,
    style: TextStyle(
      fontFamily: AppFonts.nunito,
      fontSize: 40,
      fontWeight: FontWeight.w600,
      color: _kHeading,
      height: 1.2,
    ),
  );

  Widget _buildPage(SitePage? page) {
    final contentHebrew = page?.contentIsHebrew(_isHebrew);
    if (contentHebrew == null) {
      final l = _lFor(_isHebrew);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(sitePageFallbackTitle(l, widget.slug)),
          const SizedBox(height: 40),
          SitePageComingSoon(message: l.sitePageComingSoon),
        ],
      );
    }

    // Laid out in the language it was written in, which is the other one
    // when the client has written only that.
    final l = _lFor(contentHebrew);
    return Directionality(
      textDirection: contentHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(page!.title(contentHebrew)),
            if (page.updatedAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    IconsaxPlusLinear.clock,
                    size: 16,
                    color: _kGreyText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.sitePageLastUpdated(sitePageDate(page.updatedAt!)),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: _kGreyText,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
            SitePageBody(text: page.body(contentHebrew)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final l = _lFor(_isHebrew);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.sitePageLoadError,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              color: _kGreyText,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.invalidate(sitePageProvider(widget.slug)),
            child: Text(l.tryAgain),
          ),
        ],
      ),
    );
  }
}
