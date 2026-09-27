import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electronic_municipality_final/core/repositories/auth_repository.dart';
import 'package:electronic_municipality_final/features/authentication/data/auth_repository_fake.dart';
import 'package:electronic_municipality_final/features/complaints/data/models/complaint_models.dart';
import 'package:electronic_municipality_final/features/complaints/domain/complaints_repository.dart';
import 'package:electronic_municipality_final/features/complaints/presentation/screens/complaint_location_picker_screen.dart';
import 'package:electronic_municipality_final/features/complaints/presentation/screens/complaints_screen.dart';

void main() {
  testWidgets('creates draft, uploads by report id, then submits', (
    WidgetTester tester,
  ) async {
    final repository = _ComplaintsRepositoryFake();
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComplaintsScreen(
            repository: repository,
            municipalityId: 12,
            locationSelector: (_, __) async => const ComplaintLocation(
              latitude: 33.5138,
              longitude: 36.2765,
              placeDescription: 'شارع النصر، دمشق',
            ),
            imagePicker: () async => <ComplaintAttachment>[
              ComplaintAttachment(
                name: 'evidence.jpg',
                bytes: Uint8List(20),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('complaint_category_group_field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('المياه والصرف الصحي').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('complaint_category_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسرب مياه').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('complaint_title_field')),
      'انقطاع المياه',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complaint_description_field')),
      'انقطاع المياه منذ الصباح',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final complaintsList = find.byType(ListView);

    final selectLocation =
        find.byKey(const ValueKey('select_complaint_location'));
    await tester.dragUntilVisible(
      selectLocation,
      complaintsList,
      const Offset(0, -200),
    );
    await tester.tap(selectLocation);
    await tester.pumpAndSettle();
    expect(find.text('33.513800, 36.276500'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('complaint_text_location_field')),
              matching: find.byType(TextField),
            ),
          )
          .controller
          ?.text,
      'شارع النصر، دمشق',
    );

    final pickImages = find.byKey(const ValueKey('pick_complaint_images'));
    await tester.dragUntilVisible(
      pickImages,
      complaintsList,
      const Offset(0, -200),
    );
    await tester.tap(pickImages);
    await tester.pumpAndSettle();

    final submit = find.byKey(const ValueKey('submit_complaint'));
    await tester.dragUntilVisible(
      submit,
      complaintsList,
      const Offset(0, -200),
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      repository.mutations,
      <String>[
        'create:12:16',
        'upload:51:1',
        'submit:51',
      ],
    );
    expect(repository.createdInput?.latitude, 33.5138);
    expect(repository.createdInput?.longitude, 36.2765);
    expect(find.text('مرسلة'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit_complaint_51')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('delete_complaint_51')),
      findsNothing,
    );
  });

  testWidgets('unverified citizen sees notice and cannot submit', (
    WidgetTester tester,
  ) async {
    final repository = _ComplaintsRepositoryFake();
    final authRepository = AuthRepositoryFake(
      currentUser: const AuthUser(
        id: 1,
        fullName: 'مواطن غير موثق',
        email: 'citizen@example.sy',
        phoneNumber: '0990000000',
        roles: <String>['citizen'],
        accountType: 'citizen',
        citizenProfile: <String, dynamic>{
          'is_verified': false,
          'municipality_id': 12,
        },
      ),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComplaintsScreen(
            repository: repository,
            authRepository: authRepository,
            municipalityId: 12,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('citizen_verification_notice')),
      findsOneWidget,
    );
    expect(find.text('حساب المواطن غير موثق'), findsOneWidget);

    final submit = find.byKey(const ValueKey('submit_complaint'));
    await tester.dragUntilVisible(
      submit,
      find.byType(ListView),
      const Offset(0, -220),
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.mutations, isEmpty);
    expect(
      find.text(
        'حساب المواطن غير موثق. يجب توثيق الحساب قبل إرسال الشكوى.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens complaint details and displays its attached images', (
    WidgetTester tester,
  ) async {
    final repository = _ComplaintsHistoryRepositoryFake();
    const verifiedCitizen = AuthUser(
      id: 9,
      fullName: 'مواطن موثق',
      email: 'verified@example.sy',
      phoneNumber: '0990000000',
      roles: <String>['citizen'],
      accountType: 'citizen',
      citizenProfile: <String, dynamic>{
        'is_verified': true,
        'municipality_id': 1,
      },
    );
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComplaintsScreen(
            repository: repository,
            authRepository: AuthRepositoryFake(
              currentUser: verifiedCitizen,
            ),
            municipalityId: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('سجل الشكاوى'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('open_complaint_34')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('open_complaint_34')));
    await tester.pumpAndSettle();

    expect(repository.getReportCalls, 1);
    expect(
      find.byKey(const ValueKey('complaint_details_screen')),
      findsOneWidget,
    );
    expect(find.text('تفاصيل الشكوى'), findsOneWidget);
    expect(find.text('عمود إنارة متضرر'), findsWidgets);
    expect(find.text('بلدية كفرسوسة'), findsOneWidget);
    expect(find.text('scaled_125865.jpg'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('complaint_image_5')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('complaint_status_history_91'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'تمت إحالة الشكوى إلى الوحدة المختصة.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}

class _ComplaintsRepositoryFake implements ComplaintsRepository {
  final List<String> mutations = <String>[];
  ComplaintDraftInput? createdInput;
  ComplaintReport? _report;

  static const _waterLeak = ComplaintCategory(
    id: 16,
    parentId: 15,
    name: 'تسرب مياه',
  );

  static const _water = ComplaintCategory(
    id: 15,
    name: 'المياه والصرف الصحي',
    children: <ComplaintCategory>[_waterLeak],
  );

  @override
  Future<List<ComplaintCategory>> getCategories() async {
    return const <ComplaintCategory>[_water];
  }

  @override
  Future<List<ComplaintReport>> getReports() async {
    return <ComplaintReport>[if (_report != null) _report!];
  }

  @override
  Future<ComplaintReportsPage> getReportsPage({
    int page = 1,
    int perPage = 15,
  }) async {
    final reports = await getReports();
    return ComplaintReportsPage(
      items: reports,
      currentPage: page,
      lastPage: page,
      perPage: perPage,
      total: reports.length,
    );
  }

  @override
  Future<ComplaintReport> getReport(int reportId) async {
    return _report!;
  }

  @override
  Future<ComplaintReport> createDraft(ComplaintDraftInput input) async {
    createdInput = input;
    mutations.add(
      'create:${input.municipalityId}:${input.categoryId}',
    );
    _report = ComplaintReport(
      id: 51,
      status: const ComplaintStatus(key: 'draft', label: 'مسودة'),
      images: const <ComplaintImage>[],
      municipalityId: input.municipalityId,
      categoryId: input.categoryId,
      category: _waterLeak,
      title: input.title?.trim(),
      description: input.description?.trim(),
      textLocation: input.textLocation?.trim(),
      latitude: input.latitude,
      longitude: input.longitude,
      serverCanEdit: true,
    );
    return _report!;
  }

  @override
  Future<ComplaintReport> updateDraft({
    required ComplaintReport report,
    required ComplaintDraftInput input,
  }) async {
    mutations.add('update:${report.id}');
    return report;
  }

  @override
  Future<void> uploadImages({
    required ComplaintReport report,
    required List<ComplaintAttachment> images,
  }) async {
    mutations.add('upload:${report.id}:${images.length}');
    _report = ComplaintReport(
      id: report.id,
      status: report.status,
      images: const <ComplaintImage>[
        ComplaintImage(id: 7, url: 'images/evidence.jpg'),
      ],
      municipalityId: report.municipalityId,
      categoryId: report.categoryId,
      category: report.category,
      title: report.title,
      description: report.description,
      textLocation: report.textLocation,
      latitude: report.latitude,
      longitude: report.longitude,
      serverCanEdit: true,
    );
  }

  @override
  Future<ComplaintReport> submitDraft(ComplaintReport report) async {
    mutations.add('submit:${report.id}');
    _report = ComplaintReport(
      id: report.id,
      status: const ComplaintStatus(key: 'submitted', label: 'مرسلة'),
      images: report.images,
      municipalityId: report.municipalityId,
      categoryId: report.categoryId,
      category: report.category,
      title: report.title,
      description: report.description,
      textLocation: report.textLocation,
      latitude: report.latitude,
      longitude: report.longitude,
      serverCanEdit: false,
    );
    return _report!;
  }

  @override
  Future<void> deleteDraft(ComplaintReport report) async {
    mutations.add('delete:${report.id}');
    _report = null;
  }

  @override
  Future<void> deleteImage({
    required ComplaintReport report,
    required int imageId,
  }) async {
    mutations.add('delete-image:${report.id}:$imageId');
  }
}

class _ComplaintsHistoryRepositoryFake implements ComplaintsRepository {
  int getReportCalls = 0;

  static final ComplaintReport report = ComplaintReport(
    id: 34,
    status: const ComplaintStatus(
      id: 2,
      key: 'submitted',
      label: 'تم الإرسال',
      isTerminal: false,
    ),
    images: const <ComplaintImage>[
      ComplaintImage(
        id: 5,
        url: 'https://example.invalid/complaint-image.jpg',
        name: 'scaled_125865.jpg',
        mimeType: 'image/jpeg',
        fileSize: 149020,
      ),
    ],
    statusHistory: <ComplaintStatusHistory>[
      ComplaintStatusHistory(
        id: 91,
        fromStatus: const ComplaintStatus(key: 'submitted', label: 'مرسلة'),
        toStatus: const ComplaintStatus(
          key: 'in_progress',
          label: 'قيد المعالجة',
        ),
        note: 'تمت إحالة الشكوى إلى الوحدة المختصة.',
        createdAt: DateTime.utc(2026, 8, 15, 10, 30),
      ),
    ],
    municipalityId: 1,
    municipalityName: 'بلدية كفرسوسة',
    categoryId: 13,
    category: const ComplaintCategory(
      id: 13,
      parentId: 11,
      name: 'عمود إنارة متضرر',
    ),
    title: 'بلاغ عمود إنارة',
    description: 'العمود متضرر ويحتاج إلى صيانة.',
    textLocation: 'قرب الحديقة العامة',
    latitude: 33.47287,
    longitude: 36.249791,
    serverCanEdit: false,
    isLinked: false,
    submittedAt: DateTime.utc(2026, 8, 14, 15, 45, 23),
    createdAt: DateTime.utc(2026, 8, 14, 15, 45, 21),
    updatedAt: DateTime.utc(2026, 8, 14, 15, 45, 23),
  );

  @override
  Future<List<ComplaintCategory>> getCategories() async {
    return const <ComplaintCategory>[];
  }

  @override
  Future<List<ComplaintReport>> getReports() async {
    return <ComplaintReport>[report];
  }

  @override
  Future<ComplaintReportsPage> getReportsPage({
    int page = 1,
    int perPage = 15,
  }) async {
    return ComplaintReportsPage(
      items: <ComplaintReport>[report],
      currentPage: page,
      lastPage: page,
      perPage: perPage,
      total: 1,
    );
  }

  @override
  Future<ComplaintReport> getReport(int reportId) async {
    getReportCalls++;
    return report;
  }

  @override
  Future<ComplaintReport> createDraft(ComplaintDraftInput input) {
    throw UnsupportedError('Not used by this test.');
  }

  @override
  Future<ComplaintReport> updateDraft({
    required ComplaintReport report,
    required ComplaintDraftInput input,
  }) {
    throw UnsupportedError('Not used by this test.');
  }

  @override
  Future<void> uploadImages({
    required ComplaintReport report,
    required List<ComplaintAttachment> images,
  }) {
    throw UnsupportedError('Not used by this test.');
  }

  @override
  Future<void> deleteImage({
    required ComplaintReport report,
    required int imageId,
  }) {
    throw UnsupportedError('Not used by this test.');
  }

  @override
  Future<void> deleteDraft(ComplaintReport report) {
    throw UnsupportedError('Not used by this test.');
  }

  @override
  Future<ComplaintReport> submitDraft(ComplaintReport report) {
    throw UnsupportedError('Not used by this test.');
  }
}
