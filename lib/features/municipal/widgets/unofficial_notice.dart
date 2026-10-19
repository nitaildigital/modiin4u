import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';

/// The municipality's own website, the source the notice links to.
const kMunicipalityUrl = 'https://www.modiin.muni.il/';

/// That the app is not the municipality's, and where its information comes
/// from. Google Play turned the app down on 19 Oct under its Misleading
/// Claims policy: a Municipal tab with no source link for the government
/// information and no clear statement that the app is not official. This
/// stands at the top of that tab, where it is seen before any of it.
class UnofficialNotice extends StatelessWidget {
  const UnofficialNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FB),
        border: Border.all(color: const Color(0xFFD8E2EF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(IconsaxPlusLinear.info_circle, size: 20, color: AppColors.midBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.unofficialTitle,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.unofficialBody,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    height: 1.45,
                    color: const Color(0xFF4B4B4B),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => launchUrl(Uri.parse(kMunicipalityUrl), mode: LaunchMode.inAppBrowserView),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      l.unofficialLink,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midBlue,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.midBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
