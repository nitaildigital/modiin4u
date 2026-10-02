import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/push/push_feed.dart';
import '../../../core/push/push_service.dart';
import '../../../core/push/push_switch.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';

/// The notifications sent so far, as the bell lists them — on the phone and
/// on the website. Each opens what it was about, as the notification did.
class PushFeedList extends ConsumerWidget {
  final String languageCode;

  /// Drawn when nothing was sent yet: the screen's own empty state.
  final Widget empty;

  /// The website's list sits inside a page that scrolls; the phone's is the
  /// page.
  final bool shrinkWrap;

  const PushFeedList({
    super.key,
    required this.languageCode,
    required this.empty,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(pushFeedProvider);
    return feed.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      // Not an error page: the bell is a convenience, and an empty one says
      // what it should while the connection is down.
      error: (_, _) => empty,
      data: (items) {
        if (items.isEmpty) return empty;
        final list = ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, _) =>
              const Divider(color: AppColors.border, height: 1, indent: 76),
          itemBuilder: (context, i) => _FeedRow(item: items[i], languageCode: languageCode),
        );
        if (shrinkWrap) return list;
        return RefreshIndicator(
          onRefresh: () => ref.refresh(pushFeedProvider.future),
          child: list,
        );
      },
    );
  }
}

class _FeedRow extends StatelessWidget {
  final PushFeedItem item;
  final String languageCode;

  const _FeedRow({required this.item, required this.languageCode});

  /// The time today, the date before that.
  String _when() {
    final now = DateTime.now();
    final t = item.sentAt;
    final today = t.year == now.year && t.month == now.month && t.day == now.day;
    return DateFormat(today ? 'HH:mm' : 'd.M.yyyy').format(t);
  }

  void _open(BuildContext context) {
    final link = item.link;
    if (link == null || link.isEmpty) return;
    if (link.startsWith('/')) {
      context.push(link);
    } else {
      final uri = Uri.tryParse(link);
      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = item.titleFor(languageCode);
    final body = item.bodyFor(languageCode);
    return InkWell(
      onTap: item.link == null ? null : () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            item.imageUrl != null
                ? NetworkPhoto(
                    url: item.imageUrl,
                    width: 44,
                    height: 44,
                    radius: BorderRadius.circular(12),
                    icon: IconsaxPlusLinear.notification,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.surfaceDim,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      IconsaxPlusLinear.notification,
                      size: 22,
                      color: AppColors.turquoise,
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: const TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 13,
                        color: AppColors.grayMeta,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _when(),
                    style: const TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      color: AppColors.grayLight,
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

/// "Turn on notifications", above the list, while this device has not
/// allowed them and could. On the website it is the way in: a browser may
/// only be asked from a tap.
class PushTurnOnCard extends ConsumerWidget {
  final String title;
  final String action;

  const PushTurnOnCard({super.key, required this.title, required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.read(pushServiceProvider);
    if (!push.isAvailable) return const SizedBox.shrink();
    return ValueListenableBuilder<bool?>(
      valueListenable: push.allowed,
      builder: (context, allowed, _) {
        if (allowed == true) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.turquoise.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(IconsaxPlusLinear.notification, color: AppColors.turquoise),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await setPushEnabled(ref, true);
                  ref.invalidate(pushFeedProvider);
                },
                child: Text(action, style: const TextStyle(fontFamily: AppFonts.rubik)),
              ),
            ],
          ),
        );
      },
    );
  }
}
