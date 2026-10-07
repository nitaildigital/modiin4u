import 'dart:convert' show HtmlEscape;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../../../core/supabase/supabase_config.dart';
import '../admin_language.dart';
import '../ui/admin_kit.dart';

/// The panel's text editor for an article's (or page's) body: bold, italic,
/// headings, lists, quotes, links and pictures placed inside the text.
///
/// The client asked (6 Oct) for an editor like a word processor in place of
/// the text box, where formatting meant typing HTML. The body stays HTML — the
/// site reads HTML, and the 669 stories brought over from WordPress are HTML —
/// so the editor reads it in and writes it out. It offers only what the
/// site's article page draws (`article_body.dart`): paragraphs, headings,
/// lists, pictures, bold, italic and links.
///
/// A story is written back only when someone has typed in it: opening and
/// saving one leaves the old markup exactly as it was ([onChanged] fires on
/// an edit, not on load). "HTML" shows the markup itself, for the rare case
/// the editor cannot express.
class AdminRichEditor extends StatefulWidget {
  final String initialHtml;

  /// The body as HTML, on every edit.
  final ValueChanged<String> onChanged;

  /// Where a picture placed in the text is uploaded, in the `media` bucket.
  final String imageFolder;
  final String? placeholder;
  final double minHeight;

  const AdminRichEditor({
    super.key,
    required this.initialHtml,
    required this.onChanged,
    this.imageFolder = 'articles/body',
    this.placeholder,
    this.minHeight = 360,
  });

  @override
  State<AdminRichEditor> createState() => _AdminRichEditorState();
}

class _AdminRichEditorState extends State<AdminRichEditor> {
  late final QuillController _controller;
  late final TextEditingController _source;
  final _focus = FocusNode();
  final _scroll = ScrollController();
  bool _showSource = false;
  bool _uploading = false;

