import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posture_alert/aplicativo.dart';
import 'package:posture_alert/componentes/previa_camera.dart';

void main() {
  testWidgets('mostra a tela sem pedir acesso à câmera ao abrir o app', (
    testador,
  ) async {
    await testador.pumpWidget(const AplicativoPostureAlert());

    expect(find.text('Posture Alert'), findsOneWidget);
    expect(
      testador.getSize(find.byType(PreviaCamera)).height,
      greaterThanOrEqualTo(240),
    );
    await testador.scrollUntilVisible(
      find.text('Iniciar monitoramento'),
      240,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Iniciar monitoramento'), findsOneWidget);
    expect(find.text('Monitoramento pausado'), findsOneWidget);
  });

  testWidgets('mostra a prévia ampla em orientação horizontal', (
    testador,
  ) async {
    testador.view.physicalSize = const Size(900, 500);
    testador.view.devicePixelRatio = 1;
    addTearDown(testador.view.resetPhysicalSize);
    addTearDown(testador.view.resetDevicePixelRatio);

    await testador.pumpWidget(const AplicativoPostureAlert());

    final tamanhoPrevia = testador.getSize(find.byType(PreviaCamera));
    expect(tamanhoPrevia.width, greaterThan(tamanhoPrevia.height));
    expect(tamanhoPrevia.width, greaterThan(400));
  });
}
