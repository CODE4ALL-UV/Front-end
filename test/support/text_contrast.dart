import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

/// Un texto que no se lee bien sobre lo que tiene detrás.
class ContrastProblem {
  ContrastProblem(
    this.text,
    this.foreground,
    this.background,
    this.ratio,
    this.minimum,
    this.where,
  );

  final String text;
  final String where;
  final Color foreground;
  final Color background;
  final double ratio;
  final double minimum;

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  @override
  String toString() =>
      '«$text» ${_hex(foreground)} sobre ${_hex(background)} = '
      '${ratio.toStringAsFixed(2)}:1 (mínimo ${minimum.toStringAsFixed(1)}) en $where';
}

/// Revisa cada texto e icono de la pantalla contra el fondo que tiene detrás.
///
/// El fondo se busca subiendo por los widgets: el primer `Material`,
/// `ColoredBox`, `DecoratedBox` o `Ink` con color opaco, mezclado con los
/// semitransparentes que haya entre medias. Con degradados se mira cada uno
/// de sus colores y vale el peor.
///
/// Los mínimos son los de la WCAG 2.1: 4,5:1 para texto, 3:1 para texto
/// grande (24 px, o 18,7 px en negrita) y para iconos.
List<ContrastProblem> lowContrastTexts(WidgetTester tester) {
  final problems = <ContrastProblem>[];

  for (final element in find.byType(RichText).evaluate()) {
    final render = element.renderObject;
    if (render is! RenderBox || !render.hasSize || render.size.isEmpty) {
      continue;
    }
    if (_hidden(element)) continue;

    final widget = element.widget as RichText;
    final backgrounds = _backgroundsBehind(element);

    for (final (text, color, style) in _spans(widget.text, null, null)) {
      if (color == null) continue;
      final isIcon = (style?.fontFamily ?? '').contains('Icons');
      final size = style?.fontSize ?? 14;
      final bold =
          (style?.fontWeight ?? FontWeight.normal).value >=
          FontWeight.w700.value;
      final large = size >= 24 || (size >= 18.66 && bold);
      final minimum = (isIcon || large) ? AppContrast.ui : AppContrast.text;

      for (final background in backgrounds) {
        final visible = Color.alphaBlend(color, background);
        final ratio = AppContrast.ratio(visible, background);
        if (ratio < minimum) {
          problems.add(
            ContrastProblem(
              isIcon ? 'icono U+${text.runes.first.toRadixString(16)}' : text,
              visible,
              background,
              ratio,
              minimum,
              _where(element),
            ),
          );
          break;
        }
      }
    }
  }
  return problems;
}

/// Las clases de la app, para decir en cuál está cada texto.
final Set<String> _appClasses = () {
  final names = <String>{};
  final pattern = RegExp(r'^\s*class\s+(\w+)', multiLine: true);
  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      for (final match in pattern.allMatches(file.readAsStringSync())) {
        names.add(match.group(1)!);
      }
    }
  }
  return names;
}();

/// Los dos widgets de la app más cercanos al texto.
String _where(Element element) {
  final found = <String>[];
  element.visitAncestorElements((ancestor) {
    final name = ancestor.widget.runtimeType.toString().split('<').first;
    if (_appClasses.contains(name) && !found.contains(name)) found.add(name);
    return found.length < 2;
  });
  return found.isEmpty ? '?' : found.join(' < ');
}

/// Dentro de algo invisible (opacidad casi cero): no se ve, no se mide.
bool _hidden(Element element) {
  var hidden = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Opacity && widget.opacity < 0.1) hidden = true;
    if (widget is Visibility && !widget.visible) hidden = true;
    return !hidden;
  });
  return hidden;
}

Iterable<(String, Color?, TextStyle?)> _spans(
  InlineSpan span,
  Color? inherited,
  TextStyle? inheritedStyle,
) sync* {
  final style = inheritedStyle?.merge(span.style) ?? span.style;
  final color = span.style?.color ?? inherited;
  if (span is TextSpan) {
    final text = span.text?.trim() ?? '';
    if (text.isNotEmpty) yield (text, color, style);
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* _spans(child, color, style);
    }
  }
}

List<Color> _backgroundsBehind(Element element) {
  final layers = <List<Color>>[];
  Color base = Colors.white;

  element.visitAncestorElements((ancestor) {
    final colors = _paints(ancestor);
    if (colors == null || colors.isEmpty) return true;
    layers.add(colors);
    if (colors.every((c) => c.a >= 0.99)) return false;
    return true;
  });

  if (layers.isEmpty || !layers.last.every((c) => c.a >= 0.99)) {
    base = Theme.of(element).scaffoldBackgroundColor;
  }

  var result = [base];
  for (final layer in layers.reversed) {
    result = [
      for (final under in result)
        for (final color in layer) Color.alphaBlend(color, under),
    ];
  }
  return result;
}

/// Lo que pinta este widget debajo de sus hijos, si pinta algo.
List<Color>? _paints(Element element) {
  final widget = element.widget;
  if (widget is Material) {
    if (widget.type == MaterialType.transparency) return null;
    final theme = Theme.of(element);
    final color =
        widget.color ??
        (widget.type == MaterialType.card
            ? theme.cardColor
            : theme.canvasColor);
    return [color];
  }
  if (widget is ColoredBox) return [widget.color];
  if (widget is DecoratedBox &&
      widget.position == DecorationPosition.background) {
    return _decorationColors(widget.decoration);
  }
  if (widget is Ink) {
    final decoration = widget.decoration;
    if (decoration != null) return _decorationColors(decoration);
  }
  return null;
}

List<Color>? _decorationColors(Decoration decoration) {
  if (decoration is BoxDecoration) {
    if (decoration.gradient != null) return decoration.gradient!.colors;
    if (decoration.color != null) return [decoration.color!];
  }
  if (decoration is ShapeDecoration) {
    if (decoration.gradient != null) return decoration.gradient!.colors;
    if (decoration.color != null) return [decoration.color!];
  }
  return null;
}
