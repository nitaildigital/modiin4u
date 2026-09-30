import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../news/widgets/m_article_parts.dart';
import '../providers/community_providers.dart';
import '../widgets/community_widgets.dart';
import 'web_community_screen.dart';

/// Community, at /community.
///
/// It opened with a feed written into the source — named residents, a
/// plumber's "phone number", a pothole at a real address — later emptied,
/// because there is no posts table. It is now built from what the client
/// really has: his Facebook group, his "share with us" form and his news,
/// all three set in the panel (Remote Config), so nothing here is invented
/// and he can change any of it. Figma has no Community frame.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebCommunityContent();
        return _buildMobile(context, ref);
      },
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final settings = ref.watch(communitySettingsProvider).valueOrNull;
    final news = ref.watch(communityNewsProvider);

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
                            l.communityTitle,
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
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(communitySettingsProvider);
                      ref.invalidate(communityNewsProvider);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        MediaQuery.paddingOf(context).bottom + 24,
                      ),
                      children: [
                        CommunityCover(
                          title: l.communityTitle,
                          intro: l.communityIntro,
                          height: 170,
                        ),
                        if (settings?.facebookUrl != null) ...[
                          const SizedBox(height: 16),
                          CommunityLinkCard(
                            kind: CommunityLinkKind.facebook,
                            title: l.joinGroupTitle,
                            body: l.joinGroupBody,
                            cta: l.joinGroupCta,
                            url: settings!.facebookUrl!,
                          ),
                        ],
                        if (settings?.shareUrl != null) ...[
                          const SizedBox(height: 12),
                          CommunityLinkCard(
                            kind: CommunityLinkKind.share,
                            title: l.shareWithUsTitle,
                            body: l.shareWithUsBody,
                            cta: l.shareWithUsCta,
                            url: settings!.shareUrl!,
                          ),
                        ],
                        ...switch (news) {
                          AsyncData(value: final n?) => [
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l.communityNews,
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F1F1F),
                                    ),
                                  ),
                                ),
                                if (n.articles.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => context.push(
                                      '/news/category/${n.categoryId}',
                                    ),
                                    child: Text(
                                      l.seeAll,
                                      style: TextStyle(
                                        fontFamily: AppFonts.inter,
                                        fontSize: 14,
                                        color: const Color(0xFF123A72),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (n.articles.isEmpty)
                              Text(
                                l.noStoriesYet,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  color: const Color(0xFF6D6D6D),
                                ),
                              )
                            else
                              SizedBox(
                                height: 250,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: n.articles.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, i) => MNewsCard(
                                    article: n.articles[i],
                                    onTap: () => context.push(
                                      '/article/${n.articles[i].id}',
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          AsyncLoading() => const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ],
                          _ => const <Widget>[],
                        },
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
}
