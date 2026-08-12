import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class _Post {
  final String id;
  final String authorName;
  final String authorInitials;
  final String category;
  final String content;
  final bool hasImage;
  final String imageLabel;
  final String timeAgo;
  int likes;
  int commentsCount;
  int shares;
  bool isLiked;
  final bool isPinned;
  final List<_Comment> comments;

  _Post({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.category,
    required this.content,
    this.hasImage = false,
    this.imageLabel = '',
    required this.timeAgo,
    required this.likes,
    required this.commentsCount,
    required this.shares,
    bool isLiked = false,
    this.isPinned = false,
    required this.comments,
  }) : isLiked = isLiked;
}

class _Comment {
  final String authorName;
  final String authorInitials;
  final String content;
  final String timeAgo;
  int likes;
  bool isLiked;

  _Comment({
    required this.authorName,
    required this.authorInitials,
    required this.content,
    required this.timeAgo,
    int likes = 0,
    bool isLiked = false,
  })  : likes = likes,
        isLiked = isLiked;
}

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _selectedCategory = 'הכל';
  final _categories = ['הכל', 'כללי', 'שאלה', 'המלצה', 'דיווח', 'שכנים'];

  late List<_Post> _posts;

  @override
  void initState() {
    super.initState();
    _posts = _generateMockPosts();
  }

  List<_Post> get _filteredPosts {
    if (_selectedCategory == 'הכל') return _posts;
    return _posts.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isLoggedIn = user != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.isDark ? context.scaffoldBg : AppColors.sectionBg,
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 600));
          },
          color: AppColors.turquoise,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/community_cover.jpg',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'קהילת מודיעין-מכבים-רעות',
                              style: GoogleFonts.rubik(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.public, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text('קבוצה ציבורית', style: GoogleFonts.rubik(fontSize: 13, color: Colors.white70)),
                                const SizedBox(width: 12),
                                const Icon(Icons.people, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text('12,340 חברים', style: GoogleFonts.rubik(fontSize: 13, color: Colors.white70)),
                                const SizedBox(width: 12),
                                const Icon(Icons.article_outlined, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text('48 פוסטים היום', style: GoogleFonts.rubik(fontSize: 13, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(icon: const Icon(Icons.search, size: 22), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.notifications_outlined, size: 22), onPressed: () {}),
                ],
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: context.cardBg,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      _GroupStat(Icons.trending_up, '23', 'פוסטים חדשים', AppColors.turquoise),
                      const SizedBox(width: 8),
                      _GroupStat(Icons.people_outline, '5', 'חברים חדשים', AppColors.success),
                      const SizedBox(width: 8),
                      _GroupStat(Icons.how_to_vote, '1', 'סקר פעיל', AppColors.gold),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: context.cardBg,
                  margin: const EdgeInsets.only(top: 1),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: GestureDetector(
                    onTap: () => _showNewPostSheet(context, isLoggedIn, user?.name ?? ''),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: isLoggedIn ? AppColors.brandGradient : null,
                            color: isLoggedIn ? null : context.surfaceDim,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isLoggedIn
                                ? Text(user.initials, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white))
                                : const Icon(Icons.person, size: 20, color: AppColors.grayMeta),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: context.surfaceDim,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: context.borderClr),
                            ),
                            child: Text(
                              'מה חדש? שתפו את הקהילה...',
                              style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(Icons.photo_library_outlined, color: AppColors.success, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: context.cardBg,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final sel = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.turquoise : context.surfaceDim,
                              borderRadius: BorderRadius.circular(50),
                              border: sel ? null : Border.all(color: context.borderClr),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  color: sel ? AppColors.white : AppColors.grayMeta,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = _filteredPosts[index];
                    return _PostCard(
                      post: post,
                      onLike: () => setState(() {
                        post.isLiked = !post.isLiked;
                        post.likes += post.isLiked ? 1 : -1;
                      }),
                      onComment: () => _showCommentsSheet(context, post, isLoggedIn, user?.name ?? '', user?.initials ?? ''),
                      onShare: () {
                        Share.share('${post.authorName}: ${post.content}\n\nמקהילת מודיעין בשבילך');
                        setState(() => post.shares++);
                      },
                    );
                  },
                  childCount: _filteredPosts.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: AppColors.cyanGradient,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(color: const Color(0xFF00EEFF).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _showNewPostSheet(context, isLoggedIn, user?.name ?? ''),
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.edit, color: AppColors.white, size: 20),
            label: Text('פוסט חדש', style: GoogleFonts.rubik(fontWeight: FontWeight.w600, color: AppColors.white)),
          ),
        ),
      ),
    );
  }

  void _showNewPostSheet(BuildContext context, bool isLoggedIn, String userName) {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('יש להתחבר כדי לפרסם', style: GoogleFonts.rubik()),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final textController = TextEditingController();
    String selectedCategory = 'כללי';
    final categories = ['כללי', 'שאלה', 'המלצה', 'דיווח', 'שכנים'];
    Uint8List? pickedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) => Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderClr, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.turquoise.withValues(alpha: 0.15),
                      child: Text(userName.isNotEmpty ? userName[0] : '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.turquoise)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary)),
                        Text('פוסט ציבורי · קהילת מודיעין', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final sel = cat == selectedCategory;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.turquoise.withValues(alpha: 0.1) : context.surfaceDim,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: sel ? AppColors.turquoise : context.borderClr),
                          ),
                          child: Center(child: Text(cat, style: GoogleFonts.rubik(fontSize: 13, color: sel ? AppColors.turquoise : AppColors.grayMeta, fontWeight: sel ? FontWeight.w600 : FontWeight.w400))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 5,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.rubik(fontSize: 15, color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'מה עובר עליכם?',
                    hintStyle: GoogleFonts.rubik(fontSize: 15, color: AppColors.grayLight),
                    filled: true,
                    fillColor: context.surfaceDim,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.borderClr)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.borderClr)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.turquoise, width: 1.5)),
                  ),
                ),
                if (pickedImage != null) ...[
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(pickedImage!, height: 140, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: GestureDetector(
                          onTap: () => setSheetState(() => pickedImage = null),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 16, color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SheetAction(Icons.photo_outlined, 'תמונה', AppColors.success, () async {
                      final picker = ImagePicker();
                      final result = await picker.pickImage(source: ImageSource.gallery);
                      if (result != null) {
                        final bytes = await result.readAsBytes();
                        setSheetState(() => pickedImage = bytes);
                      }
                    }),
                    const SizedBox(width: 4),
                    _SheetAction(Icons.location_on_outlined, 'מיקום', AppColors.error, () {}),
                    const SizedBox(width: 4),
                    _SheetAction(Icons.poll_outlined, 'סקר', AppColors.gold, () {}),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (textController.text.trim().isEmpty) return;
                        setState(() {
                          _posts.insert(0, _Post(
                            id: 'new_${DateTime.now().millisecondsSinceEpoch}',
                            authorName: userName,
                            authorInitials: userName.isNotEmpty ? userName[0] : '?',
                            category: selectedCategory,
                            content: textController.text.trim(),
                            hasImage: pickedImage != null,
                            imageLabel: 'תמונה שהועלתה',
                            timeAgo: 'עכשיו',
                            likes: 0,
                            commentsCount: 0,
                            shares: 0,
                            comments: [],
                          ));
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle, color: AppColors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('הפוסט פורסם!', style: GoogleFonts.rubik()),
                          ]),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(50)),
                        child: Text('פרסום', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, _Post post, bool isLoggedIn, String userName, String userInitials) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderClr, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('תגובות', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
                          const SizedBox(width: 6),
                          Text('(${post.comments.length})', style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayMeta)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 22),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.midBlue.withValues(alpha: 0.15),
                        child: Text(post.authorInitials, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.authorName, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              post.content,
                              style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.borderClr),

                Expanded(
                  child: post.comments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text('אין תגובות עדיין', style: GoogleFonts.rubik(fontSize: 15, color: AppColors.grayLight)),
                              Text('היו הראשונים להגיב!', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: post.comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (_, i) {
                            final c = post.comments[i];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.turquoise.withValues(alpha: 0.15),
                                  child: Text(c.authorInitials, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.turquoise)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: context.surfaceDim,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c.authorName, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                                            const SizedBox(height: 2),
                                            Text(c.content, style: GoogleFonts.rubik(fontSize: 14, color: context.textPrimary)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(c.timeAgo, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                                          const SizedBox(width: 16),
                                          GestureDetector(
                                            onTap: () => setSheetState(() {
                                              c.isLiked = !c.isLiked;
                                              c.likes += c.isLiked ? 1 : -1;
                                            }),
                                            child: Text(
                                              'אהבתי${c.likes > 0 ? ' (${c.likes})' : ''}',
                                              style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: c.isLiked ? AppColors.error : AppColors.grayLight),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text('הגב/י', style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayLight)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                Container(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    border: Border(top: BorderSide(color: context.borderClr)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.turquoise.withValues(alpha: 0.15),
                        child: isLoggedIn
                            ? Text(userInitials, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.turquoise))
                            : const Icon(Icons.person, size: 16, color: AppColors.turquoise),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.rubik(fontSize: 14, color: context.textPrimary),
                          decoration: InputDecoration(
                            hintText: isLoggedIn ? 'כתבו תגובה...' : 'התחברו כדי להגיב',
                            hintStyle: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight),
                            filled: true,
                            fillColor: context.surfaceDim,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                          enabled: isLoggedIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (!isLoggedIn || commentController.text.trim().isEmpty) return;
                          setSheetState(() {
                            post.comments.add(_Comment(
                              authorName: userName,
                              authorInitials: userInitials,
                              content: commentController.text.trim(),
                              timeAgo: 'עכשיו',
                            ));
                            post.commentsCount++;
                          });
                          setState(() {});
                          commentController.clear();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.cyanGradient,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(Icons.send, size: 16, color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_Post> _generateMockPosts() {
    return [
      _Post(
        id: 'pinned_1',
        authorName: 'מנהלי הקהילה',
        authorInitials: 'מ',
        category: 'כללי',
        content: 'ברוכים הבאים לקהילת מודיעין! 🏙️\n\nכאן המקום לשתף שאלות, המלצות, דיווחים ועדכונים שכונתיים. שמרו על שיח מכבד — אנחנו שכנים!\n\nכללי הקהילה:\n• ללא פרסום ללא אישור\n• שיח מכבד בלבד\n• דיווחי תקלות — ציינו שכונה ורחוב',
        timeAgo: 'פוסט מוצמד',
        likes: 234,
        commentsCount: 18,
        shares: 12,
        isPinned: true,
        comments: [
          _Comment(authorName: 'דנה כ.', authorInitials: 'ד', content: 'סוף סוף קבוצה מסודרת! 🎉', timeAgo: 'לפני 3 ימים', likes: 8),
          _Comment(authorName: 'עמית ר.', authorInitials: 'ע', content: 'מעולה, תודה למנהלים', timeAgo: 'לפני 3 ימים', likes: 5),
        ],
      ),
      _Post(
        id: 'post_1',
        authorName: 'רחלי מ.',
        authorInitials: 'ר',
        category: 'שאלה',
        content: 'מישהו מכיר שרברב אמין בשכונת הפרחים? יש לנו נזילה מתחת לכיור כבר שבוע ואף אחד לא זמין 😩\n\nעדיפות למישהו עם המלצות',
        timeAgo: 'לפני 23 דקות',
        likes: 3,
        commentsCount: 12,
        shares: 0,
        comments: [
          _Comment(authorName: 'יוסי ד.', authorInitials: 'י', content: 'מוטי שרברב — 050-1234567. אמין, מגיע מהר, מחירים הוגנים. עשה לנו עבודה מעולה', timeAgo: 'לפני 20 דק׳', likes: 6),
          _Comment(authorName: 'שרה ל.', authorInitials: 'ש', content: 'אני שנייה ליוסי! מוטי מעולה, הזמנתי אותו שלוש פעמים', timeAgo: 'לפני 18 דק׳', likes: 3),
          _Comment(authorName: 'אורן ב.', authorInitials: 'א', content: 'יש גם את רונן — 050-9876543. קצת יותר יקר אבל מקצועי מאוד', timeAgo: 'לפני 15 דק׳', likes: 2),
          _Comment(authorName: 'רחלי מ.', authorInitials: 'ר', content: 'תודה רבה! 🙏 התקשרתי למוטי, הוא מגיע מחר בבוקר', timeAgo: 'לפני 10 דק׳', likes: 4),
        ],
      ),
      _Post(
        id: 'post_2',
        authorName: 'דני כ.',
        authorInitials: 'ד',
        category: 'המלצה',
        content: 'חייבים לספר — אכלנו אתמול במסעדת נאיתאי ופשוט וואו! 🍜\n\nהאוכל התאילנדי הכי טוב שאכלתי מחוץ לבנגקוק. המון טעמים, מנות עשירות, שירות אדיב.\n\nממליץ בחום על הפאד תאי והקארי הירוק. הילדים אהבו את הנודלס.',
        hasImage: true,
        imageLabel: '🍜 נאיתאי',
        timeAgo: 'לפני שעה',
        likes: 28,
        commentsCount: 7,
        shares: 4,
        comments: [
          _Comment(authorName: 'מיכל ג.', authorInitials: 'מ', content: 'אוהבים שם! הסום טאם שלהם גם מושלם', timeAgo: 'לפני 50 דק׳', likes: 3),
          _Comment(authorName: 'עידו ש.', authorInitials: 'ע', content: 'כשר?', timeAgo: 'לפני 45 דק׳', likes: 0),
          _Comment(authorName: 'דני כ.', authorInitials: 'ד', content: 'כן, כשרות מהדרין!', timeAgo: 'לפני 40 דק׳', likes: 2),
        ],
      ),
      _Post(
        id: 'post_3',
        authorName: 'אבי ש.',
        authorInitials: 'א',
        category: 'דיווח',
        content: 'בור ענק ברחוב הפלמ"ח, ליד הגן ברחוב הפרחים 22. מסוכן ביותר! כמעט נפלתי מהאופניים.\n\nדיווחתי לעירייה אבל רציתי להזהיר — בבקשה להיזהר באזור, בייחוד בחושך.',
        hasImage: true,
        imageLabel: '⚠️ דיווח',
        timeAgo: 'לפני 2 שעות',
        likes: 45,
        commentsCount: 9,
        shares: 15,
        comments: [
          _Comment(authorName: 'נטע ר.', authorInitials: 'נ', content: 'ראיתי את זה! ממש מסוכן, תודה שדיווחת', timeAgo: 'לפני שעתיים', likes: 7),
          _Comment(authorName: 'גלית א.', authorInitials: 'ג', content: 'גם אני דיווחתי ב-106. ככל שיותר אנשים ידווחו יטפלו יותר מהר', timeAgo: 'לפני שעתיים', likes: 11),
          _Comment(authorName: 'ציון מ.', authorInitials: 'צ', content: 'למה תמיד לוקח להם נצח לתקן? 🤦', timeAgo: 'לפני שעה', likes: 5),
        ],
      ),
      _Post(
        id: 'post_4',
        authorName: 'ליאת ב.',
        authorInitials: 'ל',
        category: 'שכנים',
        content: 'מישהו רוצה להצטרף לקבוצת ריצה בערב? 🏃‍♀️\n\nאנחנו רצים כל יום שלישי וחמישי ב-20:00, יוצאים מהכניסה לפארק ענבה. מסלול 5 קמ. כל הרמות מוזמנות!\n\nיש כרגע 8 משתתפים קבועים ותמיד שמחים לקבל חדשים.',
        timeAgo: 'לפני 3 שעות',
        likes: 19,
        commentsCount: 14,
        shares: 3,
        comments: [
          _Comment(authorName: 'רון כ.', authorInitials: 'ר', content: 'אני בפנים! איפה בדיוק הנקודה?', timeAgo: 'לפני 3 שעות', likes: 1),
          _Comment(authorName: 'ליאת ב.', authorInitials: 'ל', content: 'כניסה ראשית לפארק ענבה, ליד החניון. יש שלט גדול', timeAgo: 'לפני 3 שעות', likes: 2),
          _Comment(authorName: 'שי מ.', authorInitials: 'ש', content: 'מתאים גם למתחילים? חזרתי מפציעה', timeAgo: 'לפני שעתיים', likes: 0),
          _Comment(authorName: 'ליאת ב.', authorInitials: 'ל', content: 'בהחלט! רצים בקצב שנוח לכולם, ויש אפשרות ללכת חלק מהדרך', timeAgo: 'לפני שעתיים', likes: 3),
        ],
      ),
      _Post(
        id: 'post_5',
        authorName: 'עומר ג.',
        authorInitials: 'ע',
        category: 'כללי',
        content: 'שמתם לב שפתחו חנות ירקות חדשה במע"ר? ליד הדואר. נכנסתי היום — מגוון ענק של ירקות ופירות אורגניים, המחירים סבירים מאוד!\n\nשווה ביקור.',
        timeAgo: 'לפני 5 שעות',
        likes: 32,
        commentsCount: 5,
        shares: 8,
        comments: [
          _Comment(authorName: 'הדר ל.', authorInitials: 'ה', content: 'ראיתי! נראה מבטיח. יודע מה שעות הפתיחה?', timeAgo: 'לפני 4 שעות', likes: 1),
          _Comment(authorName: 'עומר ג.', authorInitials: 'ע', content: 'א׳-ה׳ 7:00-20:00, ו׳ עד 14:00', timeAgo: 'לפני 4 שעות', likes: 4),
        ],
      ),
      _Post(
        id: 'post_6',
        authorName: 'מירב ש.',
        authorInitials: 'מ',
        category: 'כללי',
        content: 'תודה ענקית לכל מי שהשתתף באירוע הניקיון הקהילתי בשבת! 🧹✨\n\nהיינו 47 משתתפים ואספנו 120 שקיות זבל מפארק ענבה ומהאזורים הסמוכים. גאה להיות חלק מהקהילה הזו!',
        hasImage: true,
        imageLabel: '🧹 ניקיון קהילתי',
        timeAgo: 'לפני 8 שעות',
        likes: 89,
        commentsCount: 22,
        shares: 11,
        comments: [
          _Comment(authorName: 'יובל ד.', authorInitials: 'י', content: 'היה מדהים! מחכה לפעם הבאה', timeAgo: 'לפני 7 שעות', likes: 6),
          _Comment(authorName: 'רינת מ.', authorInitials: 'ר', content: 'אשמח לשמוע על האירוע הבא מראש כדי להירשם', timeAgo: 'לפני 6 שעות', likes: 3),
          _Comment(authorName: 'מירב ש.', authorInitials: 'מ', content: 'בהחלט! נפרסם כאן שבועיים מראש. האירוע הבא מתוכנן ל-29.08', timeAgo: 'לפני 5 שעות', likes: 9),
        ],
      ),
      _Post(
        id: 'post_7',
        authorName: 'חני ק.',
        authorInitials: 'ח',
        category: 'שאלה',
        content: 'מחפשת המלצה לגן ילדים פרטי באזור נופים/אבני חן לילד בן שנתיים. מה חשוב לי:\n\n• צוות חם ואוהב\n• חצר גדולה\n• ארוחות ביתיות\n• מצלמות\n\nתודה מראש! 🙏',
        timeAgo: 'אתמול',
        likes: 7,
        commentsCount: 16,
        shares: 1,
        comments: [
          _Comment(authorName: 'שירן ד.', authorInitials: 'ש', content: 'גן "שמש" ברחוב הזית! הבן שלי היה שם שנתיים, צוות מעולה. יש כל מה שחיפשת', timeAgo: 'אתמול', likes: 4),
          _Comment(authorName: 'טל א.', authorInitials: 'ט', content: 'גן הדס ברחוב האלון — חצר ענקית ואוכל ביתי מעולה. גם מצלמות אונליין', timeAgo: 'אתמול', likes: 3),
          _Comment(authorName: 'חני ק.', authorInitials: 'ח', content: 'תודה רבה!! יש לכם מספרי טלפון?', timeAgo: 'אתמול', likes: 0),
        ],
      ),
    ];
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetAction(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.rubik(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final _Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  Color _categoryColor() {
    switch (post.category) {
      case 'שאלה': return const Color(0xFF9B59B6);
      case 'המלצה': return AppColors.success;
      case 'דיווח': return AppColors.error;
      case 'שכנים': return AppColors.gold;
      default: return AppColors.turquoise;
    }
  }

  IconData _categoryIcon() {
    switch (post.category) {
      case 'שאלה': return Icons.help_outline;
      case 'המלצה': return Icons.thumb_up_outlined;
      case 'דיווח': return Icons.report_problem_outlined;
      case 'שכנים': return Icons.people_outline;
      default: return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: context.cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: catColor.withValues(alpha: 0.15),
                  child: Text(post.authorInitials, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: catColor)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.authorName, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                          if (post.isPinned) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.admin_panel_settings, size: 14, color: AppColors.turquoise),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(post.timeAgo, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                          const SizedBox(width: 6),
                          Text('·', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                          const SizedBox(width: 6),
                          Icon(_categoryIcon(), size: 12, color: catColor),
                          const SizedBox(width: 3),
                          Text(post.category, style: GoogleFonts.rubik(fontSize: 11, color: catColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.turquoise.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.push_pin, size: 11, color: AppColors.turquoise),
                        const SizedBox(width: 3),
                        Text('מוצמד', style: GoogleFonts.rubik(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.turquoise)),
                      ],
                    ),
                  )
                else
                  const Icon(Icons.more_horiz, size: 20, color: AppColors.grayLight),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              post.content,
              style: GoogleFonts.rubik(fontSize: 14, color: context.textPrimary, height: 1.5),
            ),
          ),

          if (post.hasImage) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 200,
              color: context.surfaceDim,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, size: 40, color: catColor.withValues(alpha: 0.3)),
                    const SizedBox(height: 6),
                    Text(post.imageLabel, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight)),
                  ],
                ),
              ),
            ),
          ],

          if (post.likes > 0 || post.commentsCount > 0 || post.shares > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  if (post.likes > 0) ...[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite, size: 10, color: AppColors.white),
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likes}', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
                  ],
                  const Spacer(),
                  if (post.commentsCount > 0)
                    GestureDetector(
                      onTap: onComment,
                      child: Text('${post.commentsCount} תגובות', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
                    ),
                  if (post.shares > 0) ...[
                    const SizedBox(width: 12),
                    Text('${post.shares} שיתופים', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
                  ],
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(height: 1, color: context.borderClr),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: 'אהבתי',
                    color: post.isLiked ? AppColors.error : AppColors.grayMeta,
                    onTap: onLike,
                  ),
                ),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.chat_bubble_outline,
                    label: 'תגובה',
                    color: AppColors.grayMeta,
                    onTap: onComment,
                  ),
                ),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.share_outlined,
                    label: 'שיתוף',
                    color: AppColors.grayMeta,
                    onTap: onShare,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _GroupStat(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(value, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 4),
            Flexible(child: Text(label, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayMeta), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
