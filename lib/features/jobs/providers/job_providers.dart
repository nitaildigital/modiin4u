import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorite_providers.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../models/job.dart';
import '../repositories/job_repository.dart';

final jobRepositoryProvider = Provider((ref) => JobRepository());

/// The filters on the residents' Jobs list.
final jobFiltersProvider = StateProvider<JobFilters>((ref) => const JobFilters());

final liveJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) {
  final filters = ref.watch(jobFiltersProvider);
  return ref.watch(jobRepositoryProvider).fetchLive(filters);
});

final jobProvider = FutureProvider.autoDispose.family<Job?, String>(
  (ref, id) => ref.watch(jobRepositoryProvider).fetchById(id),
);

final businessPhotosProvider = FutureProvider.autoDispose.family<List<String>, String>(
  (ref, businessId) => ref.watch(jobRepositoryProvider).businessPhotos(businessId),
);

final jobCategoriesProvider = FutureProvider<List<({String id, String name})>>(
  (ref) => ref.watch(jobRepositoryProvider).categories(),
);

/// The signed-in person's applications, by job.
final myApplicationsProvider = FutureProvider.autoDispose<List<JobApplication>>((ref) {
  ref.watch(authProvider.select((u) => u?.id));
  return ref.watch(jobRepositoryProvider).myApplications();
});

/// When the person applied to [jobId], or null.
final appliedAtProvider = Provider.autoDispose.family<DateTime?, String>((ref, jobId) {
  final apps = ref.watch(myApplicationsProvider).valueOrNull ?? const [];
  return apps.where((a) => a.jobId == jobId).firstOrNull?.createdAt;
});

/// The jobs behind the person's applications.
final appliedJobsProvider = FutureProvider.autoDispose<List<(Job, JobApplication)>>((ref) async {
  final apps = await ref.watch(myApplicationsProvider.future);
  final jobs = await ref.watch(jobRepositoryProvider).fetchByIds(apps.map((a) => a.jobId));
  final byId = {for (final j in jobs) j.id: j};
  return [
    for (final a in apps)
      if (byId[a.jobId] != null) (byId[a.jobId]!, a),
  ];
});

/// The jobs the person saved (favorites, entity type 'job').
final savedJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final keys = ref.watch(favoritesProvider);
  final ids = [
    for (final k in keys)
      if (k.startsWith('${FavoriteKind.job.value}:')) k.split(':').last,
  ];
  final jobs = await ref.watch(jobRepositoryProvider).fetchByIds(ids);
  // Still open first; a closed one stays until it is unsaved.
  jobs.sort((a, b) => (b.isLive ? 1 : 0).compareTo(a.isLive ? 1 : 0));
  return jobs;
});

// ── The job seeker's profile ──

class JobSeekerData {
  final JobProfile? profile;
  final List<WorkExperience> experiences;
  final List<Education> educations;
  final List<Resume> resumes;

  const JobSeekerData({
    this.profile,
    this.experiences = const [],
    this.educations = const [],
    this.resumes = const [],
  });

  /// How much of My Profile is filled, as the design's bar shows it: basic
  /// details, about, skills, work experience, education, a CV, and more
  /// information — each a seventh.
  double completion({required bool hasBasics}) {
    final parts = [
      hasBasics,
      (profile?.about ?? '').trim().isNotEmpty,
      (profile?.skills ?? const []).isNotEmpty,
      experiences.isNotEmpty,
      educations.isNotEmpty,
      resumes.isNotEmpty,
      (profile?.additionalInfo ?? '').trim().isNotEmpty,
    ];
    return parts.where((p) => p).length / parts.length;
  }
}

/// A person's job profile: their own, or an applicant's (the business reads
/// it under 00069's `can_view_job_seeker`).
final jobSeekerProvider = FutureProvider.autoDispose.family<JobSeekerData, String>((ref, profileId) async {
  final repo = ref.watch(jobRepositoryProvider);
  final mine = ref.watch(authProvider)?.id == profileId;
  final results = await Future.wait([
    repo.fetchProfile(profileId),
    repo.fetchExperiences(profileId),
    repo.fetchEducations(profileId),
    // Another person's CV files are seen only through their application.
    if (mine) repo.fetchResumes(profileId) else Future.value(const <Resume>[]),
  ]);
  return JobSeekerData(
    profile: results[0] as JobProfile?,
    experiences: results[1] as List<WorkExperience>,
    educations: results[2] as List<Education>,
    resumes: results[3] as List<Resume>,
  );
});

final myJobSeekerProvider = FutureProvider.autoDispose<JobSeekerData>((ref) {
  final id = ref.watch(authProvider)?.id;
  if (id == null) return const JobSeekerData();
  return ref.watch(jobSeekerProvider(id).future);
});

// ── The business's side ──

final businessJobsProvider = FutureProvider.autoDispose.family<List<Job>, String>(
  (ref, businessId) => ref.watch(jobRepositoryProvider).fetchForBusiness(businessId),
);

final applicationCountsProvider = FutureProvider.autoDispose.family<Map<String, int>, String>(
  (ref, businessId) async {
    final jobs = await ref.watch(businessJobsProvider(businessId).future);
    return ref.watch(jobRepositoryProvider).applicationCounts(jobs.map((j) => j.id).toList());
  },
);

final jobStatsProvider = FutureProvider.autoDispose.family<Map<String, int>, String>(
  (ref, jobId) => ref.watch(jobRepositoryProvider).stats(jobId),
);

final applicantsProvider = FutureProvider.autoDispose.family<List<JobApplication>, String>(
  (ref, jobId) => ref.watch(jobRepositoryProvider).applicants(jobId),
);
