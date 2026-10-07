import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/router/app_router.dart' show AppNavigation;
import '../../../shared/widgets/m_kit.dart';
import '../../../shared/widgets/m_step_form.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../../business_owner/data/owner_data.dart';
import '../../businesses/models/business.dart';
import '../models/job.dart';
import '../providers/job_providers.dart';

/// Post a Job (`business_side/Post a Job*.png`), laid out like Add Apartment:
///
/// Step 1, the job: title, category and type, location, experience and
///   schedule, salary and how it is paid, and whether it suits youth or
///   students (the residents' Jobs list filters on both).
/// Step 2, the text: about the job, responsibilities, requirements — a line
///   each, which the job page turns into bullets.
/// Step 3, who to contact, and pictures.
///
/// With [jobId] it edits that job, keeping its status; "Save Draft" always
/// stores it as a draft, which only the business sees.
class PostJobScreen extends ConsumerStatefulWidget {
  final String? jobId;
  const PostJobScreen({super.key, this.jobId});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  int _step = 0;

  // ── Step 1 ──
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _salary = TextEditingController();
  String? _categoryId;
  JobType? _type;
  JobExperience? _experience;
  JobSchedule? _schedule;
  PayPeriod? _period;
  bool _forYouth = false;
  bool _forStudents = false;

  // ── Step 2 ──
  final _about = TextEditingController();
  final _responsibilities = TextEditingController();
  final _requirements = TextEditingController();

  // ── Step 3 ──
  final _contactName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  /// Public addresses, uploaded as they are picked so the last button does
  /// not wait on a slow connection; the first is the job's cover.
  static const _maxImages = 5;
  final List<String> _images = [];
  bool _uploading = false;

  /// The row this form writes over: the job being edited, or the draft saved
  /// a moment ago, so a second save does not add another job.
  String? _savedId;

