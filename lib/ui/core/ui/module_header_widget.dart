//REFACTOR-APROVED x 2 - COLOR TEST REMAINING - DONT TESTED IN UI YET
import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor_screen.dart';

class ModuleHeaderWidget extends StatelessWidget {
  final String moduleName;
  final bool isTeacher;
  final Function(String?) onEditCompleted;

  const ModuleHeaderWidget({
    super.key,
    required this.moduleName,
    required this.isTeacher,
    required this.onEditCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moduleName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Preparación',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (isTeacher)
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherModuleEditor(),
                        ),
                      );
                      onEditCompleted(result as String?);
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          //Row(
          //children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.asset(
                'assets/images/logoUV_Gris1.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          //],
          //),
        ],
      ),
    );
  }
}
