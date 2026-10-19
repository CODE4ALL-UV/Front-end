import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'accessibility_announcer_widget.dart';
import 'accessibility_text_scale_widget.dart';
import 'learning_preferences.dart';

/// Todos los ajustes de accesibilidad y aprendizaje en una sola pantalla.
///
/// Es la que abre «Configuración» en el menú de ayuda. Antes era una maqueta:
/// los interruptores cambiaban su propio dibujo y nada más —el modo visual no
/// tocaba el tema, la velocidad no llegaba a la voz— y al subir la letra la
/// pantalla se rompía (`late final` reasignado en `didChangeDependencies`).
/// Ahora cada control escribe en el mismo sitio que el menú «?»: el tema en
/// [ThemeManager], la letra en [AccessibilityTextScaleController] y el resto
/// en [LearningPreferences]. Lo que se cambia aquí se ve en el menú y al
/// revés, y se guarda en el dispositivo.
class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

/// Los filtros de color, con un nombre que se entiende sin saber qué es cada
/// daltonismo.
const List<(AppThemeMode, String, String)> _colorFilters = [
  (AppThemeMode.protanopia, 'Protanopía', 'No distingo bien el rojo'),
  (AppThemeMode.protanomalia, 'Protanomalía', 'Veo el rojo apagado'),
  (AppThemeMode.deuteranopia, 'Deuteranopía', 'No distingo bien el verde'),
  (AppThemeMode.deuteranomalia, 'Deuteranomalía', 'Veo el verde apagado'),
  (AppThemeMode.tritanopia, 'Tritanopía', 'No distingo azul y amarillo'),
  (AppThemeMode.tritanomalia, 'Tritanomalía', 'Veo el azul apagado'),
  (AppThemeMode.achromatopsia, 'Escala de grises', 'Sin colores'),
];

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  final LearningPreferences _prefs = LearningPreferences.instance;
  AccessibilityTextScaleController? _textScale;

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onChanged);
    ThemeManager.themeNotifier.addListener(_onChanged);
    _prefs.ensureLoaded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se vuelve a llamar cada vez que cambia la letra o el tema: por eso no
    // puede ser un `late final`, que revienta al asignarse por segunda vez.
    final controller = AccessibilityTextScaleScope.of(context);
    if (controller != _textScale) {
      _textScale?.removeListener(_onChanged);
      _textScale = controller..addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _prefs.removeListener(_onChanged);
    ThemeManager.themeNotifier.removeListener(_onChanged);
    _textScale?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Dice en qué quedó el ajuste, en pantalla y al lector de pantalla.
  void _say(String message) {
    announceForAccessibility(context, message);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: context.colorScheme.onInverseSurface,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  AccessibilityTextScaleController get _scale =>
      _textScale ?? AccessibilityTextScaleController.global;

  void _setTheme(AppThemeMode mode, String message) {
    ThemeManager.changeTheme(mode);
    _say(message);
  }

  Future<void> _resetAll() async {
    _scale.reset();
    ThemeManager.changeTheme(AppThemeMode.light);
    await Future.wait([
      _prefs.setPace(SpeechPace.medium),
      _prefs.setClearSpeech(false),
      _prefs.setSignSupport(SignSupportLevel.off),
      _prefs.setContentPreference(ContentPreference.none),
      _prefs.setLevel(LearningLevel.medium),
      _prefs.setHintsEnabled(false),
      _prefs.setManualEnabled(false),
    ]);
    if (mounted) _say('Ajustes restablecidos a los de fábrica.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Scaffold(
      appBar: const GlobalAppBarWidget(
        title: 'Configuración de Accesibilidad',
        showUserIcon: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Dos columnas a partir de una tablet en horizontal: en una sola,
          // en un portátil las tarjetas quedaban estiradas y había que bajar
          // mucho para llegar a las últimas.
          final twoColumns = constraints.maxWidth >= 860;
          final reading = [_textSizeCard(), _colorsCard()];
          final learning = [
            _voiceCard(),
            _signsCard(),
            _learningCard(),
            _supportCard(),
          ];

          return ListView(
            padding: AppMetrics.pagePadding(constraints.maxWidth),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: twoColumns ? 1080 : AppMetrics.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(colors),
                      const SizedBox(height: AppMetrics.sectionGap),
                      if (twoColumns)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _column(reading)),
                            const SizedBox(width: AppMetrics.sectionGap),
                            Expanded(child: _column(learning)),
                          ],
                        )
                      else
                        _column([...reading, ...learning]),
                      const SizedBox(height: AppMetrics.sectionGap),
                      Align(
                        child: OutlinedButton.icon(
                          onPressed: _resetAll,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, AppMetrics.minTapTarget),
                          ),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Restablecer ajustes'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _column(List<Widget> cards) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(height: AppMetrics.gap + 4),
        cards[i],
      ],
    ],
  );

  Widget _header(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.accessibility_new,
                color: colors.onPrimary,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Personaliza tu experiencia',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajusta las opciones según tus necesidades. Los cambios '
                  'se aplican al instante y se guardan en este dispositivo.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textSizeCard() {
    final scale = _scale.scale;
    final enabled = scale != 1.0;
    final colors = context.colorScheme;

    return _SettingsCard(
      icon: Icons.text_fields,
      title: 'Tamaño de texto',
      subtitle: 'Aumenta el tamaño para leer con más comodidad',
      children: [
        _SwitchRow(
          title: 'Texto grande',
          subtitle: enabled
              ? 'El contenido aparecerá con letra más grande.'
              : 'La lectura seguirá en el tamaño normal.',
          value: enabled,
          onChanged: (value) {
            if (value) {
              _scale.setScale(1.2);
            } else {
              _scale.reset();
            }
            _say(value ? 'Texto grande activado' : 'Texto grande desactivado');
          },
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Reducir el texto',
                onPressed: scale <= 0.9 ? null : _scale.decrease,
                icon: const Icon(Icons.remove_circle_outline),
                color: colors.secondary,
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label:
                      'Tamaño del texto: ${(scale * 100).round()} por ciento',
                  excludeSemantics: true,
                  child: Text(
                    '${(scale * 100).round()} %',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Agrandar el texto',
                onPressed: scale >= 2.0 ? null : _scale.increase,
                icon: const Icon(Icons.add_circle_outline),
                color: colors.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colorsCard() {
    final mode = ThemeManager.themeNotifier.value;
    final isFilter = mode != AppThemeMode.light && mode != AppThemeMode.dark;

    return _SettingsCard(
      icon: Icons.palette_outlined,
      title: 'Modo visual',
      subtitle: 'Cambia el contraste y los colores de la pantalla',
      children: [
        _ChoiceGroup<AppThemeMode?>(
          label: 'Apariencia',
          options: const [
            (AppThemeMode.light, 'Claro', Icons.light_mode_outlined),
            (AppThemeMode.dark, 'Oscuro', Icons.dark_mode_outlined),
            (null, 'Según el sistema', Icons.brightness_auto_outlined),
          ],
          isSelected: (option) => option != null && option == mode,
          onSelected: (option) {
            final next =
                option ??
                (MediaQuery.platformBrightnessOf(context) == Brightness.dark
                    ? AppThemeMode.dark
                    : AppThemeMode.light);
            _setTheme(
              next,
              option == null
                  ? 'Modo según el sistema: '
                        '${next == AppThemeMode.dark ? 'oscuro' : 'claro'}.'
                  : 'Modo ${next == AppThemeMode.dark ? 'oscuro' : 'claro'} '
                        'activado.',
            );
          },
        ),
        const SizedBox(height: 14),
        _ChoiceGroup<AppThemeMode?>(
          label: 'Filtro para daltonismo',
          options: [
            (null, 'Ninguno', Icons.block),
            for (final (filter, name, _) in _colorFilters) (filter, name, null),
          ],
          isSelected: (option) => option == null ? !isFilter : option == mode,
          onSelected: (option) {
            if (option == null) {
              if (isFilter) _setTheme(AppThemeMode.light, 'Filtro quitado.');
              return;
            }
            final name = _colorFilters.firstWhere((f) => f.$1 == option).$2;
            _setTheme(option, 'Filtro $name activado.');
          },
        ),
        if (isFilter) ...[
          const SizedBox(height: 8),
          _Note(
            _colorFilters.firstWhere((f) => f.$1 == mode).$3,
            icon: Icons.visibility_outlined,
          ),
        ],
      ],
    );
  }

  Widget _voiceCard() {
    return _SettingsCard(
      icon: Icons.record_voice_over_outlined,
      title: 'Asistencia auditiva',
      subtitle: 'Ajusta la voz para que sea más clara y comprensible',
      children: [
        _SwitchRow(
          title: 'Voz más clara y pausada',
          subtitle: _prefs.clearSpeech
              ? 'La voz separa más las frases.'
              : 'La voz habla a su ritmo normal.',
          value: _prefs.clearSpeech,
          onChanged: (value) {
            _prefs.setClearSpeech(value);
            _say(
              value
                  ? 'Voz más pausada activada'
                  : 'Voz más pausada desactivada',
            );
          },
        ),
        const SizedBox(height: 8),
        _ChoiceGroup<SpeechPace>(
          label: 'Velocidad de la voz',
          options: [
            for (final pace in SpeechPace.values) (pace, pace.label, null),
          ],
          isSelected: (pace) => _prefs.pace == pace,
          onSelected: (pace) {
            _prefs.setPace(pace);
            _say('Velocidad ${pace.label} seleccionada');
          },
        ),
      ],
    );
  }

  Widget _signsCard() {
    return _SettingsCard(
      icon: Icons.sign_language,
      title: 'Lengua de señas',
      subtitle: 'Activa ayudas visuales para comprender mejor el contenido',
      children: [
        _ChoiceGroup<SignSupportLevel>(
          label: 'Nivel de apoyo',
          options: [
            for (final level in SignSupportLevel.values)
              (level, level.label, null),
          ],
          isSelected: (level) => _prefs.signSupport == level,
          onSelected: (level) {
            _prefs.setSignSupport(level);
            _say(
              level == SignSupportLevel.off
                  ? 'Lengua de señas desactivada'
                  : 'Nivel ${level.label} seleccionado',
            );
          },
        ),
        const SizedBox(height: 8),
        _Note(switch (_prefs.signSupport) {
          SignSupportLevel.off => 'No se muestra ningún apoyo en señas.',
          SignSupportLevel.basic =>
            'En los videos, un panel deletrea con el alfabeto manual lo que '
                'se dice.',
          SignSupportLevel.advanced =>
            'Además del deletreo, la seña de la palabra completa cuando '
                'exista grabada.',
        }),
      ],
    );
  }

  Widget _learningCard() {
    return _SettingsCard(
      icon: Icons.psychology_outlined,
      title: 'Ajustes de aprendizaje',
      subtitle: 'Cómo se ordena y acompaña el contenido del curso',
      children: [
        _ChoiceGroup<ContentPreference>(
          label: 'Prefiero empezar por',
          options: [
            for (final preference in ContentPreference.values)
              (preference, preference.label, null),
          ],
          isSelected: (preference) => _prefs.contentPreference == preference,
          onSelected: (preference) {
            _prefs.setContentPreference(preference);
            _say('Preferencia: ${preference.label.toLowerCase()}.');
          },
        ),
        const SizedBox(height: 14),
        _ChoiceGroup<LearningLevel>(
          label: 'Nivel de aprendizaje',
          options: [
            for (final level in LearningLevel.values)
              (level, level.label, null),
          ],
          isSelected: (level) => _prefs.level == level,
          onSelected: (level) {
            _prefs.setLevel(level);
            _say('Nivel de aprendizaje: ${level.label.toLowerCase()}.');
          },
        ),
      ],
    );
  }

  Widget _supportCard() {
    return _SettingsCard(
      icon: Icons.volunteer_activism_outlined,
      title: 'Apoyo',
      subtitle: 'Ayudas extra mientras estudias',
      children: [
        _SwitchRow(
          title: 'Pistas',
          subtitle: 'Una ayuda antes de responder en los quiz.',
          value: _prefs.hintsEnabled,
          onChanged: (value) {
            _prefs.setHintsEnabled(value);
            _say(value ? 'Pistas activadas' : 'Pistas desactivadas');
          },
        ),
        _SwitchRow(
          title: 'Manual interactivo',
          subtitle: 'Una guía de cada pantalla al abrir una actividad.',
          value: _prefs.manualEnabled,
          onChanged: (value) {
            _prefs.setManualEnabled(value);
            _say(
              value
                  ? 'Manual interactivo activado'
                  : 'Manual interactivo desactivado',
            );
          },
        ),
      ],
    );
  }
}

/// Una tarjeta de ajustes: icono, nombre, para qué sirve y sus controles.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppMetrics.cardRadius + 2),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius + 2),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: colors.secondary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Un interruptor con su nombre y lo que hace; se puede tocar la fila entera.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
      ),
    );
  }
}

/// Un grupo de opciones excluyentes en chips.
///
/// Chips y no botones segmentados: con la letra al 200 % en un celular, cuatro
/// segmentos no caben en una fila y aquí simplemente bajan a la siguiente.
class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.options,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final List<(T, String, IconData?)> options;
  final bool Function(T option) isSelected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, text, icon) in options)
              ChoiceChip(
                avatar: icon == null ? null : Icon(icon),
                label: Text(text),
                selected: isSelected(value),
                showCheckmark: icon == null,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

/// Qué cambia con la opción que está puesta.
class _Note extends StatelessWidget {
  const _Note(this.text, {this.icon = Icons.info_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
