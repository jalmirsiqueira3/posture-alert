import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../componentes/aviso_privacidade.dart';
import '../componentes/cartao_status.dart';
import '../componentes/previa_camera.dart';
import '../dominio/avaliacao_postura.dart';
import '../servicos/servico_monitoramento.dart';

class TelaMonitoramento extends StatefulWidget {
  const TelaMonitoramento({super.key});

  @override
  State<TelaMonitoramento> createState() => _EstadoTelaMonitoramento();
}

class _EstadoTelaMonitoramento extends State<TelaMonitoramento>
    with WidgetsBindingObserver {
  final ServicoMonitoramento _servico = ServicoMonitoramento();
  DateTime? _desvioDesde;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _servico.addListener(_aoAtualizarMonitoramento);
  }

  void _aoAtualizarMonitoramento() {
    if (_servico.avaliacao.estado == EstadoPostura.precisaAjuste) {
      _desvioDesde ??= DateTime.now();

      final desvioPersistente = DateTime.now().difference(_desvioDesde!) >= const Duration(seconds: 2);

      if(desvioPersistente) {
        HapticFeedback.heavyImpact();
      }
    } else {
      _desvioDesde = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.inactive ||
        estado == AppLifecycleState.paused) {
      unawaited(_servico.pausar());
    } else if (estado == AppLifecycleState.resumed &&
        _servico.monitoramentoSolicitado &&
        _servico.controladorCamera == null) {
      unawaited(_servico.iniciar());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _servico.removeListener(_aoAtualizarMonitoramento);
    _servico.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = _servico.estadoCamera;

    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientacao) {
            if (orientacao == Orientation.landscape) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: PreviaCamera(
                        controlador: _servico.controladorCamera,
                        estado: estado,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: _construirPainel(context, estado),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _construirInstrucoes(context),
                const SizedBox(height: 14),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.4,
                  child: PreviaCamera(
                    controlador: _servico.controladorCamera,
                    estado: estado,
                  ),
                ),
                const SizedBox(height: 16),
                _construirPainel(context, estado, incluirInstrucoes: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _construirInstrucoes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posture Alert',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Fique de perfil para a câmera e mantenha a orelha e o ombro visíveis.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _construirPainel(
    BuildContext context,
    EstadoCamera estado, {
    bool incluirInstrucoes = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (incluirInstrucoes) ...[
          _construirInstrucoes(context),
          const SizedBox(height: 16),
        ],
        _construirCartaoStatus(),
        const SizedBox(height: 16),
        if (estado == EstadoCamera.ativo)
          FilledButton.icon(
            onPressed: _servico.parar,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Parar monitoramento'),
          )
        else
          FilledButton.icon(
            onPressed: estado == EstadoCamera.iniciando
                ? null
                : _servico.iniciar,
            icon: estado == EstadoCamera.iniciando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: Text(
              estado == EstadoCamera.iniciando
                  ? 'Iniciando câmera...'
                  : estado == EstadoCamera.erro
                  ? 'Tentar novamente'
                  : 'Iniciar monitoramento',
            ),
          ),
        const SizedBox(height: 12),
        const AvisoPrivacidade(),
      ],
    );
  }

  Widget _construirCartaoStatus() {
    if (_servico.erroCamera != null) {
      return CartaoStatus(
        titulo: 'Não foi possível iniciar a câmera',
        descricao: _servico.erroCamera!,
        tipo: TipoAviso.erro,
      );
    }
    if (_servico.estadoCamera == EstadoCamera.iniciando) {
      return const CartaoStatus(
        titulo: 'Iniciando monitoramento',
        descricao: 'Aguarde enquanto a câmera é preparada.',
        tipo: TipoAviso.informacao,
      );
    }
    if (_servico.estadoCamera != EstadoCamera.ativo) {
      return const CartaoStatus(
        titulo: 'Monitoramento pausado',
        descricao:
            'Inicie quando estiver pronto. A câmera só será usada com sua autorização.',
        tipo: TipoAviso.informacao,
      );
    }
    if (_servico.erroAnalise != null) {
      return CartaoStatus(
        titulo: 'Não foi possível analisar a imagem',
        descricao: _servico.erroAnalise!,
        tipo: TipoAviso.erro,
      );
    }
    if (_servico.avaliacao.estado == EstadoPostura.naoVisivel) {
      return const CartaoStatus(
        titulo: 'Ajuste o enquadramento',
        descricao: 'Fique de perfil e mantenha a orelha e o ombro visíveis.',
        tipo: TipoAviso.orientacao,
      );
    }
    if (_servico.avaliacao.estado == EstadoPostura.precisaAjuste) {
      final desvioPersistente =
          _desvioDesde != null &&
          DateTime.now().difference(_desvioDesde!) >=
              const Duration(seconds: 2);
      return desvioPersistente
          ? const CartaoStatus(
              titulo: 'Alinhe a cabeça com o ombro',
              descricao:
                  'A orelha parece deslocada em relação ao ombro. Ajuste-se sem forçar o corpo.',
              tipo: TipoAviso.orientacao,
            )
          : const CartaoStatus(
              titulo: 'Desalinhamento observado',
              descricao: 'Verificando se a posição persiste...',
              tipo: TipoAviso.informacao,
            );
    }
    return const CartaoStatus(
      titulo: 'Postura alinhada',
      descricao: 'Nenhum desvio persistente foi observado neste momento.',
      tipo: TipoAviso.sucesso,
    );
  }
}
