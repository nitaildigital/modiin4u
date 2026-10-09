import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../data/urban_profile.dart';

/// The Urban Profile as a card (the spec's §7 "WOW moment"): the photo or
/// initials on the brand's blue, the name and neighbourhood, the few words in
/// quotes, the interests, "My places", and the Top Picks once there are
/// enough places. The same card is the finished screen, the Profile's
/// block, another resident's profile and — drawn off screen — the picture
/// that is shared. What the person left empty is not drawn.
class UrbanProfileCard extends StatelessWidget {
  final UrbanProfile profile;

  /// For the shared picture: network photos must already be loaded, so the
  /// card is drawn with what it has rather than with spinners.
  final bool forShare;

  /// Opens a place's page; null on the shared picture.
  final ValueChanged<UrbanPlace>? onPlace;

  const UrbanProfileCard({super.key, required this.profile, this.forShare = false, this.onPlace});

  @override
  Widget build(BuildContext context) {
    final he = Localizations.localeOf(context).languageCode == 'he';
    final p = profile;
    final neighborhood = p.neighborhoodLabel(he);
    final picks = [
      for (final pick in TopPick.values)
        if (p.places.any((pl) => pl.topPick == pick)) (pick, p.places.firstWhere((pl) => pl.topPick == pick)),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EDF3)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The band and the photo over its edge.
          SizedBox(
            height: 132,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 84,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [AppColors.midBlue, AppColors.navy],
                    ),
                  ),
                  alignment: AlignmentDirectional.topEnd,
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset('assets/images/logo_white.svg', height: 26),
                ),
                PositionedDirectional(
                  start: 20,
                  top: 36,
                  child: Container(
                    width: 92,
                    height: 92,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      gradient: const LinearGradient(colors: [Color(0xFF0058B5), Color(0xFF010A36)]),
                    ),
                    child: p.hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: p.avatarUrl!,
                            fit: BoxFit.cover,
                            fadeInDuration: forShare ? Duration.zero : const Duration(milliseconds: 300),
                            errorWidget: (_, _, _) => _Initials(p.name),
                          )
                        : _Initials(p.name),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: mText(21, weight: FontWeight.w700, color: Colors.black)),
                if ((neighborhood ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(IconsaxPlusLinear.location, size: 15, color: mStepGrey),
                      const SizedBox(width: 4),
                      Flexible(child: Text(neighborhood!, style: mText(13.5, color: mStepGrey))),
                    ],
                  ),
                ],
                if (p.hasBio) ...[
                  const SizedBox(height: 14),
                  Text(
                    '“${p.bio!.trim()}”',
                    style: mText(15, color: mStepInk, height: 1.45).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                if (p.interests.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in p.interests)
                        if (interestOf(key) case final i?)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF3FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('${i.emoji} ${i.label(he)}', style: mText(12.5, weight: FontWeight.w500, color: mStepMid)),
                          ),
                    ],
                  ),
                ],
                if (p.places.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(mTr(context, 'My Places', 'המקומות שלי'), style: mText(14, weight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: forShare ? const NeverScrollableScrollPhysics() : null,
                      itemCount: p.places.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _PlaceTile(
                        place: p.places[i],
                        hebrew: he,
                        onTap: onPlace == null ? null : () => onPlace!(p.places[i]),
                      ),
                    ),
                  ),
                ],
                // Top Picks only with three places or more (the spec: hidden
                // rather than shown with gaps).
                if (p.places.length >= 3 && picks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(mTr(context, 'My Top Picks in Modiin', 'הבחירות שלי במודיעין'), style: mText(14, weight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  for (final (pick, place) in picks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: onPlace == null ? null : () => onPlace!(place),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: mStepHairline),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _PlaceImage(place: place, width: 48, height: 48, radius: 9),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(pick.icon, size: 14, color: mStepMid),
                                        const SizedBox(width: 5),
                                        Text(pick.label(he), style: mText(12, weight: FontWeight.w500, color: mStepMid)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      place.label(he),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: mText(14.5, weight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials(this.name);

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'))..removeWhere((s) => s.isEmpty);
    final text = parts.isEmpty
        ? '?'
        : parts.length == 1
        ? parts.first.characters.first
        : '${parts.first.characters.first}${parts[1].characters.first}';
    return Center(child: Text(text, style: mText(30, weight: FontWeight.w600, color: Colors.white)));
  }
}

class _PlaceImage extends StatelessWidget {
  final UrbanPlace place;
  final double width;
  final double height;
  final double radius;
  const _PlaceImage({required this.place, required this.width, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: place.image != null
            ? CachedNetworkImage(
                imageUrl: place.image!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _blank(),
              )
            : _blank(),
      ),
    );
  }

  Widget _blank() => ColoredBox(
    color: const Color(0xFFEEF2F7),
    child: Icon(place.kind == 'park' ? IconsaxPlusLinear.tree : IconsaxPlusLinear.shop, color: mStepMid, size: 20),
  );
}

class _PlaceTile extends StatelessWidget {
  final UrbanPlace place;
  final bool hebrew;
  final VoidCallback? onTap;
  const _PlaceTile({required this.place, required this.hebrew, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlaceImage(place: place, width: 96, height: 72),
            const SizedBox(height: 6),
            Text(
              place.label(hebrew),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: mText(12, weight: FontWeight.w500, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Your Urban Profile is 70% complete", with the bar and the way to finish
/// it — on the Profile screen while something is missing.
class UrbanProfileCompletion extends StatelessWidget {
  final UrbanProfile profile;
  final VoidCallback onComplete;
  const UrbanProfileCompletion({super.key, required this.profile, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final pct = profile.completion;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF2F6FB), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mTr(context, 'Your Urban Profile is $pct% complete', 'הפרופיל העירוני שלכם הושלם ב־$pct%'),
            style: mText(14.5, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              color: mStepMid,
              backgroundColor: const Color(0xFFDDE5F0),
            ),
          ),
          const SizedBox(height: 14),
          MButton(
            label: mTr(context, 'Complete your Urban Profile', 'השלימו את הפרופיל העירוני'),
            height: 44,
            onTap: onComplete,
          ),
        ],
      ),
    );
  }
}
