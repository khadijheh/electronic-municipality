import 'package:flutter/material.dart' as material;

import 'app_localizations.dart';

/// Drop-in localized counterpart for Flutter's [material.Text].
///
/// Existing Arabic UI copy remains the canonical lookup value. When English
/// is selected it is resolved through [AppLocalizations], including nested
/// [material.TextSpan] values used by rich text.
class Text extends material.StatelessWidget {
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.translate = true,
  }) : textSpan = null;

  const Text.rich(
    material.InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.translate = true,
  }) : data = null;

  final String? data;
  final material.InlineSpan? textSpan;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;
  final bool translate;

  @override
  material.Widget build(material.BuildContext context) {
    // Keep isolated widget tests and reusable widgets safe when they are
    // mounted without the application's localization delegates.
    final localizations =
        AppLocalizations.maybeOf(context) ?? const AppLocalizations(material.Locale('ar'));
    final value = data;
    if (value != null) {
      return material.Text(
        translate ? localizations.translate(value) : value,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel == null
            ? null
            : localizations.translate(semanticsLabel!),
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }

    return material.Text.rich(
      translate ? _translateSpan(localizations, textSpan!) : textSpan!,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel == null
          ? null
          : localizations.translate(semanticsLabel!),
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  static material.InlineSpan _translateSpan(
    AppLocalizations localizations,
    material.InlineSpan span,
  ) {
    if (span is! material.TextSpan) return span;
    return material.TextSpan(
      text: span.text == null ? null : localizations.translate(span.text!),
      children: span.children
          ?.map((child) => _translateSpan(localizations, child))
          .toList(growable: false),
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      locale: span.locale,
    );
  }
}
