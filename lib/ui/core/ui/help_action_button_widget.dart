import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'accessibility_settings_screen.dart';
import 'accessibility_announcer_widget.dart';
import 'accessibility_text_scale_widget.dart';
import 'centered_toast.dart';
import 'learning_preferences.dart';

class HelpActionButton extends StatefulWidget {
  //AccessibilityMenu == HelpActionButton
  const HelpActionButton({super.key});

  @override
  State<HelpActionButton> createState() => _HelpActionButtonState();
}

// IMPORTANT: MAIN CODE
class _HelpActionButtonState extends State<HelpActionButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  String? _selectedOption;
  OverlayEntry? _overlayEntry;
  late AnimationController _controller;
  late Animation<double> _animation;
  late AccessibilityTextScaleController _textScaleController;

  // Add this near your other variables (like _activeCategory, etc.)
  final GlobalKey _buttonKey = GlobalKey();

  // NEW: Track which category is currently open
  String? _activeCategory;

  // NEW: Maintain the order of horizontal categories
  List<String> horizontalCategories = [
    'Ayuda',
    'Ajustes de aprendizaje',
    'Apoyo',
  ];

  // NEW: Map each category to its specific vertical options
  // Labels need to match exactly with the ones used in _selectOption and _buildOptionContent
  final Map<String, List<Map<String, dynamic>>> categoryOptions = {
    'Ayuda': [
      {'icon': Icons.settings, 'label': 'Configuración'},
      {'icon': Icons.text_fields, 'label': 'Tamaño de texto'},
      {'icon': Icons.brightness_4, 'label': 'Modo visual'},
      {'icon': Icons.hearing, 'label': 'Asistencia auditiva'},
      {'icon': Icons.language, 'label': 'Lengua de señas'},
    ], // Add Help's vertical buttons here
    'Ajustes de aprendizaje': [
      {'icon': Icons.settings, 'label': 'Configuración'},
      {'icon': Icons.build_circle, 'label': 'Preferencias de aprendizaje'},
      {'icon': Icons.stars, 'label': 'Nivel de aprendizaje'},
    ],
    'Apoyo': [
      {'icon': Icons.settings, 'label': 'Configuración'},
      {'icon': Icons.saved_search, 'label': 'Pistas'},
      {'icon': Icons.menu_book, 'label': 'Manual interactivo'},
    ],
  };

  // Logic to reorder the horizontal buttons
  void _onHorizontalButtonTapped(String category) {
    setState(() {
      // THIS CLOSES THE DIALOG WHENEVER A HORIZONTAL TABS IS CLICKED
      _selectedOption = null;

      if (_activeCategory == category) {
        _activeCategory = null; // Close the vertical menu if clicked again
      } else {
        _activeCategory = category; // Open the respective vertical menu

        // Reordering logic: if it's not already the first item
        if (horizontalCategories.first != category) {
          String oldFirst = horizontalCategories.first;
          horizontalCategories.remove(category); // Remove the clicked item
          horizontalCategories.remove(
            oldFirst,
          ); // Remove the previous first item
          horizontalCategories.insert(
            0,
            category,
          ); // Place clicked item at the start
          horizontalCategories.add(
            oldFirst,
          ); // Move previous first item to the end
        }
      }
    });
    _refreshOverlay();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _textScaleController = AccessibilityTextScaleController.global;
    _textScaleController.addListener(_handleTextScaleChanged);
    LearningPreferences.instance.ensureLoaded();
  }

  @override
  void dispose() {
    // El menú vive en el Overlay, no debajo de este botón: si la página se
    // cierra con el menú abierto, hay que quitarlo a mano o se queda flotando.
    _overlayEntry
      ?..remove()
      ..dispose();
    _overlayEntry = null;
    _textScaleController.removeListener(_handleTextScaleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTextScaleChanged() {
    if (!mounted) return;
    _refreshOverlay();
  }

  void _refreshOverlay() {
    if (!mounted) return;
    _overlayEntry?.markNeedsBuild();
  }

  /* Toggles the visibility of the help menu. */
  void _toggleMenu() {
    if (_overlayEntry != null) {
      _hideOverlay();
      return;
    }

    // --- NEW: Find the exact position of the closed button ---
    final RenderBox? renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    Offset buttonPosition = Offset.zero;

    if (renderBox != null) {
      buttonPosition = renderBox.localToGlobal(Offset.zero);
    }

    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    // La distancia del borde de abajo del botón al de la pantalla. Se usa su
    // alto real: con la letra agrandada el botón mide 44 × escala, y restando
    // 44 fijos la fila del menú abierto quedaba más abajo que el botón.
    final double buttonHeight = renderBox?.size.height ?? 44;
    final double exactBottom = screenHeight - buttonPosition.dy - buttonHeight;
    final double exactLeft = buttonPosition.dx;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final double scale = AccessibilityTextScaleScope.of(
          overlayContext,
        ).scale;
        final overlayMediaQuery = MediaQuery.of(overlayContext);
        final overlayHeight = overlayMediaQuery.size.height;
        final overlayWidth = overlayMediaQuery.size.width;
        // Lo que hay a la derecha del botón «?» hasta el borde de la pantalla.
        final available = overlayWidth - exactLeft - 12;

        // Los botones crecen con la letra, pero solo hasta donde cabe la fila
        // de cuatro (tres categorías y cerrar). Con la letra al 200 % en un
        // celular la fila medía unos 400 px y el botón de cerrar se salía.
        final rowFits = (available - 4 * 12) / (4 * 44);
        final buttonScale = scale.clamp(1.0, rowFits < 1.0 ? 1.0 : rowFits);
        final buttonWidth = 44.0 * buttonScale;
        final overlaySafeWidth = (4 * (buttonWidth + 12)).clamp(
          220.0,
          available < 220.0 ? 220.0 : available,
        );

        // El panel de cada opción va a la derecha de los botones y crece con
        // la letra. Si ahí no cabe con un ancho decente, ocupa el ancho de la
        // pantalla por encima de los botones: mejor tapar los botones un
        // momento que leer el texto partido a mitad de palabra.
        var overlayPanelLeft = buttonWidth + (overlayWidth > 360 ? 28.0 : 12.0);
        var overlayPanelWidth = (available - overlayPanelLeft).clamp(
          0.0,
          340.0 * scale,
        );
        final fullWidthPanel = overlayPanelWidth < 260.0;
        if (fullWidthPanel) {
          overlayPanelLeft = 12.0 - exactLeft;
          overlayPanelWidth = overlayWidth - 24.0;
        }
        final panelHeight = (overlayHeight - 24.0).clamp(280.0, 520.0);

        // El panel mide lo que mida su contenido. Antes tenía un alto fijo
        // (hasta 520 px): «Pistas», con un solo botón, salía igual de alto
        // que «Modo visual» y le sobraba media tarjeta en blanco. Solo se
        // limita a lo que cabe en pantalla; si no cabe, se desplaza dentro.
        final safe = overlayMediaQuery.padding;
        final minTop = safe.top + 12.0;
        // El panel vive por encima de la fila de categorías: si la tapara, no
        // se podría cambiar de categoría ni cerrar el menú sin cerrarlo antes.
        // Solo si encima no queda sitio razonable (el botón muy arriba en la
        // pantalla) se le deja bajar hasta el borde.
        final rowTop = overlayHeight - exactBottom - buttonWidth;
        final aboveRow = rowTop - 12.0;
        final maxBottom = aboveRow - minTop >= 220.0
            ? aboveRow
            : overlayHeight - safe.bottom - 12.0;
        final panelMaxHeight = (maxBottom - minTop).clamp(0.0, 560.0);

        // A la derecha de los botones, el panel arranca a la altura de la
        // opción tocada, para que se vea de qué botón sale. A todo lo ancho,
        // queda justo encima de la fila de categorías.
        double? panelTop;
        if (!fullWidthPanel) {
          final options = categoryOptions[_activeCategory] ?? const [];
          final index = options.indexWhere(
            (opt) => opt['label'] == _selectedOption,
          );
          if (index != -1) {
            // Las opciones se apilan sobre la fila: cada una mide el botón
            // más 10 px de separación, y entre la última y la fila hay 12.
            final fromBelow = options.length - 1 - index;
            panelTop = rowTop - 12.0 - (fromBelow + 1) * (buttonWidth + 10.0);
          }
        }
        final double absoluteLeft = exactLeft + overlayPanelLeft;

        return _HelpButtonScale(
          scale: buttonScale,
          child: Stack(
            children: [
              // Fondo atenuado mientras el menú está abierto.
              //
              // Antes era transparente del todo, así que los botones parecían
              // sueltos encima de la pantalla en lugar de una capa, y se
              // confundían con el contenido que tenían detrás. Atenuar separa
              // una cosa de la otra y, de paso, sube el contraste de los
              // botones sobre lo que haya debajo.
              //
              // Se anuncia como botón de cerrar: tocar fuera ya cerraba el
              // menú, pero quien usa lector de pantalla no tenía forma de
              // saberlo porque no había nada que anunciar.
              Semantics(
                button: true,
                label: 'Cerrar el menú de accesibilidad',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _hideOverlay,
                  child: Container(
                    width: overlayWidth,
                    height: overlayHeight,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
              Positioned(
                left: exactLeft,
                bottom: exactBottom,
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: overlaySafeWidth,
                    height: panelHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          bottom: 0,
                          // ROW OF COLUMNS: This keeps everything horizontally aligned
                          // while allowing vertical buttons to shoot up from their specific parent.
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 2. The 3 Dynamic Category Buttons
                              if (_isExpanded)
                                ...horizontalCategories.map((category) {
                                  bool isActive = _activeCategory == category;

                                  IconData displayIcon;
                                  if (category == 'Ajustes de aprendizaje') {
                                    displayIcon = Icons.psychology;
                                  } else if (category == 'Apoyo') {
                                    displayIcon = Icons.volunteer_activism;
                                  } else {
                                    displayIcon = Icons.help;
                                  }

                                  /* Horizontal Buttons */
                                  return Padding(
                                    // This ensures an equal gap between all buttons AND the main closed button.
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isActive) ...[
                                          ...categoryOptions[category]!.map((
                                            optionData,
                                          ) {
                                            return _buildAnimatedOption(
                                              icon:
                                                  optionData['icon']
                                                      as IconData,
                                              label:
                                                  optionData['label'] as String,
                                              color: const Color(0xFF7E57C2),
                                              onTap: () => _selectOption(
                                                optionData['label'] as String,
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 12),
                                        ],

                                        // Vertical Buttons
                                        // (44 - 44) = 12 / 2 = 0. No adding 0px of bottom padding perfectly centers it!
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 0.0,
                                          ),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () =>
                                                _onHorizontalButtonTapped(
                                                  category,
                                                ),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              width:
                                                  44 *
                                                  buttonScale, // Same as Vertical Buttons
                                              height:
                                                  44 *
                                                  buttonScale, // Same as Vertical Buttons
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isActive
                                                      ? const [
                                                          Color(0xFFAB47BC),
                                                          Color(0xFF8E24AA),
                                                        ]
                                                      : const [
                                                          Color(0xFFD8C8F5),
                                                          Color(0xFFC0A8F0),
                                                        ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.18,
                                                        ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                displayIcon,
                                                color: isActive
                                                    ? Colors.white
                                                    // 7E57C2 sobre el lila se
                                                    // quedaba en 2,5:1.
                                                    : const Color(0xFF4527A0),
                                                size:
                                                    33 *
                                                    buttonScale, //Same as Vertical Buttons
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                              // Main and Close Button, Same circle and icons Sizes as Horizontal Buttons
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _toggleMenu,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width:
                                          44 *
                                          buttonScale, // Same as Vertical and Horizontal Buttons
                                      height:
                                          44 *
                                          buttonScale, // Same as Vertical and Horizontal Buttons
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _isExpanded
                                              ? const [
                                                  Color(0xFFAB47BC),
                                                  Color(0xFF8E24AA),
                                                ]
                                              : const [
                                                  Color(0xFFCD00D3),
                                                  Color(0xFFB000D1),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.18,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size:
                                            33.0 *
                                            buttonScale, // Same as Vertical and Horizontal Buttons
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedOption != null)
                // Ocupa toda la capa solo para poder colocar el panel una vez
                // medido; fuera del panel los toques siguen pasando a los
                // botones y al fondo de debajo.
                Positioned.fill(
                  child: CustomSingleChildLayout(
                    delegate: _PanelLayout(
                      left: absoluteLeft,
                      width: overlayPanelWidth,
                      maxHeight: panelMaxHeight,
                      minTop: minTop,
                      maxBottom: maxBottom,
                      top: panelTop,
                      bottom: aboveRow,
                    ),
                    child: TweenAnimationBuilder<double>(
                      // Una animación por opción: al cambiar de una a otra el
                      // panel nuevo entra en lugar de aparecer de golpe.
                      key: ValueKey(_selectedOption),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - t)),
                          child: child,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: _OptionPanel(
                          option: _selectedOption!,
                          onClose: _closePanel,
                          onRefresh: _refreshOverlay,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    overlay.insert(_overlayEntry!);
    if (!mounted) return;
    setState(() {
      _isExpanded = true;
      _selectedOption = null;
      _activeCategory = null;
    });
    _refreshOverlay();
    _runAnimation(forward: true);
  }

  void _hideOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry != null) {
      // Cada apertura crea una entrada nueva: sin dispose, todas las que se
      // cerraban seguían ocupando memoria.
      entry
        ..remove()
        ..dispose();
    }
    _runAnimation(forward: false);
    if (mounted) {
      setState(() {
        _isExpanded = false;
        _selectedOption = null;
      });
    }
  }

  void _runAnimation({required bool forward}) {
    if (!mounted) return;
    if (_controller.isAnimating) {
      _controller.stop();
    }
    if (forward) {
      _controller.forward(from: _controller.value);
    } else {
      _controller.reverse(from: _controller.value);
    }
  }

  void _selectOption(String option) {
    if (!mounted) return;
    if (option == 'Configuración') {
      _navigateToSettings();
      return;
    }
    setState(() {
      _selectedOption = option;
    });
    _refreshOverlay();
  }

  void _navigateToSettings() {
    _hideOverlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => const AccessibilitySettingsScreen(),
        ),
      );
    });
  }

  void _closePanel() {
    if (!mounted) return;
    setState(() {
      _selectedOption = null;
    });
    _refreshOverlay();
  }

  /*Closed button displayed*/
  @override
  Widget build(BuildContext context) {
    final double scale = AccessibilityTextScaleScope.of(context).scale;
    // Return a plain, non-positioned button so callers can place it
    // consistently across screens. No SafeArea to avoid the white row.
    return Offstage(
      offstage: _overlayEntry != null,
      // Sin etiqueta, el lector de pantalla anunciaba un botón sin nombre:
      // justo quien más necesita este menú no sabía qué era.
      child: Semantics(
        button: true,
        label: 'Ayuda y accesibilidad',
        hint: 'Abre el menú de ayuda, ajustes de aprendizaje y apoyo',
        excludeSemantics: true,
        child: GestureDetector(
          key: _buttonKey, // <-- Attach the key here
          behavior: HitTestBehavior.opaque,
          onTap: _toggleMenu,
          child: Container(
            width: 44 * scale, // Same as Vertical and Horizontal Buttons
            height: 44 * scale, // Same as Vertical and Horizontal Buttons
            decoration: BoxDecoration(
              color: const Color(0xFF7E57C2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7E57C2).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.question_mark,
              color: Colors.white,
              size: 33 * scale, // Same as Vertical and Horizontal Buttons
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(_animation),
          child: Tooltip(
            message: label,
            child: _AccessibilityIconButton(
              icon: icon,
              label: label,
              color: color,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}

/// Coloca el panel de una opción una vez medido.
///
/// Con [top] el panel arranca a esa altura y crece hacia abajo; sin él, su
/// borde de abajo queda en [bottom] y crece hacia arriba. En los dos casos se
/// empuja lo justo para que no se salga entre [minTop] y [maxBottom].
class _PanelLayout extends SingleChildLayoutDelegate {
  const _PanelLayout({
    required this.left,
    required this.width,
    required this.maxHeight,
    required this.minTop,
    required this.maxBottom,
    required this.bottom,
    this.top,
  });

  final double left;
  final double width;
  final double maxHeight;
  final double minTop;
  final double maxBottom;
  final double bottom;
  final double? top;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(minWidth: width, maxWidth: width, maxHeight: maxHeight);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final wanted = top ?? bottom - childSize.height;
    final lowest = maxBottom - childSize.height;
    final y = lowest < minTop ? minTop : wanted.clamp(minTop, lowest);
    return Offset(left, y);
  }

  @override
  bool shouldRelayout(_PanelLayout old) =>
      old.left != left ||
      old.width != width ||
      old.maxHeight != maxHeight ||
      old.minTop != minTop ||
      old.maxBottom != maxBottom ||
      old.bottom != bottom ||
      old.top != top;
}

/// Icono y para qué sirve cada panel, en la cabecera.
///
/// El icono es el mismo del botón que lo abre: así se ve de dónde salió. Antes
/// cinco paneles llevaban el de lengua de señas aunque no tuvieran nada que
/// ver con ella.
const Map<String, (IconData, String)> _panelInfo = {
  'Tamaño de texto': (
    Icons.text_fields,
    'Ajusta la lectura sin perder la vista del contenido.',
  ),
  'Modo visual': (
    Icons.brightness_4,
    'Elige el contraste y los colores que mejor veas.',
  ),
  'Asistencia auditiva': (
    Icons.hearing,
    'Ajusta la voz para que sea más clara y comprensible.',
  ),
  'Lengua de señas': (
    Icons.language,
    'Ayudas visuales en señas para comprender mejor el contenido.',
  ),
  'Preferencias de aprendizaje': (
    Icons.build_circle,
    'Qué tipo de actividad aparece primero en cada capítulo.',
  ),
  'Nivel de aprendizaje': (
    Icons.stars,
    'Cuánto acompañamiento ves alrededor del contenido.',
  ),
  'Pistas': (
    Icons.saved_search,
    'Una ayuda para guiarte antes de responder en los quiz.',
  ),
  'Manual interactivo': (
    Icons.menu_book,
    'Una guía de cada pantalla y sus controles.',
  ),
};

/// El tamaño de los botones del menú abierto, ya ajustado a lo que cabe.
class _HelpButtonScale extends InheritedWidget {
  const _HelpButtonScale({required this.scale, required super.child});

  final double scale;

  static double? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HelpButtonScale>()?.scale;

  @override
  bool updateShouldNotify(_HelpButtonScale oldWidget) =>
      oldWidget.scale != scale;
}

class _AccessibilityIconButton extends StatelessWidget {
  /*
  Vertical Buttons, Figma aesthetic perfectly.
  */
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AccessibilityIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double scale =
        _HelpButtonScale.maybeOf(context) ??
        AccessibilityTextScaleScope.of(context).scale;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44 * scale, // Same as Horizontal Buttons
        height: 44 * scale, // Same as Horizontal Buttons
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 33 * scale,
        ), // Same as Horizontal Buttons
      ),
    );
  }
}

class _OptionPanel extends StatefulWidget {
  /*
  This is the skeleton for the rounded white modal card that appears
  on the right (the one holding the toggles and sliders).
  */
  final String option;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  const _OptionPanel({
    required this.option,
    required this.onClose,
    required this.onRefresh,
  });

  @override
  State<_OptionPanel> createState() => _OptionPanelState();
}

class _OptionPanelState extends State<_OptionPanel> {
  /// Los ajustes de aprendizaje, de verdad.
  ///
  /// Estos paneles estaban dibujados pero vacíos: los botones tenían
  /// `onTap: () {}` y el interruptor de la voz estaba fijo en `true`. Ahora
  /// cada uno escribe aquí y lo que se elige se guarda y se nota.
  final LearningPreferences _prefs = LearningPreferences.instance;

  /// Aplica un ajuste y dice en qué quedó, por pantalla y en voz alta.
  ///
  /// El aviso no es un adorno: el panel se queda abierto y varios de estos
  /// ajustes sólo se notan en otra pantalla, así que sin decirlo no habría
  /// forma de saber si el toque hizo algo.
  void _apply(Future<void> Function() change, String message) {
    change();
    setState(() {});
    widget.onRefresh();
    if (!mounted) return;

    announceForAccessibility(context, message);
    // Centrado y no abajo: el SnackBar sale justo donde estan los botones de
    // este menu, asi que el aviso quedaba tapado y parecia que el toque no
    // habia hecho nada.
    CenteredToast.show(context, message);
  }

  AccessibilityTextScaleController? _textScaleController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AccessibilityTextScaleScope.of(context);
    if (_textScaleController != controller) {
      _textScaleController?.removeListener(_handleTextScaleChanged);
      _textScaleController = controller;
      _textScaleController?.addListener(_handleTextScaleChanged);
    }
  }

  @override
  void dispose() {
    _textScaleController?.removeListener(_handleTextScaleChanged);
    super.dispose();
  }

  /// El panel lee la escala directamente del controlador al construirse, asi
  /// que basta con volver a pintar cuando esta cambia.
  void _handleTextScaleChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _applyVisualMode(AppThemeMode mode) {
    // The notifier rebuilds both the app theme and this panel.
    ThemeManager.changeTheme(mode);
  }

  @override
  Widget build(BuildContext context) {
    // El panel es siempre lila claro. Con el tema oscuro, los textos y
    // chips tomaban sus colores claros y no se veían sobre él: dentro del
    // panel manda un tema claro. Los temas de daltonismo ya son claros.
    final theme = Theme.of(context);
    return Theme(
      data: theme.brightness == Brightness.dark
          ? AppTheme.getTheme(mode: AppThemeMode.light)
          : theme,
      // El Material pone también el estilo de texto del tema: sin él, los
      // títulos seguían con el color claro heredado del tema oscuro.
      child: Material(
        type: MaterialType.transparency,
        child: Builder(builder: _panel),
      ),
    );
  }

  /// La tarjeta: cabecera con icono, nombre y para qué sirve, y debajo los
  /// controles.
  ///
  /// Mide lo que mide su contenido (`MainAxisSize.min`); el alto máximo lo
  /// pone quien la coloca y, si no cabe, el contenido se desplaza. Antes cada
  /// panel repetía su nombre en una segunda tarjeta y añadía otra con una
  /// frase de relleno: tres cajas para un solo botón.
  Widget _panel(BuildContext context) {
    final (icon, purpose) =
        _panelInfo[widget.option] ??
        (Icons.settings, 'Ajustes rápidos para una mejor experiencia.');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2D8F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: _panelHeaderColor,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _panelAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
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
                              widget.option,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: _panelTitleColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            purpose,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: _panelTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar ${widget.option}',
                      onPressed: widget.onClose,
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF6B5D83),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: _buildOptionContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionContent() {
    switch (widget.option) {
      //Dialogs or modals for help horizontal button
      case 'Tamaño de texto':
        final controller = AccessibilityTextScaleScope.of(context);
        final activeScale = controller.scale;
        return _PanelTile(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Texto grande ${activeScale != 1.0 ? 'activado' : 'desactivado'}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _panelTitleColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch(
                    value: activeScale != 1.0,
                    onChanged: (value) {
                      if (!mounted) return;
                      if (value) {
                        controller.setScale(1.2);
                      } else {
                        controller.reset();
                      }
                    },
                    activeThumbColor: const Color(0xFF7E57C2),
                    activeTrackColor: const Color(0xFFD8C8F5),
                    inactiveThumbColor: const Color(0xFF8D8D8D),
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                  ),
                ],
              ),
              const Divider(height: 16, color: _panelBorderColor),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Reducir el texto',
                    onPressed: () {
                      if (!mounted) return;
                      controller.decrease();
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 26),
                    color: _panelAccent,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${controller.scale.toStringAsFixed(2)}x',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _panelTitleColor,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Agrandar el texto',
                    onPressed: () {
                      if (!mounted) return;
                      controller.increase();
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 26),
                    color: _panelAccent,
                  ),
                ],
              ),
            ],
          ),
        );
      case 'Modo visual':
        return ValueListenableBuilder<AppThemeMode>(
          valueListenable: ThemeManager.themeNotifier,
          builder: (context, currentThemeMode, child) {
            // Lista de opciones para iterar fácilmente
            final daltonismOptions = [
              {
                'mode': AppThemeMode.protanopia,
                'label': 'Protanopía',
                'sub': 'Rojo-Verde',
              },
              {
                'mode': AppThemeMode.protanomalia,
                'label': 'Protanomalía',
                'sub': 'Sensibilidad al rojo',
              },
              {
                'mode': AppThemeMode.deuteranopia,
                'label': 'Deuteranopía',
                'sub': 'Verde-Rojo',
              },
              {
                'mode': AppThemeMode.deuteranomalia,
                'label': 'Deuteranomalía',
                'sub': 'Sensibilidad al verde',
              },
              {
                'mode': AppThemeMode.tritanopia,
                'label': 'Tritanopía',
                'sub': 'Azul-Amarillo',
              },
              {
                'mode': AppThemeMode.tritanomalia,
                'label': 'Tritanomalía',
                'sub': 'Sensibilidad al azul',
              },
              {
                'mode': AppThemeMode.achromatopsia,
                'label': 'Acromatopsia',
                'sub': 'Sin colores',
              },
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelLabel('Apariencia'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      showCheckmark: false,
                      avatar: const Icon(Icons.brightness_2),
                      label: const Text('Oscuro'),
                      selected: currentThemeMode == AppThemeMode.dark,
                      onSelected: (_) {
                        _applyVisualMode(AppThemeMode.dark);
                      },
                    ),
                    ChoiceChip(
                      showCheckmark: false,
                      avatar: const Icon(Icons.brightness_5),
                      label: const Text('Claro'),
                      selected: currentThemeMode == AppThemeMode.light,
                      onSelected: (_) {
                        _applyVisualMode(AppThemeMode.light);
                      },
                    ),
                    ChoiceChip(
                      showCheckmark: false,
                      avatar: const Icon(Icons.brightness_auto),
                      label: const Text('Auto'),
                      selected: false,
                      onSelected: (_) {
                        final systemBrightness =
                            MediaQuery.platformBrightnessOf(context);
                        final modeToApply =
                            (systemBrightness == Brightness.dark)
                            ? AppThemeMode.dark
                            : AppThemeMode.light;
                        _applyVisualMode(modeToApply);
                      },
                    ),
                  ],
                ),
                const Divider(height: 28, color: _panelBorderColor),
                const _PanelLabel('Filtro de color (Daltonismo)'),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Ajusta los colores si tienes alguna dificultad visual.',
                    style: TextStyle(fontSize: 12.5, color: _panelTextColor),
                  ),
                ),
                // Chips de Selección Integrados (Sin riesgo de quedar debajo del modal)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: daltonismOptions.map((opt) {
                    final mode = opt['mode'] as AppThemeMode;
                    final label = opt['label'] as String;
                    final sub = opt['sub'] as String;

                    // Se selecciona "Sin filtro" si el tema actual no es ninguno de daltonismo
                    final isSelected = currentThemeMode == mode;

                    return ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            sub,
                            style: TextStyle(
                              fontSize: 10,
                              // onPrimaryContainer no está definido en los
                              // temas y salía blanco sobre el chip claro.
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      showCheckmark: true,
                      onSelected: (bool selected) {
                        if (selected) {
                          _applyVisualMode(mode);
                        } else {
                          // Si el usuario vuelve a tocar el chip activo para desmarcarlo, vuelve a claro
                          _applyVisualMode(AppThemeMode.light);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      case 'Asistencia auditiva':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelTile(
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: _panelAccent, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Voz más clara y pausada',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _panelTitleColor,
                      ),
                    ),
                  ),
                  Switch(
                    value: _prefs.clearSpeech,
                    onChanged: (value) => _apply(
                      () => _prefs.setClearSpeech(value),
                      value
                          ? 'Voz más pausada activada.\n'
                                'Se nota al pulsar «Escuchar» en cualquier '
                                'pantalla del curso.'
                          : 'Voz más pausada desactivada.\n'
                                'La voz vuelve a su ritmo normal.',
                    ),
                    activeThumbColor: const Color(0xFF7E57C2),
                    activeTrackColor: const Color(0xFFD8C8F5),
                    inactiveThumbColor: const Color(0xFF8D8D8D),
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _PanelLabel('Velocidad de la voz'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pace in SpeechPace.values)
                  _buildSpeedPill(
                    pace.label,
                    selected: _prefs.pace == pace,
                    onTap: () => _apply(
                      () => _prefs.setPace(pace),
                      'Velocidad de la voz: ${pace.label.toLowerCase()}.\n'
                      'Se nota al pulsar «Escuchar», arriba en cada '
                      'pantalla.',
                    ),
                  ),
              ],
            ),
          ],
        );
      case 'Lengua de señas':
        return _ChoicesWithNote(
          title: 'Nivel de apoyo',
          note: switch (_prefs.signSupport) {
            SignSupportLevel.off =>
              'Ahora no se muestra ningún apoyo en señas.',
            SignSupportLevel.basic =>
              'En los videos, un panel deletrea con el alfabeto manual lo que '
                  'se dice.',
            SignSupportLevel.advanced =>
              'Además del deletreo, verás la seña de la palabra completa '
                  'cuando exista grabada.',
          },
          choices: [
            for (final level in SignSupportLevel.values)
              _LevelButton(
                label: level.label,
                selected: _prefs.signSupport == level,
                onTap: () =>
                    _apply(() => _prefs.setSignSupport(level), switch (level) {
                      SignSupportLevel.off =>
                        'Apoyo en señas desactivado.\n'
                            'El panel de señas deja de aparecer en los '
                            'videos.',
                      SignSupportLevel.basic =>
                        'Apoyo en señas: básico.\n'
                            'En las actividades de video verás un panel que '
                            'deletrea con el alfabeto manual lo que se está '
                            'diciendo.',
                      SignSupportLevel.advanced =>
                        'Apoyo en señas: avanzado.\n'
                            'Además del deletreo, verás la seña de la '
                            'palabra completa cuando exista grabada.',
                    }),
              ),
          ],
        );
      //Dialogs or modals for accesibility horizontal button
      case 'Preferencias de aprendizaje':
        return _ChoicesWithNote(
          title: 'Prefiero empezar por',
          note: switch (_prefs.contentPreference) {
            ContentPreference.none =>
              'Las actividades siguen el orden normal del capítulo.',
            ContentPreference.readings =>
              'Cada capítulo empieza por la lectura.',
            ContentPreference.videos => 'Cada capítulo empieza por el video.',
            ContentPreference.audios =>
              'La lectura en voz alta empieza sola al abrir una actividad.',
          },
          choices: [
            for (final preference in ContentPreference.values)
              _LevelButton(
                label: preference.label,
                selected: _prefs.contentPreference == preference,
                onTap: () => _apply(
                  () => _prefs.setContentPreference(preference),
                  switch (preference) {
                    ContentPreference.none =>
                      'Sin preferencia.\n'
                          'En cada capítulo, la ruta de actividades vuelve '
                          'a su orden normal.',
                    ContentPreference.readings =>
                      'Lecturas primero.\n'
                          'En cada capítulo, la ruta de actividades '
                          'empezará por la lectura.',
                    ContentPreference.videos =>
                      'Videos primero.\n'
                          'En cada capítulo, la ruta de actividades '
                          'empezará por el video.',
                    ContentPreference.audios =>
                      'Audios.\n'
                          'Al abrir una actividad, la lectura en voz alta '
                          'empezará sola.',
                  },
                ),
              ),
          ],
        );
      case 'Nivel de aprendizaje':
        return _ChoicesWithNote(
          title: 'Mi nivel',
          note: switch (_prefs.level) {
            LearningLevel.basic =>
              'Los objetivos de cada sección se ven desplegados.',
            LearningLevel.medium =>
              'El apoyo de siempre: los objetivos siguen a la vista.',
            LearningLevel.advanced =>
              'Sin objetivos desplegados: solo la ruta de actividades.',
          },
          choices: [
            for (final level in LearningLevel.values)
              _LevelButton(
                label: level.label,
                selected: _prefs.level == level,
                onTap: () =>
                    _apply(() => _prefs.setLevel(level), switch (level) {
                      LearningLevel.basic =>
                        'Nivel básico.\n'
                            'En cada capítulo verás desplegados los '
                            'objetivos de la sección.',
                      LearningLevel.medium =>
                        'Nivel medio.\n'
                            'El apoyo de siempre: los objetivos siguen a la '
                            'vista en cada capítulo.',
                      LearningLevel.advanced =>
                        'Nivel avanzado.\n'
                            'Se retiran los objetivos de cada capítulo para '
                            'dejar sitio a la ruta de actividades.',
                    }),
              ),
          ],
        );
      //Dialogs or modals for support horizontal button
      case 'Pistas':
        return _ChoicesWithNote(
          note: _prefs.hintsEnabled
              ? 'Las pistas están activas en los quiz.'
              : 'Ahora los quiz se responden sin pistas.',
          choices: [
            _LevelButton(
              label: _prefs.hintsEnabled
                  ? 'Desactivar pistas'
                  : 'Activar pistas',
              selected: _prefs.hintsEnabled,
              onTap: () => _apply(
                () => _prefs.setHintsEnabled(!_prefs.hintsEnabled),
                _prefs.hintsEnabled
                    ? 'Pistas desactivadas.'
                    : 'Pistas activadas: aparecerán en los quiz.',
              ),
            ),
          ],
        );
      case 'Manual interactivo':
        return _ChoicesWithNote(
          note: _prefs.manualEnabled
              ? 'Al abrir una actividad verás la guía de esa pantalla.'
              : 'Ahora las actividades se abren sin la guía.',
          choices: [
            _LevelButton(
              label: _prefs.manualEnabled
                  ? 'Desactivar manual interactivo'
                  : 'Activar manual interactivo',
              selected: _prefs.manualEnabled,
              onTap: () => _apply(
                () => _prefs.setManualEnabled(!_prefs.manualEnabled),
                _prefs.manualEnabled
                    ? 'Manual interactivo desactivado.\n'
                          'Deja de salir la guía al abrir una actividad.'
                    : 'Manual interactivo activado.\n'
                          'Al abrir una actividad verás una guía de esa '
                          'pantalla concreta y sus controles.',
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// Los colores del panel. Es siempre claro (ver _OptionPanelState.build), así
// que van fijos; todos pasan de 4,5:1 sobre el blanco y el lila de la cabecera.
const Color _panelAccent = Color(0xFF7E57C2);
const Color _panelHeaderColor = Color(0xFFF4EDFF);
const Color _panelTileColor = Color(0xFFF8F5FD);
const Color _panelBorderColor = Color(0xFFE6DDF7);
const Color _panelTitleColor = Color(0xFF2F1F56);
const Color _panelTextColor = Color(0xFF5B4B72);

/// Un recuadro suave que agrupa un interruptor con lo que controla.
class _PanelTile extends StatelessWidget {
  const _PanelTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: _panelTileColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _panelBorderColor),
      ),
      child: child,
    );
  }
}

/// El nombre de un grupo de opciones dentro del panel.
class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: _panelTitleColor,
        ),
      ),
    );
  }
}

