import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/job.dart';

/// Filters on the residents' Jobs list — the design's chips and filter sheet.
class JobFilters {
  final String search;
  final bool youth;
  final bool noExperience;
  final bool partTime;
  final bool students;
  final bool shifts;
  final JobType? type;
  final String? categoryId;

  const JobFilters({
    this.search = '',
    this.youth = false,
    this.noExperience = false,
    this.partTime = false,
    this.students = false,
    this.shifts = false,
    this.type,
    this.categoryId,
  });

  JobFilters copyWith({
    String? search,
    bool? youth,
    bool? noExperience,
    bool? partTime,
    bool? students,
    bool? shifts,
    JobType? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategory = false,
  }) => JobFilters(
    search: search ?? this.search,
    youth: youth ?? this.youth,
    noExperience: noExperience ?? this.noExperience,
    partTime: partTime ?? this.partTime,
    students: students ?? this.students,
    shifts: shifts ?? this.shifts,
    type: clearType ? null : (type ?? this.type),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
  );

  @override
  bool operator ==(Object other) =>
      other is JobFilters &&
      other.search == search &&
      other.youth == youth &&
      other.noExperience == noExperience &&
      other.partTime == partTime &&
      other.students == students &&
      other.shifts == shifts &&
      other.type == type &&
      other.categoryId == categoryId;

  @override
  int get hashCode =>
      Object.hash(search, youth, noExperience, partTime, students, shifts, type, categoryId);
}

class JobRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  static const _select =
      '*, businesses(id, name, name_en, logo_url, cover_url, short_description, full_description)';

  String? get _uid => _client.auth.currentUser?.id;

  // ── Residents ──

  /// Live jobs: promoted first (00069 clears a promotion when it ends), then
  /// the newest.
  Future<List<Job>> fetchLive(JobFilters f) async {
    var q = _client.from('jobs').select(_select).eq('status', 'active');
    if (f.youth) q = q.eq('for_youth', true);
    if (f.students) q = q.eq('for_students', true);
    if (f.noExperience) q = q.or('no_experience.eq.true,experience.eq.none');
    if (f.shifts) q = q.or('shift_work.eq.true,schedule.eq.shifts');
    if (f.partTime) q = q.eq('job_type', JobType.partTime.value);
    if (f.type != null) q = q.eq('job_type', f.type!.value);
    if (f.categoryId != null) q = q.eq('category_id', f.categoryId!);
    final s = f.search.trim().replaceAll(RegExp(r'[,()%]'), ' ');
    if (s.isNotEmpty) {
      q = q.or('title.ilike.%$s%,description.ilike.%$s%,location.ilike.%$s%');
    }
    final rows = await q
        .order('promoted_until', ascending: false, nullsFirst: false)
        .order('published_at', ascending: false)
        .limit(200);
    final now = DateTime.now();
    var jobs = List<Map<String, dynamic>>.from(rows).map(Job.fromJson)
        .where((j) => j.expiresAt == null || j.expiresAt!.isAfter(now))
        .toList();
    // A business's name is searched here: PostgREST cannot `or` across the
    // join.
    if (s.isNotEmpty) {
      final lower = s.toLowerCase();
      final byName = await _client
          .from('jobs')
          .select(_select)
          .eq('status', 'active')
          .inFilter('business_id', await _businessIdsNamed(lower));
      final more = List<Map<String, dynamic>>.from(byName).map(Job.fromJson);
      final seen = jobs.map((j) => j.id).toSet();
      jobs = [...jobs, ...more.where((j) => !seen.contains(j.id))];
    }
    return jobs;
  }

  Future<List<String>> _businessIdsNamed(String s) async {
    final rows = await _client
        .from('businesses')
        .select('id')
        .or('name.ilike.%$s%,name_en.ilike.%$s%')
        .limit(50);
    return [for (final r in List<Map<String, dynamic>>.from(rows)) r['id'] as String];
  }

  Future<Job?> fetchById(String id) async {
    final row = await _client.from('jobs').select(_select).eq('id', id).maybeSingle();
    return row == null ? null : Job.fromJson(row);
  }

  Future<List<Job>> fetchByIds(Iterable<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _client.from('jobs').select(_select).inFilter('id', ids.toList());
    return List<Map<String, dynamic>>.from(rows).map(Job.fromJson).toList();
  }

  /// A business's gallery, for the "About" section of the job page.
  Future<List<String>> businessPhotos(String businessId) async {
    final rows = await _client
        .from('entity_media')
        .select('sort_order, media(url)')
        .eq('entity_type', 'business')
        .eq('entity_id', businessId)
        .eq('role', 'gallery')
        .order('sort_order');
    return [
      for (final r in List<Map<String, dynamic>>.from(rows))
        if ((r['media'] as Map?)?['url'] is String) (r['media'] as Map)['url'] as String,
    ];
  }

  /// The signed-in person's applications, newest first.
  Future<List<JobApplication>> myApplications() async {
    if (_uid == null) return const [];
    final rows = await _client.rpc('my_job_applications');
    return [
      for (final r in List<Map<String, dynamic>>.from(rows as List))
        JobApplication(
          id: r['id'] as String,
          jobId: r['job_id'] as String,
          fullName: '',
          status: (r['status'] as String?) ?? 'new',
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
        ),
    ];
  }

  /// Applies through `apply_for_job` (00052), with the person's name and
  /// contact from their account, and a CV of theirs or none.
  Future<void> apply({
    required String jobId,
    required String fullName,
    String? phone,
    String? email,
    String? cvPath,
  }) async {
    await _client.rpc('apply_for_job', params: {
      'p_job': jobId,
      'p_full_name': fullName,
      'p_phone': phone,
      'p_email': email,
      'p_cv_path': cvPath,
      'p_platform': 'app',
    });
  }

  Future<void> recordEvent(String jobId, String kind) async {
    final visitor = _uid ?? 'anonymous-device';
    try {
      await _client.rpc('record_job_event', params: {
        'p_job': jobId,
        'p_kind': kind,
        'p_platform': 'app',
        'p_visitor': visitor.length < 8 ? '$visitor-app' : visitor,
      });
    } catch (_) {
      // A lost count is not worth an error on screen.
    }
  }

  // ── The job seeker's profile ──

  Future<JobProfile?> fetchProfile(String profileId) async {
    final row = await _client.from('job_profiles').select().eq('profile_id', profileId).maybeSingle();
    return row == null ? null : JobProfile.fromJson(row);
  }

  Future<void> saveProfile(Map<String, dynamic> patch) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    await _client.from('job_profiles').upsert({'profile_id': uid, ...patch}, onConflict: 'profile_id');
  }

  Future<List<WorkExperience>> fetchExperiences(String profileId) async {
    final rows = await _client
        .from('job_experiences')
        .select()
        .eq('profile_id', profileId)
        .order('is_current', ascending: false)
        .order('start_date', ascending: false, nullsFirst: false);
    return List<Map<String, dynamic>>.from(rows).map(WorkExperience.fromJson).toList();
  }

  Future<void> saveExperience(WorkExperience e) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    if (e.id == null) {
      await _client.from('job_experiences').insert(e.toRow(uid));
    } else {
      await _client.from('job_experiences').update(e.toRow(uid)).eq('id', e.id!);
    }
  }

  Future<void> deleteExperience(String id) =>
      _client.from('job_experiences').delete().eq('id', id);

  Future<List<Education>> fetchEducations(String profileId) async {
    final rows = await _client
        .from('job_educations')
        .select()
        .eq('profile_id', profileId)
        .order('is_current', ascending: false)
        .order('start_date', ascending: false, nullsFirst: false);
    return List<Map<String, dynamic>>.from(rows).map(Education.fromJson).toList();
  }

  Future<void> saveEducation(Education e) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    if (e.id == null) {
      await _client.from('job_educations').insert(e.toRow(uid));
    } else {
      await _client.from('job_educations').update(e.toRow(uid)).eq('id', e.id!);
    }
  }

  Future<void> deleteEducation(String id) =>
      _client.from('job_educations').delete().eq('id', id);

  Future<List<Resume>> fetchResumes(String profileId) async {
    final rows = await _client
        .from('resumes')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows).map(Resume.fromJson).toList();
  }

  /// Uploads a CV into the person's own folder of the private `cvs` bucket
  /// and lists it under Resume / CV.
  Future<Resume> uploadResume({required String fileName, required Uint8List bytes}) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? '.pdf' : fileName.substring(dot).toLowerCase();
    final mime = switch (ext) {
      '.doc' => 'application/msword',
      '.docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/pdf',
    };
    final tail = Random().nextInt(0x7fffffff).toRadixString(16);
    final path = '$uid/${DateTime.now().microsecondsSinceEpoch}_$tail$ext';
    await _client.storage
        .from('cvs')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: false));
    final row = await _client
        .from('resumes')
        .insert({
          'profile_id': uid,
          'file_path': path,
          'file_name': fileName,
          'size_bytes': bytes.lengthInBytes,
        })
        .select()
        .single();
    return Resume.fromJson(row);
  }

  /// Removes it from the list and the file from storage. An application that
  /// was sent with it keeps its own link; the business loses the file with
  /// it, as 00052 says.
  Future<void> deleteResume(Resume r) async {
    await _client.from('resumes').delete().eq('id', r.id);
    try {
      await _client.storage.from('cvs').remove([r.filePath]);
    } catch (_) {}
  }

  /// A short-lived address for a private CV — its owner's, or one sent to
  /// the caller's business with an application.
  Future<String> cvUrl(String path) =>
      _client.storage.from('cvs').createSignedUrl(path, 600);

  // ── The business's side ──

  Future<List<Job>> fetchForBusiness(String businessId) async {
    final rows = await _client
        .from('jobs')
        .select(_select)
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows).map(Job.fromJson).toList();
  }

  /// Applications per job, for the counts on My Jobs.
  Future<Map<String, int>> applicationCounts(List<String> jobIds) async {
    if (jobIds.isEmpty) return const {};
    final rows = await _client.from('job_applications').select('job_id').inFilter('job_id', jobIds);
    final counts = <String, int>{};
    for (final r in List<Map<String, dynamic>>.from(rows)) {
      final id = r['job_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  /// Views and the rest for one job (`job_stats`, 00052), as kind → total.
  Future<Map<String, int>> stats(String jobId) async {
    final rows = await _client.rpc('job_stats', params: {'p_job': jobId});
    return {
      for (final r in List<Map<String, dynamic>>.from(rows as List))
        r['kind'] as String: (r['total'] as num?)?.toInt() ?? 0,
    };
  }

  /// Writes the job — a new row, or over [id]. Returns its id.
  Future<String> save({String? id, required Map<String, dynamic> row}) async {
    if (id == null) {
      final created = await _client.from('jobs').insert(row).select('id').single();
      return created['id'] as String;
    }
    await _client.from('jobs').update(row).eq('id', id);
    return id;
  }

  Future<void> setStatus(String id, JobStatus status) =>
      _client.from('jobs').update({'status': status.value}).eq('id', id);

  /// A picture for a job, under `jobs/<business id>/` (00069).
  Future<String> uploadImage({
    required String businessId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final dot = fileName.lastIndexOf('.');
    var ext = dot == -1 ? '.jpg' : fileName.substring(dot).toLowerCase();
    if (!const {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext)) ext = '.jpg';
    final mime = ext == '.png' ? 'image/png' : ext == '.webp' ? 'image/webp' : 'image/jpeg';
    final tail = Random().nextInt(0x7fffffff).toRadixString(16);
    final path = 'jobs/$businessId/${DateTime.now().microsecondsSinceEpoch}_$tail$ext';
    await _client.storage
        .from('media')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: false));
    return _client.storage.from('media').getPublicUrl(path);
  }

  Future<List<JobApplication>> applicants(String jobId) async {
    final rows = await _client.rpc('job_applicants', params: {'p_job': jobId});
    return [
      for (final r in List<Map<String, dynamic>>.from(rows as List))
        JobApplication.fromJson(r, jobId: jobId),
    ];
  }

  Future<void> setApplicationStatus(String applicationId, String status) =>
      _client.from('job_applications').update({'status': status}).eq('id', applicationId);

  Future<void> setShortlisted(String applicationId, bool value) =>
      _client.from('job_applications').update({'shortlisted': value}).eq('id', applicationId);

  /// Job categories the client keeps in the panel (scope 'job').
  Future<List<({String id, String name})>> categories() async {
    final rows = await _client
        .from('categories')
        .select('id, name, name_en')
        .eq('scope', 'job')
        .eq('is_active', true)
        .order('sort_order');
    return [
      for (final r in List<Map<String, dynamic>>.from(rows))
        (id: r['id'] as String, name: r['name'] as String),
    ];
  }
}
