import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/features/complaints/presentation/screens/complaint_location_picker_screen.dart';
import 'package:electronic_municipality_final/features/complaints/presentation/services/complaint_location_service.dart';

void main() {
  testWidgets('uses the device location and returns its coordinates', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _LocationServiceFake();
    final placeResolver = _PlaceResolverFake();
    ComplaintLocation? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<ComplaintLocation>(
                    MaterialPageRoute<ComplaintLocation>(
                      builder: (_) => ComplaintLocationPickerScreen(
                        locationService: service,
                        placeResolver: placeResolver,
                        mapOverride: const SizedBox.expand(
                          child: ColoredBox(
                            color: Color(0xFFE6ECE9),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('use_current_complaint_location')),
    );
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(placeResolver.calls, 1);
    expect(find.text('شارع الثورة'), findsOneWidget);
    expect(find.text('الصالحية، دمشق'), findsOneWidget);
    expect(find.text('33.513800\n36.276500'), findsNothing);
    expect(find.textContaining('33.513800'), findsOneWidget);
    expect(find.textContaining('36.276500'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('confirm_complaint_location')),
    );
    await tester.pumpAndSettle();

    expect(result?.latitude, 33.5138);
    expect(result?.longitude, 36.2765);
  });
}

class _LocationServiceFake implements ComplaintLocationService {
  int calls = 0;

  @override
  Future<ComplaintLocation> getCurrentLocation() async {
    calls++;
    return const ComplaintLocation(
      latitude: 33.5138,
      longitude: 36.2765,
    );
  }

  @override
  Future<bool> openSettings(ComplaintLocationFailureKind kind) async => true;
}

class _PlaceResolverFake implements ComplaintPlaceResolver {
  int calls = 0;

  @override
  Future<ComplaintPlace?> resolve(ComplaintLocation location) async {
    calls++;
    return const ComplaintPlace(
      title: 'شارع الثورة',
      subtitle: 'الصالحية، دمشق',
    );
  }
}
