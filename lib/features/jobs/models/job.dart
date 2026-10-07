import '../../../core/providers/content_language.dart';

/// The choices the Post a Job form offers, as the `jobs` table stores them
/// (00052, 00069). Labels are the reader's language.
enum JobType { fullTime, partTime, shifts, temporary, freelance, internship }

enum JobExperience { none, junior, mid, senior }

enum JobSchedule { fixed, shifts, flexible }

enum PayPeriod { hour, month, year, project }

enum JobStatus { draft, active, expired, closed }

// Labels follow the language the app shows (content_language.dart), so a
// model can name its choices without a BuildContext.
String _he(String en, String he) => contentInEnglish ? en : he;

extension JobTypeX on JobType {
  String get value => const {
    JobType.fullTime: 'full_time',
    JobType.partTime: 'part_time',
    JobType.shifts: 'shifts',
    JobType.temporary: 'temporary',
    JobType.freelance: 'freelance',
    JobType.internship: 'internship',
  }[this]!;

  String get label => switch (this) {
    JobType.fullTime => _he('Full-time', 'משרה מלאה'),
    JobType.partTime => _he('Part-time', 'משרה חלקית'),
    JobType.shifts => _he('Shifts', 'משמרות'),
    JobType.temporary => _he('Temporary', 'זמנית'),
    JobType.freelance => _he('Freelance', 'פרילנס'),
    JobType.internship => _he('Internship', 'התמחות'),
  };

  static JobType? parse(String? v) =>
      JobType.values.where((t) => t.value == v).firstOrNull;
}

extension JobExperienceX on JobExperience {
  String get value => name;

  String get label => switch (this) {
    JobExperience.none => _he('No experience', 'ללא ניסיון'),
    JobExperience.junior => _he('1+ year experience', 'שנת ניסיון ומעלה'),
    JobExperience.mid => _he('3+ years experience', '3 שנות ניסיון ומעלה'),
    JobExperience.senior => _he('5+ years experience', '5 שנות ניסיון ומעלה'),
  };

  static JobExperience? parse(String? v) =>
      JobExperience.values.where((t) => t.value == v).firstOrNull;
}

extension JobScheduleX on JobSchedule {
  String get value => name;

  String get label => switch (this) {
    JobSchedule.fixed => _he('Fixed hours', 'שעות קבועות'),
    JobSchedule.shifts => _he('Shift work', 'עבודה במשמרות'),
    JobSchedule.flexible => _he('Flexible hours', 'שעות גמישות'),
  };

  static JobSchedule? parse(String? v) =>
      JobSchedule.values.where((t) => t.value == v).firstOrNull;
}

extension PayPeriodX on PayPeriod {
  String get value => name;

  String get label => switch (this) {
    PayPeriod.hour => _he('Per hour', 'לשעה'),
    PayPeriod.month => _he('Per month', 'לחודש'),
    PayPeriod.year => _he('Per year', 'לשנה'),
    PayPeriod.project => _he('Per project', 'לפרויקט'),
  };

  /// The short suffix after an amount: ₪38/hour.
  String get suffix => switch (this) {
    PayPeriod.hour => _he('/hour', 'לשעה'),
    PayPeriod.month => _he('/month', 'לחודש'),
    PayPeriod.year => _he('/year', 'לשנה'),
    PayPeriod.project => _he('/project', 'לפרויקט'),
  };

  static PayPeriod? parse(String? v) =>
      PayPeriod.values.where((t) => t.value == v).firstOrNull;
}

extension JobStatusX on JobStatus {
  String get value => name;

  String get label => switch (this) {
    JobStatus.draft => _he('Draft', 'טיוטה'),
    JobStatus.active => _he('Active', 'פעילה'),
    JobStatus.expired => _he('Expired', 'פגה'),
    JobStatus.closed => _he('Closed', 'סגורה'),
  };

  static JobStatus parse(String? v) =>
      JobStatus.values.where((t) => t.value == v).firstOrNull ?? JobStatus.draft;
}

/// A job opening, with the business it belongs to.
class Job {
  final String id;
  final String businessId;
  final String? categoryId;
  final String title;
  final String? description;
  final String? responsibilities;
  final String? requirements;
  final JobType? jobType;
  final JobExperience? experience;
  final JobSchedule? schedule;
  final String? location;
  final double? salary;
  final PayPeriod? payPeriod;
  final List<String> images;
  final bool forYouth;
  final bool forStudents;
  final bool noExperience;
  final bool shiftWork;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final JobStatus status;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? promotedUntil;

  // The business, joined.
  final String? businessNameHe;
  final String? businessNameEn;
  final String? businessLogo;
  final String? businessCover;
  final String? businessAbout;

