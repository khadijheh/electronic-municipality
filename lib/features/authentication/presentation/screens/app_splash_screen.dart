import 'package:flutter/material.dart' hide Text;
import 'package:electronic_municipality_final/l10n/localized_text.dart';
import 'package:electronic_municipality_final/l10n/app_localizations.dart';

import '../../../../app/design_system.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../shared/widgets/municipality_widgets.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(seconds: 3);

  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();
    _initialize();
  }

  Future<void> _initialize() async {
    var destination = AuthStartupDestination.login;

    try {
      final results = await Future.wait<Object?>([
        DI.auth.restoreSession(),
        Future<void>.delayed(_splashDuration),
      ]);
      destination = results.first as AuthStartupDestination;
    } catch (error, stackTrace) {
      debugPrint('SESSION RESTORE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;

    final route = switch (destination) {
      AuthStartupDestination.authenticated =>
        DI.auth.currentUser?.isFieldInspector == true
            ? AppRoutes.fieldInspector
            : AppRoutes.shell,
      AuthStartupDestination.changeTemporaryPassword =>
        AppRoutes.changeTemporaryPassword,
      AuthStartupDestination.login => AppRoutes.login,
    };

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emerald,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final logoSize = (width * 0.45).clamp(132.0, 180.0).toDouble();
          final progressWidth = (width * 0.533).clamp(168.0, 220.0).toDouble();

          return CustomPaint(
            painter: const _SplashFramePainter(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: height * 0.25875,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MunicipalityLogo(size: logoSize),
                      SizedBox(height: width * 0.061),
                      const Text(
                        'بلديتنا الإلكترونية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'بوابة المواطن الرقمية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.splashSubtitle,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: height * 0.64625,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _SplashProgressBar(
                      animation: _progressController,
                      width: progressWidth,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SplashProgressBar extends StatelessWidget {
  const _SplashProgressBar({
    required this.animation,
    required this.width,
  });

  final Animation<double> animation;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('جارٍ تحميل بوابة المواطن الرقمية'),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final progress = Curves.easeInOutCubic.transform(animation.value);

          return Container(
            width: width,
            height: 4,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.splashProgressTrack,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: width * progress,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.goldLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplashFramePainter extends CustomPainter {
  const _SplashFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * (8 / 720);
    final lineCenter = size.width * (68 / 720);
    final segmentLength = size.width * (256 / 720);
    final paint = Paint()
      ..color = AppColors.splashFrame
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas
      // Top-left corner.
      ..drawLine(
        Offset(lineCenter, 0),
        Offset(lineCenter, segmentLength),
        paint,
      )
      ..drawLine(
        Offset.zero.translate(0, lineCenter),
        Offset(segmentLength, lineCenter),
        paint,
      )
      // Top-right corner.
      ..drawLine(
        Offset(size.width - lineCenter, 0),
        Offset(size.width - lineCenter, segmentLength),
        paint,
      )
      ..drawLine(
        Offset(size.width - segmentLength, lineCenter),
        Offset(size.width, lineCenter),
        paint,
      )
      // Bottom-left corner.
      ..drawLine(
        Offset(lineCenter, size.height - segmentLength),
        Offset(lineCenter, size.height),
        paint,
      )
      ..drawLine(
        Offset(0, size.height - lineCenter),
        Offset(segmentLength, size.height - lineCenter),
        paint,
      )
      // Bottom-right corner.
      ..drawLine(
        Offset(size.width - lineCenter, size.height - segmentLength),
        Offset(size.width - lineCenter, size.height),
        paint,
      )
      ..drawLine(
        Offset(size.width - segmentLength, size.height - lineCenter),
        Offset(size.width, size.height - lineCenter),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _SplashFramePainter oldDelegate) => false;
}
