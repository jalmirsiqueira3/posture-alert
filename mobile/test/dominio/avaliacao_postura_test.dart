import 'package:flutter_test/flutter_test.dart';
import 'package:posture_alert/dominio/avaliacao_postura.dart';

void main() {
  group('AvaliacaoPostura.calcular', () {
    test('considera alinhados orelha e ombro na mesma linha vertical', () {
      final resultado = avaliar(orelhaX: 40, ombroX: 40);

      expect(resultado.estado, EstadoPostura.alinhada);
      expect(resultado.desalinhamentoGraus, 0);
    });

    test('detecta deslocamento da orelha em qualquer lado', () {
      final paraDireita = avaliar(orelhaX: 70, ombroX: 40);
      final paraEsquerda = avaliar(orelhaX: 10, ombroX: 40);

      expect(paraDireita.estado, EstadoPostura.precisaAjuste);
      expect(paraEsquerda.estado, EstadoPostura.precisaAjuste);
    });

    test('aceita o limite de desalinhamento de 15 graus', () {
      final resultado = avaliar(orelhaX: 40 + 100 * 0.267949, ombroX: 40);

      expect(resultado.estado, EstadoPostura.alinhada);
    });

    test('avalia usando apenas a orelha e o ombro', () {
      final resultado = AvaliacaoPostura.calcular(
        orelha: ponto(40, 10),
        ombro: ponto(40, 110),
      );

      expect(resultado.estado, EstadoPostura.alinhada);
    });

    test('rejeita orelha ou ombro ausentes', () {
      final resultado = AvaliacaoPostura.calcular(
        orelha: ponto(40, 10),
        ombro: null,
      );

      expect(resultado.estado, EstadoPostura.naoVisivel);
    });

    test('rejeita pontos abaixo da confiança mínima', () {
      final resultado = AvaliacaoPostura.calcular(
        orelha: ponto(40, 10),
        ombro: ponto(40, 110, confianca: 0.49),
      );

      expect(resultado.estado, EstadoPostura.naoVisivel);
    });

    test('rejeita pontos sem separação vertical', () {
      final resultado = AvaliacaoPostura.calcular(
        orelha: ponto(40, 10),
        ombro: ponto(50, 10),
      );

      expect(resultado.estado, EstadoPostura.naoVisivel);
    });
  });
}

AvaliacaoPostura avaliar({required double orelhaX, required double ombroX}) {
  return AvaliacaoPostura.calcular(
    orelha: ponto(orelhaX, 10),
    ombro: ponto(ombroX, 110),
  );
}

PontoCorporal ponto(double x, double y, {double confianca = 0.9}) {
  return PontoCorporal(x: x, y: y, confianca: confianca);
}
