import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/activity_theme.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/themes/ide_theme.dart';
import 'package:flutter_code4all/ui/core/themes/message_theme.dart';
import 'package:flutter_code4all/ui/core/themes/module_theme.dart';

/// Las extensiones de tema llevan los colores propios de la aplicación: los
/// de cada módulo, cada tipo de actividad, los avisos y la consola de Python.
///
/// Se comprueban dos cosas. Primero, que `copyWith` y `lerp` hacen lo que
/// Flutter espera de ellas —cambiar solo lo pedido y fundir de un tema a otro
/// sin saltos—, porque al cambiar de tema la app anima entre ambos con
/// `lerp`. Segundo, que los nueve modos visuales, incluidos los tres de
/// anomalía (protanomalía, deuteranomalía y tritanomalía), dan a cada módulo
/// los colores que su tipo de daltonismo sí distingue y que el texto de la
/// cabecera se sigue leyendo.
void main() {
  const a = Color(0xFF000000);
  const b = Color(0xFFFFFFFF);
  final mid = Color.lerp(a, b, 0.5)!;

  group('consola de código', () {
    const console = CodeConsoleTheme(
      background: a,
      border: a,
      text: a,
      prompt: a,
      keyword: a,
      string: a,
      comment: a,
      error: a,
    );
    const other = CodeConsoleTheme(
      background: b,
      border: b,
      text: b,
      prompt: b,
      keyword: b,
      string: b,
      comment: b,
      error: b,
    );

    test('copyWith cambia el fondo y deja todo lo demás', () {
      final copy = console.copyWith(background: b);
      expect(copy.background, b);
      for (final color in [
        copy.border,
        copy.text,
        copy.prompt,
        copy.keyword,
        copy.string,
        copy.comment,
        copy.error,
      ]) {
        expect(color, a);
      }
      // Sin nada que cambiar, queda igual.
      expect(console.copyWith().background, a);
    });

    test('lerp funde todos los colores y sin destino se queda como está', () {
      final half = console.lerp(other, 0.5);
      for (final color in [
        half.background,
        half.border,
        half.text,
        half.prompt,
        half.keyword,
        half.string,
        half.comment,
        half.error,
      ]) {
        expect(color, mid);
      }
      expect(console.lerp(null, 0.5), same(console));
    });
  });

  group('avisos', () {
    const message = MessageTheme(
      infoBackground: Color(0xFF000001),
      infoForeground: Color(0xFF000002),
      successBackground: Color(0xFF000003),
      successForeground: Color(0xFF000004),
      warningBackground: Color(0xFF000005),
      warningForeground: Color(0xFF000006),
      dangerBackground: Color(0xFF000007),
      dangerForeground: Color(0xFF000008),
    );

    test('cada tono devuelve su pareja de fondo y texto', () {
      expect(message.tone(MessageThemeTone.info), (
        background: const Color(0xFF000001),
        foreground: const Color(0xFF000002),
      ));
      expect(
        message.tone(MessageThemeTone.success).background,
        const Color(0xFF000003),
      );
      expect(
        message.tone(MessageThemeTone.warning).foreground,
        const Color(0xFF000006),
      );
      expect(message.tone(MessageThemeTone.danger), (
        background: const Color(0xFF000007),
        foreground: const Color(0xFF000008),
      ));
    });

    test('copyWith cambia solo los colores pedidos', () {
      final copy = message.copyWith(warningBackground: b, dangerForeground: a);
      expect(copy.warningBackground, b);
      expect(copy.dangerForeground, a);
      // Lo demás no se toca.
      expect(copy.infoBackground, message.infoBackground);
      expect(copy.infoForeground, message.infoForeground);
      expect(copy.successBackground, message.successBackground);
      expect(copy.successForeground, message.successForeground);
      expect(copy.warningForeground, message.warningForeground);
      expect(copy.dangerBackground, message.dangerBackground);

      final same = message.copyWith();
      for (final tone in MessageThemeTone.values) {
        expect(same.tone(tone), message.tone(tone));
      }
    });

    test('lerp hasta el final llega al otro tema', () {
      final other = message.copyWith(infoBackground: b, dangerForeground: b);
      final end = message.lerp(other, 1.0);
      for (final tone in MessageThemeTone.values) {
        expect(end.tone(tone), other.tone(tone));
      }
      expect(message.lerp(null, 0.3), same(message));
    });
  });

  group('actividades', () {
    final activities = AppTheme.getTheme(
      mode: AppThemeMode.light,
    ).extension<ActivityTheme>()!;

    test('copyWith cambia solo los colores pedidos', () {
      final copy = activities.copyWith(quizBackground: a, labForeground: b);
      expect(copy.quizBackground, a);
      expect(copy.labForeground, b);
      for (final tone in ActivityThemeTone.values) {
        if (tone == ActivityThemeTone.quiz || tone == ActivityThemeTone.lab) {
          continue;
        }
        expect(copy.tone(tone), activities.tone(tone), reason: '$tone');
      }

      final untouched = activities.copyWith();
      for (final tone in ActivityThemeTone.values) {
        expect(untouched.tone(tone), activities.tone(tone));
      }
    });

    test('lerp hasta el final llega al otro tema en los ocho tipos', () {
      final dark = AppTheme.getTheme(
        mode: AppThemeMode.dark,
      ).extension<ActivityTheme>()!;
      final end = activities.lerp(dark, 1.0);
      for (final tone in ActivityThemeTone.values) {
        expect(end.tone(tone), dark.tone(tone), reason: '$tone');
      }
      expect(activities.lerp(null, 0.5), same(activities));
    });
  });

  group('módulos', () {
    test('copyWith cambia solo los colores pedidos', () {
      final theme = ModuleTheme.fromModule(1, AppThemeMode.light);
      final copy = theme.copyWith(headerBackground: a, progressTrackFilled: b);

      expect(copy.headerBackground, a);
      expect(copy.progressTrackFilled, b);
      expect(copy.headerIconBackground, theme.headerIconBackground);
      expect(copy.headerForeground, theme.headerForeground);
      expect(copy.chapterIconColor1, theme.chapterIconColor1);
      expect(
        copy.chapterIconBackgroundColor1,
        theme.chapterIconBackgroundColor1,
      );
      expect(copy.chapterIconColor2, theme.chapterIconColor2);
      expect(
        copy.chapterIconBackgroundColor2,
        theme.chapterIconBackgroundColor2,
      );
      expect(copy.chapterIconColor3, theme.chapterIconColor3);
      expect(
        copy.chapterIconBackgroundColor3,
        theme.chapterIconBackgroundColor3,
      );
      expect(copy.lessonCardBackground, theme.lessonCardBackground);
      expect(copy.lessonCardBorder, theme.lessonCardBorder);
      expect(copy.lessonCardText, theme.lessonCardText);
      expect(copy.lessonCardNumber, theme.lessonCardNumber);
      expect(copy.lessonCardNumberBackground, theme.lessonCardNumberBackground);
      expect(copy.progressTrackRemaining, theme.progressTrackRemaining);

      expect(theme.copyWith().headerBackground, theme.headerBackground);
    });

    test('lerp entre dos módulos pasa por colores intermedios', () {
      final blue = ModuleTheme.fromModule(1, AppThemeMode.light);
      final red = ModuleTheme.fromModule(6, AppThemeMode.light);

      expect(blue.lerp(red, 0).headerBackground, blue.headerBackground);
      expect(blue.lerp(red, 1).headerBackground, red.headerBackground);
      expect(
        blue.lerp(red, 0.5).headerBackground,
        Color.lerp(blue.headerBackground, red.headerBackground, 0.5),
      );
      expect(blue.lerp(null, 0.5), same(blue));
    });

    test('cada daltonismo cambia el módulo que no distingue', () {
      Color header(int module, AppThemeMode mode) =>
          ModuleTheme.fromModule(module, mode).headerBackground;

      // Rojo-verde por falta de verde: el módulo verde pasa a ámbar.
      for (final mode in [
        AppThemeMode.deuteranopia,
        AppThemeMode.deuteranomalia,
      ]) {
        expect(header(3, mode), const Color(0xFFFF8F00), reason: '$mode');
        expect(header(4, mode), const Color(0xFFFF8F00), reason: '$mode');
        expect(header(1, mode), header(1, AppThemeMode.light));
      }

      // Por falta de rojo: el módulo rojo pasa a azul.
      for (final mode in [AppThemeMode.protanopia, AppThemeMode.protanomalia]) {
        expect(header(6, mode), const Color(0xFF0D47A1), reason: '$mode');
        expect(header(3, mode), header(3, AppThemeMode.light));
      }

      // Azul-amarillo: el azul pasa a rosa y el amarillo a verde.
      for (final mode in [AppThemeMode.tritanopia, AppThemeMode.tritanomalia]) {
        expect(header(1, mode), const Color(0xFFC2185B), reason: '$mode');
        expect(header(2, mode), const Color(0xFFC2185B), reason: '$mode');
        expect(header(5, mode), const Color(0xFF2E7D32), reason: '$mode');
      }

      // Sin color: todos los módulos en el mismo gris.
      for (var module = 1; module <= 6; module++) {
        expect(
          header(module, AppThemeMode.achromatopsia),
          const Color(0xFF424242),
        );
      }

      // Un módulo desconocido usa el color del módulo 6.
      expect(header(99, AppThemeMode.light), header(6, AppThemeMode.light));
    });

    test('las anomalías usan los mismos iconos que su ceguera completa', () {
      const pairs = {
        AppThemeMode.protanomalia: AppThemeMode.protanopia,
        AppThemeMode.deuteranomalia: AppThemeMode.deuteranopia,
        AppThemeMode.tritanomalia: AppThemeMode.tritanopia,
      };
      for (final MapEntry(key: anomaly, value: full) in pairs.entries) {
        final x = ModuleTheme.fromModule(2, anomaly);
        final y = ModuleTheme.fromModule(2, full);
        expect(x.chapterIconColor1, y.chapterIconColor1, reason: '$anomaly');
        expect(x.chapterIconColor2, y.chapterIconColor2, reason: '$anomaly');
        expect(x.chapterIconColor3, y.chapterIconColor3, reason: '$anomaly');
      }
    });

    test('en oscuro el color del módulo se apaga para no deslumbrar', () {
      for (var module = 1; module <= 6; module++) {
        final dark = ModuleTheme.fromModule(module, AppThemeMode.dark);
        final hsl = HSLColor.fromColor(dark.headerBackground);
        expect(
          hsl.saturation,
          lessThanOrEqualTo(0.551),
          reason: 'módulo $module',
        );
        expect(
          hsl.lightness,
          lessThanOrEqualTo(0.321),
          reason: 'módulo $module',
        );
        expect(dark.lessonCardBackground, const Color(0xFF1E1E1E));
        expect(dark.lessonCardText, Colors.white);
      }
    });

    test('en los nueve modos el título del módulo se lee sobre su color', () {
      for (final mode in AppThemeMode.values) {
        for (var module = 1; module <= 6; module++) {
          final theme = ModuleTheme.fromModule(module, mode);
          expect(
            AppContrast.ratio(theme.headerForeground, theme.headerBackground),
            greaterThanOrEqualTo(AppContrast.text),
            reason: 'módulo $module en $mode',
          );
          // La barra de progreso también se distingue de la tarjeta.
          expect(
            AppContrast.ratio(
              theme.progressTrackFilled,
              theme.lessonCardBackground,
            ),
            greaterThanOrEqualTo(AppContrast.ui - 0.01),
            reason: 'progreso del módulo $module en $mode',
          );
        }
      }
    });
  });

  group('tema completo', () {
    test('los nueve modos traen las cuatro extensiones y se reutilizan', () {
      for (final mode in AppThemeMode.values) {
        final theme = AppTheme.getTheme(mode: mode, moduleId: 3);
        expect(theme.extension<ModuleTheme>(), isNotNull, reason: '$mode');
        expect(theme.extension<CodeConsoleTheme>(), isNotNull, reason: '$mode');
        expect(theme.extension<ActivityTheme>(), isNotNull, reason: '$mode');
        expect(theme.extension<MessageTheme>(), isNotNull, reason: '$mode');
        expect(
          theme.brightness,
          mode == AppThemeMode.dark ? Brightness.dark : Brightness.light,
          reason: '$mode',
        );
        // Pedirlo otra vez no arma un tema nuevo.
        expect(AppTheme.getTheme(mode: mode, moduleId: 3), same(theme));
      }
    });

    testWidgets('sin extensiones en el tema se usan las del tema claro', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final light = AppTheme.getTheme(mode: AppThemeMode.light);
      expect(
        context.codeConsoleTheme.background,
        light.extension<CodeConsoleTheme>()!.background,
      );
      expect(
        context.messageColors.tone(MessageThemeTone.info),
        light.extension<MessageTheme>()!.tone(MessageThemeTone.info),
      );
    });

    test('el resaltado de Python en grises distingue sin usar color', () {
      final light = AppTheme.pythonLightSyntax;
      final gray = AppTheme.pythonAchromatopsiaSyntax;

      for (final key in ['keyword', 'string', 'comment', 'number', 'title']) {
        expect(light, contains(key));
        expect(gray, contains(key));
      }
      expect(light['comment']!.fontStyle, FontStyle.italic);
      expect(light['keyword']!.fontWeight, FontWeight.bold);
      // Sin color, las palabras clave se marcan con subrayado y las cadenas
      // con cursiva: la diferencia no depende de ver el color.
      expect(gray['keyword']!.decoration, TextDecoration.underline);
      expect(gray['string']!.fontStyle, FontStyle.italic);
      expect(gray['number']!.fontWeight, FontWeight.w900);
    });
  });
}
