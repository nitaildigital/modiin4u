import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// The page's photograph with its title and one line under it, over a
/// darkening gradient so the words read on any part of the picture.
class CommunityCover extends StatelessWidget {
  final String title;
  final String intro;
  final double height;
  final double titleSize;

  const CommunityCover({
    super.key,
    required this.title,
    required this.intro,
    this.height = 170,
    this.titleSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/community_cover.jpg', fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: 16,
              end: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    intro,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: titleSize * 0.6,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum CommunityLinkKind { facebook, share }

/// A card that leads off the site: the client's Facebook group, or his
/// "share with us" form. Both open in the browser or the Facebook app.
class CommunityLinkCard extends StatelessWidget {
  final CommunityLinkKind kind;
  final String title;
  final String body;
  final String cta;
  final String url;
  final bool large;

  const CommunityLinkCard({
    super.key,
    required this.kind,
    required this.title,
    required this.body,
    required this.cta,
    required this.url,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final facebook = kind == CommunityLinkKind.facebook;
    final accent = facebook ? const Color(0xFF1877F2) : AppColors.turquoise;
    return Container(
      padding: EdgeInsets.all(large ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: large ? 48 : 40,
                height: large ? 48 : 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: facebook
                      ? SvgPicture.asset(
                          'assets/web/news/share_facebook.svg',
                          height: large ? 22 : 18,
                          colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                        )
                      : Icon(
                          IconsaxPlusLinear.send_2,
                          size: large ? 24 : 20,
                          color: accent,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: large ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: large ? 15 : 14,
              color: const Color(0xFF6D6D6D),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: () => launchUrl(
                Uri.parse(url),
                // Over the app rather than out to the browser.
                mode: LaunchMode.inAppBrowserView,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: facebook ? accent : AppColors.midBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
              child: Text(
                cta,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
