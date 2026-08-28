import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  double _mortgagePercent = 75;
  final _imagePageController = PageController();
  int _currentImagePage = 0;

  static const _imageColors = [
    Color(0xFFE8F4FD), Color(0xFFFCE4EC), Color(0xFFE8F5E9),
    Color(0xFFF3E5F5), Color(0xFFFFF3E0), Color(0xFFE0F7FA),
    Color(0xFFFBE9E7), Color(0xFFE8EAF6), Color(0xFFF1F8E9),
    Color(0xFFEDE7F6), Color(0xFFFFF8E1), Color(0xFFE0F2F1),
  ];

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  int get _priceNum => 2450000;
  double get _mortgageAmount => _priceNum * (_mortgagePercent / 100);
  double get _monthlyPayment {
    final principal = _mortgageAmount;
    const rate = 0.045 / 12;
    const months = 25 * 12;
    return principal * rate * _pow(1 + rate, months) / (_pow(1 + rate, months) - 1);
  }

  static double _pow(double base, int exp) {
    double result = 1;
    for (var i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isFav = user?.favoriteListingIds.contains(widget.listingId) ?? false;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _imagePageController,
                      itemCount: 12,
                      onPageChanged: (i) => setState(() => _currentImagePage = i),
                      itemBuilder: (context, index) {
                        return Container(
                          color: _imageColors[index],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                [Icons.apartment, Icons.living, Icons.kitchen, Icons.bathroom, Icons.bed, Icons.balcony,
                                 Icons.garage, Icons.elevator, Icons.chair, Icons.window, Icons.roofing, Icons.park][index],
                                size: 56,
                                color: AppColors.midBlue.withValues(alpha: 0.25),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ['סלון', 'מטבח', 'חדר שינה', 'אמבטיה', 'חדר ילדים', 'מרפסת',
                                 'חניה', 'לובי', 'פינת אוכל', 'נוף', 'גג', 'חצר'][index],
                                style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayMeta),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 90, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(6)),
                        child: Text('ללא תיווך · פרטי', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
                      ),
                    ),
                    Positioned(
                      bottom: 12, left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                        child: Text('${_currentImagePage + 1}/12', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.white)),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(12, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: _currentImagePage == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentImagePage == i ? AppColors.white : AppColors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? AppColors.error : null),
                  onPressed: () {
                    if (user == null) return;
                    ref.read(authProvider.notifier).toggleFavoriteListing(widget.listingId);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => Share.share('דירת 4 חדרים, 110 מ"ר, הפרחים (מירומי)\n2,450,000 ₪\nמודיעין בשבילך'),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2,450,000 ₪', style: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w700, color: context.textPrimary)),
                    const SizedBox(height: 6),
                    Text('רח׳ הנרקיס 12, הפרחים (מירומי)', style: GoogleFonts.rubik(fontSize: 15, color: AppColors.grayText)),
                    const SizedBox(height: 4),
                    Text('4 חדרים · 110 מ"ר · קומה 3', style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _SpecIcon(Icons.bed_outlined, '4', 'חדרים'),
                        _SpecIcon(Icons.square_foot, '110', 'מ"ר'),
                        _SpecIcon(Icons.stairs, '3', 'קומה'),
                        _SpecIcon(Icons.shield_outlined, '✓', 'ממ"ד'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => _launchPhone('0501234567'),
                            icon: const Icon(Icons.phone),
                            label: Text('התקשרו למוכר', style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _launchWhatsApp('0501234567', 'שלום, ראיתי את המודעה שלך באפליקציית מודיעין בשבילך ואשמח לפרטים נוספים.'),
                            icon: const Icon(Icons.chat, size: 18),
                            label: Text('וואטסאפ', style: GoogleFonts.rubik(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('מאפייני הנכס', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _PropTag('מרפסת שמש'), _PropTag('חניה פרטית'), _PropTag('מעלית'),
                        _PropTag('מחסן'), _PropTag('משופצת'), _PropTag('מיזוג מרכזי'), _PropTag('סורגים'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('תיאור', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      'דירת 4 חדרים מרווחת ומוארת בשכונת הפרחים. '
                      'הדירה עברה שיפוץ מלא לפני שנתיים וכוללת מטבח חדש, '
                      'שני חדרי רחצה, ממ"ד, מרפסת שמש גדולה וחניה פרטית.\n\n'
                      'קרובה לבתי ספר, גנים, מרכז מסחרי ותחבורה ציבורית. '
                      'מיקום שקט ומשפחתי.',
                      style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    Text('מחשבון משכנתא', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
                    const SizedBox(height: 10),
                    _buildMortgageCalculator(),
                    const SizedBox(height: 24),
                    Text('פרטי איש קשר', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderClr, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.success.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: AppColors.success),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('דוד כהן', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text('בעלים פרטי', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: AppColors.turquoise),
                            onPressed: () => _launchPhone('0501234567'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat, color: AppColors.success),
                            onPressed: () => _launchWhatsApp('0501234567', 'שלום, ראיתי את המודעה שלך'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('נכסים דומים בשכונה', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final similar = [
                            ('3 חדרים · 90 מ"ר', '2,100,000 ₪'),
                            ('4 חדרים · 115 מ"ר', '2,550,000 ₪'),
                            ('5 חדרים · 135 מ"ר', '2,900,000 ₪'),
                          ];
                          final (specs, price) = similar[index];
                          return Container(
                            width: 180,
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderClr, width: 0.5),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.midBlue.withValues(alpha: 0.06),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    child: Center(child: Icon(Icons.apartment, size: 36, color: AppColors.midBlue.withValues(alpha: 0.2))),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(price, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                                      Text(specs, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
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

  Widget _buildMortgageCalculator() {
    final formatted = _monthlyPayment.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    final mortgageFormatted = _mortgageAmount.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('אחוז מימון', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
              Text('${_mortgagePercent.round()}%', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
            ],
          ),
          Slider(
            value: _mortgagePercent,
            min: 25,
            max: 75,
            divisions: 10,
            activeColor: AppColors.turquoise,
            onChanged: (val) => setState(() => _mortgagePercent = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('סכום מימון', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
              Text('$mortgageFormatted ₪', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ריבית משוערת', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
              Text('4.5%', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('החזר חודשי משוער', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
              Text('~$formatted ₪', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.turquoise)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    final formatted = phone.replaceFirst('0', '972');
    final uri = Uri.parse('https://wa.me/$formatted?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SpecIcon extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _SpecIcon(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppColors.midBlue.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.midBlue),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
            Text(label, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
          ],
        ),
      ),
    );
  }
}

class _PropTag extends StatelessWidget {
  final String label;
  const _PropTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.midBlue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.midBlue)),
    );
  }
}
