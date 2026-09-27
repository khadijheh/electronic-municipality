import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/features/home/domain/unified_complaints_map_repository.dart';
import 'package:electronic_municipality_final/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('removes donations and loads unified complaint count on home map',
      (tester) async {
    final repository = _UnifiedComplaintsMapRepositoryFake(<UnifiedComplaintMapItem>[
      const UnifiedComplaintMapItem(
        id: 11,
        latitude: 33.5138,
        longitude: 36.2765,
        statusKey: 'in_progress',
        statusName: 'قيد المعالجة',
      ),
      const UnifiedComplaintMapItem(
        id: 12,
        latitude: 33.5190,
        longitude: 36.2810,
        statusKey: 'resolved',
        statusName: 'محلولة',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            onOpenProfile: _ignore,
            onOpenComplaints: _ignore,
            onOpenTransactions: _ignore,
            onOpenNews: _ignore,
            unifiedComplaintsRepository: repository,
            mapOverride: const ColoredBox(color: Color(0xFFEAF5EF)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home_donation_card')), findsNothing);
    expect(find.byKey(const ValueKey('home_complaint_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_transaction_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_map_card')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(repository.calls, 1);
  });
}

void _ignore() {}

class _UnifiedComplaintsMapRepositoryFake
    implements UnifiedComplaintsMapRepository {
  _UnifiedComplaintsMapRepositoryFake(this.items);

  final List<UnifiedComplaintMapItem> items;
  int calls = 0;

  @override
  Future<List<UnifiedComplaintMapItem>> getAllForMap({int perPage = 50}) async {
    calls++;
    return items;
  }

  @override
  Future<UnifiedComplaintsMapPage> getPage({
    int page = 1,
    int perPage = 50,
  }) async {
    return UnifiedComplaintsMapPage(
      items: items,
      currentPage: page,
      lastPage: page,
      total: items.length,
    );
  }
}
