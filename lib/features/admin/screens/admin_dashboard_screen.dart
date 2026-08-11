import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedSection = 0;

  final _sections = [
    ('סקירה', Icons.dashboard),
    ('משתמשים', Icons.people),
    ('עסקים', Icons.store),
    ('תוכן', Icons.article),
    ('מודרציה', Icons.shield),
    ('אירועים', Icons.event),
    ('נדל"ן', Icons.apartment),
    ('כספים', Icons.payments),
    ('AI', Icons.auto_awesome),
    ('הגדרות', Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('ניהול — מודיעין בשבילך', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
        ),
        body: isWide
            ? Row(
                children: [
                  _Sidebar(
                    sections: _sections,
                    selected: _selectedSection,
                    onSelect: (i) => setState(() => _selectedSection = i),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _DashboardContent()),
                ],
              )
            : Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _sections.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final (label, _) = _sections[index];
                        final sel = index == _selectedSection;
                        return ChoiceChip(
                          label: Text(label),
                          selected: sel,
                          onSelected: (_) => setState(() => _selectedSection = index),
                          selectedColor: AppColors.turquoise,
                          labelStyle: GoogleFonts.rubik(
                            fontSize: 12,
                            color: sel ? AppColors.white : AppColors.navy,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                  ),
                  Expanded(child: _DashboardContent()),
                ],
              ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<(String, IconData)> sections;
  final int selected;
  final ValueChanged<int> onSelect;

  const _Sidebar({required this.sections, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.navy.withValues(alpha: 0.03),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final (label, icon) = sections[index];
          final sel = index == selected;
          return ListTile(
            leading: Icon(icon, size: 20, color: sel ? AppColors.turquoise : AppColors.grayLight),
            title: Text(
              label,
              style: GoogleFonts.rubik(
                fontSize: 14,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? AppColors.turquoise : AppColors.navy,
              ),
            ),
            selected: sel,
            selectedTileColor: AppColors.turquoise.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () => onSelect(index),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricCard('תושבים רשומים', '4,230', Icons.people, AppColors.turquoise, '+180 החודש'),
            _MetricCard('עסקים פעילים', '312', Icons.store, AppColors.midBlue, '+12 החודש'),
            _MetricCard('הכנסה חודשית', '₪24,500', Icons.payments, AppColors.success, '+8% מהחודש הקודם'),
            _MetricCard('בתור מודרציה', '7', Icons.shield, AppColors.gold, '3 ביקורות, 4 תמונות'),
          ],
        ),
        const SizedBox(height: 24),
        Text('תור מודרציה', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              _ModerationRow('ביקורת חדשה', 'יוסי כ. על "פיצה פרגו"', 'ביקורת', 'ממתין'),
              const Divider(height: 1, color: AppColors.border),
              _ModerationRow('תמונה חדשה', 'מיכל ל. — גלריית "מודיעין בעדשתך"', 'תמונה', 'ממתין'),
              const Divider(height: 1, color: AppColors.border),
              _ModerationRow('רישום עסק', 'ביסטרו חדש — ממתין לאימות רישיון', 'עסק', 'ממתין'),
              const Divider(height: 1, color: AppColors.border),
              _ModerationRow('דיווח תקלה', 'בור בכביש — רח׳ הנרקיס', 'תקלה', 'חדש'),
              const Divider(height: 1, color: AppColors.border),
              _ModerationRow('מודעת נדל"ן', 'דירה 4 חדרים — ממתין לאימות בעלות', 'נדל"ן', 'ממתין'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('התראות מערכת', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
        const SizedBox(height: 12),
        _AlertCard(Icons.warning_amber, 'עומס על שרת AI', '23 שאילתות נכשלו בשעה האחרונה', AppColors.gold),
        const SizedBox(height: 8),
        _AlertCard(Icons.check_circle, 'גיבוי לילי הושלם', 'גיבוי מלא — 4.2GB — 03:15', AppColors.success),
        const SizedBox(height: 8),
        _AlertCard(Icons.info_outline, 'עדכון מערכת', 'גרסה 1.2.0 זמינה להתקנה', AppColors.turquoise),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _MetricCard(this.title, this.value, this.icon, this.color, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.rubik(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _ModerationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String type;
  final String status;

  const _ModerationRow(this.title, this.subtitle, this.type, this.status);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.midBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(type, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.midBlue)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AlertCard(this.icon, this.title, this.subtitle, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                Text(subtitle, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
