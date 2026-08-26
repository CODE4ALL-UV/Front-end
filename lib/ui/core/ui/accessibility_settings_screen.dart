import 'package:flutter/material.dart';
import 'accessibility_text_scale.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  late final AccessibilityTextScaleController? _textScaleController;
  bool _textSizeEnabled = false;
  bool _visualModeEnabled = false;
  bool _audioAssistEnabled = true;
  bool _signLanguageEnabled = false;
  String _selectedVisualMode = 'Auto';
  String _selectedAudioSpeed = 'Media';
  String _selectedSignLevel = 'Básico';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textScaleController = AccessibilityTextScaleScope.of(context);
    _textSizeEnabled = _textScaleController?.scale != 1.0;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7E57C2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configuración de Accesibilidad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildTextSizeSection(),
            const SizedBox(height: 16),
            _buildVisualModeSection(),
            const SizedBox(height: 16),
            _buildAudioAssistSection(),
            const SizedBox(height: 16),
            _buildSignLanguageSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E57C2).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.accessibility_new,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personaliza tu experiencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ajusta las opciones según tus necesidades',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSizeSection() {
    return _buildSettingCard(
      icon: Icons.text_fields,
      title: 'Tamaño de texto',
      subtitle: 'Aumenta el tamaño para leer con más comodidad',
      child: Column(
        children: [
          Row(
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
                  if (value) {
                    _textScaleController?.setScale(1.2);
                  } else {
                    _textScaleController?.reset();
                  }
                  _showStatusMessage(
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScaleMarker('A', 14),
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF424242),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 50,
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
      ),
    );
  }

  Widget _buildVisualModeSection() {
    return _buildSettingCard(
      icon: Icons.visibility,
      title: 'Modo visual',
      subtitle: 'Cambia el contraste y la claridad de la pantalla',
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModeButton('Oscuro', Icons.brightness_2),
              _buildModeButton('Claro', Icons.brightness_5),
              _buildModeButton('Auto', Icons.brightness_auto),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioAssistSection() {
    return _buildSettingCard(
      icon: Icons.hearing,
      title: 'Asistencia auditiva',
      subtitle: 'Ajusta la voz para que sea más clara y comprensible',
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up, color: Color(0xFF7E57C2), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voz del asistente',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F1F56),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _audioAssistEnabled
                          ? 'La voz será más clara y pausada.'
                          : 'El asistente de voz está desactivado.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6A5B7D),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _audioAssistEnabled,
                onChanged: (value) {
                  setState(() {
                    _audioAssistEnabled = value;
                  });
                  _showStatusMessage(
                    _audioAssistEnabled
                        ? 'Asistencia auditiva activada'
                        : 'Asistencia auditiva desactivada',
                  );
                },
                activeColor: const Color(0xFF9575CD),
                activeTrackColor: const Color(0xFFD8C8F5),
                inactiveThumbColor: const Color(0xFFBDBDBD),
                inactiveTrackColor: const Color(0xFFE0E0E0),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSpeedPill('Lenta'),
              _buildSpeedPill('Media'),
              _buildSpeedPill('Rápida'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignLanguageSection() {
    return _buildSettingCard(
      icon: Icons.sign_language,
      title: 'Lengua de señas',
      subtitle: 'Activa ayudas visuales para comprender mejor el contenido',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apoyos visuales',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F1F56),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _signLanguageEnabled
                          ? 'Se mostrarán señales de contexto.'
                          : 'Los apoyos visuales están desactivados.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6A5B7D),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _signLanguageEnabled,
                onChanged: (value) {
                  setState(() {
                    _signLanguageEnabled = value;
                  });
                  _showStatusMessage(
                    _signLanguageEnabled
                        ? 'Lengua de señas activada'
                        : 'Lengua de señas desactivada',
                  );
                },
                activeColor: const Color(0xFF9575CD),
                activeTrackColor: const Color(0xFFD8C8F5),
                inactiveThumbColor: const Color(0xFFBDBDBD),
                inactiveTrackColor: const Color(0xFFE0E0E0),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLevelButton('Básico'),
              _buildLevelButton('Avanzado'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E57C2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF7E57C2), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F1F56),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A5B7D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
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

  Widget _buildModeButton(String label, IconData icon) {
    final isSelected = _selectedVisualMode == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedVisualMode = label;
          });
          _showStatusMessage('Modo $label seleccionado');
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF5F3F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7E57C2)
                  : const Color(0xFFD8C8F5),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7E57C2).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : const Color(0xFF7E57C2),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedPill(String label) {
    final isSelected = _selectedAudioSpeed == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAudioSpeed = label;
          });
          _showStatusMessage('Velocidad $label seleccionada');
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7E57C2) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7E57C2)
                  : const Color(0xFFD8C8F5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF9575CD,
                ).withOpacity(isSelected ? 0.2 : 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF5B3E8A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(String label) {
    final isSelected = _selectedSignLevel == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSignLevel = label;
          });
          _showStatusMessage('Nivel $label seleccionado');
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7E57C2) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7E57C2)
                  : const Color(0xFFD4C4F2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF9575CD,
                ).withOpacity(isSelected ? 0.18 : 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF424242),
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF7E57C2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
