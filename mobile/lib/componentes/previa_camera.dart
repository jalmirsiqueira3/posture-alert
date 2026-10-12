import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../servicos/servico_monitoramento.dart';

class PreviaCamera extends StatelessWidget {
  const PreviaCamera({
    required this.controlador,
    required this.estado,
    super.key,
  });

  final CameraController? controlador;
  final EstadoCamera estado;

  @override
  Widget build(BuildContext context) {
    final aspecto = controlador?.value.aspectRatio ?? 4 / 3;
    final orientacao = MediaQuery.of(context).orientation;
    final aspectoCorrigido =
        (orientacao == Orientation.portrait && aspecto > 1) ||
            (orientacao == Orientation.landscape && aspecto < 1)
        ? 1 / aspecto
        : aspecto;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: const Color(0xFF152521),
        child: controlador != null && controlador!.value.isInitialized
            ? Center(
                child: AspectRatio(
                  aspectRatio: aspectoCorrigido,
                  child: CameraPreview(controlador!),
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estado == EstadoCamera.erro
                          ? Icons.no_photography_outlined
                          : Icons.camera_alt_outlined,
                      color: Colors.white70,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      estado == EstadoCamera.iniciando
                          ? 'Preparando a câmera...'
                          : 'A prévia da câmera aparecerá aqui',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (estado == EstadoCamera.iniciando) ...[
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
