import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/services/api_service.dart';
import '../../data/services/auth_storage.dart';
import '../core/ui/user_profile_menu.dart';

class DirectorPerformanceScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const DirectorPerformanceScreen({super.key, this.onLogout});

  @override
  State<DirectorPerformanceScreen> createState() =>
      _DirectorPerformanceScreenState();
}

class _DirectorPerformanceScreenState extends State<DirectorPerformanceScreen> {
  final ApiService _api = ApiService();
  final AuthStorage _storage = AuthStorage();

  List<Map<String, dynamic>> _aggregate = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final token = await _storage.getToken();
    try {
      if (token == null) throw Exception('No auth token');
      final rows = await _api.getPerformancesAverage(bearerToken: token);
      setState(() {
        _aggregate = List<Map<String, dynamic>>.from(
          rows.map((e) => Map<String, dynamic>.from(e)),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando datos: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendimiento de estudiantes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: UserProfileMenu(showName: true, onLogout: widget.onLogout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header / module card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Resumen',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.book, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chart-like card with progress bars
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Rendimiento estudiantil',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._aggregate.map((row) {
                            final lesson = row['lesson_name'] ?? '';
                            final scoreD = (row['avg_score'] ?? 0.0) as double;
                            final score = scoreD.round();
                            final pct = (score.clamp(0, 100)) / 100.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor: pct,
                                              child: Container(
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[600],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            width: 48,
                                            child: Text(
                                              '$score',
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          const Text(
                                            'Promedio',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Table-like card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // Table header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 6.0,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: const [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'Lección',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Puntaje',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Fallidos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Buenos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Excelentes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Export PDF button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onPressed: _aggregate.isEmpty ? null : _exportPdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Exportar reporte'),
                          ),
                          const SizedBox(height: 12),

                          // Table rows
                          Column(
                            children: _aggregate.map((r) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 6.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade100,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        r['lesson_name'] ?? '',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${(r['avg_score'] ?? 0.0).round()}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${(r['avg_failed'] ?? 0.0).round()}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${(r['avg_good'] ?? 0.0).round()}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${(r['avg_excellent'] ?? 0.0).round()}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  Widget _buildChart() {
    if (_aggregate.isEmpty) return const Center(child: Text('No hay datos'));
    // Representación simple: barras horizontales proporcionales al `score`.
    final maxScore = _aggregate
        .map((r) => ((r['avg_score'] ?? 0.0) as double).round())
        .fold<int>(0, (a, b) => a > b ? a : b);
    return ListView.separated(
      itemCount: _aggregate.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = _aggregate[index];
        final lesson = row['lesson_name'] ?? '';
        final score = ((row['avg_score'] ?? 0.0) as double).round();
        final pct = maxScore == 0 ? 0.0 : (score / maxScore);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  child: Text('$score', textAlign: TextAlign.right),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTable() {
    if (_aggregate.isEmpty)
      return const Center(child: Text('No hay registros'));

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Lección')),
            DataColumn(label: Text('Puntaje')),
            DataColumn(label: Text('Fallidos')),
            DataColumn(label: Text('Buenos')),
            DataColumn(label: Text('Excelentes')),
          ],
          rows: _aggregate.map((r) {
            return DataRow(
              cells: [
                DataCell(Text(r['lesson_name'] ?? '')),
                DataCell(
                  Text('${((r['avg_score'] ?? 0.0) as double).round()}'),
                ),
                DataCell(
                  Text('${((r['avg_failed'] ?? 0.0) as double).round()}'),
                ),
                DataCell(Text('${((r['avg_good'] ?? 0.0) as double).round()}')),
                DataCell(
                  Text('${((r['avg_excellent'] ?? 0.0) as double).round()}'),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    try {
      final doc = pw.Document();

      final now = DateTime.now();
      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Reporte - Rendimiento estudiantil',
                style: pw.TextStyle(fontSize: 18),
              ),
            ),
            pw.Text('Generado: ${now.toLocal()}'),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: [
                'Lección',
                'Puntaje',
                'Fallidos',
                'Buenos',
                'Excelentes',
              ],
              data: _aggregate.map((r) {
                final lesson = r['lesson_name'] ?? '';
                final avg = ((r['avg_score'] ?? 0.0) as double).round();
                final failed = ((r['avg_failed'] ?? 0.0) as double).round();
                final good = ((r['avg_good'] ?? 0.0) as double).round();
                final excellent = ((r['avg_excellent'] ?? 0.0) as double)
                    .round();
                return [lesson, '$avg', '$failed', '$good', '$excellent'];
              }).toList(),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exportando PDF: $e')));
    }
  }
}