/// Las opciones de un ajuste y, debajo, qué cambia con la que está puesta.
///
/// La nota sustituye a la frase de relleno que llevaba cada panel («Estas
/// preferencias te ayudarán…»): ocupaba lo mismo y no decía nada.
class _ChoicesWithNote extends StatelessWidget {
  const _ChoicesWithNote({
    required this.choices,
    required this.note,
    this.title,
  });

  final String? title;
  final List<Widget> choices;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) _PanelLabel(title!),
        Wrap(spacing: 8, runSpacing: 8, children: choices),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.info_outline, size: 16, color: _panelAccent),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: _panelTextColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Una de las velocidades de la voz.
///
/// [selected] marca la que está puesta ahora. Sin eso se elegía a ciegas: el
/// botón no cambiaba y no había forma de saber cuál estaba activa.
Widget _buildSpeedPill(
  String label, {
  required bool selected,
  required VoidCallback onTap,
}) {
  return Semantics(
    button: true,
    selected: selected,
    label: 'Velocidad de la voz: $label',
    child: ExcludeSemantics(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppMetrics.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7E57C2) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF5B3E8A)
                  : const Color(0xFFD8C8F5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF5B3E8A),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LevelButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  /// Si es la opcion puesta ahora mismo.
  ///
  /// Antes no existia: se tocaba un boton y no cambiaba nada en pantalla, asi
  /// que no habia forma de saber que se habia elegido ni que estaba activo.
  final bool selected;

  const _LevelButton({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppMetrics.minTapTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF7E57C2) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? const Color(0xFF5B3E8A)
                    : const Color(0xFFD4C4F2),
                width: selected ? 2 : 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check, size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
