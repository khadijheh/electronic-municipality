import 'package:flutter/material.dart';

/// Centralized design tokens for spacing, sizing, and visual properties
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 48.0;
}

class AppRadius {
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const full = 9999.0;
}

class AppElevation {
  static const none = 0.0;
  static const sm = 2.0;
  static const md = 4.0;
  static const lg = 8.0;
  static const xl = 12.0;
}

class AppTypography {
  // Headlines
  static const headlineXl = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const headlineLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const headlineMd = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const headlineSm = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  // Body text
  static const bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const bodySm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Labels
  static const labelLg = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
  );

  static const labelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.4,
  );
}

/// Shadow styles
class AppShadows {
  static const sm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    )
  ];

  static const md = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    )
  ];

  static const lg = [
    BoxShadow(
      color: Color(0x15000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    )
  ];

  static const xl = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    )
  ];

  // Special gold gradient shadow (from Figma)
  static const goldGradient = [
    BoxShadow(
      color: Color(0x0DE9C176),
      blurRadius: 30,
      offset: Offset(0, 8),
    )
  ];
}

/// Interactive states for buttons and inputs
class AppStates {
  static const buttonHeight = 56.0;
  static const buttonHeightDense = 44.0;
  static const textFieldHeight = 56.0;
  static const textFieldMinHeight = 44.0;
}