  /// True while the editor is filled from HTML, so that is not taken as an
  /// edit.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: _documentFrom(widget.initialHtml),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _source = TextEditingController(text: widget.initialHtml);
    _controller.addListener(_onEdit);
    _loading = false;
  }

  @override
  void dispose() {
    _controller.removeListener(_onEdit);
    _controller.dispose();
    _source.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Plain text from before (paragraphs split by blank lines) reads as
  /// paragraphs; HTML is converted.
  static Document _documentFrom(String html) {
    final text = html.trim();
    if (text.isEmpty) return Document();
    final looksLikeHtml = RegExp(r'<(p|div|br|img|h[1-6]|ul|ol|li|strong|b|em|i|a|span|figure)\b',
            caseSensitive: false)
        .hasMatch(text);
    final source = looksLikeHtml
        ? text
        : text
            .split(RegExp(r'\n\s*\n'))
            .map((p) => '<p>${const HtmlEscape().convert(p.trim()).replaceAll('\n', '<br>')}</p>')
            .join();
    try {
      final delta = HtmlToDelta().convert(source);
      if (delta.isEmpty) return Document();
      return Document.fromDelta(delta);
    } catch (_) {
      return Document()..insert(0, text);
    }
  }

  String _toHtml() {
    final ops = _controller.document.toDelta().toJson().cast<Map<String, dynamic>>();
    final html = QuillDeltaToHtmlConverter(
      ops,
      ConverterOptions(
        multiLineParagraph: false,
        converterOptions: OpConverterOptions(inlineStylesFlag: false),
      ),
    ).convert();
    // An empty editor is an empty body, not "<p><br/></p>"; empty lines and
    // list items left by Enter are not kept either, as the site would draw
    // them as gaps and bare bullets.
    if (_controller.document.toPlainText().trim().isEmpty && !html.contains('<img')) return '';
    return html
        .replaceAll(RegExp(r'<li>(<br/?>)?</li>'), '')
        .replaceAll(RegExp(r'<(ol|ul)></\1>'), '')
        .replaceAll(RegExp(r'<p>(<br/?>)?</p>'), '')
        .trim();
  }

  void _onEdit() {
    if (_loading || _showSource) return;
    widget.onChanged(_toHtml());
  }

  void _toggleSource() {
    setState(() {
      if (_showSource) {
        // Back from the markup: the editor takes in what was typed there.
        _loading = true;
        _controller.document = _documentFrom(_source.text);
        _loading = false;
        widget.onChanged(_source.text);
      } else {
        _source.text = _toHtml().isEmpty ? _source.text : _toHtml();
      }
      _showSource = !_showSource;
    });
  }

  Future<void> _insertImage() async {
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
    } catch (_) {
      _say(tr('לא ניתן לפתוח את בוחר הקבצים', 'Could not open the file picker'));
      return;
    }
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        _say(tr('הקובץ גדול מ-10MB', 'The file is larger than 10MB'));
        return;
      }
      final name = picked.name.toLowerCase();
      final ext = name.contains('.') ? name.substring(name.lastIndexOf('.')) : '.jpg';
      final path = '${widget.imageFolder}/${DateTime.now().millisecondsSinceEpoch}$ext';
      final storage = SupabaseConfig.client.storage.from('media');
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: switch (ext) {
            '.png' => 'image/png',
            '.webp' => 'image/webp',
            '.gif' => 'image/gif',
            _ => 'image/jpeg',
          },
        ),
      );
      final url = storage.getPublicUrl(path);
      // On a line of its own where the cursor is.
      final at = _controller.selection.baseOffset < 0 ? _controller.document.length - 1 : _controller.selection.baseOffset;
      _controller.replaceText(at, 0, BlockEmbed.image(url), null);
      _controller.replaceText(at + 1, 0, '\n', TextSelection.collapsed(offset: at + 2));
    } catch (_) {
      _say(tr('ההעלאה נכשלה', 'Upload failed'));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static QuillIconTheme _iconTheme(AdminKit k) => QuillIconTheme(
    iconButtonSelectedData: IconButtonData(
      // The heading buttons' letters take this one.
      color: Colors.white,
      style: IconButton.styleFrom(backgroundColor: k.accent, foregroundColor: Colors.white),
    ),
    iconButtonUnselectedData: IconButtonData(color: k.inkSoft),
  );

  @override
  Widget build(BuildContext context) {
    final k = AdminKit.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: k.border),
        borderRadius: BorderRadius.circular(k.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: k.subtle,
              border: Border(bottom: BorderSide(color: k.border)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(k.radius)),
            ),
            child: Row(
              children: [
                Expanded(
                  // Its "on" buttons in the panel's blue, not the app's.
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(primary: k.accent),
                    ),
                    child: IgnorePointer(
                    ignoring: _showSource,
                    child: Opacity(
                      opacity: _showSource ? 0.35 : 1,
                      child: QuillSimpleToolbar(
                        controller: _controller,
                        config: QuillSimpleToolbarConfig(
                          multiRowsDisplay: true,
                          showDividers: true,
                          showFontFamily: false,
                          showFontSize: false,
                          showUnderLineButton: false,
                          showStrikeThrough: false,
                          showInlineCode: false,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showListCheck: false,
                          showCodeBlock: false,
                          showIndent: false,
                          showSearchButton: false,
                          showSubscript: false,
                          showSuperscript: false,
                          showDirection: false,
                          headerStyleType: HeaderStyleType.buttons,
                          // A button takes the keyboard on the web; it goes
                          // back to the text, so one can press "list" and
                          // type on.
                          buttonOptions: QuillSimpleToolbarButtonOptions(
                            base: QuillToolbarBaseButtonOptions(
                              afterButtonPressed: _focus.requestFocus,
                              // The panel's blue for what is on, its grey for the rest.
                              iconTheme: _iconTheme(k),
                            ),
                          ),
                          customButtons: [
                            QuillToolbarCustomButtonOptions(
                              icon: _uploading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.image_outlined, size: 20),
                              tooltip: tr('הוספת תמונה לתוך הטקסט', 'Add a picture into the text'),
                              onPressed: _uploading ? null : _insertImage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _toggleSource,
                  icon: Icon(_showSource ? Icons.edit_note : Icons.code, size: 18, color: k.accent),
                  label: Text(_showSource ? tr('עורך', 'Editor') : 'HTML',
                      style: k.label.copyWith(color: k.accent)),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            child: _showSource
                ? TextField(
                    controller: _source,
                    maxLines: null,
                    minLines: 16,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    onChanged: widget.onChanged,
                  )
                : QuillEditor(
                    controller: _controller,
                    focusNode: _focus,
                    scrollController: _scroll,
                    config: QuillEditorConfig(
                      placeholder: widget.placeholder ?? tr('כתבו כאן את הכתבה…', 'Write the article here…'),
                      padding: const EdgeInsets.all(18),
                      minHeight: widget.minHeight,
                      scrollable: false,
                      expands: false,
                      embedBuilders: const [_ImageEmbed()],
                      customStyles: DefaultStyles(
                        paragraph: DefaultTextBlockStyle(
                          k.body.copyWith(fontSize: 16, height: 1.7),
                          const HorizontalSpacing(0, 0),
                          const VerticalSpacing(0, 10),
                          const VerticalSpacing(0, 0),
                          null,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A picture inside the text, as wide as the column allows.
class _ImageEmbed extends EmbedBuilder {
  const _ImageEmbed();

  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final url = embedContext.node.value.data as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              height: 80,
              alignment: Alignment.center,
              color: const Color(0xFFF1F1F1),
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}
