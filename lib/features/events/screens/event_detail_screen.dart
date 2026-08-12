import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isAttending = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            AppColors.navy,
                            AppColors.midBlue.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 80,
                        color: AppColors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Positioned(
                      top: 100,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '15',
                              style: GoogleFonts.rubik(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              'אוג׳',
                              style: GoogleFonts.rubik(
                                fontSize: 13,
                                color: AppColors.turquoise,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.share), onPressed: () => Share.share('הופעת שלמה ארצי\n15.8.2026 · 21:00\nהיכל התרבות מודיעין\nמודיעין בשבילך')),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'הופעת שלמה ארצי',
                      style: GoogleFonts.rubik(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _isAttending = !_isAttending);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(_isAttending ? 'נרשמת לאירוע!' : 'ביטלת הרשמה', style: GoogleFonts.rubik()),
                                backgroundColor: _isAttending ? AppColors.success : AppColors.grayMeta,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ));
                            },
                            icon: Icon(_isAttending ? Icons.check_circle : Icons.check_circle_outline),
                            label: Text(_isAttending ? 'רשום/ה!' : 'אני מגיע/ה', style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: _isAttending ? AppColors.success : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('האירוע נוסף ליומן', style: GoogleFonts.rubik()),
                              backgroundColor: AppColors.turquoise,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ));
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text('ליומן', style: GoogleFonts.rubik()),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=31.8932,35.0145');
                            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.navigation_outlined, size: 18),
                          label: Text('ניווט', style: GoogleFonts.rubik()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(Icons.access_time, 'יום ו׳, 15.8.2026', '21:00 - 23:30'),
                    const SizedBox(height: 12),
                    _InfoRow(Icons.location_on_outlined, 'היכל התרבות מודיעין', 'רח׳ הלוטוס 1, המע"ר'),
                    const SizedBox(height: 12),
                    _InfoRow(Icons.confirmation_number_outlined, 'כרטיסים', '₪180 · מכירה באתר'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Stack(
                            children: List.generate(4, (i) {
                              return Positioned(
                                right: i * 18.0,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: [
                                    AppColors.turquoise,
                                    AppColors.midBlue,
                                    AppColors.gold,
                                    AppColors.navy,
                                  ][i],
                                  child: Text(
                                    ['י', 'ד', 'מ', 'א'][i],
                                    style: GoogleFonts.rubik(
                                      fontSize: 11,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '234 תושבים מתעניינים',
                          style: GoogleFonts.rubik(
                            fontSize: 13,
                            color: AppColors.turquoise,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'על האירוע',
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'שלמה ארצי חוזר למודיעין עם מופע מיוחד הכולל את כל הלהיטים הגדולים. '
                      'ערב של נוסטלגיה, שירה בציבור ורגעים מוזיקליים בלתי נשכחים.\n\n'
                      'הכניסה מגיל 8 ומעלה. חניה חינם בחניון היכל התרבות.',
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        color: AppColors.grayText,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'מיקום',
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.midBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, size: 36, color: AppColors.midBlue.withValues(alpha: 0.3)),
                            const SizedBox(height: 6),
                            Text(
                              'היכל התרבות מודיעין',
                              style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'מארגן',
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.midBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.business, color: AppColors.midBlue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'היכל התרבות מודיעין',
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                                Text(
                                  'אירועים ותרבות',
                                  style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grayLight),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'אירועים דומים',
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SimilarEvent('הופעת עידן רייכל', '22.8', '₪200'),
                    const SizedBox(height: 8),
                    _SimilarEvent('פסטיבל ג\'אז מודיעין', '29.8', '₪80'),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.turquoise.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.turquoise),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
            Text(subtitle, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
          ],
        ),
      ],
    );
  }
}

class _SimilarEvent extends StatelessWidget {
  final String title;
  final String date;
  final String price;

  const _SimilarEvent(this.title, this.date, this.price);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                date.split('.')[0],
                style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.navy)),
          ),
          Text(price, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.turquoise, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
