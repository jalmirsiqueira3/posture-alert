import 'package:flutter/material.dart';

import 'telas/tela_monitoramento.dart';

class AplicativoPostureAlert extends StatelessWidget {
  const AplicativoPostureAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PostureAlert',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F73),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const TelaMonitoramento(),
    );
  }
}
