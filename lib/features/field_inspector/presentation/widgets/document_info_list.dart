import 'package:flutter/material.dart' hide Text;

import '../../../../app/design_system.dart';
import '../../../../shared/widgets/municipality_widgets.dart';
import '../../data/models/inspector_document_model.dart';

/// بيانات الوثيقة (مقابل InfoCard في الويب). عمود واحد على الموبايل.
class DocumentInfoList extends StatelessWidget {
  const DocumentInfoList({super.key, required this.document});

  final InspectorDocumentModel document;

  String _or(String? value) => (value == null || value.isEmpty) ? '-' : value;

  @override
  Widget build(BuildContext context) {
    final fields = <(String, String)>[
      ('رقم الوثيقة', _or(document.documentNumber)),
      ('اسم المواطن', _or(document.citizenName)),
      ('نوع الخدمة', _or(document.serviceName)),
      ('البلدية', _or(document.municipality)),
      ('تاريخ الإصدار', formatInspectorDate(document.issuedAt)),
      ('تاريخ الانتهاء', formatInspectorDate(document.expiresAt)),
    ];

    return Column(
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          ReadonlyField(label: fields[i].$1, value: fields[i].$2),
          if (i != fields.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
