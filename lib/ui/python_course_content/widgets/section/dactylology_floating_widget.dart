import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'sign_language_panel.dart';

/// Collapsible dactylology reader that floats above activity content.
class DactylologyFloatingWidget extends StatefulWidget {
  const DactylologyFloatingWidget({
    super.key,
    required this.text,
    this.showWordSigns = false,
  });

  final String text;
  final bool showWordSigns;

  @override
  State<DactylologyFloatingWidget> createState() =>
      _DactylologyFloatingWidgetState();
}

class _DactylologyFloatingWidgetState extends State<DactylologyFloatingWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width < 380 ? width - 32 : 340.0;
    final colors = context.messageColors;

    return Material(
      color: Colors.transparent,
      child: _expanded
          ? ConstrainedBox(
              constraints: BoxConstraints(maxWidth: panelWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sign_language,
                            color: colors.infoForeground,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Dactilología',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Ocultar lector de señas',
                            onPressed: () => setState(() => _expanded = false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    SignLanguagePanel(
                      text: widget.text,
                      showWordSigns: widget.showWordSigns,
                    ),
                  ],
                ),
              ),
            )
          : Semantics(
              button: true,
              label: 'Mostrar lector de dactilología',
              child: FloatingActionButton.small(
                heroTag: 'dactylology-reader',
                tooltip: 'Mostrar lector de dactilología',
                onPressed: () => setState(() => _expanded = true),
                child: const Icon(Icons.sign_language),
              ),
            ),
    );
  }
}