  const Job({
    required this.id,
    required this.businessId,
    this.categoryId,
    required this.title,
    this.description,
    this.responsibilities,
    this.requirements,
    this.jobType,
    this.experience,
    this.schedule,
    this.location,
    this.salary,
    this.payPeriod,
    this.images = const [],
    this.forYouth = false,
    this.forStudents = false,
    this.noExperience = false,
    this.shiftWork = false,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.status = JobStatus.draft,
    this.publishedAt,
    this.expiresAt,
    required this.createdAt,
    this.promotedUntil,
    this.businessNameHe,
    this.businessNameEn,
    this.businessLogo,
    this.businessCover,
    this.businessAbout,
  });

  String? get businessName =>
      businessNameHe == null ? null : localName(businessNameHe!, businessNameEn);

  bool get isLive =>
      status == JobStatus.active && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool get isPromoted => promotedUntil != null && promotedUntil!.isAfter(DateTime.now());

  /// The date a list shows: when it went live, or when it was written.
  DateTime get shownDate => publishedAt ?? createdAt;

  String? get coverImage => images.isEmpty ? null : images.first;

  /// "₪38/hour", or null when no salary was given.
  String? get salaryLabel {
    if (salary == null) return null;
    final n = salary!;
    final amount = n == n.roundToDouble()
        ? _thousands(n.round())
        : n.toStringAsFixed(2);
    return '₪$amount${payPeriod == null ? '' : payPeriod!.suffix}';
  }

