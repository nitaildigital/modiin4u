import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class DealDetailScreen extends StatefulWidget {
  final String dealId;

  const DealDetailScreen({super.key, required this.dealId});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  bool _isRedeemed = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.turquoise, AppColors.midBlue],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '20%\nהנחה',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rubik(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.white),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.midBlue.withValues(alpha: 0.1),
                          child: const Icon(Icons.store, color: AppColors.midBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('קפה גרג', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: AppColors.grayLight),
                                  const SizedBox(width: 4),
                                  Text('הפרחים (מירומי) · 500 מ׳', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '20% הנחה על כל המשקאות החמים',
                      style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    const SizedBox(height: 16),
                    Text('תנאי מימוש', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    _TermRow(Icons.calendar_today, 'תוקף: עד 18.8.2026'),
                    const SizedBox(height: 6),
                    _TermRow(Icons.access_time, 'ימים א׳-ה׳, 08:00-14:00'),
                    const SizedBox(height: 6),
                    _TermRow(Icons.person, 'לתושבים רשומים בלבד'),
                    const SizedBox(height: 6),
                    _TermRow(Icons.repeat_one, 'מימוש חד-פעמי ללקוח'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: _isRedeemed
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: AppColors.success),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.qr_code_2, size: 100, color: AppColors.navy),
                                  const SizedBox(height: 12),
                                  Text('MOD-20OFF-7X4K', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy, letterSpacing: 2)),
                                  const SizedBox(height: 8),
                                  Text('הראו קוד זה לקופה', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => setState(() => _isRedeemed = true),
                              icon: const Icon(Icons.qr_code),
                              label: Text('מימוש ההטבה', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=31.8935,35.0110');
                            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.navigation_outlined, size: 18),
                          label: Text('ניווט', style: GoogleFonts.rubik()),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri(scheme: 'tel', path: '0501234567');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          icon: const Icon(Icons.phone, size: 18),
                          label: Text('התקשרו', style: GoogleFonts.rubik()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('עוד הטבות מקפה גרג', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 12),
                    _MoreDeal('מאפה + קפה ב-25 ₪', 'כל יום עד 12:00'),
                    const SizedBox(height: 8),
                    _MoreDeal('קנו 5 קפה, ה-6 חינם', 'כרטיסיית נאמנות דיגיטלית'),
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

class _TermRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TermRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grayLight),
        const SizedBox(width: 10),
        Text(text, style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText)),
      ],
    );
  }
}

class _MoreDeal extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MoreDeal(this.title, this.subtitle);

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                Text(subtitle, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grayLight),
        ],
      ),
    );
  }
}
