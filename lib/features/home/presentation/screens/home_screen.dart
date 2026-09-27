import 'package:flutter/material.dart' hide Text;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:electronic_municipality_final/l10n/app_localizations.dart';
import 'package:electronic_municipality_final/l10n/localized_text.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../shared/widgets/municipality_widgets.dart';
import '../../domain/unified_complaints_map_repository.dart';

const Color _homeDeepGreen = Color(0xFF002A1C);
const Color _homeText = Color(0xFF1B1C19);
const Color _homeMutedText = Color(0xFF5F665F);
const Color _homeDanger = Color(0xFFC43A3A);
const LatLng _damascusCenter = LatLng(33.5138, 36.2765);

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenProfile,
    required this.onOpenComplaints,
    required this.onOpenTransactions,
    required this.onOpenNews,
    this.unifiedComplaintsRepository,
    this.mapOverride,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onOpenComplaints;
  final VoidCallback onOpenTransactions;
  final VoidCallback onOpenNews;
  final UnifiedComplaintsMapRepository? unifiedComplaintsRepository;
  final Widget? mapOverride;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('home_screen'),
      padding: EdgeInsets.zero,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        HomeTopBar(onOpenProfile: onOpenProfile),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnnouncementsSection(onOpenNews: onOpenNews),
              const SizedBox(height: 30),
              QuickActionsSection(
                onOpenComplaints: onOpenComplaints,
                onOpenTransactions: onOpenTransactions,
              ),
              const SizedBox(height: 30),
              MunicipalityMapCard(
                repository: unifiedComplaintsRepository,
                mapOverride: mapOverride,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.onOpenProfile});
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: Color(0x14002A1C))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: IconButton(
              key: const ValueKey('home_notifications_button'),
              tooltip: context.tr('الإشعارات'),
              padding: EdgeInsets.zero,
              onPressed: () {},
              icon: const BadgeDot(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: _homeMutedText,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              key: const ValueKey('home_search_field'),
              textDirection: Directionality.of(context),
              decoration: InputDecoration(
                hintText: context.tr('ابحث في الخدمات...'),
                hintStyle: const TextStyle(color: _homeMutedText, fontSize: 15),
                prefixIcon: const Icon(Icons.search_rounded, color: _homeMutedText),
                prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsetsDirectional.only(
                  start: 2,
                  end: 14,
                  top: 11,
                  bottom: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: Color(0xFFC9D0CA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: Color(0xFFC9D0CA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: _homeDeepGreen, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Material(
            color: const Color(0xFFE4EEE8),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('home_profile_button'),
              customBorder: const CircleBorder(),
              onTap: onOpenProfile,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.person_outline_rounded, color: _homeDeepGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementsSection extends StatelessWidget {
  const AnnouncementsSection({super.key, required this.onOpenNews});
  final VoidCallback onOpenNews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أحدث الأخبار والإعلانات',
          style: TextStyle(color: _homeText, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth * .82).clamp(250.0, 310.0).toDouble();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: 2,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) => SizedBox(
                  width: width,
                  child: _AnnouncementCard(
                    onTap: onOpenNews,
                    tag: index == 0 ? 'تطوير المدينة' : 'إعلان رسمي',
                    title: index == 0
                        ? 'افتتاح حديقة جديدة في وسط المدينة'
                        : 'تحديث آلية استقبال معاملات البناء',
                    icon: index == 0 ? Icons.park_outlined : Icons.apartment_rounded,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.onTap,
    required this.tag,
    required this.title,
    required this.icon,
  });
  final VoidCallback onTap;
  final String tag;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _homeDeepGreen,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('home_latest_news_card'),
        onTap: onTap,
        child: Stack(
          children: [
            PositionedDirectional(
              top: -28,
              end: -18,
              child: Icon(icon, size: 150, color: Colors.white.withOpacity(.08)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.35, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('عرض التفاصيل', style: TextStyle(color: Color(0xFFD4E9DC), fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 5),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        color: const Color(0xFFD4E9DC),
                        size: 17,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.onOpenComplaints,
    required this.onOpenTransactions,
  });
  final VoidCallback onOpenComplaints;
  final VoidCallback onOpenTransactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('الخدمات السريعة', style: TextStyle(color: _homeText, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        const Text('ابدأ بالخدمة التي تحتاجها الآن', style: TextStyle(color: _homeMutedText, fontSize: 14)),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _QuickServiceCard(
                key: const ValueKey('home_complaint_card'),
                accent: const Color(0xFFD95F59),
                surface: const Color(0xFFFFF0EE),
                icon: Icons.campaign_outlined,
                eyebrow: 'إبلاغ جديد',
                title: 'تقديم شكوى',
                subtitle: 'بلّغ عن مشكلة في منطقتك',
                onTap: onOpenComplaints,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickServiceCard(
                key: const ValueKey('home_transaction_card'),
                accent: const Color(0xFF22785A),
                surface: const Color(0xFFEAF5EF),
                icon: Icons.assignment_outlined,
                eyebrow: 'طلب رسمي',
                title: 'تقديم معاملة',
                subtitle: 'ابدأ أو تابع طلباتك الرسمية',
                onTap: onOpenTransactions,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickServiceCard extends StatelessWidget {
  const _QuickServiceCard({
    super.key,
    required this.accent,
    required this.surface,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final Color accent;
  final Color surface;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 178,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: accent.withOpacity(.22), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Icon(icon, color: Colors.white, size: 23),
                  ),
                  const Spacer(),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    color: accent,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(eyebrow, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _homeText, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _homeMutedText, fontSize: 12.5, height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MapComplaintFilter { all, active, terminal }

class MunicipalityMapCard extends StatefulWidget {
  const MunicipalityMapCard({super.key, this.repository, this.mapOverride});
  final UnifiedComplaintsMapRepository? repository;
  final Widget? mapOverride;

  @override
  State<MunicipalityMapCard> createState() => _MunicipalityMapCardState();
}

class _MunicipalityMapCardState extends State<MunicipalityMapCard> {
  final MapController _mapController = MapController();
  late final UnifiedComplaintsMapRepository _repository = widget.repository ?? DI.unifiedComplaintsMap;
  List<UnifiedComplaintMapItem> _items = const [];
  UnifiedComplaintMapItem? _selected;
  _MapComplaintFilter _filter = _MapComplaintFilter.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.getAllForMap();
      if (!mounted) return;
      setState(() {
        _items = items;
        if (!_items.contains(_selected)) _selected = null;
      });
      _focusMapOnItems(items);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحميل خريطة الشكاوى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _focusMapOnItems(List<UnifiedComplaintMapItem> items) {
    if (widget.mapOverride != null || items.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final points = items
          .map((item) => LatLng(item.latitude, item.longitude))
          .toList(growable: false);
      if (points.length == 1) {
        _mapController.move(points.single, 14.5);
        return;
      }
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(44),
          maxZoom: 14.5,
        ),
      );
    });
  }

  List<UnifiedComplaintMapItem> get _visibleItems => _items.where((item) {
        return switch (_filter) {
          _MapComplaintFilter.all => true,
          _MapComplaintFilter.active => !_isTerminal(item.statusKey),
          _MapComplaintFilter.terminal => _isTerminal(item.statusKey),
        };
      }).toList(growable: false);

  void _changeFilter(_MapComplaintFilter filter) {
    setState(() {
      _filter = filter;
      if (_selected != null && !_visibleItems.contains(_selected)) _selected = null;
    });
  }

  void _select(UnifiedComplaintMapItem item) {
    setState(() => _selected = item);
    _mapController.move(LatLng(item.latitude, item.longitude), 15.2);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;
    return Container(
      key: const ValueKey('home_map_card'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x3322785A)),
        boxShadow: const [BoxShadow(color: Color(0x16002A1C), blurRadius: 28, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 13),
            child: _MapHeader(count: _items.length, loading: _loading),
          ),
          _MapFilterBar(filter: _filter, onChanged: _changeFilter),
          const SizedBox(height: 12),
          SizedBox(
            height: 370,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: widget.mapOverride ?? FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(initialCenter: _damascusCenter, initialZoom: 11.2, minZoom: 5, maxZoom: 18),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.electronic_municipality',
                          maxZoom: 19,
                        ),
                        MarkerLayer(markers: visible.map((item) => _marker(context, item)).toList(growable: false)),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: 14,
                    start: 14,
                    child: _MapLegend(items: visible),
                  ),
                  PositionedDirectional(
                    top: 14,
                    end: 14,
                    child: Material(
                      color: const Color(0xEFFFFFFF),
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: const ValueKey('home_map_reload_button'),
                        tooltip: context.tr('إعادة تحميل الخريطة'),
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.refresh_rounded, color: _homeDeepGreen),
                      ),
                    ),
                  ),
                  if (_loading) const Positioned.fill(child: _MapLoadingOverlay())
                  else if (_error != null) Positioned.fill(child: _MapErrorOverlay(message: _error!, onRetry: _load))
                  else if (visible.isEmpty) const Positioned.fill(child: _MapEmptyOverlay()),
                  if (_selected != null && !_loading && _error == null)
                    PositionedDirectional(
                      start: 14,
                      end: 14,
                      bottom: 14,
                      child: _MapComplaintDetails(item: _selected!, onClose: () => setState(() => _selected = null)),
                    ),
                  const PositionedDirectional(
                    end: 8,
                    bottom: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xD9FFFFFF), borderRadius: BorderRadius.all(Radius.circular(5))),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        child: Text('© OpenStreetMap contributors', translate: false, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 8.5, color: _homeMutedText)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _marker(BuildContext context, UnifiedComplaintMapItem item) {
    final selected = identical(item, _selected);
    return Marker(
      point: LatLng(item.latitude, item.longitude),
      width: selected ? 54 : 46,
      height: selected ? 61 : 53,
      child: Semantics(
        button: true,
        label: '${context.tr('شكوى موحدة')} #${item.id}',
        child: InkWell(
          key: ValueKey('home_unified_complaint_marker_${item.id}'),
          borderRadius: BorderRadius.circular(99),
          onTap: () => _select(item),
          child: _ComplaintMarker(color: _statusColor(item.statusKey), selected: selected),
        ),
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.count, required this.loading});
  final int count;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(color: Color(0xFFE5F3EB), shape: BoxShape.circle),
          child: const Icon(Icons.map_outlined, color: _homeDeepGreen, size: 24),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('شكاوى المنطقة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              SizedBox(height: 3),
              Text('عرض مواقع الشكاوى الرئيسية ضمن بلديتك.', style: TextStyle(color: _homeMutedText, fontSize: 12.5)),
            ],
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 34, minHeight: 31),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFEAF5EF), borderRadius: BorderRadius.circular(99)),
          child: loading
              ? const SizedBox.square(dimension: 15, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('$count', translate: false, textDirection: TextDirection.ltr, style: const TextStyle(color: _homeDeepGreen, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _MapFilterBar extends StatelessWidget {
  const _MapFilterBar({required this.filter, required this.onChanged});
  final _MapComplaintFilter filter;
  final ValueChanged<_MapComplaintFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _MapFilterChip(label: 'جميع الحالات', selected: filter == _MapComplaintFilter.all, onTap: () => onChanged(_MapComplaintFilter.all)),
          const SizedBox(width: 8),
          _MapFilterChip(label: 'غير منتهية', selected: filter == _MapComplaintFilter.active, onTap: () => onChanged(_MapComplaintFilter.active)),
          const SizedBox(width: 8),
          _MapFilterChip(label: 'منتهية', selected: filter == _MapComplaintFilter.terminal, onTap: () => onChanged(_MapComplaintFilter.terminal)),
        ],
      ),
    );
  }
}

class _MapFilterChip extends StatelessWidget {
  const _MapFilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _homeDeepGreen : const Color(0xFFF0F3F0),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : _homeMutedText, fontSize: 12.5, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.items});
  final List<UnifiedComplaintMapItem> items;

  @override
  Widget build(BuildContext context) {
    final active = items.where((item) => !_isTerminal(item.statusKey)).length;
    final terminal = items.length - active;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
        boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendDot(color: _homeDanger, value: active),
            const SizedBox(width: 8),
            _LegendDot(color: AppColors.success, value: terminal),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.value});
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$value', translate: false, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _homeText)),
      ],
    );
  }
}

class _MapLoadingOverlay extends StatelessWidget {
  const _MapLoadingOverlay();
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x66F2F6F3),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.2)),
                SizedBox(width: 10),
                Text('جارٍ تحميل الشكاوى الموحدة...', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapErrorOverlay extends StatelessWidget {
  const _MapErrorOverlay({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xD9FFF9F8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: _homeDanger, size: 34),
              const SizedBox(height: 9),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة تحميل الخريطة')),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapEmptyOverlay extends StatelessWidget {
  const _MapEmptyOverlay();
  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xBFF4F7F5),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_searching_rounded, color: _homeMutedText, size: 36),
              SizedBox(height: 10),
              Text(
                'لا توجد شكاوى موحّدة ذات إحداثيات لعرضها على الخريطة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _homeMutedText, height: 1.45, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComplaintMarker extends StatelessWidget {
  const _ComplaintMarker({required this.color, required this.selected});
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 47.0 : 40.0;
    return SizedBox(
      width: selected ? 54 : 46,
      height: selected ? 61 : 53,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: size - 7,
            child: Transform.rotate(angle: .785398, child: Container(width: 14, height: 14, color: color)),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: selected ? 3 : 2),
              boxShadow: [BoxShadow(color: color.withOpacity(.36), blurRadius: selected ? 16 : 10, offset: const Offset(0, 5))],
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MapComplaintDetails extends StatelessWidget {
  const _MapComplaintDetails({required this.item, required this.onClose});
  final UnifiedComplaintMapItem item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.statusKey);
    final description = item.canonicalDescription;
    final location = item.locationDescription;
    final category = item.categoryName;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(.25),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on_rounded, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title ?? 'شكوى #${item.id}',
                    translate: item.title == null,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      translate: false,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _homeMutedText,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (location != null) ...[
                    const SizedBox(height: 6),
                    _MapDetailLine(
                      icon: Icons.place_outlined,
                      value: location,
                    ),
                  ],
                  if (category != null) ...[
                    const SizedBox(height: 4),
                    _MapDetailLine(
                      icon: Icons.category_outlined,
                      value: category,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _StatusPill(label: item.statusName, color: color),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr('إغلاق'),
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapDetailLine extends StatelessWidget {
  const _MapDetailLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _homeMutedText),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            translate: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _homeMutedText, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }
}

bool _isTerminal(String key) => switch (key.toLowerCase()) {
      'resolved' || 'closed' || 'rejected' => true,
      _ => false,
    };

Color _statusColor(String key) =>
    _isTerminal(key) ? AppColors.success : _homeDanger;
