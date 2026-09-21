import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor_screen.dart';

class ModuleHeaderWidget extends StatelessWidget {
  final String moduleId;
  final String moduleTitle;
  final bool isTeacher;
  final Function(String?) onEditCompleted;

  const ModuleHeaderWidget({
    super.key,
    required this.moduleId,
    required this.moduleTitle,
    required this.isTeacher,
    required this.onEditCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final appModuleTheme = context.courseTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appModuleTheme.iconBackground,
            appModuleTheme.headerBackground,
          ],
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
                        'Módulo $moduleId',
                        style: TextStyle(
                          color: appModuleTheme.foregroundColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moduleTitle,
                        style: TextStyle(
                          color: appModuleTheme.foregroundColor,
                          fontSize: 14,
                        ),
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
                'assets/images/logoUV_Oficial_Blanco_1.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
