import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../models/listing.dart';
import '../providers/listing_providers.dart';

/// The owner's actions on one of their listings in My Apartments.
///
/// Once a listing was sent the page offered nothing: it could not be changed,
/// taken down, marked sold or deleted. Changing it makes it a draft again and
/// opens the form, so the change goes back for review, as the database
/// requires of a resident's edit (00033). Shared by the phone and desktop
/// cards.
class MyListingMenu extends ConsumerWidget {
  final Listing listing;

  /// The button; a white circle with dots when not given.
  final Widget? child;

  /// An "open" item ahead of the actions, as the phone card's menu had.
  final String? openLabel;
  final VoidCallback? onOpen;

  const MyListingMenu({
    super.key,
    required this.listing,
    this.child,
    this.openLabel,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final he = Localizations.localeOf(context).languageCode == 'he';
    String t(String en, String hebrew) => he ? hebrew : en;
    final status = listing.status;
    final sent = status == ListingStatus.pending || status == ListingStatus.active;
    final rent = listing.kind == ListingKind.rent;

    return PopupMenuButton<String>(
      tooltip: t('Actions', 'פעולות'),
      color: Colors.white,
      position: PopupMenuPosition.under,
      onSelected: (action) =>
          action == 'open' ? onOpen?.call() : _run(context, ref, action, t),
      itemBuilder: (_) => [
        if (onOpen != null && openLabel != null)
          PopupMenuItem(value: 'open', child: Text(openLabel!)),
        if (status != ListingStatus.draft)
          PopupMenuItem(value: 'edit', child: Text(t('Edit', 'עריכה'))),
        if (status == ListingStatus.active)
          PopupMenuItem(
            value: 'closed',
            child: Text(rent ? t('Mark as rented', 'סימון כהושכר') : t('Mark as sold', 'סימון כנמכר')),
          ),
        if (sent)
          PopupMenuItem(value: 'withdraw', child: Text(t('Take down', 'הסרה מהאתר'))),
        PopupMenuItem(
          value: 'delete',
          child: Text(t('Delete', 'מחיקה'), style: const TextStyle(color: Color(0xFFCB3E3C))),
        ),
      ],
      child: child ?? Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(IconsaxPlusLinear.more, size: 18, color: Color(0xFF0A1230)),
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    String action,
    String Function(String, String) t,
  ) async {
    final repo = ref.read(listingRepositoryProvider);
    final live = listing.status == ListingStatus.active;
    final rent = listing.kind == ListingKind.rent;

    final (title, body, yes) = switch (action) {
      'edit' => (
        t('Edit this listing?', 'לערוך את המודעה?'),
        live
            ? t('The listing leaves the site while you edit it, and goes back for approval when you send it.',
                'המודעה יורדת מהאתר בזמן העריכה, וחוזרת לאישור כשתשלחו אותה.')
            : t('The listing goes back to your drafts until you send it again.',
                'המודעה חוזרת לטיוטות עד שתשלחו אותה שוב.'),
        t('Edit', 'עריכה'),
      ),
      'closed' => (
        rent ? t('Mark as rented?', 'לסמן כהושכר?') : t('Mark as sold?', 'לסמן כנמכר?'),
        t('The listing leaves the site.', 'המודעה תוסר מהאתר.'),
        rent ? t('Rented', 'הושכר') : t('Sold', 'נמכר'),
      ),
      'withdraw' => (
        t('Take this listing down?', 'להסיר את המודעה מהאתר?'),
        t('It stays in your drafts, and you can send it again.',
            'היא נשמרת בטיוטות, ואפשר לשלוח אותה שוב.'),
        t('Take down', 'הסרה'),
      ),
      _ => (
        t('Delete this listing?', 'למחוק את המודעה?'),
        t('This cannot be undone.', 'לא ניתן לבטל את המחיקה.'),
        t('Delete', 'מחיקה'),
      ),
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(t('Cancel', 'ביטול'))),
          TextButton(onPressed: () => Navigator.pop(dialog, true), child: Text(yes)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      switch (action) {
        case 'edit' || 'withdraw':
          await repo.setOwnStatus(listing.id, ListingStatus.draft);
        case 'closed':
          await repo.setOwnStatus(listing.id, rent ? ListingStatus.rented : ListingStatus.sold);
        default:
          await repo.deleteById(listing.id);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('That did not work. Please try again.', 'הפעולה לא הצליחה. נסו שוב.'))),
        );
      }
      return;
    }

    ref.invalidate(myListingsProvider);
    ref.invalidate(listingByIdProvider(listing.id));
    ref.invalidate(listingsProvider);
    ref.invalidate(allActiveListingsProvider);
    if (action == 'edit' && context.mounted) {
      context.push('/add-apartment?draft=${listing.id}');
    }
  }
}
