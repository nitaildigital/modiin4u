import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';

/// Picks an image, uploads it, and hands back the public URL.
///
/// The editor used to ask for a URL typed into a text box, which meant the
/// person managing the directory had to host the picture somewhere else
/// first. This uploads to the `media` bucket instead.
///
/// The field stays editable, so an address that is already good — the 129
/// photographs still sitting on the WordPress site — can be pasted or left
/// alone.
class ImageUploadField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  /// Where in the bucket the file lands, e.g. `businesses/logo`.
  final String folder;

  const ImageUploadField({
    super.key,
    required this.label,
    required this.controller,
    required this.folder,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  bool _busy = false;
  String? _error;

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
