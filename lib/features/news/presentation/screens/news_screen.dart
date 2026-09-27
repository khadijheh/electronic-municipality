import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../shared/widgets/municipality_widgets.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        children: const [
          PageHeader(title: 'الأخبار', subtitle: 'إعلانات وخدمات البلدية'),
          SizedBox(height: 24),
          NewsArticleCard(
              title: 'افتتاح حديقة جديدة في وسط المدينة', tag: 'تطوير المدينة'),
          SizedBox(height: 16),
          NewsArticleCard(
              title: 'تحديث آلية استقبال معاملات البناء', tag: 'إعلان رسمي'),
        ]);
  }
}

class NewsArticleCard extends StatelessWidget {
  const NewsArticleCard({super.key, required this.title, required this.tag});
  final String title;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 210,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(AppAssets.cityNews, fit: BoxFit.cover),
              Container(color: AppColors.deepPrimary.withOpacity(0.34)),
              Positioned(
                  right: 18,
                  bottom: 62,
                  child: StatusPill(label: tag, color: AppColors.gold)),
              Positioned(
                  right: 18,
                  left: 18,
                  bottom: 18,
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)))
            ])));
  }
}
