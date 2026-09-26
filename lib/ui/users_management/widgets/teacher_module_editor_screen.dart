import 'dart:convert';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';

class TeacherModuleEditor extends StatefulWidget {
  final String? moduleId;
  const TeacherModuleEditor({super.key, this.moduleId});

  @override
  State<TeacherModuleEditor> createState() => _TeacherModuleEditorState();
}

class _TeacherModuleEditorState extends State<TeacherModuleEditor> {
  static const String _defaultModuleId =
      '1'; // ID del módulo por defecto si no se proporciona uno

  final _nameCtrl = TextEditingController();
  final List<TextEditingController> _topicCtrls = [];
  bool _loading = false;
  String? _moduleId;

  String get backendUrl => ApiService().baseUrl;

  /// El nombre de fábrica de este módulo, el que ve el estudiante si nadie
  /// lo ha cambiado.
  String _catalogTitle() {
    final number = int.tryParse(_moduleId ?? '');
    if (number == null) return '';
    return PythonCourseCatalog.moduleByNumber(number)?.title ?? '';
  }

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
    for (final c in _topicCtrls) {
      c.dispose();
    }
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
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _nameCtrl.text = data['name'] ?? '';
        final topics = (data['topics'] as List<dynamic>? ?? []).cast<String>();
        _topicCtrls.clear();
        for (final t in topics) {
          _addTopic(t);
        }
      } else if (res.statusCode == 404) {
        // Este módulo no se ha editado nunca: es el estado normal la primera
        // vez, no un fallo. Se parte del nombre del temario para que el
        // docente corrija en lugar de escribirlo desde cero.
        _nameCtrl.text = _catalogTitle();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar el módulo')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
      // El servidor comprueba por su cuenta que quien guarda sea docente: no
      // se fía del rol que diga la aplicación, porque el dispositivo podría
      // mentir. Sin este token la respuesta es un 401.
      final token = await AuthStorage().getToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu sesión no está iniciada. Vuelve a entrar.'),
          ),
        );
        return;
      }

      final payload = {
        'module_id': _moduleId ?? _defaultModuleId,
        'name': name,
        'topics': topics,
      };
      final res = await http.post(
        Uri.parse('$backendUrl/api/modules/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      if (!mounted) return;
      if (res.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu sesión caducó. Vuelve a entrar.')),
        );
      } else if (res.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu cuenta no puede editar el contenido del curso.'),
          ),
        );
      } else if (res.statusCode == 201) {
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBarWidget(
        userName: '', //widget.userName,
        onLogout: null, //widget.onLogout,
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
