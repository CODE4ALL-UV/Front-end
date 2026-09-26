import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/web_player_html.dart'; //Daniel Pruebas
import 'package:flutter_code4all/web_player_html_2.dart'; //Daniel Pruebas
import 'accessibility_settings_screen.dart';
import 'accessibility_announcer_widget.dart';
import 'accessibility_text_scale_widget.dart';
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
      {'icon': Icons.assignment_late, 'label': 'Video prueba Daniel'},
      {'icon': Icons.notifications_paused, 'label': 'Audio prueba Daniel'},
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
    debugPrint('🔴 [MODAL] dispose() llamado - El modal se destruyó');
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

    // Calculate the exact bottom and left coordinates based on the real button
    // We subtract 56 (the button height) to get the distance from the bottom edge
    final double exactBottom =
        screenHeight -
        buttonPosition.dy -
        44; // Same as Vertical and Horizontal Buttons
    final double exactLeft = buttonPosition.dx;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final double scale = AccessibilityTextScaleScope.of(
          overlayContext,
        ).scale;
        final overlayMediaQuery = MediaQuery.of(overlayContext);
        final overlayHeight = overlayMediaQuery.size.height;
        final overlayWidth = overlayMediaQuery.size.width;
        final overlaySafeWidth = (overlayWidth - 24).clamp(220.0, 380.0);
        final overlayPanelWidth = (overlaySafeWidth - 92).clamp(200.0, 260.0);
        final overlayPanelLeft = (overlaySafeWidth > 300 ? 72.0 : 56.0).clamp(
          0.0,
          (overlaySafeWidth - overlayPanelWidth - 16).clamp(
            0.0,
            overlaySafeWidth,
          ),
        );
        final panelHeight = (overlayHeight - 24.0).clamp(280.0, 520.0);

        // Calculate vertical alignment so the modal's TOP aligns with the vertical button's TOP
        double panelBottomPosition = 62.0;

        if (_selectedOption != null && _activeCategory != null) {
          final options = categoryOptions[_activeCategory!] ?? [];
          final index = options.indexWhere(
            (opt) => opt['label'] == _selectedOption,
          );

          if (index != -1) {
            // Reversing the index because the options map renders top-to-bottom,
            // but we calculate position from bottom-to-top
            final int reversedIndex = options.length - 1 - index;

            // Distance from the bottom of the Stack to the bottom of the LOWEST vertical button.
            // 6px (bottom padding) + 44px (horizontal button) + 12px (SizedBox) = 62.0
            final double optionHeight = 62.0;

            // FIX 3: STEP HEIGHT
            // This is the exact distance from the bottom of one vertical button to the bottom of the next.
            // If your _buildAnimatedOption is 44px tall and has 12px of spacing between them, this is 56.0.
            // If the modal is still falling below the UPPER buttons, INCREASE this number (e.g. 60.0 or 64.0)
            final double stepHeight = 56.0;

            // 50.0 is the horizontal button height (44) + bottom padding (6)
            // This perfectly calculates where the BOTTOM of the clicked button is.
            final calculatedPosition =
                optionHeight + (reversedIndex * stepHeight);
            // MAGIA AQUÍ: Limitamos la posición para que el panel NUNCA
            // rebase la pantalla por la parte superior (dejando un margen de seguridad de 20px)
            final maxAllowedBottom = overlayHeight - panelHeight - 20.0;
            panelBottomPosition = calculatedPosition
                .clamp(62.0, maxAllowedBottom > 62.0 ? maxAllowedBottom : 62.0)
                .toDouble();
          }
        }

        // Calculate the absolute position after applying the selected option's
        // vertical offset so every modal button remains in the hit-test area.
        final double absoluteBottom = exactBottom + panelBottomPosition;
        final double absoluteLeft = exactLeft + overlayPanelLeft;

        return Stack(
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
                                                optionData['icon'] as IconData,
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
                                                scale, // Same as Vertical Buttons
                                            height:
                                                44 *
                                                scale, // Same as Vertical Buttons
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
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              displayIcon,
                                              color: isActive
                                                  ? Colors.white
                                                  : const Color(0xFF7E57C2),
                                              size:
                                                  33 *
                                                  scale, //Same as Vertical Buttons
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
                                    duration: const Duration(milliseconds: 300),
                                    width:
                                        44 *
                                        scale, // Same as Vertical and Horizontal Buttons
                                    height:
                                        44 *
                                        scale, // Same as Vertical and Horizontal Buttons
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
                                          scale, // Same as Vertical and Horizontal Buttons
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
              Positioned(
                left: absoluteLeft,
                bottom: absoluteBottom,
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: overlayPanelWidth,
                    child: _OptionPanel(
                      option: _selectedOption!,
                      onClose: _closePanel,
                      width: overlayPanelWidth,
                      height: panelHeight,
                      onRefresh: _refreshOverlay,
                    ),
                  ),
                ),
              ),
          ],
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
      entry.remove();
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
    if (option == 'Video prueba Daniel') {
      _navigateToVideoDaniel();
      return;
    }
    if (option == 'Audio prueba Daniel') {
      _navigateToAudioDaniel();
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

  void _navigateToVideoDaniel() {
    _hideOverlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) =>
              const YoutubeIframeTestScreen(videoId: 'dQw4w9WgXcQ'),
        ),
      );
    });
  }

  void _navigateToAudioDaniel() {
    _hideOverlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => const CustomAudioPlayerScreen(),
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
    final double scale = AccessibilityTextScaleScope.of(context).scale;
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
  final double width;
  final double height;
  final VoidCallback onRefresh;

  const _OptionPanel({
    required this.option,
    required this.onClose,
    required this.width,
    required this.height,
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /*
  This _OptionPanelState is the core brain of the white modal card. Your classmate used a very clean switch(widget.option) statement to dynamically render different UI layouts (the font size slider, the visual mode toggles, the sign language buttons) depending on which vertical button was tapped. It also properly connects to the AccessibilityTextScaleScope and app_theme.dart to actually apply the changes to the app.

Handling the UI states for these accessibility toggles this way is a very solid approach for this stage of your TG.

I assume the final parts of the file contain the small helper widgets mentioned here (like _buildInfoBanner, _ModeButton, _LevelButton, and _buildSpeedPill).
  */
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
    debugPrint('🔵 [MODAL] _applyVisualMode(): Cambiando modo a: $mode');
    // The notifier rebuilds both the app theme and this panel.
    ThemeManager.changeTheme(mode);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF4EDFF), Color(0xFFE8E4F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8C8F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.option,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F1F56),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF6B5D83),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildOptionContent(),
              ),
            ),
            const SizedBox(height: 16),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              icon: Icons.text_fields,
              title: 'Tamaño de texto',
              subtitle: 'Ajusta la lectura sin perder la vista del contenido.',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8F7)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Texto grande ${activeScale != 1.0 ? 'activado' : 'desactivado'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6A5B7D),
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
                    activeThumbColor: const Color(0xFF9575CD),
                    activeTrackColor: const Color(0xFFD8C8F5),
                    inactiveThumbColor: const Color(0xFFBDBDBD),
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () {
                    if (!mounted) return;
                    controller.decrease();
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  color: const Color(0xFF7E57C2),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${controller.scale.toStringAsFixed(2)}x',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F1F56),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () {
                    if (!mounted) return;
                    controller.increase();
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  color: const Color(0xFF7E57C2),
                ),
              ],
            ),
          ],
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
                'mode': AppThemeMode.deuteranopia,
                'label': 'Deuteranopía',
                'sub': 'Verde-Rojo',
              },
              {
                'mode': AppThemeMode.tritanopia,
                'label': 'Tritanopía',
                'sub': 'Azul-Amarillo',
              },
              {
                'mode': AppThemeMode.achromatopsia,
                'label': 'Acromatopsia',
                'sub': 'Sin colores',
              },
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // _buildInfoBanner(
                //   icon: Icons.visibility,
                //   title: 'Modo visual',
                //   subtitle:
                //       'Elige el contraste que prefieras para la interfaz.',
                // ),
                const SizedBox(height: 10),
                // 1. MODOS PRINCIPALES CON CHOICECHIP
                const Text(
                  'Apariencia',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
                        debugPrint('🔵 [MODAL] Cambiando modo a DARK');
                        _applyVisualMode(AppThemeMode.dark);
                      },
                    ),
                    ChoiceChip(
                      showCheckmark: false,
                      avatar: const Icon(Icons.brightness_5),
                      label: const Text('Claro'),
                      selected: currentThemeMode == AppThemeMode.light,
                      onSelected: (_) {
                        debugPrint('🔵 [MODAL] Cambiando modo a LIGHT');
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
                const SizedBox(height: 10),
                const Divider(), // Una pequeña línea divisoria ayuda mucho a la UI
                const SizedBox(height: 10),

                // 2. NUEVA SECCIÓN: Select (Dropdown) para Daltonismo
                const Text(
                  'Filtro de color (Daltonismo)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ajusta los colores si tienes alguna dificultad visual.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // El "Select" estilizado en Dropdown con AppThemeMode directamente
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
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      showCheckmark: true,
                      onSelected: (bool selected) {
                        if (selected) {
                          debugPrint(
                            '🔵 [MODAL] Cambiando modo de daltonismo: $mode, y enviado a _applyVisualMode()',
                          );
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
            _buildInfoBanner(
              icon: Icons.hearing,
              title: 'Asistencia auditiva',
              subtitle: 'Ajusta la voz para que sea más clara y comprensible.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8F7)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.volume_up,
                    color: Color(0xFF7E57C2),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'La voz del asistente será más clara y pausada.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6A5B7D),
                      ),
                    ),
                  ),
                  Switch(
                    value: _prefs.clearSpeech,
                    onChanged: (value) => _apply(
                      () => _prefs.setClearSpeech(value),
                      value
                          ? 'La voz irá más pausada.'
                          : 'La voz vuelve a su ritmo normal.',
                    ),
                    activeThumbColor: const Color(0xFF9575CD),
                    activeTrackColor: const Color(0xFFD8C8F5),
                    inactiveThumbColor: const Color(0xFFBDBDBD),
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                      'Velocidad de la voz: ${pace.label.toLowerCase()}.',
                    ),
                  ),
              ],
            ),
          ],
        );
      case 'Lengua de señas':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              icon: Icons.sign_language,
              title: 'Lengua de señas',
              subtitle:
                  'Activa ayudas visuales para comprender mejor el contenido.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8F7)),
              ),
              child: const Text(
                'Se mostrarán apoyos visuales y señales de contexto para facilitar la comprensión.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF6A5B7D)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in SignSupportLevel.values)
                  _LevelButton(
                    label: level.label,
                    selected: _prefs.signSupport == level,
                    onTap: () => _apply(
                      () => _prefs.setSignSupport(level),
                      level == SignSupportLevel.off
                          ? 'Apoyo en señas desactivado.'
                          : 'Apoyo en señas: ${level.label.toLowerCase()}.',
                    ),
                  ),
              ],
            ),
          ],
        );
      //Dialogs or modals for accesibility horizontal button
      case 'Preferencias de aprendizaje':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              icon: Icons.sign_language,
              title: 'Preferencias de aprendizaje',
              subtitle:
                  'Que tipo de contenido predomina para el proceso de aprendizaje.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8F7)),
              ),
              child: const Text(
                'Estas preferencias te ayudarán a personalizar tu experiencia de aprendizaje.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF6A5B7D)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preference in ContentPreference.values)
                  _LevelButton(
                    label: preference.label,
                    selected: _prefs.contentPreference == preference,
                    onTap: () => _apply(
                      () => _prefs.setContentPreference(preference),
                      preference == ContentPreference.none
                          ? 'Sin preferencia: las actividades van en su orden.'
                          : '${preference.label} primero en cada sección.',
                    ),
                  ),
              ],
            ),
          ],
        );
      case 'Nivel de aprendizaje':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              icon: Icons.sign_language,
              title: 'Nivel de aprendizaje',
              subtitle:
                  'Cual es el nivel de dificultad para el proceso de aprendizaje.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8F7)),
              ),
              child: const Text(
                'Estas preferencias te ayudarán a personalizar tu experiencia de aprendizaje.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF6A5B7D)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in LearningLevel.values)
                  _LevelButton(
                    label: level.label,
                    selected: _prefs.level == level,
                    onTap: () => _apply(
                      () => _prefs.setLevel(level),
                      level == LearningLevel.basic
                          ? 'Nivel básico: verás los objetivos y la explicación de cada respuesta.'
                          : 'Nivel ${level.label.toLowerCase()}.',
                    ),
                  ),
              ],
            ),
          ],
        );
      //Dialogs or modals for support horizontal button
      case 'Pistas':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              icon: Icons.sign_language,
              title: 'Pistas',
              subtitle:
                  'Sirven para guiar al usuario en su proceso de aprendizaje.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8F7)),
              ),
              child: const Text(
                'Estas pistas te ayudarán para avanzar en tu proceso de aprendizaje.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF6A5B7D)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
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
            ),
          ],
        );
      case 'Manual interactivo':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              icon: Icons.sign_language,
              title: 'Manual interactivo',
              subtitle:
                  'Guía interactiva para facilitar el proceso de aprendizaje.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8F7)),
              ),
              child: const Text(
                'Esta guía interactiva te ayudará a personalizar tu experiencia de aprendizaje.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF6A5B7D)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LevelButton(
                  label: _prefs.manualEnabled
                      ? 'Desactivar manual interactivo'
                      : 'Activar manual interactivo',
                  selected: _prefs.manualEnabled,
                  onTap: () => _apply(
                    () => _prefs.setManualEnabled(!_prefs.manualEnabled),
                    _prefs.manualEnabled
                        ? 'Manual interactivo desactivado.'
                        : 'Manual interactivo activado: verás la guía al abrir una actividad.',
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              icon: Icons.settings,
              title: widget.option,
              subtitle:
                  'Ajustes rápidos y accesibles para una mejor experiencia.',
            ),
          ],
        );
    }
  }
}

Widget _buildInfoBanner({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  debugPrint('🚨 [TEST] _buildInfoBanner: BOTONES VERTICALES DESPLEGADOS');
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF7E57C2).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD8C8F5)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7E57C2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F1F56),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.2,
                  color: Color(0xFF6A5B7D),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
