import 'dart:math' as math;

enum EstadoPostura { naoVisivel, alinhada, precisaAjuste }

class PontoCorporal {
  const PontoCorporal({
    required this.x,
    required this.y,
    required this.confianca,
  });

  final double x;
  final double y;
  final double confianca;
}

class AvaliacaoPostura {
  const AvaliacaoPostura._({
    required this.estado,
    required this.confiancaDosPontos,
    this.desalinhamentoGraus,
  });

  static const confiancaMinima = 0.5;
  static const desalinhamentoMaximoGraus = 15.0;

  static const naoVisivel = AvaliacaoPostura._(
    estado: EstadoPostura.naoVisivel,
    confiancaDosPontos: 0,
  );

  final EstadoPostura estado;
  final double confiancaDosPontos;
  final double? desalinhamentoGraus;

  factory AvaliacaoPostura.calcular({
    required PontoCorporal? orelha,
    required PontoCorporal? ombro,
  }) {
    if (!_pontoEhValido(orelha) || !_pontoEhValido(ombro)) {
      return naoVisivel;
    }

    final diferencaVertical = (ombro!.y - orelha!.y).abs();
    if (diferencaVertical < 1) {
      return naoVisivel;
    }

    final desalinhamentoGraus =
        math.atan2((orelha.x - ombro.x).abs(), diferencaVertical) *
        180 /
        math.pi;
    final confiancaDosPontos = math.min(
      orelha.confianca,
      ombro.confianca,
    );

    return AvaliacaoPostura._(
      estado: desalinhamentoGraus > desalinhamentoMaximoGraus
          ? EstadoPostura.precisaAjuste
          : EstadoPostura.alinhada,
      confiancaDosPontos: confiancaDosPontos,
      desalinhamentoGraus: desalinhamentoGraus,
    );
  }

  static bool _pontoEhValido(PontoCorporal? ponto) {
    return ponto != null &&
        ponto.x.isFinite &&
        ponto.y.isFinite &&
        ponto.confianca.isFinite &&
        ponto.confianca >= confiancaMinima &&
        ponto.confianca <= 1;
  }
}
