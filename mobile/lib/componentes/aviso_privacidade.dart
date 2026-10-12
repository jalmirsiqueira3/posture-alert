import 'package:flutter/material.dart';

class AvisoPrivacidade extends StatelessWidget {
  const AvisoPrivacidade({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'As imagens são analisadas no dispositivo e não são gravadas nem enviadas. '
      'Este protótipo não faz diagnóstico médico.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF53615D), fontSize: 12),
    );
  }
}
