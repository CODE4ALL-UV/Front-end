import 'package:flutter/material.dart';

class WelcomePageLight extends StatefulWidget {
  final VoidCallback? onStart;
  const WelcomePageLight({super.key, this.onStart});

  @override
  State<WelcomePageLight> createState() => _WelcomePageLightState();
}

class _WelcomePageLightState extends State<WelcomePageLight> {
  int _selectedLevel = 0; // 0 = Básico, 1 = Avanzado

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset('assets/images/logoUV_Oficial_Rojo.png'),
        ),
        title: const Text(
          'CODE4ALL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Icon(Icons.account_circle_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo-flutter.png',
                    height: 200,
                    width: 280,
                  ),
                  const SizedBox(height: 48),

                  // Botón EMPEZAR
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onStart ?? () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'EMPEZAR',
                          style: TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Selector de nivel
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Básico
                        GestureDetector(
                          onTap: () => setState(() => _selectedLevel = 0),
                          child: _LevelOption(
                            label: 'Básico',
                            stars: 1,
                            selected: _selectedLevel == 0,
                            selectedColor: const Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Avanzado
                        GestureDetector(
                          onTap: () => setState(() => _selectedLevel = 1),
                          child: _LevelOption(
                            label: 'Avanzado',
                            stars: 2,
                            selected: _selectedLevel == 1,
                            selectedColor: const Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ícono accesibilidad
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF5C6BC0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.accessibility_new, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),

      // Barra inferior
      bottomNavigationBar: Container(
        color: const Color(0xFFE53935),
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Icon(Icons.skip_previous, color: Colors.white, size: 28),
            Icon(Icons.play_arrow, color: Colors.white, size: 32),
            Icon(Icons.skip_next, color: Colors.white, size: 28),
            Icon(Icons.settings, color: Colors.white, size: 26),
          ],
        ),
      ),
    );
  }
}

class _LevelOption extends StatelessWidget {
  final String label;
  final int stars;
  final bool selected;
  final Color selectedColor;

  const _LevelOption({
    required this.label,
    required this.stars,
    required this.selected,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            stars,
            (i) => Icon(
              selected ? Icons.star : Icons.star_border,
              color: selected ? selectedColor : const Color(0xFF9E9E9E),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? selectedColor : const Color(0xFF9E9E9E),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}