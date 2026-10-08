import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/business_owner/data/owner_data.dart';
import '../../features/businesses/providers/business_providers.dart';
import '../../features/jobs/providers/job_providers.dart';

/// Reads again what a notification may have changed for the person signed
/// in: their business (approved), its promotions (approved or declined), its
/// deals and jobs (claims, applications), and their own applications (moved
/// to interview, accepted, not selected), and a business's gallery with
/// their photographs waiting for it (a resident's photo approved or declined).
///
/// These screens read once and keep what they read, so a business approved
/// while its owner was looking still said "waiting for approval", and an
/// approved promotion still said "requested", until the app was restarted.
void refreshAfterNotification(Ref ref) {
  ref
    ..invalidate(myBusinessProvider)
    ..invalidate(myPromotionRequestsProvider)
    ..invalidate(myDealsProvider)
    ..invalidate(businessJobsProvider)
    ..invalidate(applicationCountsProvider)
    ..invalidate(applicantsProvider)
    ..invalidate(jobStatsProvider)
    ..invalidate(myApplicationsProvider)
    ..invalidate(jobProvider)
    ..invalidate(businessGalleryProvider)
    ..invalidate(myPendingPhotosProvider);
}

/// The same, from a widget (`WidgetRef` is not a `Ref`).
void refreshAfterNotificationWidget(WidgetRef ref) {
  ref
    ..invalidate(myBusinessProvider)
    ..invalidate(myPromotionRequestsProvider)
    ..invalidate(myDealsProvider)
    ..invalidate(businessJobsProvider)
    ..invalidate(applicationCountsProvider)
    ..invalidate(applicantsProvider)
    ..invalidate(jobStatsProvider)
    ..invalidate(myApplicationsProvider)
    ..invalidate(jobProvider)
    ..invalidate(businessGalleryProvider)
    ..invalidate(myPendingPhotosProvider);
}
