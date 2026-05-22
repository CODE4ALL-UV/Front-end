import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────
//  MODELOS DE DATOS
// ─────────────────────────────────────────────────────────────

enum ActivityStatus { completed, active, locked }

enum ActivityType {
  tema,
  capsula,
  ejemplo,
  ejercicio,
  quiz,
  lab,
  evaluacion,
  buenaPractica,
}

class LessonData {
  final int number;
  final String title;
  final double progress; // 0.0 a 1.0
  final IconData icon;
  final Color iconColor;
  final bool isActive;
  final List<ActivityData> activities;

  const LessonData({
    required this.number,
    required this.title,
    required this.progress,
    required this.icon,
    required this.iconColor,
    this.isActive = false,
    required this.activities,
  });
}

class ActivityData {
  final int number;
  final String name;
  final String duration;
  final ActivityStatus status;
  final ActivityType type;
  final List<String> resourceIcons;

  const ActivityData({
    required this.number,
    required this.name,
    required this.duration,
    required this.status,
    required this.type,
    this.resourceIcons = const [],
  });
}

// ─────────────────────────────────────────────────────────────
//  DATOS DEL MÓDULO (aquí puedes cambiar el progreso)
// ─────────────────────────────────────────────────────────────

const List<LessonData> moduleLessons = [
  LessonData(
    number: 3,
    title: 'El factor inglés',
    progress: 0.75,
    icon: Icons.account_tree_rounded,
    iconColor: Color(0xFFF97316),
    activities: [],
  ),
  LessonData(
    number: 2,
    title: 'El entorno',
    progress: 0.60,
    icon: Icons.manage_search_rounded,
    iconColor: Color(0xFFA78BFA),
    activities: [],
  ),
  LessonData(
    number: 1,
    title: 'Conociendo\nPython',
    progress: 0.30,
    icon: Icons.code_rounded,
    iconColor: Color(0xFF818CF8),
    isActive: true,
    activities: [
      ActivityData(
        number: 1,
        name: 'Relevancia del lenguaje Python',
        duration: '5 min',
        status: ActivityStatus.completed,
        type: ActivityType.tema,
        resourceIcons: ['📚', '🖥️', '🎧'],
      ),
      ActivityData(
        number: 2,
        name: 'Cápsula de conocimiento',
        duration: '3 min',
        status: ActivityStatus.completed,
        type: ActivityType.capsula,
        resourceIcons: ['🎁'],
      ),
      ActivityData(
        number: 3,
        name: 'Ejemplo práctico',
        duration: '8 min',
        status: ActivityStatus.completed,
        type: ActivityType.ejemplo,
        resourceIcons: ['💡'],
      ),
      ActivityData(
        number: 4,
        name: 'Descarga y puesta en marcha',
        duration: '10 min',
        status: ActivityStatus.active,
        type: ActivityType.tema,
        resourceIcons: ['📚', '🖥️', '🎧'],
      ),
      ActivityData(
        number: 5,
        name: 'Cápsula de conocimiento',
        duration: '3 min',
        status: ActivityStatus.locked,
        type: ActivityType.capsula,
        resourceIcons: ['🎁'],
      ),
      ActivityData(
        number: 6,
        name: 'Ejercicio aplicado',
        duration: '15 min',
        status: ActivityStatus.locked,
        type: ActivityType.ejercicio,
        resourceIcons: [],
      ),
      ActivityData(
        number: 7,
        name: 'Preparando la versión instalada',
        duration: '8 min',
        status: ActivityStatus.locked,
        type: ActivityType.tema,
        resourceIcons: ['📚', '🖥️', '🎧'],
      ),
      ActivityData(
        number: 8,
        name: 'Nombre de la buena práctica',
        duration: '5 min',
        status: ActivityStatus.locked,
        type: ActivityType.buenaPractica,
        resourceIcons: ['🏅'],
      ),
      ActivityData(
        number: 9,
        name: 'Quiz parcial',
        duration: '10 min',
        status: ActivityStatus.locked,
        type: ActivityType.quiz,
        resourceIcons: [],
      ),
      ActivityData(
        number: 10,
        name: 'Laboratorio Python',
        duration: '20 min',
        status: ActivityStatus.locked,
        type: ActivityType.lab,
        resourceIcons: [],
      ),
      ActivityData(
        number: 11,
        name: 'Evaluación final del capítulo',
        duration: '15 min',
        status: ActivityStatus.locked,
        type: ActivityType.evaluacion,
        resourceIcons: [],
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
//  CONSTANTES DE COLOR
// ─────────────────────────────────────────────────────────────

const _bgDeep = Color(0xFF1A1A1A);
const _bgCard = Color(0xFF252525);
const _bgCardActive = Color(0xFF1E2040);
const _borderDefault = Color(0xFF1F2937);
const _borderActive = Color(0xFF3B3F99);
const _borderTop = Color(0xFF333333);
const _textPrimary = Color(0xFFE2E8F0);
const _textMuted = Color(0xFF6B7280);
const _textAccent = Color(0xFF818CF8);
const _blue = Color(0xFF1D4ED8);
const _blueSoft = Color(0xFF3B82F6);
const _moduleGradientStart = Color(0xFF1565C0);
const _moduleGradientEnd   = Color(0xFF0D47A1);

// ─────────────────────────────────────────────────────────────
//  PANTALLA PRINCIPAL — MÓDULO
// ─────────────────────────────────────────────────────────────

class ModuloAprendizajeDark extends StatelessWidget {
  const ModuloAprendizajeDark({super.key});

  // Progreso total del módulo (promedio de lecciones)
  double get _moduleProgress {
    final total = moduleLessons.fold(0.0, (sum, l) => sum + l.progress);
    return total / moduleLessons.length;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final circleSize = screenW * 0.40;

    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                children: [
                  // ── Card Módulo ──
                  _ModuleHeaderCard(progress: _moduleProgress),
                  const SizedBox(height: 24),

                  // ── Lección 3 (círculo izq, caja der) ──
                  _LessonRow(
                    lesson: moduleLessons[0],
                    circleSize: circleSize,
                    circleOnLeft: true,
                    onTap: null,
                  ),
                  const SizedBox(height: 16),

                  // ── Lección 2 (caja izq, círculo der) ──
                  _LessonRow(
                    lesson: moduleLessons[1],
                    circleSize: circleSize,
                    circleOnLeft: false,
                    onTap: null,
                  ),
                  const SizedBox(height: 16),

                  // ── Lección 1 — ACTIVA y NAVEGABLE ──
                  _LessonRow(
                    lesson: moduleLessons[2],
                    circleSize: circleSize,
                    circleOnLeft: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, anim, __) =>
                              CapituloDetalleDark(lesson: moduleLessons[2]),
                          transitionsBuilder: (_, anim, __, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                  parent: anim, curve: Curves.easeOutCubic)),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Barra inferior info + accesibilidad ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                // Botón accesibilidad
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4338CA),
                    shape: BoxShape.circle,
                    border: Border.all(color: _textAccent, width: 1),
                  ),
                  child: const Icon(Icons.accessibility_new_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  '${moduleLessons.length} lecciones · Módulo 1',
                  style: const TextStyle(color: _textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CARD DEL HEADER DEL MÓDULO
// ─────────────────────────────────────────────────────────────

class _ModuleHeaderCard extends StatelessWidget {
  final double progress;
  const _ModuleHeaderCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_moduleGradientStart, _moduleGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3A6E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'MÓDULO 1',
                  style: TextStyle(
                    color: _blueSoft.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Preparación',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ]),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A6E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF2D5299), width: 1),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: _blueSoft, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso general',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                    color: _blueSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFF0A1A3A),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_blueSoft),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FILA DE LECCIÓN (círculo + caja)
// ─────────────────────────────────────────────────────────────

class _LessonRow extends StatelessWidget {
  final LessonData lesson;
  final double circleSize;
  final bool circleOnLeft;
  final VoidCallback? onTap;

  const _LessonRow({
    required this.lesson,
    required this.circleSize,
    required this.circleOnLeft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final circle = _ProgressCircle(
      lesson: lesson,
      size: circleSize,
    );

    final box = _LessonBox(
      lesson: lesson,
      onTap: onTap,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: circleOnLeft
          ? [circle, const SizedBox(width: 12), Expanded(child: box)]
          : [Expanded(child: box), const SizedBox(width: 12), circle],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CÍRCULO DE PROGRESO DINÁMICO
// ─────────────────────────────────────────────────────────────

class _ProgressCircle extends StatelessWidget {
  final LessonData lesson;
  final double size;

  const _ProgressCircle({required this.lesson, required this.size});

  // Colores del arco según progreso
  List<Color> get _arcColors {
    final p = lesson.progress;
    if (p < 0.33) {
      return [const Color(0xFF6366F1), const Color(0xFF818CF8)];
    } else if (p < 0.66) {
      return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    } else {
      return [const Color(0xFF3B82F6), const Color(0xFF6366F1)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (lesson.progress * 100).round();
    final innerSize = size * 0.68;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DynamicArcPainter(
          progress: lesson.progress,
          strokeWidth: size * 0.065,
          arcColors: _arcColors,
          trackColor: const Color(0xFF1E1E2E),
        ),
        child: Center(
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(lesson.icon, color: lesson.iconColor, size: size * 0.28),
                const SizedBox(height: 4),
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w700,
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

// ─────────────────────────────────────────────────────────────
//  CUSTOM PAINTER — arco dinámico con degradado
// ─────────────────────────────────────────────────────────────

class _DynamicArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> arcColors;
  final Color trackColor;

  const _DynamicArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.arcColors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Track (fondo del arco)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Arco de progreso con degradado sweep
    final sweepAngle = 2 * math.pi * progress;
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweepAngle,
      colors: arcColors,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Punto luminoso al final del arco
    final endAngle = -math.pi / 2 + sweepAngle;
    final dotX = center.dx + radius * math.cos(endAngle);
    final dotY = center.dy + radius * math.sin(endAngle);

    canvas.drawCircle(
      Offset(dotX, dotY),
      strokeWidth * 0.45,
      Paint()..color = arcColors.last,
    );
  }

  @override
  bool shouldRepaint(covariant _DynamicArcPainter old) =>
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
//  CAJA DE LECCIÓN
// ─────────────────────────────────────────────────────────────

class _LessonBox extends StatelessWidget {
  final LessonData lesson;
  final VoidCallback? onTap;

  const _LessonBox({required this.lesson, this.onTap});

  String get _progressLabel {
    final pct = (lesson.progress * 100).round();
    if (lesson.isActive) return 'En progreso · $pct%';
    if (lesson.progress >= 1.0) return 'Completado';
    return '$pct% completado';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = lesson.isActive;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _bgCardActive : _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? _borderActive : _borderDefault,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Número en círculo
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? _blue : const Color(0xFF374151),
              ),
              child: Center(
                child: Text(
                  '${lesson.number}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive ? Colors.white : _textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _progressLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? _textAccent : _textMuted,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Ver capítulo →',
                      style: TextStyle(
                          fontSize: 10,
                          color: _textAccent,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.chevron_right_rounded,
                  color: _textAccent, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PANTALLA DETALLE — CAPÍTULO
// ─────────────────────────────────────────────────────────────

class CapituloDetalleDark extends StatefulWidget {
  final LessonData lesson;
  const CapituloDetalleDark({super.key, required this.lesson});

  @override
  State<CapituloDetalleDark> createState() => _CapituloDetalleState();
}

class _CapituloDetalleState extends State<CapituloDetalleDark> {
  bool _resumenExpanded = true;
  bool _rutaExpanded = true;

  int get _completedCount => widget.lesson.activities
      .where((a) => a.status == ActivityStatus.completed)
      .length;

  int get _totalCount => widget.lesson.activities.length;

  double get _progress =>
      _totalCount == 0 ? 0 : _completedCount / _totalCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: _buildDetailAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              child: Column(
                children: [
                  _buildChapterHeader(),
                  const SizedBox(height: 12),
                  _buildCollapsibleCard(
                    title: 'Resumen del capítulo',
                    icon: Icons.info_outline_rounded,
                    iconBgColor: const Color(0xFF1A2E4A),
                    iconColor: const Color(0xFF60A5FA),
                    expanded: _resumenExpanded,
                    onToggle: () =>
                        setState(() => _resumenExpanded = !_resumenExpanded),
                    child: _buildResumenContent(),
                  ),
                  const SizedBox(height: 12),
                  _buildCollapsibleCard(
                    title: 'Ruta de actividades',
                    icon: Icons.route_rounded,
                    iconBgColor: const Color(0xFF1A3A2A),
                    iconColor: const Color(0xFF34D399),
                    subtitle: '$_completedCount/$_totalCount completadas',
                    expanded: _rutaExpanded,
                    onToggle: () =>
                        setState(() => _rutaExpanded = !_rutaExpanded),
                    progressValue: _progress,
                    child: _buildActivityList(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4338CA),
                  shape: BoxShape.circle,
                  border: Border.all(color: _textAccent, width: 1),
                ),
                child: const Icon(Icons.accessibility_new_rounded,
                    color: Colors.white, size: 24),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildDetailAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bgDeep,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('CODE4ALL',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 2)),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: _borderTop, height: 1),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _blue,
                  border: Border.all(color: _blueSoft, width: 1)),
              child: const Center(
                child: Text('S',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildChapterHeader() {
    final pct = (widget.lesson.progress * 100).round();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_moduleGradientStart, _moduleGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3A6E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _blue.withOpacity(0.4), width: 1),
              ),
              child: const Text('Capítulo 1',
                  style: TextStyle(
                      color: _blueSoft, fontSize: 10, letterSpacing: 1)),
            ),
            const Spacer(),
            // Círculo de progreso mini en el header
            SizedBox(
              width: 52,
              height: 52,
              child: CustomPaint(
                painter: _DynamicArcPainter(
                  progress: widget.lesson.progress,
                  strokeWidth: 5,
                  arcColors: const [Color(0xFF3B82F6), Color(0xFF6366F1)],
                  trackColor: const Color(0xFF1E3A6E),
                ),
                child: Center(
                  child: Text(
                    '$pct%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            widget.lesson.title.replaceAll('\n', ' '),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _StatMini(icon: Icons.list_rounded, value: '5', label: 'Temas'),
            const SizedBox(width: 8),
            _StatMini(
                icon: Icons.inventory_2_outlined,
                value: '2',
                label: 'Cápsulas'),
            const SizedBox(width: 8),
            _StatMini(
                icon: Icons.edit_outlined, value: '3', label: 'Ejercicios'),
            const SizedBox(width: 8),
            _StatMini(
                icon: Icons.task_alt_outlined, value: '1', label: 'Quiz'),
          ]),
        ],
      ),
    );
  }

  Widget _buildCollapsibleCard({
    required String title,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
    String? subtitle,
    double? progressValue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderDefault, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        if (subtitle != null)
                          Text(subtitle,
                              style: const TextStyle(
                                  color: _textMuted, fontSize: 11)),
                      ]),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _textMuted,
                  size: 22,
                ),
              ]),
            ),
          ),
          if (progressValue != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Progreso',
                      style: TextStyle(color: _textMuted, fontSize: 11)),
                  Text('${(progressValue * 100).round()}%',
                      style: const TextStyle(
                          color: _blueSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF1E1E2E),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_blueSoft),
                  ),
                ),
              ]),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(children: [
              const Divider(height: 1, color: _borderDefault),
              child,
            ]),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenContent() {
    final items = [
      (Icons.list_rounded, '5 Temas', const Color(0xFF60A5FA)),
      (Icons.inventory_2_outlined, '2 Cápsulas', const Color(0xFFA78BFA)),
      (Icons.edit_outlined, '3 Ejercicios', const Color(0xFFFB923C)),
      (Icons.task_alt_outlined, '1 Quiz parcial', const Color(0xFF34D399)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: items
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: e.$3.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(e.$1, color: e.$3, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Text(e.$2,
                        style: const TextStyle(
                            color: _textPrimary, fontSize: 13)),
                  ]),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: List.generate(widget.lesson.activities.length, (i) {
        final act = widget.lesson.activities[i];
        final isLast = i == widget.lesson.activities.length - 1;
        return _ActivityTile(activity: act, isLast: isLast);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TILE DE ACTIVIDAD
// ─────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final ActivityData activity;
  final bool isLast;

  const _ActivityTile({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isActive = activity.status == ActivityStatus.active;
    final isCompleted = activity.status == ActivityStatus.completed;
    final isLocked = activity.status == ActivityStatus.locked;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E2A1E) : Colors.transparent,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF1F2937), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          _ActivityIndicator(status: activity.status, number: activity.number),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                activity.name,
                style: TextStyle(
                  color: isLocked ? _textMuted : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Row(children: [
                _TypePill(type: activity.type),
                const SizedBox(width: 6),
                Text(
                  activity.duration,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF34D399)
                        : _textMuted,
                    fontSize: 10,
                  ),
                ),
              ]),
            ]),
          ),
          if (activity.resourceIcons.isNotEmpty)
            Row(
              children: activity.resourceIcons
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(e, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
            ),
          const SizedBox(width: 4),
          if (isLocked)
            const Icon(Icons.lock_outline_rounded, color: Color(0xFF374151), size: 15),
          if (isCompleted)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF1D4ED8), size: 16),
          if (isActive)
            const Icon(Icons.play_circle_filled_rounded,
                color: Color(0xFFF97316), size: 16),
        ]),
      ),
    );
  }
}

