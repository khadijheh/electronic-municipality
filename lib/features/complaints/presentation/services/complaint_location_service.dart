import 'dart:async';
import 'dart:ui';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/complaint_location.dart';

enum ComplaintLocationFailureKind {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

class ComplaintLocationFailure implements Exception {
  const ComplaintLocationFailure(this.kind, this.message);

  final ComplaintLocationFailureKind kind;
  final String message;

  bool get canOpenSettings =>
      kind == ComplaintLocationFailureKind.serviceDisabled ||
      kind == ComplaintLocationFailureKind.permissionDeniedForever;

  @override
  String toString() => message;
}

abstract class ComplaintLocationService {
  Future<ComplaintLocation> getCurrentLocation();

  Future<bool> openSettings(ComplaintLocationFailureKind kind);
}

class GeolocatorComplaintLocationService implements ComplaintLocationService {
  const GeolocatorComplaintLocationService();

  @override
  Future<ComplaintLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ComplaintLocationFailure(
        ComplaintLocationFailureKind.serviceDisabled,
        'خدمة الموقع غير مفعّلة. فعّل GPS ثم حاول مجددًا.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const ComplaintLocationFailure(
        ComplaintLocationFailureKind.permissionDenied,
        'لم يتم منح إذن الموقع. يمكنك اختيار الموقع يدويًا من الخريطة.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ComplaintLocationFailure(
        ComplaintLocationFailureKind.permissionDeniedForever,
        'إذن الموقع مرفوض نهائيًا. فعّله من إعدادات التطبيق أو اختر الموقع يدويًا.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      return ComplaintLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      throw const ComplaintLocationFailure(
        ComplaintLocationFailureKind.timeout,
        'تعذر تثبيت موقعك بسرعة. اقترب من نافذة أو اختر الموقع يدويًا.',
      );
    } catch (_) {
      throw const ComplaintLocationFailure(
        ComplaintLocationFailureKind.unavailable,
        'تعذر تحديد موقعك الآن. حاول مجددًا أو اختر الموقع يدويًا.',
      );
    }
  }

  @override
  Future<bool> openSettings(ComplaintLocationFailureKind kind) {
    if (kind == ComplaintLocationFailureKind.serviceDisabled) {
      return Geolocator.openLocationSettings();
    }
    return Geolocator.openAppSettings();
  }
}

class ComplaintPlace {
  const ComplaintPlace({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}

abstract class ComplaintPlaceResolver {
  Future<ComplaintPlace?> resolve(ComplaintLocation location);
}

class NativeComplaintPlaceResolver implements ComplaintPlaceResolver {
  const NativeComplaintPlaceResolver();

  @override
  Future<ComplaintPlace?> resolve(ComplaintLocation location) async {
    final placemarks = await Geocoding().placemarkFromCoordinates(
      location.latitude,
      location.longitude,
      locale: const Locale('ar_SY'),
    );
    if (placemarks.isEmpty) return null;

    final place = placemarks.first;
    final title = _firstValue([
      place.name,
      place.street,
      place.thoroughfare,
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ]);
    final details = _uniqueValues([
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
      place.country,
    ]).where((value) => value != title).take(3).join('، ');

    if (title == null && details.isEmpty) return null;
    return ComplaintPlace(
      title: title ?? 'موقع محدد على الخريطة',
      subtitle: details.isEmpty ? null : details,
    );
  }

  static String? _firstValue(Iterable<String?> values) {
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) return normalized;
    }
    return null;
  }

  static Iterable<String> _uniqueValues(Iterable<String?> values) sync* {
    final seen = <String>{};
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized == null || normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      yield normalized;
    }
  }
}
