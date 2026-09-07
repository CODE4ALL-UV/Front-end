import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TeacherModuleEditor extends StatefulWidget {
  final String? moduleId;
  const TeacherModuleEditor({super.key, this.moduleId});

  @override
  State<TeacherModuleEditor> createState() => _TeacherModuleEditorState();
}

class _TeacherModuleEditorState extends State<TeacherModuleEditor> {
  static const String _defaultModuleId = 'default-module';

  final _nameCtrl = TextEditingController();
  final List<TextEditingController> _topicCtrls = [];
  bool _loading = false;
  String? _moduleId;

  String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    _moduleId = widget.moduleId ?? _defaultModuleId;
    if (_moduleId != null) _loadModule();
    if (_topicCtrls.isEmpty) _addTopic();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _topicCtrls) c.dispose();
    super.dispose();
  }

  void _addTopic([String? value]) {
    final c = TextEditingController(text: value ?? '');
    setState(() => _topicCtrls.add(c));
  }

  void _removeTopic(int i) {
    setState(() {
      _topicCtrls.removeAt(i).dispose();
    });
  }

  Future<void> _loadModule() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$backendUrl/api/modules/$_moduleId'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _nameCtrl.text = data['name'] ?? '';
        final topics = (data['topics'] as List<dynamic>? ?? []).cast<String>();
        _topicCtrls.clear();
        for (final t in topics) _addTopic(t);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar el módulo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final topics = _topicCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del módulo es requerido')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'module_id': _moduleId ?? _defaultModuleId,
        'name': name,
        'topics': topics,
      };
      final res = await http.post(
        Uri.parse('$backendUrl/api/modules/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final savedId = (data['id'] ?? _moduleId ?? _defaultModuleId)
            .toString();
        setState(() => _moduleId = savedId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Módulo guardado')));
        Navigator.of(context).pop(savedId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar módulo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_moduleId == null ? 'Crear Módulo' : 'Editar Módulo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del módulo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Temas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_topicCtrls.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _topicCtrls[i],
                              decoration: InputDecoration(
                                labelText: 'Tema ${i + 1}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeTopic(i),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addTopic,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar tema'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Guardar información del módulo'),
                  ),
                ],
              ),
            ),
    );
  }
}
