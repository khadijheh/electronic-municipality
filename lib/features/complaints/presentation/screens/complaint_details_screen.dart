import 'package:flutter/material.dart' hide Text;

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/localized_text.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/municipality_widgets.dart';
import '../../data/models/complaint_models.dart';
import '../../domain/complaints_repository.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  const ComplaintDetailsScreen({
    super.key,
    required this.summary,
    required this.repository,
  });

  final ComplaintReport summary;
  final ComplaintsRepository repository;

  @override
  State<ComplaintDetailsScreen> createState() =>
      _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late ComplaintReport _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _report = widget.summary;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await widget.repository.getReport(widget.summary.id);
      if (!mounted) return;
      setState(() => _report = report);
    } catch (error, stackTrace) {
      debugPrint('LOAD COMPLAINT DETAILS ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('complaint_details_screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _DetailsHeader(report: _report),
            if (_loading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null) ...[
                              _DetailsNotice(message: _error!, retry: _load),
                              const SizedBox(height: 14),
                            ],
                            _SummaryCard(report: _report),
                            const SizedBox(height: 14),
                            _LocationCard(report: _report),
                            const SizedBox(height: 14),
                            _ImagesCard(images: _report.images),
                            const SizedBox(height: 14),
                            _StatusHistoryCard(history: _report.statusHistory),
                            const SizedBox(height: 14),
                            _TimelineCard(report: _report),
                          ],
                        ),
                      ),
                    ),
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

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.report});

  final ComplaintReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 18, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('close_complaint_details'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_forward_rounded),
            tooltip: 'رجوع',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تفاصيل الشكوى',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'رقم البلاغ #${report.id}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(
            label: report.status.label,
            color: _statusColor(report.status.key),
            pale: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final ComplaintReport report;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(18),
      elevation: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleIcon(
                icon: Icons.description_outlined,
                size: 46,
                color: Color(0xFFE1EEE8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title ?? 'شكوى #${report.id}',
                      key: const ValueKey('complaint_details_title'),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (report.category?.name != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        report.category!.name,
                        key: const ValueKey('complaint_details_category'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _CardLabel('وصف الشكوى'),
          const SizedBox(height: 6),
          Text(
            report.description ?? 'لم يُضف وصف للشكوى.',
            key: const ValueKey('complaint_details_description'),
            style: TextStyle(
              height: 1.65,
              color: report.description == null
                  ? AppColors.muted
                  : AppColors.text,
            ),
          ),
          if (report.municipalityName != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.account_balance_outlined,
              label: 'البلدية',
              value: report.municipalityName!,
              valueKey: const ValueKey('complaint_details_municipality'),
            ),
          ],
          if (report.complaintId != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.confirmation_number_outlined,
              label: 'رقم الشكوى الموحدة',
              value: '#${report.complaintId}',
            ),
          ],
          if (report.reportersCount != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.groups_outlined,
              label: 'عدد المبلّغين',
              value: '${report.reportersCount}',
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.report});

  final ComplaintReport report;

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = report.latitude != null && report.longitude != null;
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(
            icon: Icons.location_on_outlined,
            title: 'موقع الشكوى',
          ),
          const SizedBox(height: 15),
          _InfoRow(
            icon: Icons.signpost_outlined,
            label: 'وصف الموقع',
            value: report.textLocation ?? 'لم يُضف وصف للموقع.',
            valueKey: const ValueKey('complaint_details_text_location'),
          ),
          if (hasCoordinates) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(.12)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${report.latitude!.toStringAsFixed(7)}, '
                      '${report.longitude!.toStringAsFixed(7)}',
                      key: const ValueKey('complaint_details_coordinates'),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImagesCard extends StatelessWidget {
  const _ImagesCard({required this.images});

  final List<ComplaintImage> images;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(
            icon: Icons.photo_library_outlined,
            title: 'الصور المرفقة',
            trailing: images.isEmpty ? null : '${images.length}',
          ),
          const SizedBox(height: 15),
          if (images.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.hide_image_outlined,
                    color: AppColors.subtle,
                    size: 34,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'لا توجد صور مرفقة بهذه الشكوى.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 580 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: images.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .82,
                  ),
                  itemBuilder: (context, index) {
                    final image = images[index];
                    return _ComplaintImageTile(image: image);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ComplaintImageTile extends StatelessWidget {
  const _ComplaintImageTile({required this.image});

  final ComplaintImage image;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('complaint_image_${image.id}'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _FullScreenImage(image: image),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'complaint-image-${image.id}',
                child: Image.network(
                  image.url,
                  key: ValueKey('complaint_image_network_${image.id}'),
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, synchronous) {
                    if (frame != null || synchronous) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const ColoredBox(
                    color: AppColors.surfaceMuted,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.subtle,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    image.name ?? 'صورة #${image.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (image.fileSize != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatBytes(image.fileSize!),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.image});

  final ComplaintImage image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07110E),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: .8,
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: 'complaint-image-${image.id}',
                    child: Image.network(
                      image.url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 52,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'تعذر تحميل الصورة.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(.46),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'إغلاق',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusHistoryCard extends StatelessWidget {
  const _StatusHistoryCard({required this.history});

  final List<ComplaintStatusHistory> history;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(
            icon: Icons.swap_horiz_rounded,
            title: 'تاريخ الحالة',
            trailing: history.isEmpty ? null : '${history.length}',
          ),
          const SizedBox(height: 15),
          if (history.isEmpty)
            const Text(
              'لا توجد تحديثات عامة على حالة الشكوى حتى الآن.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            for (final item in history) ...[
              _StatusHistoryRow(history: item),
              if (item != history.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _StatusHistoryRow extends StatelessWidget {
  const _StatusHistoryRow({required this.history});

  final ComplaintStatusHistory history;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (history.note?.trim().isNotEmpty == true) history.note!,
      if (history.changedByName?.trim().isNotEmpty == true)
        'بواسطة ${history.changedByName}',
      if (history.createdAt != null) _formatDate(history.createdAt!),
    ];

    return Container(
      key: ValueKey('complaint_status_history_${history.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sync_alt_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusHistoryTitle(history),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details.join(' • '),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.report});

  final ComplaintReport report;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void add(IconData icon, String label, DateTime? value) {
      if (value == null) return;
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(_InfoRow(icon: icon, label: label, value: _formatDate(value)));
    }

    add(Icons.add_circle_outline, 'تاريخ الإنشاء', report.createdAt);
    add(Icons.update_outlined, 'آخر تحديث', report.updatedAt);
    add(Icons.send_outlined, 'تاريخ الإرسال', report.submittedAt);
    add(Icons.link_outlined, 'تاريخ الربط', report.linkedAt);

    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(
            icon: Icons.history_rounded,
            title: 'معلومات زمنية',
          ),
          const SizedBox(height: 15),
          if (rows.isEmpty)
            const Text(
              'لا توجد معلومات زمنية متاحة.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ...rows,
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFE1EEE8),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueKey,
  });

  final IconData icon;
  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: 9),
        SizedBox(
          width: 94,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            key: valueKey,
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DetailsNotice extends StatelessWidget {
  const _DetailsNotice({required this.message, required this.retry});

  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.danger.withOpacity(.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: retry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

String _statusHistoryTitle(ComplaintStatusHistory history) {
  final from = history.fromStatus?.label;
  final to = history.toStatus?.label;
  if (from != null && to != null) return 'تغيّرت الحالة من $from إلى $to';
  if (to != null) return 'تغيّرت الحالة إلى $to';
  return 'تحديث على حالة الشكوى';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}/${two(local.month)}/${two(local.day)} – '
      '${two(local.hour)}:${two(local.minute)}';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}

Color _statusColor(String key) {
  switch (key.toLowerCase()) {
    case 'draft':
      return AppColors.gold;
    case 'resolved':
    case 'closed':
      return AppColors.success;
    case 'rejected':
      return AppColors.danger;
    case 'submitted':
    case 'in_progress':
      return AppColors.info;
    default:
      return AppColors.primary;
  }
}

String _messageFor(Object error) => error is ApiException
    ? error.message
    : 'تعذر تحميل أحدث تفاصيل الشكوى. اسحب للأسفل للمحاولة مجددًا.';
