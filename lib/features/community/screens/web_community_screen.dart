import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../news/models/article.dart';
import '../../news/widgets/m_article_parts.dart';
import '../providers/community_providers.dart';
import '../widgets/community_widgets.dart';

// ═══════════════════════════════════════════════════════════
// Web Community — desktop layout for /community
//
// Built from what the client has: his Facebook group and his "share with
// us" form side by side, then his community news. All three are set in the
// panel (Remote Config); a link left empty hides its card. The page said
// "the community has not opened yet" over an empty feed with no table
// behind it.
// ═══════════════════════════════════════════════════════════

class WebCommunityContent extends ConsumerStatefulWidget {
  const WebCommunityContent({super.key});

  @override
  ConsumerState<WebCommunityContent> createState() =>
      _WebCommunityContentState();
}

class _WebCommunityContentState extends ConsumerState<WebCommunityContent>
    with WebLanguageState<WebCommunityContent> {
  bool get _isHebrew => webIsHebrew.value;

  /// The navbar's toggle is this page's language, not the app's locale.
  static final _en = lookupL(const Locale('en'));
  static final _he = lookupL(const Locale('he'));
  L get _l => _isHebrew ? _he : _en;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(communitySettingsProvider).valueOrNull;
    final news = ref.watch(communityNewsProvider);
    final l = _l;

    final cards = [
      if (settings?.facebookUrl != null)
        CommunityLinkCard(
          kind: CommunityLinkKind.facebook,
          title: l.joinGroupTitle,
          body: l.joinGroupBody,
          cta: l.joinGroupCta,
          url: settings!.facebookUrl!,
          large: true,
        ),
      if (settings?.shareUrl != null)
        CommunityLinkCard(
          kind: CommunityLinkKind.share,
          title: l.shareWithUsTitle,
          body: l.shareWithUsBody,
          cta: l.shareWithUsCta,
          url: settings!.shareUrl!,
          large: true,
        ),
    ];

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(isHebrew: _isHebrew),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    WebSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommunityCover(
                            title: l.communityTitle,
                            intro: l.communityIntro,
                            height: 300,
                            titleSize: 40,
                          ),
                          if (cards.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final (i, card) in cards.indexed) ...[
                                    if (i > 0) const SizedBox(width: 24),
                                    Expanded(child: card),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          ..._news(news, l),
                        ],
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

  List<Widget> _news(
    AsyncValue<({String categoryId, List<Article> articles})?> news,
    L l,
  ) {
    final n = news.valueOrNull;
    if (n == null) return const [];
    return [
      const SizedBox(height: 48),
      Row(
        children: [
          Expanded(
            child: Text(
              l.communityNews,
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
          ),
          if (n.articles.isNotEmpty)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.push('/news/category/${n.categoryId}'),
                child: Text(
                  l.seeAll,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      if (n.articles.isEmpty)
        Text(
          l.noStoriesYet,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 16,
            color: const Color(0xFF6D6D6D),
          ),
        )
      else
        Wrap(
          spacing: 24,
          runSpacing: 32,
          children: [
            for (final a in n.articles)
              MNewsCard(
                article: a,
                width: 300,
                imageHeight: 180,
                onTap: () => context.push('/article/${a.id}'),
              ),
          ],
        ),
    ];
  }
}