class _ActivityIndicator extends StatelessWidget {
  final ActivityStatus status;
  final int number;
  const _ActivityIndicator({required this.status, required this.number});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ActivityStatus.completed:
        return Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: Color(0xFF1D4ED8), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        );
      case ActivityStatus.active:
        return Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: Color(0xFFF97316), shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 16),
        );
      case ActivityStatus.locked:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF374151), width: 1.5),
          ),
          child: Center(
            child: Text('$number',
                style: const TextStyle(
                    color: _textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        );
    }
  }
}

class _TypePill extends StatelessWidget {
  final ActivityType type;
  const _TypePill({required this.type});

  (String, Color, Color) get _cfg {
    switch (type) {
      case ActivityType.tema:
        return ('Tema', const Color(0xFF1A2E4A), const Color(0xFF60A5FA));
      case ActivityType.capsula:
        return ('Cápsula', const Color(0xFF2E1A4A), const Color(0xFFA78BFA));
      case ActivityType.ejemplo:
        return ('Ejemplo', const Color(0xFF2E2A1A), const Color(0xFFFBBF24));
      case ActivityType.ejercicio:
        return ('Ejercicio', const Color(0xFF2E1A1A), const Color(0xFFFB923C));
      case ActivityType.quiz:
        return ('Quiz', const Color(0xFF1A2E3A), const Color(0xFF60A5FA));
      case ActivityType.lab:
        return ('Lab', const Color(0xFF1A3A2A), const Color(0xFF34D399));
      case ActivityType.evaluacion:
        return ('Evaluación', const Color(0xFF3A1A1A), const Color(0xFFF87171));
      case ActivityType.buenaPractica:
        return ('Buena práctica', const Color(0xFF1A2E1A), const Color(0xFF86EFAC));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _cfg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STAT MINI (header capítulo)
// ─────────────────────────────────────────────────────────────

class _StatMini extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatMini(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white60, size: 15),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 8),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HELPERS COMPARTIDOS
// ─────────────────────────────────────────────────────────────

AppBar _buildAppBar() {
  return AppBar(
    backgroundColor: _bgDeep,
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.all(10.0),
      child: Image.asset('assets/images/logoUV_Oficial_Rojo.png'),
    ),
    title: const Text('CODE4ALL',
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
            letterSpacing: 2)),
    centerTitle: true,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(color: _borderTop, height: 1),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blue,
                border: Border.all(color: _blueSoft, width: 1)),
            child: const Center(
              child: Text('S',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Sheher',
              style: TextStyle(color: _textMuted, fontSize: 12)),
          const SizedBox(width: 4),
        ]),
      ),
    ],
  );
}

Widget _buildBottomNav() {
  return Container(
    color: _bgDeep,
    height: 60,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Icon(Icons.skip_previous_rounded, color: Color(0xFF475569), size: 26),
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
        ),
        const Icon(Icons.skip_next_rounded, color: Color(0xFF475569), size: 26),
      ],
    ),
  );
}