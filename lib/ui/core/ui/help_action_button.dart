import 'package:flutter/material.dart';
import 'package:flutter_code4all/web_player_html.dart'; //Daniel Pruebas
import 'accessibility_settings_screen.dart';
import 'accessibility_text_scale.dart';
import 'visual_theme_controller.dart';

//TAREAS
// SOLVED BUG DE PANTALLAZO ROJO AL PRESIONAR EL BOTÓN DE CONFIGURACIÓN ATTE MI PAPACHO
// BUG DEL CAMBIO DE FONDO Y BLOQUEO DE COMPONENTE QUE NO DEJA INTERACTUAR SOLO CERRAR ATTE MI PAPACHO
// SOLVED BUG DE AUMENTAR EL TAMAÑO DE TEXTO PARA QUE APLIQUE A LOS BOTONES DE ESTE COMPONENTE ATTE MI PAPACHO
// BUG DEL BUG

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
  }

  @override
  void dispose() {
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
    final screenWidth = mediaQuery.size.width;
    final safeWidth = (screenWidth - 24).clamp(220.0, 380.0);

    // Calculate the exact bottom and left coordinates based on the real button
    // We subtract 56 (the button height) to get the distance from the bottom edge
    final double exactBottom =
        screenHeight -
        buttonPosition.dy -
        44; // Same as Vertical and Horizontal Buttons
    final double exactLeft = buttonPosition.dx;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final double scale = AccessibilityTextScaleScope.of(overlayContext).scale;
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
        final panelHeight = (screenHeight * 0.65).clamp(280.0, 380.0);
        final availableBottomSpace =
            overlayHeight - 24 - overlayMediaQuery.padding.bottom;

        // --- NEW BOTTOM-TO-BOTTOM ALIGNMENT ---
        // Calculate vertical alignment so the modal's TOP aligns with the vertical button's TOP
        double? panelBottomPosition;

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
            panelBottomPosition = optionHeight + (reversedIndex * stepHeight);
          }
        }

        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hideOverlay,
              child: Container(
                width: overlayWidth,
                height: overlayHeight,
                color: Colors.transparent,
              ),
            ),
            Positioned(
              left: exactLeft,
              bottom:
                  exactBottom, // Matches the bottom padding of your closed button
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: overlaySafeWidth,
                  height: panelHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (_selectedOption != null)
                        Positioned(
                          left: overlayPanelLeft,
                          bottom:
                              panelBottomPosition ??
                              62.0, // Use the calculated bottom position, defaulting to 62.0 (the base height) just in case
                          child: SizedBox(
                            width: overlayPanelWidth,
                            child: _OptionPanel(
                              option: _selectedOption!,
                              onClose: _closePanel,
                              width: overlayPanelWidth,
                              onRefresh: _refreshOverlay,
                            ),
                          ),
                        ),
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
                                        }).toList(),
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
                              }).toList(),

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
                                          color: Colors.black.withValues(alpha: 0.18),
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
          builder: (context) => const YoutubeIframeTestScreen(videoId: 'dQw4w9WgXcQ'),
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
            colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.8)],
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
  final VoidCallback onRefresh;

  const _OptionPanel({
    super.key,
    required this.option,
    required this.onClose,
    required this.width,
    required this.onRefresh,
  });

  @override
  State<_OptionPanel> createState() => _OptionPanelState();
}

class _OptionPanelState extends State<_OptionPanel> {
  /*
  This _OptionPanelState is the core brain of the white modal card. Your classmate used a very clean switch(widget.option) statement to dynamically render different UI layouts (the font size slider, the visual mode toggles, the sign language buttons) depending on which vertical button was tapped. It also properly connects to the AccessibilityTextScaleScope and VisualThemeController to actually apply the changes to the app.

Handling the UI states for these accessibility toggles this way is a very solid approach for this stage of your TG.

I assume the final parts of the file contain the small helper widgets mentioned here (like _buildInfoBanner, _ModeButton, _LevelButton, and _buildSpeedPill).
  */
  bool _textSizeEnabled = false;
  bool _visualModeEnabled = false;
  double _textSize = 1.0;
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
    _textSizeEnabled = controller.scale != 1.0;
    _textSize = controller.scale;
  }

  @override
  void dispose() {
    _textScaleController?.removeListener(_handleTextScaleChanged);
    super.dispose();
  }

  void _handleTextScaleChanged() {
    if (!mounted) return;
    setState(() {
      _textSizeEnabled = (_textScaleController?.scale ?? 1.0) != 1.0;
      _textSize = _textScaleController?.scale ?? 1.0;
    });
  }

  void _applyVisualMode(bool isDarkTheme) {
    VisualThemeController.updateTheme(isDarkTheme);

    final controller = VisualThemeController.of(context);
    if (controller != null) {
      controller.onThemeChanged(isDarkTheme);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.width),
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
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildOptionContent(),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              icon: Icons.visibility,
              title: 'Modo visual',
              subtitle: 'Elige el contraste que prefieras para la interfaz.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModeButton(
                  icon: Icons.brightness_2,
                  label: 'Oscuro',
                  onTap: () => _applyVisualMode(true),
                ),
                _ModeButton(
                  icon: Icons.brightness_5,
                  label: 'Claro',
                  onTap: () => _applyVisualMode(false),
                ),
                _ModeButton(
                  icon: Icons.brightness_auto,
                  label: 'Auto',
                  onTap: () => _applyVisualMode(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ],
            ),
          ],
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
                    value: true,
                    onChanged: (value) {},
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
                _buildSpeedPill('Lenta'),
                _buildSpeedPill('Media'),
                _buildSpeedPill('Rápida'),
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
                _LevelButton(label: 'Básico', onTap: () {}),
                _LevelButton(label: 'Avanzado', onTap: () {}),
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
                _LevelButton(label: 'Lecturas', onTap: () {}),
                _LevelButton(label: 'Videos', onTap: () {}),
                _LevelButton(label: 'Audios', onTap: () {}),
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
                _LevelButton(label: 'Básico', onTap: () {}),
                _LevelButton(label: 'Medio', onTap: () {}),
                _LevelButton(label: 'Avanzado', onTap: () {}),
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
              children: [_LevelButton(label: 'Activar pista', onTap: () {})],
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
                _LevelButton(label: 'Activar manual interactivo', onTap: () {}),
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

Widget _buildScaleMarker(String label, double fontSize) {
  return Text(
    label,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF424242),
    ),
  );
}

Widget _buildSpeedPill(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFD8C8F5)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF9575CD).withValues(alpha: 0.1),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5B3E8A),
      ),
    ),
  );
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7E57C2).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LevelButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD4C4F2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9575CD).withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
      ),
    );
  }
}
