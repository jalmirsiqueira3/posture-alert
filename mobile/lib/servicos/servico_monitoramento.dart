import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dominio/avaliacao_postura.dart';
import 'analisador_postura.dart';

enum EstadoCamera { parado, iniciando, ativo, erro }

class ServicoMonitoramento extends ChangeNotifier {
  final AnalisadorPostura _analisador = AnalisadorPostura();
  CameraController? _controladorCamera;
  EstadoCamera _estadoCamera = EstadoCamera.parado;
  AvaliacaoPostura _avaliacao = AvaliacaoPostura.naoVisivel;
  String? _erroCamera;
  String? _erroAnalise;
  DateTime _ultimaAtualizacao = DateTime.fromMillisecondsSinceEpoch(0);
  bool _monitoramentoSolicitado = false;
  bool _iniciando = false;
  bool _processandoQuadro = false;
  bool _analiseFalhou = false;
  bool _descartado = false;

  EstadoCamera get estadoCamera => _estadoCamera;
  CameraController? get controladorCamera => _controladorCamera;
  AvaliacaoPostura get avaliacao => _avaliacao;
  String? get erroCamera => _erroCamera;
  String? get erroAnalise => _erroAnalise;
  bool get monitoramentoSolicitado => _monitoramentoSolicitado;

  Future<void> iniciar() async {
    if (_descartado || _iniciando || _estadoCamera == EstadoCamera.ativo) {
      return;
    }

    _monitoramentoSolicitado = true;
    _iniciando = true;
    _estadoCamera = EstadoCamera.iniciando;
    _erroCamera = null;
    _erroAnalise = null;
    _analiseFalhou = false;
    _notificarOuvintes();

    CameraController? candidato;
    try {
      final cameras = await availableCameras();
      if (_descartado) {
        return;
      }
      if (cameras.isEmpty) {
        await _informarErroCamera(
          null,
          'Nenhuma câmera foi encontrada neste dispositivo.',
        );
        return;
      }

      final camera = cameras.firstWhere(
        (descricao) => descricao.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      candidato = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await candidato.initialize();
      if (_descartado) {
        await candidato.dispose();
        return;
      }
      _controladorCamera = candidato;
      await candidato.startImageStream(_analisarQuadro);

      if (_descartado) {
        return;
      }
      _estadoCamera = EstadoCamera.ativo;
      _notificarOuvintes();
    } on CameraException catch (erro) {
      await _informarErroCamera(
        candidato,
        erro.description ?? 'Não foi possível iniciar a câmera (${erro.code}).',
      );
    } on PlatformException catch (erro) {
      await _informarErroCamera(
        candidato,
        erro.message ?? 'Não foi possível acessar a câmera.',
      );
    } on StateError catch (erro) {
      await _informarErroCamera(candidato, erro.message);
    } finally {
      _iniciando = false;
    }
  }

  Future<void> _informarErroCamera(
    CameraController? controlador,
    String mensagem,
  ) async {
    _monitoramentoSolicitado = false;
    if (identical(_controladorCamera, controlador)) {
      _controladorCamera = null;
    }
    await controlador?.dispose();
    if (_descartado) {
      return;
    }
    _estadoCamera = EstadoCamera.erro;
    _erroCamera = mensagem;
    _notificarOuvintes();
  }

  Future<void> pausar() async {
    final controlador = _controladorCamera;
    if (controlador == null) {
      return;
    }
    _controladorCamera = null;
    if (controlador.value.isStreamingImages) {
      await controlador.stopImageStream();
    }
    await controlador.dispose();
    if (_descartado) {
      return;
    }
    _estadoCamera = EstadoCamera.parado;
    _notificarOuvintes();
  }

  Future<void> parar() async {
    _monitoramentoSolicitado = false;
    final controlador = _controladorCamera;
    _controladorCamera = null;
    if (controlador != null) {
      if (controlador.value.isStreamingImages) {
        await controlador.stopImageStream();
      }
      await controlador.dispose();
    }
    if (_descartado) {
      return;
    }
    _estadoCamera = EstadoCamera.parado;
    _avaliacao = AvaliacaoPostura.naoVisivel;
    _erroAnalise = null;
    _analiseFalhou = false;
    _notificarOuvintes();
  }

  void _analisarQuadro(CameraImage quadro) {
    unawaited(_processarQuadro(quadro));
  }

  Future<void> _processarQuadro(CameraImage quadro) async {
    if (_descartado || _processandoQuadro || _analiseFalhou) {
      return;
    }
    final controlador = _controladorCamera;
    if (controlador == null) {
      return;
    }

    _processandoQuadro = true;
    try {
      final avaliacao = await _analisador.analisar(
        quadro,
        controlador.description,
        controlador.value.deviceOrientation,
      );
      if (!identical(_controladorCamera, controlador)) {
        return;
      }
      _publicarAvaliacao(avaliacao);
    } on FormatException catch (erro) {
      _informarErroAnalise(erro.message);
    } on PlatformException catch (erro) {
      _informarErroAnalise(
        erro.message ?? 'Ocorreu um erro ao analisar a imagem da câmera.',
      );
    } finally {
      _processandoQuadro = false;
    }
  }

  void _publicarAvaliacao(AvaliacaoPostura avaliacao) {
    final estadoMudou = _avaliacao.estado != avaliacao.estado;
    _avaliacao = avaliacao;
    final agora = DateTime.now();
    if (!estadoMudou &&
        agora.difference(_ultimaAtualizacao) <
            const Duration(milliseconds: 500)) {
      return;
    }
    _ultimaAtualizacao = agora;
    _notificarOuvintes();
  }

  void _informarErroAnalise(String mensagem) {
    if (_descartado) {
      return;
    }
    _analiseFalhou = true;
    _erroAnalise = mensagem;
    _notificarOuvintes();
  }

  void _notificarOuvintes() {
    if (!_descartado) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _monitoramentoSolicitado = false;
    final controlador = _controladorCamera;
    _controladorCamera = null;
    if (controlador != null) {
      unawaited(controlador.dispose());
    }
    unawaited(_analisador.close());
    super.dispose();
  }
}
