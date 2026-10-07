import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../deals/models/offer.dart';
import '../data/owner_data.dart';

/// "Deal Published!" (`business_side/Success Deal.png`), shown once after a
/// new deal is saved, with the offer to promote it.
class DealPublishedScreen extends ConsumerStatefulWidget {
  final String dealId;
  const DealPublishedScreen({super.key, required this.dealId});

  @override
  ConsumerState<DealPublishedScreen> createState() => _DealPublishedScreenState();
}

class _DealPublishedScreenState extends ConsumerState<DealPublishedScreen> {
  late final Future<Offer?> _deal = ref.read(ownerRepositoryProvider).fetchDeal(widget.dealId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Offer?>(
      future: _deal,
      builder: (context, snap) {
        final deal = snap.data;
        return MPublishedPage(
          title: mTr(context, 'Deal Published!', 'המבצע פורסם!'),
          subtitle: mTr(
            context,
            'Your deal is now live and visible to customers on Modiin4U.',
            'המבצע שלכם פעיל ומוצג ללקוחות ב-Modiin4U.',
          ),
          // Blank until the row arrives rather than a stand-in title.
          itemTitle: deal?.name ?? '',
          itemImage: deal?.imageUrl,
          promoteTitle: mTr(context, 'Want to reach more customers?', 'רוצים להגיע ליותר לקוחות?'),
          promoteText: mTr(
            context,
            'Promote this deal to increase its visibility and attract more customers.',
            'קדמו את המבצע כדי שיבלוט יותר וימשוך יותר לקוחות.',
          ),
          promoteLabel: mTr(context, 'Promote Deal', 'קידום המבצע'),
          onPromote: () => context.pushReplacement('/promote/offer/${widget.dealId}'),
          onLater: () => context.go('/business-deals'),
        );
      },
    );
  }
}
