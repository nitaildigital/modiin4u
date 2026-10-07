import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/supabase/account_blocked.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import 'sign_in_action.dart';

/// "Report" on something a resident sees — a review, a business, a listing.
///
/// Both legal texts promise a way to report content, and the panel has had a
/// Reports queue since the start, which nothing filled: no screen wrote to
/// `reports`. The reasons are the table's own (`report_reason`, 00001), so
/// the panel labels them as it already does. App only: the website has no
/// resident accounts, and a report needs one (`reporter_id`).
Future<void> showReportSheet(
  BuildContext context, {
  required String entityType,
  required String entityId,
}) async {
  final he = Localizations.localeOf(context).languageCode == 'he';
  String t(String en, String hebrew) => he ? hebrew : en;
  final messenger = ScaffoldMessenger.of(context);

  void toast(String message, {bool error = false, bool signIn = false}) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        backgroundColor: error ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
        action: signIn ? signInAction(context) : null,
      ),
    );
  }

  if (SupabaseConfig.client.auth.currentUser == null) {
    toast(t('Sign in to report', 'יש להתחבר כדי לדווח'), signIn: true);
    return;
  }

  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReportForm(
      entityType: entityType,
      entityId: entityId,
      t: t,
      onBlocked: () => toast(
        // Said here rather than in the sheet, which closes first.
        he
            ? 'החשבון חסום. לבירור, פנו אלינו דרך עזרה ותמיכה.'
            : 'This account is blocked. To ask why, contact us from Help & Support.',
        error: true,
      ),
    ),
  );
  if (sent == true) {
    toast(t(
      'Thank you. The team will look at it.',
      'תודה. הצוות יבדוק את הדיווח.',
    ));
  }
}

/// One report per person per item (00064): a second one is refused as a
/// duplicate, and the person is told theirs is already in.
bool _alreadyReported(Object e) => e is PostgrestException && e.code == '23505';

class _ReportForm extends StatefulWidget {
  final String entityType;
  final String entityId;
  final String Function(String en, String he) t;
  final VoidCallback onBlocked;

  const _ReportForm({
    required this.entityType,
    required this.entityId,
    required this.t,
    required this.onBlocked,
  });

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  String? _reason;
  final _details = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  List<(String, String)> get _reasons {
    final t = widget.t;
    return [
      ('spam', t('Spam or advertising', 'ספאם או פרסום')),
      ('offensive', t('Offensive content', 'תוכן פוגעני')),
      ('fake', t('False or misleading', 'מידע כוזב או מטעה')),
      ('personal_info', t('Someone\'s personal information', 'מידע אישי של מישהו')),
      ('harassment', t('Harassment', 'הטרדה')),
      ('other', t('Something else', 'אחר')),
    ];
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await SupabaseConfig.client.from('reports').insert({
        'reporter_id': SupabaseConfig.client.auth.currentUser!.id,
        'entity_type': widget.entityType,
        'entity_id': widget.entityId,
        'reason': reason,
        if (_details.text.trim().isNotEmpty) 'details': _details.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (_alreadyReported(e)) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = widget.t(
            'You have already reported this. The team has it.',
            'כבר דיווחת על זה. הדיווח אצל הצוות.',
          );
        });
        return;
      }
      if (await refusedAsBlocked(e)) {
        if (mounted) Navigator.of(context).pop(false);
        widget.onBlocked();
        return;
      }
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = widget.t(
          'Could not send. Please try again.',
          'לא ניתן היה לשלוח. נסו שוב.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Padding(
      // Above the keyboard while the details are typed.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('Report', 'דיווח'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t(
                  'What is wrong with it? The team sees your report; the person who wrote it does not.',
                  'מה הבעיה? הדיווח מגיע לצוות בלבד, לא למי שכתב את התוכן.',
                ),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (final (value, label) in _reasons)
                      RadioListTile<String>(
                        value: value,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          label,
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _details,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: t('More details (optional)', 'פרטים נוספים (לא חובה)'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _reason == null || _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.midBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          t('Send report', 'שליחת דיווח'),
                          style: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
