import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_map/flutter_map.dart';

import '../../../../l10n/localized_text.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_colors.dart';
import '../models/complaint_location.dart';
import '../services/complaint_location_service.dart';

export '../models/complaint_location.dart';

class ComplaintLocationPickerScreen extends StatefulWidget {
  const ComplaintLocationPickerScreen({
    super.key,
    this.initialLocation,
    this.locationService = const GeolocatorComplaintLocationService(),
    this.placeResolver = const NativeComplaintPlaceResolver(),
    @visibleForTesting this.mapOverride,
  });

  final ComplaintLocation? initialLocation;
  final ComplaintLocationService locationService;
  final ComplaintPlaceResolver placeResolver;
  final Widget? mapOverride;

  @override
  State<ComplaintLocationPickerScreen> createState() =>
      _ComplaintLocationPickerScreenState();
}

class _ComplaintLocationPickerScreenState
    extends State<ComplaintLocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(34.8021, 38.9968);

  final MapController _mapController = MapController();
  Timer? _placeDebounce;
  LatLng? _selectedPoint;
  ComplaintLocationFailure? _locationFailure;
  ComplaintPlace? _place;
  String? _placeError;
  bool _locating = false;
  bool _resolvingPlace = false;
  bool _mapReady = false;
  int _placeRequest = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    if (initial != null) {
      _selectedPoint = LatLng(initial.latitude, initial.longitude);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _schedulePlaceResolution(_selectedPoint!, immediate: true);
      });
    }
  }

  @override
  void dispose() {
    _placeDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _selectPoint(LatLng point) {
    setState(() {
      _selectedPoint = point;
      _locationFailure = null;
      _place = null;
      _placeError = null;
      _resolvingPlace = true;
    });
    _schedulePlaceResolution(point);
  }

  void _schedulePlaceResolution(
    LatLng point, {
    bool immediate = false,
  }) {
    _placeDebounce?.cancel();
    final request = ++_placeRequest;
    if (mounted && !_resolvingPlace) {
      setState(() => _resolvingPlace = true);
    }
    _placeDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 650),
      () => _resolvePlace(point, request),
    );
  }

  Future<void> _resolvePlace(LatLng point, int request) async {
    try {
      final place = await widget.placeResolver.resolve(
        ComplaintLocation(
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      );
      if (!_isCurrentPlaceRequest(point, request)) return;
      setState(() {
        _place = place;
        _placeError = place == null
            ? 'لم يتوفر اسم لهذا الموضع، ويمكنك اعتماده بالإحداثيات.'
            : null;
        _resolvingPlace = false;
      });
    } catch (_) {
      if (!_isCurrentPlaceRequest(point, request)) return;
      setState(() {
        _place = null;
        _placeError =
            'تعذر جلب اسم المكان الآن، ويمكنك اعتماد الإحداثيات بأمان.';
        _resolvingPlace = false;
      });
    }
  }

  bool _isCurrentPlaceRequest(LatLng point, int request) {
    final selected = _selectedPoint;
    return mounted &&
        request == _placeRequest &&
        selected != null &&
        selected.latitude == point.latitude &&
        selected.longitude == point.longitude;
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationFailure = null;
    });
    try {
      final location = await widget.locationService.getCurrentLocation();
      if (!mounted) return;
      final point = LatLng(location.latitude, location.longitude);
      setState(() {
        _selectedPoint = point;
        _place = null;
        _placeError = null;
        _resolvingPlace = true;
      });
      if (_mapReady) {
        _mapController.move(point, 16);
      }
      _schedulePlaceResolution(point, immediate: true);
    } on ComplaintLocationFailure catch (failure) {
      if (mounted) setState(() => _locationFailure = failure);
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationFailure = const ComplaintLocationFailure(
            ComplaintLocationFailureKind.unavailable,
            'تعذر تحديد موقعك الآن. حاول مجددًا أو اختر الموقع يدويًا.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openLocationSettings() async {
    final failure = _locationFailure;
    if (failure == null || !failure.canOpenSettings) return;
    await widget.locationService.openSettings(failure.kind);
  }

  void _confirmLocation() {
    final point = _selectedPoint;
    if (point == null) return;
    Navigator.pop(
      context,
      ComplaintLocation(
        latitude: point.latitude,
        longitude: point.longitude,
        placeDescription: _placeDescription(_place),
      ),
    );
  }

  String? _placeDescription(ComplaintPlace? place) {
    if (place == null) return null;
    final parts = <String>[
      place.title.trim(),
      if (place.subtitle?.trim().isNotEmpty == true) place.subtitle!.trim(),
    ];
    return parts.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selectedPoint ?? _defaultCenter;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختيار موقع الشكوى',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 3),
            Text(
              'حدّد النقطة الأقرب للمشكلة',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panelMaxHeight =
              (constraints.maxHeight * .5).clamp(330.0, 430.0).toDouble();
          return Stack(
            fit: StackFit.expand,
            children: [
              widget.mapOverride ??
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: _selectedPoint == null ? 6.5 : 15,
                      minZoom: 5,
                      maxZoom: 19,
                      onMapReady: () => _mapReady = true,
                      onTap: (_, point) => _selectPoint(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.electronic_municipality',
                        maxZoom: 19,
                      ),
                      if (_selectedPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedPoint!,
                              width: 68,
                              height: 74,
                              child: const _ComplaintMapPin(),
                            ),
                          ],
                        ),
                    ],
                  ),
              const Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: _MapHint(),
              ),
              Positioned(
                left: 12,
                bottom: panelMaxHeight + 26,
                child: const _MapAttribution(),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 620,
                        maxHeight: panelMaxHeight,
                      ),
                      child: _buildLocationPanel(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationPanel() {
    final point = _selectedPoint;
    return Material(
      color: AppColors.surface,
      elevation: 14,
      shadowColor: AppColors.deepPrimary.withOpacity(.24),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 66),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.goldLight, AppColors.primary],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),
            _LocationSummary(
              selected: point != null,
              resolving: _resolvingPlace,
              place: _place,
              error: _placeError,
            ),
            if (point != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CoordinateChip(
                      label: 'خط العرض',
                      value: point.latitude.toStringAsFixed(6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CoordinateChip(
                      label: 'خط الطول',
                      value: point.longitude.toStringAsFixed(6),
                    ),
                  ),
                ],
              ),
            ],
            if (_locationFailure != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      _locationFailure!.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_locationFailure!.canOpenSettings)
                      TextButton.icon(
                        key: const ValueKey('open_location_settings'),
                        onPressed: _openLocationSettings,
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: Text(
                          _locationFailure!.kind ==
                                  ComplaintLocationFailureKind.serviceDisabled
                              ? 'فتح إعدادات الموقع'
                              : 'فتح إعدادات التطبيق',
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const ValueKey('use_current_complaint_location'),
              onPressed: _locating ? null : _useCurrentLocation,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _locating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _locating ? 'جارٍ تحديد موقعك...' : 'استخدام موقعي الحالي',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey('confirm_complaint_location'),
              onPressed: point == null ? null : _confirmLocation,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceMuted,
                disabledForegroundColor: AppColors.muted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text(
                'اعتماد هذا الموقع',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(.1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepPrimary.withOpacity(.13),
              blurRadius: 22,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اضغط على الخريطة لتثبيت النقطة',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'سنضيف اسم المكان والإحداثيات تلقائيًا',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
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

class _ComplaintMapPin extends StatelessWidget {
  const _ComplaintMapPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 45,
          child: Container(
            width: 28,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.deepPrimary.withOpacity(.22),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const Icon(
          Icons.location_on_rounded,
          size: 62,
          color: AppColors.primary,
          shadows: [
            Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        Positioned(
          top: 13,
          child: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 4),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          '© OpenStreetMap contributors',
          textDirection: TextDirection.ltr,
          style: TextStyle(fontSize: 9.5, color: AppColors.muted),
        ),
      ),
    );
  }
}

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({
    required this.selected,
    required this.resolving,
    required this.place,
    required this.error,
  });

  final bool selected;
  final bool resolving;
  final ComplaintPlace? place;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final title = !selected
        ? 'اختر موقع المشكلة'
        : resolving
            ? 'جارٍ التعرّف على المكان...'
            : place?.title ?? 'تم تحديد الموقع بالإحداثيات';
    final subtitle = !selected
        ? 'المس الخريطة أو استخدم موقعك الحالي للبدء.'
        : resolving
            ? 'لحظات ونحاول إظهار اسم الشارع أو الحي.'
            : place?.subtitle ?? error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: selected ? AppColors.mint : AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: resolving
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(
                  selected
                      ? Icons.location_on_rounded
                      : Icons.add_location_alt_outlined,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: place == null
                    ? null
                    : const ValueKey('complaint_selected_place_name'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  key: place?.subtitle == null
                      ? null
                      : const ValueKey('complaint_selected_place_details'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: error == null ? AppColors.muted : AppColors.gold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (selected && !resolving)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.verified_rounded,
              color: AppColors.success,
              size: 21,
            ),
          ),
      ],
    );
  }
}

class _CoordinateChip extends StatelessWidget {
  const _CoordinateChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textDirection: TextDirection.ltr,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: .25,
            ),
          ),
        ],
      ),
    );
  }
}