  /// The status the job had when it was opened, kept on an edit.
  JobStatus? _loadedStatus;
  String? _loadedBusinessId;
  late bool _loading = widget.jobId != null;
  bool _notFound = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _savedId = widget.jobId;
    if (widget.jobId != null) {
      _load(widget.jobId!);
    } else {
      // The poster's name and the business's own address, phone and e-mail
      // to start with; all can be changed.
      _contactName.text = ref.read(authProvider)?.name ?? '';
      ref.listenManual<AsyncValue<Business?>>(
        myBusinessProvider,
        (_, next) => _prefill(next.valueOrNull),
        fireImmediately: true,
      );
    }
  }

  void _prefill(Business? b) {
    if (b == null || !mounted) return;
    setState(() {
      if (_location.text.isEmpty) _location.text = b.address;
      if (_phone.text.isEmpty) _phone.text = b.phone ?? b.whatsapp ?? '';
      if (_email.text.isEmpty) _email.text = b.email ?? '';
    });
  }

  Future<void> _load(String id) async {
    Job? job;
    try {
      job = await ref.read(jobRepositoryProvider).fetchById(id);
    } catch (_) {
      job = null;
    }
    if (!mounted) return;
    if (job == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }
    final j = job;
    setState(() {
      _loadedStatus = j.status;
      _loadedBusinessId = j.businessId;
      _title.text = j.title;
      _categoryId = j.categoryId;
      _type = j.jobType;
      _location.text = j.location ?? '';
      _experience = j.experience ?? (j.noExperience ? JobExperience.none : null);
      _schedule = j.schedule ?? (j.shiftWork ? JobSchedule.shifts : null);
      if (j.salary != null) {
        final s = j.salary!;
        _salary.text = s == s.roundToDouble() ? '${s.round()}' : '$s';
      }
      _period = j.payPeriod;
      _forYouth = j.forYouth;
      _forStudents = j.forStudents;
      _about.text = j.description ?? '';
      _responsibilities.text = j.responsibilities ?? '';
      _requirements.text = j.requirements ?? '';
      _contactName.text = j.contactName ?? '';
      _phone.text = j.contactPhone ?? '';
      _email.text = j.contactEmail ?? '';
      _images
        ..clear()
        ..addAll(j.images);
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _location,
      _salary,
      _about,
      _responsibilities,
      _requirements,
      _contactName,
      _phone,
      _email,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Editing a job that is already out (active, closed, expired): the last
  /// button saves it as it is. A draft — new or reopened — is posted by it.
  bool get _editingPosted =>
      _loadedStatus != null && _loadedStatus != JobStatus.draft;

  String? get _businessId => _loadedBusinessId ?? ref.read(myBusinessIdProvider);

  // ── Pictures ──

  Future<void> _pickImages() async {
    final businessId = _businessId;
    if (businessId == null || _uploading) return;
    final room = _maxImages - _images.length;
    if (room <= 0) {
      mToast(context, mTr(context, 'Up to $_maxImages images.', 'עד $_maxImages תמונות.'));
      return;
    }
    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(maxWidth: 2000, imageQuality: 85);
    } catch (_) {
      if (mounted) _uploadFailed();
      return;
    }
    if (picked.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    final repo = ref.read(jobRepositoryProvider);
    for (final file in picked.take(room)) {
      try {
        final bytes = await file.readAsBytes();
        // The bucket refuses anything over 10MB; said here rather than as a
        // failed upload.
        if (bytes.lengthInBytes > 10 * 1024 * 1024) {
          if (mounted) {
            mToast(context, mTr(context, 'That image is over 10MB.', 'התמונה גדולה מ-10MB.'), error: true);
          }
          continue;
        }
        final url = await repo.uploadImage(businessId: businessId, fileName: file.name, bytes: bytes);
        if (!mounted) return;
        setState(() => _images.add(url));
      } catch (_) {
        if (mounted) _uploadFailed();
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  void _uploadFailed() =>
      mToast(context, mTr(context, 'The image could not be uploaded.', 'לא ניתן היה להעלות את התמונה.'), error: true);

  // ── Saving ──

  Map<String, dynamic> _row(String businessId, String status) {
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final phone = text(_phone);
    return {
      'business_id': businessId,
      'title': _title.text.trim(),
      'category_id': _categoryId,
      'job_type': _type?.value,
      'location': text(_location),
      'experience': _experience?.value,
      'schedule': _schedule?.value,
      'shift_work': _schedule == JobSchedule.shifts,
      'no_experience': _experience == JobExperience.none,
      'salary_min': double.tryParse(_salary.text.trim().replaceAll(',', '')),
      'salary_period': _period?.value,
      'for_youth': _forYouth,
      'for_students': _forStudents,
      'description': text(_about),
      'responsibilities': text(_responsibilities),
      'requirements': text(_requirements),
      'contact_name': text(_contactName),
      'contact_phone': phone,
      'contact_whatsapp': phone,
      'contact_email': text(_email),
      // Residents apply in the app, with a CV if they have one.
      'apply_by_form': true,
      'form_accepts_cv': true,
      'images': _images,
      'image_url': _images.isEmpty ? null : _images.first,
      'status': status,
    };
  }

  Future<void> _save({required bool draft}) async {
    if (_saving || _loading) return;
    final businessId = _businessId;
    if (businessId == null) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _step = 0);
      mToast(context, mTr(context, 'Give the job a title.', 'תנו למשרה כותרת.'), error: true);
      return;
    }
    if (_uploading) {
      mToast(context, mTr(context, 'Wait for the images to finish uploading.', 'המתינו לסיום העלאת התמונות.'));
      return;
    }
    final status = draft
        ? JobStatus.draft
        : _editingPosted
        ? _loadedStatus!
        : JobStatus.active;
    final posting = !draft && !_editingPosted;

    setState(() => _saving = true);
    try {
      final id = await ref
          .read(jobRepositoryProvider)
          .save(id: _savedId, row: _row(businessId, status.value));
      ref.invalidate(businessJobsProvider(businessId));
      ref.invalidate(jobProvider(id));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savedId = id;
        _loadedStatus = status;
      });
      if (draft) {
        mToast(context, mTr(context, 'Draft saved.', 'הטיוטה נשמרה.'));
      } else if (posting) {
        context.pushReplacement('/business-jobs/$id/posted');
      } else {
        context.back('/business-jobs/$id');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      mToast(
        context,
        draft
            ? mTr(context, 'The draft could not be saved. Try again.', 'לא ניתן היה לשמור את הטיוטה. נסו שוב.')
            : mTr(context, 'The job could not be saved. Try again.', 'לא ניתן היה לשמור את המשרה. נסו שוב.'),
        error: true,
      );
    }
  }

  void _onBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.back('/business-jobs');
    }
  }

  // ── Layout ──

  @override
  Widget build(BuildContext context) {
    final businessId = _loadedBusinessId ?? ref.watch(myBusinessIdProvider);
    final ready = !_loading && !_notFound && businessId != null;
    return MPage(
      title: widget.jobId == null || !_editingPosted
          ? mTr(context, 'Post a Job', 'פרסום משרה')
          : mTr(context, 'Edit Job', 'עריכת משרה'),
      onBack: _onBack,
      action: ready
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _save(draft: true),
              child: Text(
                mTr(context, 'Save Draft', 'שמירת טיוטה'),
                style: mText(12, weight: FontWeight.w500, color: _saving ? mStepMid.withValues(alpha: 0.4) : mStepMid),
              ),
            )
          : null,
      bottom: ready
          ? MStepButton(
              label: _step < 2
                  ? mTr(context, 'Next', 'הבא')
                  : _editingPosted
                  ? mTr(context, 'Save', 'שמירה')
                  : mTr(context, 'Post a Job', 'פרסום משרה'),
              arrow: _step < 2,
              loading: _saving && _step == 2,
              onTap: _step < 2 ? () => setState(() => _step++) : () => _save(draft: false),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notFound
          ? MEmpty(
              icon: IconsaxPlusLinear.briefcase,
              title: mTr(context, 'This job was not found', 'המשרה לא נמצאה'),
            )
          : businessId == null
          ? MEmpty(
              icon: IconsaxPlusLinear.briefcase,
              title: mTr(context, 'This needs a business account', 'נדרש חשבון עסקי'),
              text: mTr(
                context,
                'Jobs are posted by businesses. Sign in with your business account to post one.',
                'משרות מפורסמות על ידי עסקים. התחברו עם החשבון העסקי כדי לפרסם משרה.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 24),
              children: [
                Center(
                  child: MStepProgressBar(
                    currentStep: _step,
                    labels: [
                      mTr(context, 'Basic Info', 'פרטים בסיסיים'),
                      mTr(context, 'Details', 'פרטים'),
                      mTr(context, 'Contact', 'יצירת קשר'),
                    ],
                    onStepTap: (i) => setState(() => _step = i),
                  ),
                ),
                const SizedBox(height: 32),
                ...switch (_step) {
                  0 => _buildJob(),
                  1 => _buildText(),
                  _ => _buildContact(),
                },
              ],
            ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: mText(16, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(subtitle, style: mText(12, color: mStepGrey)),
      ],
    );
  }

  /// Two cards side by side, as the design pairs them.
  Widget _pair(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  List<DropdownMenuItem<T>> _items<T>(List<T> values, String Function(T) label) => [
    for (final v in values)
      DropdownMenuItem<T>(
        value: v,
        child: Text(label(v), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
  ];

  // ═══════════════════════════════════════════════
  // Step 1: the job
  // ═══════════════════════════════════════════════
  List<Widget> _buildJob() {
    final categories = ref.watch(jobCategoriesProvider).valueOrNull ?? const [];
    final typeCard = MFormCard(
      label: mTr(context, 'Job Type', 'סוג משרה'),
      child: MDropdownRow<JobType>(
        placeholder: mTr(context, 'Select a job type', 'בחרו סוג משרה'),
        value: _type,
        items: _items(JobType.values, (t) => t.label),
        onChanged: (v) => setState(() => _type = v),
      ),
    );
    return [
      _sectionHeader(
        mTr(context, 'Job Details', 'פרטי המשרה'),
        mTr(context, 'Basic information about the job.', 'מידע בסיסי על המשרה.'),
      ),
      const SizedBox(height: 20),
      MFormCard(
        label: mTr(context, 'Job Title *', 'כותרת המשרה *'),
        child: MInputRow(
          controller: _title,
          placeholder: mTr(context, 'E.g. Cafe Team Member', 'לדוגמה: עובד/ת בית קפה'),
        ),
      ),
      const SizedBox(height: 16),
      // The categories are the client's, from the panel; with none there,
      // there is nothing to choose.
      if (categories.isEmpty)
        typeCard
      else
        _pair(
          MFormCard(
            label: mTr(context, 'Category', 'קטגוריה'),
            child: MDropdownRow<String>(
              placeholder: mTr(context, 'Select a category', 'בחרו קטגוריה'),
              value: _categoryId,
              items: [
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ),
          typeCard,
        ),
      const SizedBox(height: 16),
      MFormCard(
        label: mTr(context, 'Location', 'מיקום'),
        child: MInputRow(controller: _location, placeholder: mTr(context, 'Enter location', 'הזינו מיקום')),
      ),
      const SizedBox(height: 16),
      _pair(
        MFormCard(
          label: mTr(context, 'Experience', 'ניסיון'),
          child: MDropdownRow<JobExperience>(
            placeholder: mTr(context, 'Select', 'בחרו'),
            value: _experience,
            items: _items(JobExperience.values, (e) => e.label),
            onChanged: (v) => setState(() => _experience = v),
          ),
        ),
        MFormCard(
          label: mTr(context, 'Job Schedule', 'שעות עבודה'),
          child: MDropdownRow<JobSchedule>(
            placeholder: mTr(context, 'Select', 'בחרו'),
            value: _schedule,
            items: _items(JobSchedule.values, (s) => s.label),
            onChanged: (v) => setState(() => _schedule = v),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _pair(
        MFormCard(
          label: mTr(context, 'Salary', 'שכר'),
          child: MInputRow(
            controller: _salary,
            placeholder: mTr(context, 'Amount', 'סכום'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        MFormCard(
          label: mTr(context, 'Pay Period', 'תדירות תשלום'),
          child: MDropdownRow<PayPeriod>(
            placeholder: mTr(context, 'Select', 'בחרו'),
            value: _period,
            items: _items(PayPeriod.values, (p) => p.label),
            onChanged: (v) => setState(() => _period = v),
          ),
        ),
      ),
      const SizedBox(height: 18),
      _check(
        mTr(context, 'Suitable for youth', 'מתאים לנוער'),
        _forYouth,
        (v) => setState(() => _forYouth = v),
      ),
      const SizedBox(height: 10),
      _check(
        mTr(context, 'Suitable for students', 'מתאים לסטודנטים'),
        _forStudents,
        (v) => setState(() => _forStudents = v),
      ),
    ];
  }

  Widget _check(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? mStepMid : Colors.white,
              border: Border.all(color: value ? mStepMid : const Color(0xFFBDBDBD), width: 1.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: value ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Text(label, style: mText(13)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Step 2: the text
  // ═══════════════════════════════════════════════
  List<Widget> _buildText() {
    return [
      _sectionHeader(
        mTr(context, 'Additional Details', 'פרטים נוספים'),
        mTr(context, 'Describe the role and what you’re looking for.', 'תארו את התפקיד ואת מי שאתם מחפשים.'),
      ),
      const SizedBox(height: 20),
      _tallField(
        mTr(context, 'About the Job', 'על המשרה'),
        _about,
        mTr(
          context,
          'Describe the role, responsibilities and what the candidate will be doing...',
          'תארו את התפקיד, את תחומי האחריות ומה יעשה המועמד/ת...',
        ),
      ),
      const SizedBox(height: 16),
      _tallField(
        mTr(context, 'Key Responsibilities', 'תחומי אחריות'),
        _responsibilities,
        mTr(context, 'One responsibility per line...', 'תחום אחריות אחד בכל שורה...'),
      ),
      const SizedBox(height: 16),
      _tallField(
        mTr(context, 'Requirements', 'דרישות'),
        _requirements,
        mTr(context, 'One skill, qualification or requirement per line...', 'כישור, הכשרה או דרישה אחת בכל שורה...'),
      ),
    ];
  }

  /// The tall box of the apartment form's description.
  Widget _tallField(String label, TextEditingController controller, String hint) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: mStepHairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: mText(13, weight: FontWeight.w500)),
          const SizedBox(height: 13),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: mText(14),
              decoration: InputDecoration(
                hintText: hint,
                hintMaxLines: 3,
                hintStyle: mText(14, color: mStepGrey),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Step 3: contact and pictures
  // ═══════════════════════════════════════════════
  List<Widget> _buildContact() {
    return [
      _sectionHeader(
        mTr(context, 'Contact Information', 'פרטי התקשרות'),
        mTr(context, 'Who candidates can reach about the job.', 'למי יוכלו המועמדים לפנות בנוגע למשרה.'),
      ),
      const SizedBox(height: 20),
      MFormCard(
        label: mTr(context, 'Contact Person', 'איש/אשת קשר'),
        child: MInputRow(controller: _contactName, placeholder: mTr(context, 'Full name', 'שם מלא')),
      ),
      const SizedBox(height: 16),
      MFormCard(
        label: mTr(context, 'Phone / WhatsApp', 'טלפון / וואטסאפ'),
        child: MInputRow(
          controller: _phone,
          placeholder: mTr(context, 'Enter phone', 'הזינו טלפון'),
          keyboardType: TextInputType.phone,
        ),
      ),
      const SizedBox(height: 16),
      MFormCard(
        label: mTr(context, 'Email', 'אימייל'),
        child: MInputRow(
          controller: _email,
          placeholder: mTr(context, 'Enter email', 'הזינו אימייל'),
          keyboardType: TextInputType.emailAddress,
        ),
      ),
      const SizedBox(height: 20),
      Text(mTr(context, 'Images', 'תמונות'), style: mText(13, weight: FontWeight.w500)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (_images.length < _maxImages) _addSlot(),
          for (var i = 0; i < _images.length; i++) _thumb(i),
        ],
      ),
    ];
  }

  Widget _addSlot() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickImages,
      child: SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: MDashedBorderPainter(),
          child: Center(
            child: _uploading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                : SvgPicture.asset('assets/icons/m_realestate_plus.svg', width: 24, height: 24),
          ),
        ),
      ),
    );
  }

  Widget _thumb(int index) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: NetworkPhoto(url: _images[index], icon: IconsaxPlusBold.image),
          ),
          PositionedDirectional(
            end: 6,
            top: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _images.removeAt(index)),
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: mKitRed, shape: BoxShape.circle),
                child: SvgPicture.asset('assets/icons/m_realestate_close_x.svg', width: 7.108, height: 7.036),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
