import 'package:flutter/material.dart';

enum TipoAviso { informacao, orientacao, sucesso, erro }

class CartaoStatus extends StatelessWidget {
  const CartaoStatus({
    required this.titulo,
    required this.descricao,
    required this.tipo,
    super.key,
  });

  final String titulo;
  final String descricao;
  final TipoAviso tipo;

  @override
  Widget build(BuildContext context) {
    final estilo = switch (tipo) {
      TipoAviso.informacao => (
        Icons.info_outline,
        const Color(0xFFEAF3F2),
        const Color(0xFF155B55),
      ),
      TipoAviso.orientacao => (
        Icons.tips_and_updates_outlined,
        const Color(0xFFFFF2D8),
        const Color(0xFF765000),
      ),
      TipoAviso.sucesso => (
        Icons.check_circle_outline,
        const Color(0xFFE8F4E9),
        const Color(0xFF245C2B),
      ),
      TipoAviso.erro => (
        Icons.error_outline,
        const Color(0xFFFCE9E7),
        const Color(0xFF8B2E25),
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estilo.$2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(estilo.$1, color: estilo.$3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: estilo.$3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(descricao, style: TextStyle(color: estilo.$3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
