import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../models/municipal_place.dart';
import '../providers/municipal_places_providers.dart';
import '../widgets/municipal_place_widgets.dart';
import '../../../core/router/app_router.dart' show AppNavigation;

/// One of the Municipal page's service tiles, at /municipal/<section>:
/// Public Institutions, Health, Education, Transportation or Emergency.
/// They said "coming soon" and led nowhere. The rows are the client's, from
/// the panel (מוסדות עירוניים); Figma has the tiles but no page behind them.
class MunicipalPlacesScreen extends ConsumerStatefulWidget {
  final MunicipalSection section;
  const MunicipalPlacesScreen({super.key, required this.section});

  @override
  ConsumerState<MunicipalPlacesScreen> createState() =>
      _MunicipalPlacesScreenState();
}

class _MunicipalPlacesScreenState extends ConsumerState<MunicipalPlacesScreen>
    with WebLanguageState<MunicipalPlacesScreen> {
  String _query = '';

  static final _en = lookupL(const Locale('en'));
  static final _he = lookupL(const Locale('he'));

  static String title(L l, MunicipalSection s) => switch (s) {
    MunicipalSection.institutions => l.svcInstitutions.replaceAll('\n', ' '),
    MunicipalSection.health => l.svcHealth,
    MunicipalSection.education => l.svcEducation,
    MunicipalSection.transport => l.svcTransport,
    MunicipalSection.emergency => l.svcEmergency,
  };

  List<MunicipalPlace> _filter(List<MunicipalPlace> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.nameEn ?? '').toLowerCase().contains(q) ||
          (p.address ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth > 1100
          ? _buildWeb(context)
          : _buildMobile(context),
    );
  }

  Widget _searchField(L l, {double height = 44}) => SizedBox(
    height: height,
    child: TextField(
      onChanged: (v) => setState(() => _query = v),
      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
      decoration: InputDecoration(
        hintText: l.searchPlacesHint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 14,
          color: const Color(0xFF6D6D6D),
        ),
        prefixIcon: const Icon(
          IconsaxPlusLinear.search_normal_1,
          size: 18,
          color: Color(0xFF6D6D6D),
        ),
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
    ),
  );

  /// The list, its loading and error states, and the empty ones.
  List<Widget> _content(L l, bool hebrew, {bool large = false}) {
    final async = ref.watch(municipalPlacesProvider(widget.section));
    Widget message(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: large ? 16 : 14,
            color: const Color(0xFF6D6D6D),
          ),
        ),
      ),
    );
    return switch (async) {
      AsyncData(:final value) when value.isEmpty => [
        message(l.nothingListedYet),
      ],
      AsyncData(:final value) => () {
        final shown = _filter(value);
        return [
          if (value.length > 8) ...[
            _searchField(l, height: large ? 48 : 44),
            const SizedBox(height: 12),
          ],
          if (shown.isEmpty)
            message(l.noPlacesMatchSearch)
          else
            ...municipalPlaceGroups(
              places: shown,
              l: l,
              hebrew: hebrew,
              large: large,
            ),
          // OpenStreetMap's licence (ODbL) asks for this where its data shows.
          if (value.any((p) => p.fromOsm))
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                l.mapDataCredit,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            ),
        ];
      }(),
      AsyncError() => [
        message(l.couldNotLoadPlaces),
        Center(
          child: OutlinedButton(
            onPressed: () =>
                ref.invalidate(municipalPlacesProvider(widget.section)),
            child: Text(l.tryAgain),
          ),
        ),
      ],
      _ => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    };
  }

  Widget _buildMobile(BuildContext context) {
    final l = L.of(context);
    final hebrew = Localizations.localeOf(context).languageCode == 'he';
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      const MBackArrow(color: Color(0xFF3D3D3D)),
                      Expanded(
                        child: Center(
                          child: Text(
                            title(l, widget.section),
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(municipalPlacesProvider(widget.section)),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        MediaQuery.paddingOf(context).bottom + 24,
                      ),
                      children: _content(l, hebrew),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    final hebrew = webIsHebrew.value;
    final l = hebrew ? _he : _en;
    return Directionality(
      textDirection: hebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(isHebrew: hebrew, activeId: null),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    WebSection(
                      child: Center(
                        child: SizedBox(
                          width: 820,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => context.canPop()
                                      ? context.back('/municipal')
                                      : context.go('/municipal'),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        hebrew
                                            ? IconsaxPlusLinear.arrow_right_3
                                            : IconsaxPlusLinear.arrow_left,
                                        size: 20,
                                        color: AppColors.midBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l.sitePageBack,
                                        style: TextStyle(
                                          fontFamily: AppFonts.inter,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.midBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                title(l, widget.section),
                                style: TextStyle(
                                  fontFamily: AppFonts.nunito,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 28),
                              ..._content(l, hebrew, large: true),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                    WebFooter(isHebrew: hebrew),
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
