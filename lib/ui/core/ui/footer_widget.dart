import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pie de página corporativo. Proyecto de inclusión Code 4 All.',
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        color: Theme.of(context).cardColor,
        child: const Text(
          '© 2026 Code4All - Univalle Palmira',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ),
    );
  }
}
