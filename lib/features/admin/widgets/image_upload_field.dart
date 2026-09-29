import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/media_usage.dart';

/// Picks an image, uploads it, and hands back the public URL.
///
/// The editor used to ask for a URL typed into a text box, which meant the
/// person managing the directory had to host the picture somewhere else
/// first. This uploads to the `media` bucket instead.
///
/// The field stays editable, so an address that is already good — the 129
/// photographs still sitting on the WordPress site — can be pasted or left
/// alone.
///
/// **Replaced pictures are cleared out of the bucket**, carefully. Replacing
/// or removing a picture used to leave the old file in storage for good,
/// and so did a picture uploaded into a form that was then cancelled. The
/// field cannot know when its form saves, and must not delete a file the
/// saved row, or any other row, still shows. So it only remembers: every
/// file of ours its controller has held while the form was open — the one
/// it opened with, and each upload. When the route the form sits in (its
/// dialog or page) is popped, a few seconds later, each remembered file
/// other than the one the field ends on is removed **only if the database
/// reports that nothing uses it** (`mediaUsage`, which searches every table).
/// The file the field ends on is kept, unless it was uploaded here and
/// nothing uses it — the form was cancelled.
///
/// That relies on one thing of the call sites: **the form's save has
/// finished before its route is popped**. All eleven do exactly that (await
/// the save, then `Navigator.pop`); a cancelled form never saved, and a
/// failed save keeps the form open. Were a form to pop first and save after,
/// the old file would still be safe — the row still shows it when checked —
/// but a new upload might be judged unused before the row was written.
/// Such a form should pass `cleanUpOnPop: false`. A field on a route that
/// is never popped simply never clears anything.
class ImageUploadField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  /// Where in the bucket the file lands, e.g. `businesses/logo`.
  final String folder;

  /// Whether files this form stops using are cleared out when its route is
  /// popped; see the class comment for what that asks of the form.
  final bool cleanUpOnPop;

  const ImageUploadField({
    super.key,
    required this.label,
    required this.controller,
    required this.folder,
    this.cleanUpOnPop = true,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

/// What one form's picture has been while it was open. Kept on the
/// controller rather than the field: a form in tabs disposes the field when
/// another tab is shown and builds a new one on the way back, and the
/// history has to survive that to be of use when the form closes.
class _FieldHistory {
  /// Our bucket's files the controller has held — at open, and each upload.
  final Set<String> paths = {};

  /// Those uploaded by this form, which nothing may use if it was cancelled.
  final Set<String> uploaded = {};

  /// The value last seen, should the controller be disposed by the time the
  /// form's route is popped.
  String last = '';

  /// Set once the clean-up is waiting on the route.
  bool hooked = false;
}

final _histories = Expando<_FieldHistory>('ImageUploadField history');

/// After the form's route is popped: each remembered file the field does not
/// end on, and an upload it does end on, goes if nothing in the database
/// uses it. Any doubt — the check fails, the storage call fails — leaves the
/// file where it is.
Future<void> _cleanUp(
  _FieldHistory history,
  TextEditingController controller,
) async {
  // Margin for a save still landing as the dialog closes.
  await Future<void>.delayed(const Duration(seconds: 10));

  String current;
  try {
    current = controller.text;
  } catch (_) {
    current = history.last;
  }
  final endsOn = mediaBucketPath(current);

  final storage = SupabaseConfig.client.storage.from('media');
  for (final path in history.paths.toList()) {
    if (path == endsOn && !history.uploaded.contains(path)) continue;
    try {
      final uses = await mediaUsage(path);
      if (uses.isNotEmpty) continue;
      await storage.remove([path]);
      history.paths.remove(path);
      history.uploaded.remove(path);
    } catch (_) {
      // Left in place: a file kept by mistake costs a little space, a file
      // removed by mistake is a broken picture on the site.
    }
  }
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  bool _busy = false;
  String? _error;

  _FieldHistory get _history =>
      _histories[widget.controller] ??= _FieldHistory();

  void _remember() => _history.last = widget.controller.text;

  @override
  void initState() {
    super.initState();
    final history = _history;
    final path = mediaBucketPath(widget.controller.text);
    if (path != null) history.paths.add(path);
    history.last = widget.controller.text;
    widget.controller.addListener(_remember);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final history = _history;
    if (!widget.cleanUpOnPop || history.hooked) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    history.hooked = true;
    final controller = widget.controller;
    route.popped.then((_) {
      // A controller that outlives its dialog is watched again next time.
      history.hooked = false;
      return _cleanUp(history, controller);
    });
  }

  @override
  void didUpdateWidget(ImageUploadField old) {
    super.didUpdateWidget(old);
    if (old.controller == widget.controller) return;
    old.controller.removeListener(_remember);
    widget.controller.addListener(_remember);
    final path = mediaBucketPath(widget.controller.text);
    if (path != null) _history.paths.add(path);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_remember);
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    setState(() => _error = null);

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 85,
      );
    } catch (e) {
      setState(() => _error = 'לא ניתן לפתוח את בוחר הקבצים');
      return;
    }
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();

      // The bucket rejects anything over 10MB, and a rejected upload reads as
      // a failure rather than as "too big", so it is said plainly here.
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        setState(() {
          _busy = false;
          _error = 'הקובץ גדול מ-10MB';
        });
        return;
      }

      final ext = _extensionOf(picked.name);
      final path =
          '${widget.folder}/${DateTime.now().millisecondsSinceEpoch}$ext';

      await SupabaseConfig.client.storage
          .from('media')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _mimeOf(ext), upsert: false),
          );

      final url = SupabaseConfig.client.storage
          .from('media')
          .getPublicUrl(path);

      // Remembered before anything else can go wrong: this form made it, so
      // it is this form's to clear away if it ends up unused.
      _history
        ..paths.add(path)
        ..uploaded.add(path);

      if (!mounted) return;
      setState(() {
        widget.controller.text = url;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'ההעלאה נכשלה. נסו שוב.';
      });
    }
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = name.substring(dot).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp', '.gif'}.contains(ext)
        ? ext
        : '.jpg';
  }

  static String _mimeOf(String ext) => switch (ext) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.gif' => 'image/gif',
    _ => 'image/jpeg',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            color: AppColors.adminTextMedium,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // What is stored right now, so it is obvious whether the upload
            // landed and what the app will show.
            ValueListenableBuilder(
              valueListenable: widget.controller,
              builder: (_, value, _) => NetworkPhoto(
                url: value.text,
                width: 64,
                height: 64,
                radius: BorderRadius.circular(6),
                icon: Icons.image_outlined,
                iconSize: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: widget.controller,
                    style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'כתובת התמונה',
                      hintStyle: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 12,
                        color: AppColors.adminTextLight,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _busy ? null : _pickAndUpload,
                        icon: _busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_outlined, size: 16),
                        label: Text(
                          _busy ? 'מעלה…' : 'העלאת תמונה',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (widget.controller.text.isNotEmpty)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  widget.controller.clear();
                                }),
                          child: Text(
                            'הסרה',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      if (_error != null)
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 11,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