  static String _thousands(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// The grey chips under a job: its experience and its schedule.
  List<String> get chips => [
    if (experience != null) experience!.label,
    if (schedule != null) schedule!.label else if (shiftWork) JobSchedule.shifts.label,
  ];

  /// The lines of a free-text list, for the bullets on the job page.
  static List<String> bullets(String? text) => (text ?? '')
      .split('\n')
      .map((l) => l.trim().replaceFirst(RegExp(r'^[-•*]\s*'), ''))
      .where((l) => l.isNotEmpty)
      .toList();

  factory Job.fromJson(Map<String, dynamic> j) {
    final b = j['businesses'];
    final images = (j['images'] as List?)?.whereType<String>().toList() ?? const <String>[];
    final single = j['image_url'] as String?;
    return Job(
      id: j['id'] as String,
      businessId: j['business_id'] as String,
      categoryId: j['category_id'] as String?,
      title: (j['title'] as String?) ?? '',
      description: j['description'] as String?,
      responsibilities: j['responsibilities'] as String?,
      requirements: j['requirements'] as String?,
      jobType: JobTypeX.parse(j['job_type'] as String?),
      experience: JobExperienceX.parse(j['experience'] as String?),
      schedule: JobScheduleX.parse(j['schedule'] as String?),
      location: j['location'] as String?,
      salary: (j['salary_min'] as num?)?.toDouble() ?? (j['salary_max'] as num?)?.toDouble(),
      payPeriod: PayPeriodX.parse(j['salary_period'] as String?),
      images: images.isEmpty && single != null ? [single] : images,
      forYouth: j['for_youth'] as bool? ?? false,
      forStudents: j['for_students'] as bool? ?? false,
      noExperience: j['no_experience'] as bool? ?? false,
      shiftWork: j['shift_work'] as bool? ?? false,
      contactName: j['contact_name'] as String?,
      contactPhone: j['contact_phone'] as String?,
      contactEmail: j['contact_email'] as String?,
      status: JobStatusX.parse(j['status'] as String?),
      publishedAt: DateTime.tryParse(j['published_at'] as String? ?? ''),
      expiresAt: DateTime.tryParse(j['expires_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      promotedUntil: DateTime.tryParse(j['promoted_until'] as String? ?? ''),
      businessNameHe: b is Map ? b['name'] as String? : null,
      businessNameEn: b is Map ? b['name_en'] as String? : null,
      businessLogo: b is Map ? b['logo_url'] as String? : null,
      businessCover: b is Map ? b['cover_url'] as String? : null,
      businessAbout: b is Map
          ? (b['short_description'] as String?) ?? (b['full_description'] as String?)
          : null,
    );
  }
}

/// An application, as its applicant or the business sees it.
class JobApplication {
  final String id;
  final String jobId;
  final String? profileId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? message;
  final String? cvPath;
  final String status;
  final bool shortlisted;
  final DateTime createdAt;

  // From `job_applicants` (00069), for the business's list.
  final String? avatarUrl;
  final String? location;
  final String? headline;
  final int? experienceYears;

  const JobApplication({
    required this.id,
    required this.jobId,
    this.profileId,
    required this.fullName,
    this.email,
    this.phone,
    this.message,
    this.cvPath,
    this.status = 'new',
    this.shortlisted = false,
    required this.createdAt,
    this.avatarUrl,
    this.location,
    this.headline,
    this.experienceYears,
  });

  bool get isRejected => status == 'unsuitable';

  String get statusLabel => switch (status) {
    'viewed' => _he('Viewed', 'נצפתה'),
    'contacted' => _he('Contacted', 'נוצר קשר'),
    'interview' => _he('Interview', 'ראיון'),
    'suitable' => _he('Shortlisted', 'מתאים/ה'),
    'unsuitable' => _he('Not selected', 'לא נבחר/ה'),
    'accepted' => _he('Accepted', 'התקבל/ה'),
    'archived' => _he('Archived', 'בארכיון'),
    _ => _he('Application Submitted', 'המועמדות נשלחה'),
  };

  factory JobApplication.fromJson(Map<String, dynamic> j, {String? jobId}) => JobApplication(
    id: j['id'] as String,
    jobId: (j['job_id'] as String?) ?? jobId ?? '',
    profileId: j['profile_id'] as String?,
    fullName: (j['full_name'] as String?) ?? '',
    email: j['email'] as String?,
    phone: j['phone'] as String?,
    message: j['message'] as String?,
    cvPath: j['cv_path'] as String?,
    status: (j['status'] as String?) ?? 'new',
    shortlisted: j['shortlisted'] as bool? ?? false,
    createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    avatarUrl: j['avatar_url'] as String?,
    location: j['location'] as String?,
    headline: j['headline'] as String?,
    experienceYears: (j['experience_years'] as num?)?.toInt(),
  );
}

/// The job seeker's profile — My Profile (00069 `job_profiles`).
class JobProfile {
  final String profileId;
  final String? about;
  final List<String> skills;
  final int? experienceYears;
  final String? location;
  final String? additionalInfo;
  final DateTime? updatedAt;

  const JobProfile({
    required this.profileId,
    this.about,
    this.skills = const [],
    this.experienceYears,
    this.location,
    this.additionalInfo,
    this.updatedAt,
  });

  factory JobProfile.fromJson(Map<String, dynamic> j) => JobProfile(
    profileId: j['profile_id'] as String,
    about: j['about'] as String?,
    skills: (j['skills'] as List?)?.whereType<String>().toList() ?? const [],
    experienceYears: (j['experience_years'] as num?)?.toInt(),
    location: j['location'] as String?,
    additionalInfo: j['additional_info'] as String?,
    updatedAt: DateTime.tryParse(j['updated_at'] as String? ?? ''),
  );
}

class WorkExperience {
  final String? id;
  final String title;
  final String company;
  final String? location;
  final JobType? employmentType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;

  const WorkExperience({
    this.id,
    required this.title,
    required this.company,
    this.location,
    this.employmentType,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> j) => WorkExperience(
    id: j['id'] as String?,
    title: (j['title'] as String?) ?? '',
    company: (j['company'] as String?) ?? '',
    location: j['location'] as String?,
    employmentType: JobTypeX.parse(j['employment_type'] as String?),
    startDate: DateTime.tryParse(j['start_date'] as String? ?? ''),
    endDate: DateTime.tryParse(j['end_date'] as String? ?? ''),
    isCurrent: j['is_current'] as bool? ?? false,
    description: j['description'] as String?,
  );

  Map<String, dynamic> toRow(String profileId) => {
    'profile_id': profileId,
    'title': title,
    'company': company,
    'location': location,
    'employment_type': employmentType?.value,
    'start_date': _date(startDate),
    'end_date': isCurrent ? null : _date(endDate),
    'is_current': isCurrent,
    'description': description,
  };
}

class Education {
  final String? id;
  final String qualification;
  final String institution;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;

  const Education({
    this.id,
    required this.qualification,
    required this.institution,
    this.location,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
  });

  factory Education.fromJson(Map<String, dynamic> j) => Education(
    id: j['id'] as String?,
    qualification: (j['qualification'] as String?) ?? '',
    institution: (j['institution'] as String?) ?? '',
    location: j['location'] as String?,
    startDate: DateTime.tryParse(j['start_date'] as String? ?? ''),
    endDate: DateTime.tryParse(j['end_date'] as String? ?? ''),
    isCurrent: j['is_current'] as bool? ?? false,
  );

  Map<String, dynamic> toRow(String profileId) => {
    'profile_id': profileId,
    'qualification': qualification,
    'institution': institution,
    'location': location,
    'start_date': _date(startDate),
    'end_date': isCurrent ? null : _date(endDate),
    'is_current': isCurrent,
  };
}

/// A CV file in the private `cvs` bucket.
class Resume {
  final String id;
  final String filePath;
  final String fileName;
  final int? sizeBytes;
  final DateTime createdAt;

  const Resume({
    required this.id,
    required this.filePath,
    required this.fileName,
    this.sizeBytes,
    required this.createdAt,
  });

  String get sizeLabel {
    final b = sizeBytes;
    if (b == null) return '';
    if (b < 1024 * 1024) return '${(b / 1024).round()} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Resume.fromJson(Map<String, dynamic> j) => Resume(
    id: j['id'] as String,
    filePath: j['file_path'] as String,
    fileName: j['file_name'] as String,
    sizeBytes: (j['size_bytes'] as num?)?.toInt(),
    createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

String? _date(DateTime? d) =>
    d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
