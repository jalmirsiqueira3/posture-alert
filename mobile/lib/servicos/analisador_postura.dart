import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../dominio/avaliacao_postura.dart';

class AnalisadorPostura {
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  Future<AvaliacaoPostura> analisar(
    CameraImage quadro,
    CameraDescription camera,
    DeviceOrientation orientacaoDispositivo,
  ) async {
    final imagem = _converterImagem(quadro, camera, orientacaoDispositivo);
    if (imagem == null) {
      throw const FormatException(
        'Formato de imagem da câmera não compatível com a análise de pose.',
      );
    }

    final poses = await _detector.processImage(imagem);
    return poses.isEmpty
        ? AvaliacaoPostura.naoVisivel
        : _avaliarPose(poses.first);
  }

  InputImage? _converterImagem(
    CameraImage quadro,
    CameraDescription camera,
    DeviceOrientation orientacaoDispositivo,
  ) {
    final grausDispositivo = switch (orientacaoDispositivo) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };
    final rotacaoCompensada = Platform.isIOS
        ? (camera.sensorOrientation + grausDispositivo) % 360
        : (camera.sensorOrientation - grausDispositivo + 360) % 360;
    final rotacao = InputImageRotationValue.fromRawValue(rotacaoCompensada);
    final formato = InputImageFormatValue.fromRawValue(quadro.format.raw);
    final formatoEsperado = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;
    if (rotacao == null ||
        formato != formatoEsperado ||
        quadro.planes.length != 1) {
      return null;
    }

    final plano = quadro.planes.first;
    return InputImage.fromBytes(
      bytes: plano.bytes,
      metadata: InputImageMetadata(
        size: Size(quadro.width.toDouble(), quadro.height.toDouble()),
        rotation: rotacao,
        format: formato!,
        bytesPerRow: plano.bytesPerRow,
      ),
    );
  }

  AvaliacaoPostura _avaliarPose(Pose pose) {
    final pares = [
      (
        orelha: pose.landmarks[PoseLandmarkType.leftEar],
        ombro: pose.landmarks[PoseLandmarkType.leftShoulder],
      ),
      (
        orelha: pose.landmarks[PoseLandmarkType.rightEar],
        ombro: pose.landmarks[PoseLandmarkType.rightShoulder],
      ),
    ];
    final avaliacoes = pares
        .map(
          (par) => AvaliacaoPostura.calcular(
            orelha: _converterPonto(par.orelha),
            ombro: _converterPonto(par.ombro),
          ),
        )
        .where((avaliacao) => avaliacao.estado != EstadoPostura.naoVisivel);
    return avaliacoes.fold(
      AvaliacaoPostura.naoVisivel,
      (melhor, atual) =>
          atual.confiancaDosPontos > melhor.confiancaDosPontos ? atual : melhor,
    );
  }

  PontoCorporal? _converterPonto(PoseLandmark? ponto) {
    if (ponto == null) {
      return null;
    }
    return PontoCorporal(x: ponto.x, y: ponto.y, confianca: ponto.likelihood);
  }

  Future<void> close() => _detector.close();
}
