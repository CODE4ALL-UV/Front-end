import 'package:flutter/material.dart';
import 'accessibility_settings_screen.dart';

class HelpActionButton extends StatefulWidget {
  const HelpActionButton({super.key});

  @override
  State<HelpActionButton> createState() => _HelpActionButtonState();
}

class _HelpActionButtonState extends State<HelpActionButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  String? _selectedOption;
  OverlayEntry? _overlayEntry;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refreshOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _hideOverlay();
      return;
    }

    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final safeWidth = (screenWidth - 24).clamp(220.0, 380.0);
    final panelWidth = (safeWidth - 92).clamp(180.0, 220.0);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final overlayMediaQuery = MediaQuery.of(context);
        final overlayHeight = overlayMediaQuery.size.height;
        final overlayWidth = overlayMediaQuery.size.width;
        final overlaySafeWidth = (overlayWidth - 24).clamp(220.0, 380.0);
        final overlayPanelWidth = (overlaySafeWidth - 92).clamp(180.0, 220.0);
        final overlayPanelLeft = (overlaySafeWidth > 300 ? 72.0 : 56.0).clamp(
          0.0,
          (overlaySafeWidth - overlayPanelWidth - 16).clamp(
            0.0,
            overlaySafeWidth,
          ),
        );
        final panelHeight = 360.0;
        final availableBottomSpace =
            overlayHeight - 24 - overlayMediaQuery.padding.bottom;
        final panelTop = (availableBottomSpace - panelHeight).clamp(0.0, 80.0);

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
              left: 12,
              top: panelTop,
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
                          top: 8,
                          child: _OptionPanel(
                            option: _selectedOption!,
                            onClose: _closePanel,
                            width: overlayPanelWidth,
                          ),
                        ),
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isExpanded) ...[
                              _buildAnimatedOption(
                                icon: Icons.settings,
                                label: 'Configuración',
                                color: const Color(0xFF7E57C2),
                                onTap: () => _selectOption('Configuración'),
                              ),
                              _buildAnimatedOption(
                                icon: Icons.zoom_in,
                                label: 'Tamaño de texto',
                                color: const Color(0xFF7E57C2),
                                onTap: () => _selectOption('Tamaño de texto'),
                              ),
                              _buildAnimatedOption(
                                icon: Icons.wb_sunny,
                                label: 'Modo visual',
                                color: const Color(0xFF7E57C2),
                                onTap: () => _selectOption('Modo visual'),
                              ),
                              _buildAnimatedOption(
                                icon: Icons.record_voice_over,
                                label: 'Asistencia auditiva',
                                color: const Color(0xFF7E57C2),
                                onTap: () =>
                                    _selectOption('Asistencia auditiva'),
                              ),
                              _buildAnimatedOption(
                                icon: Icons.translate,
                                label: 'Lengua de señas',
                                color: const Color(0xFF7E57C2),
                                onTap: () => _selectOption('Lengua de señas'),
                              ),
                            ],
                            const SizedBox(height: 12),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _toggleMenu,
                              child: Container(
                                width: 56,
                                height: 56,
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
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isExpanded
                                      ? Icons.close
                                      : Icons.help_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
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

    overlay.insert(_overlayEntry!);
    setState(() {
      _isExpanded = true;
      _selectedOption = null;
    });
    _refreshOverlay();
    _controller.forward();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.reverse();
    if (mounted) {
      setState(() {
        _isExpanded = false;
        _selectedOption = null;
      });
    }
  }

  void _selectOption(String option) {
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
    setState(() {
      _selectedOption = null;
    });
    _refreshOverlay();
  }

  @override
  Widget build(BuildContext context) {
    // Return a plain, non-positioned button so callers can place it
    // consistently across screens (Align/Padding/Row). The overlay
    // behavior is handled separately via OverlayEntry.
    return SafeArea(
      child: Offstage(
        offstage: _overlayEntry != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleMenu,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF7E57C2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7E57C2).withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _isExpanded ? Icons.close : Icons.help_outline,
              color: Colors.white,
              size: 24,
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

class _AccessibilityIconButton extends StatelessWidget {
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _OptionPanel extends StatefulWidget {
  final String option;
  final VoidCallback onClose;
  final double width;

  const _OptionPanel({
    super.key,
    required this.option,
    required this.onClose,
    required this.width,
  });

  @override
  State<_OptionPanel> createState() => _OptionPanelState();
}

class _OptionPanelState extends State<_OptionPanel> {
  bool _textSizeEnabled = false;
  bool _visualModeEnabled = false;
  double _textSize = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      constraints: BoxConstraints(maxWidth: widget.width),
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
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    widget.option,
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
          // Contenido según la opción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildOptionContent(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionContent() {
    switch (widget.option) {
      case 'Tamaño de texto':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(
              icon: Icons.text_fields,
              title: 'Tamaño de texto',
              subtitle: 'Aumenta el tamaño para leer con más comodidad.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8F7)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Texto grande activo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2F1F56),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _textSizeEnabled
                              ? 'El contenido aparecerá con letra más grande.'
                              : 'La lectura seguirá en el tamaño normal.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6A5B7D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _textSizeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _textSizeEnabled = value;
                      });
                      _showStatusMessage(
                        context,
                        _textSizeEnabled
                            ? 'Texto grande activado'
                            : 'Texto grande desactivado',
                      );
                    },
                    activeColor: const Color(0xFF9575CD),
                    activeTrackColor: const Color(0xFFD8C8F5),
                    inactiveThumbColor: const Color(0xFFBDBDBD),
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScaleMarker('A', 14),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF424242),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9E9E9E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildScaleMarker('A', 20),
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
              subtitle: 'Cambia el contraste y la claridad de la pantalla.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8F7)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contraste mejorado',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2F1F56),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _visualModeEnabled
                              ? 'La interfaz usará un contraste más fuerte.'
                              : 'La interfaz conservará el diseño estándar.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6A5B7D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _visualModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _visualModeEnabled = value;
                      });
                      _showStatusMessage(
                        context,
                        _visualModeEnabled
                            ? 'Contraste mejorado activado'
                            : 'Contraste mejorado desactivado',
                      );
                    },
                    activeColor: const Color(0xFF9575CD),
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
                _ModeButton(
                  icon: Icons.brightness_2,
                  label: 'Oscuro',
                  onTap: () {},
                ),
                _ModeButton(
                  icon: Icons.brightness_5,
                  label: 'Claro',
                  onTap: () {},
                ),
                _ModeButton(
                  icon: Icons.brightness_auto,
                  label: 'Auto',
                  onTap: () {},
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
                color: Colors.white.withOpacity(0.8),
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
                color: Colors.white.withOpacity(0.8),
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
                    activeColor: const Color(0xFF9575CD),
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
      color: const Color(0xFF7E57C2).withOpacity(0.1),
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
          color: const Color(0xFF9575CD).withOpacity(0.1),
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

void _showStatusMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF7E57C2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              color: const Color(0xFF7E57C2).withOpacity(0.25),
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
              color: const Color(0xFF9575CD).withOpacity(0.12),
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
