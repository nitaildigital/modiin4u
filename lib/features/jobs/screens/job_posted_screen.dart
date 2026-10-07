import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/m_kit.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../providers/job_providers.dart';

/// "Job Posted Successfully!" (`business_side/Success Post.png`): shown once
/// a new job goes live, with the offer to promote it.
class JobPostedScreen extends ConsumerWidget {
  final String jobId;
  const JobPostedScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(jobProvider(jobId)).valueOrNull;
    return MPublishedPage(
      title: mTr(context, 'Job Posted Successfully!', 'המשרה פורסמה בהצלחה!'),
      subtitle: mTr(
        context,
        'Your job is now live and visible to job seekers on Modiin4U.',
        'המשרה פעילה כעת ומוצגת למחפשי עבודה ב-Modiin4U.',
      ),
      itemTitle: job?.title ?? '',
      itemImage: job?.coverImage,
      promoteTitle: mTr(context, 'Want to reach more candidates?', 'רוצים להגיע ליותר מועמדים?'),
      promoteText: mTr(
        context,
        'Promote this job to increase its visibility and attract more relevant applicants.',
        'קדמו את המשרה כדי להגדיל את החשיפה שלה ולמשוך מועמדים מתאימים יותר.',
      ),
      promoteLabel: mTr(context, 'Promote Job', 'קידום המשרה'),
      onPromote: () => context.pushReplacement('/promote/job/$jobId'),
      onLater: () => context.go('/business-jobs'),
    );
  }
}
