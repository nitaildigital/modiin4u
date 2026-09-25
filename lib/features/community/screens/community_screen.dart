import '../../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import 'web_community_screen.dart';

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

  /// Empty, and it has to stay empty until there is a table behind it.
  ///
  /// This screen used to open with a feed written into the source: named
  /// residents holding conversations, a plumber and an electrician given as
  /// telephone numbers, a named restaurant recommended with a claim about
  /// its kashrut, and a pothole reported at a real street address with a
  /// note that the municipality had been told. None of it came from
  /// anywhere. Someone would have rung those numbers.
  ///
  /// There is no `posts` table in the schema, so nothing can fill this yet.
  final List<_Post> _posts = [];

  List<_Post> get _filteredPosts {
    if (_selectedCategory == 'הכל') return _posts;
    return _posts.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebCommunityContent();
        return _buildMobile();
      },
    );
  }

  Widget _buildMobile() {
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
                              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.public, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                // "12,340 members" and "48 posts today" sat
                                // here, over a feed that has not opened and
                                // a schema with no posts table. Nothing
                                // counts either figure.
                                Text('קבוצה ציבורית', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                ],
              ),

              // A stat row reading "23 new posts · 5 new members · 1 active
              // poll" sat here. There is no posts table, no membership
              // table and no poll anywhere in the schema.

              SliverToBoxAdapter(
                child: Container(
                  color: context.cardBg,
                  margin: const EdgeInsets.only(top: 1),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: GestureDetector(
                    // Nowhere to write a post to, so it says so rather than
                    // opening a composer.
                    onTap: _showNotOpenYet,
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
                                ? Text(user.initials, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white))
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
                              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: AppColors.grayLight),
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
                                style: TextStyle(fontFamily: AppFonts.rubik, 
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

              if (_filteredPosts.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
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
            onPressed: _showNotOpenYet,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.edit, color: AppColors.white, size: 20),
            label: Text('פוסט חדש', style: TextStyle(fontFamily: AppFonts.rubik, fontWeight: FontWeight.w600, color: AppColors.white)),
          ),
        ),
      ),
    );
  }

  /// What the feed shows while there is nothing to show. Said plainly: a
  /// blank scroll area reads as a screen that failed to load, and this one
  /// has not failed — it has nothing yet.
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 64),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 48, color: AppColors.grayLight),
          const SizedBox(height: 16),
          Text('הקהילה עוד לא נפתחה',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 18, fontWeight: FontWeight.w600, color: context.textPrimary)),
          const SizedBox(height: 8),
          Text('בקרוב תוכלו לשתף כאן שאלות, המלצות ודיווחים שכונתיים.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, height: 1.5, color: AppColors.grayText)),
        ],
      ),
    );
  }

  void _showNotOpenYet() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('הקהילה עוד לא נפתחה', style: TextStyle(fontFamily: AppFonts.rubik)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          Text('תגובות', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
                          const SizedBox(width: 6),
                          Text('(${post.comments.length})', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: AppColors.grayMeta)),
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
                        child: Text(post.authorInitials, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.authorName, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              post.content,
                              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: AppColors.grayText),
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
                              Text('אין תגובות עדיין', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 15, color: AppColors.grayLight)),
                              Text('היו הראשונים להגיב!', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: AppColors.grayLight)),
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
                                  child: Text(c.authorInitials, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.turquoise)),
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
                                            Text(c.authorName, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                                            const SizedBox(height: 2),
                                            Text(c.content, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: context.textPrimary)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(c.timeAgo, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 11, color: AppColors.grayLight)),
                                          const SizedBox(width: 16),
                                          GestureDetector(
                                            onTap: () => setSheetState(() {
                                              c.isLiked = !c.isLiked;
                                              c.likes += c.isLiked ? 1 : -1;
                                            }),
                                            child: Text(
                                              'אהבתי${c.likes > 0 ? ' (${c.likes})' : ''}',
                                              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 11, fontWeight: FontWeight.w600, color: c.isLiked ? AppColors.error : AppColors.grayLight),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text('הגב/י', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayLight)),
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
                            ? Text(userInitials, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.turquoise))
                            : const Icon(Icons.person, size: 16, color: AppColors.turquoise),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: context.textPrimary),
                          decoration: InputDecoration(
                            hintText: isLoggedIn ? 'כתבו תגובה...' : 'התחברו כדי להגיב',
                            hintStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: AppColors.grayLight),
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
                  child: Text(post.authorInitials, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, fontWeight: FontWeight.w700, color: catColor)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.authorName, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                          if (post.isPinned) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.admin_panel_settings, size: 14, color: AppColors.turquoise),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(post.timeAgo, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 11, color: AppColors.grayLight)),
                          const SizedBox(width: 6),
                          Text('·', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 11, color: AppColors.grayLight)),
                          const SizedBox(width: 6),
                          Icon(_categoryIcon(), size: 12, color: catColor),
                          const SizedBox(width: 3),
                          Text(post.category, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 11, color: catColor, fontWeight: FontWeight.w500)),
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
                        Text('מוצמד', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.turquoise)),
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
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, color: context.textPrimary, height: 1.5),
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
                    Text(post.imageLabel, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, color: AppColors.grayLight)),
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
                    Text('${post.likes}', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: AppColors.grayMeta)),
                  ],
                  const Spacer(),
                  if (post.commentsCount > 0)
                    GestureDetector(
                      onTap: onComment,
                      child: Text('${post.commentsCount} תגובות', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: AppColors.grayMeta)),
                    ),
                  if (post.shares > 0) ...[
                    const SizedBox(width: 12),
                    Text('${post.shares} שיתופים', style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 12, color: AppColors.grayMeta)),
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
            Text(label, style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
