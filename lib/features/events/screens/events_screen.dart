import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isCalendarView = false;
  String _selectedDate = 'הכל';
  String _selectedType = 'הכל';

  final _dateFilters = ['הכל', 'היום', 'מחר', 'סוף השבוע', 'השבוע'];
  final _typeFilters = [
    'הכל',
    'עירייה וקהילה',
    'מוזיקה',
    'ילדים ומשפחה',
    'ספורט',
    'חינם',
  ];

  static const _allEvents = [
    ('הופעת שלמה ארצי', '15.8', '21:00', 'היכל התרבות', '₪180', 'מוזיקה', 234),
    ('סיפורייה בספרייה', '16.8', '10:30', 'ספרייה עירונית', 'חינם', 'ילדים ומשפחה', 56),
    ('ישיבת מועצה פתוחה', '18.8', '19:30', 'בניין העירייה', 'חינם', 'עירייה וקהילה', 128),
    ('יוגה בפארק ענבה', '14.8', '07:00', 'פארק ענבה', 'חינם', 'ספורט', 89),
    ('פסטיבל בירה מודיעין', '22.8', '18:00', 'פארק המוזיקה', '₪50', 'מוזיקה', 412),
    ('סדנת בישול ילדים', '17.8', '16:00', 'מתנ"ס אבני חן', '₪60', 'ילדים ומשפחה', 34),
    ('ריצת ערב קהילתית', '19.8', '19:00', 'אגם ענבה', 'חינם', 'ספורט', 167),
    ('שוק אוכל רחוב', '23.8', '12:00', 'המע"ר', '₪20 כניסה', 'קולינריה', 298),
  ];

  List<(String, String, String, String, String, String, int)> get _filteredEvents {
    return _allEvents.where((e) {
      final (_, date, _, _, price, type, _) = e;
      if (_selectedType != 'הכל') {
        if (_selectedType == 'חינם') {
          if (price != 'חינם') return false;
        } else if (type != _selectedType) {
          return false;
        }
      }
      if (_selectedDate != 'הכל') {
        final day = int.tryParse(date.split('.')[0]) ?? 0;
        switch (_selectedDate) {
          case 'היום':
            if (day != 12) return false;
          case 'מחר':
            if (day != 13) return false;
          case 'סוף השבוע':
            if (day < 15 || day > 16) return false;
          case 'השבוע':
            if (day < 12 || day > 18) return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('לבלות', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          backgroundColor: context.cardBg,
          foregroundColor: context.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
              onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _dateFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final d = _dateFilters[index];
                    final sel = d == _selectedDate;
                    return ChoiceChip(
                      label: Text(d),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedDate = d),
                      selectedColor: AppColors.turquoise,
                      labelStyle: GoogleFonts.rubik(
                        fontSize: 13,
                        color: sel ? AppColors.white : context.textPrimary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _typeFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final t = _typeFilters[index];
                    final sel = t == _selectedType;
                    return FilterChip(
                      label: Text(t, style: GoogleFonts.rubik(fontSize: 12)),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedType = t),
                      selectedColor: AppColors.turquoise.withValues(alpha: 0.1),
                      checkmarkColor: AppColors.turquoise,
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: _filteredEvents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final (title, date, time, location, price, type, interested) = _filteredEvents[index];
                  final isFree = price == 'חינם';
                  final isMunicipal = type == 'עירייה';

                  return GestureDetector(
                    onTap: () => context.push('/event/demo_$index'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderClr, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 100,
                            decoration: BoxDecoration(
                              color: isMunicipal
                                  ? AppColors.midBlue.withValues(alpha: 0.1)
                                  : AppColors.turquoise.withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date.split('.')[0],
                                  style: GoogleFonts.rubik(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  '.${ date.split('.')[1]}',
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    color: AppColors.grayText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.rubik(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: AppColors.grayLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        time,
                                        style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.grayLight),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isFree
                                              ? AppColors.success.withValues(alpha: 0.1)
                                              : AppColors.gold.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          price,
                                          style: GoogleFonts.rubik(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isFree ? AppColors.success : context.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (isMunicipal) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.midBlue.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'עירייה',
                                            style: GoogleFonts.rubik(
                                              fontSize: 11,
                                              color: AppColors.midBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      Icon(Icons.people_outline, size: 14, color: AppColors.grayLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$interested',
                                        style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayLight),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}
