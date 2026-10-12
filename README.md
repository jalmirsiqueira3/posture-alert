# PostureAlert

Aplicativo mobile experimental que usa visão computacional para ajudar pessoas
que trabalham sentadas a perceber desvios de postura durante o home office.

> O PostureAlert é um protótipo educativo. Não diagnostica doenças nem substitui
> avaliação ou orientação de profissionais de saúde.

## Problema

Quem trabalha por longos períodos sentado pode não perceber que inclinou o
tronco ou projetou a cabeça para a frente. O PostureAlert pretende analisar a
pose em uma câmera lateral e avisar quando esses desvios persistirem.

## Recorte do microprojeto

- **Entrada:** vídeo ao vivo da câmera em orientação horizontal, com a pessoa
  sentada enquadrada de perfil.
- **Técnica:** Google ML Kit Pose Detection identifica pontos-chave no próprio
  dispositivo. O app compara somente a orelha e o ombro visíveis e estima o
  ângulo entre eles e o eixo vertical da imagem.
- **Saída:** indicação de enquadramento/visibilidade e orientação simples sobre
  a postura observada. Um desvio precisa persistir por dois segundos antes de
  gerar um alerta.
- **Avaliação:** pipeline Python equivalente testado no Google Colab (MediaPipe
  Tasks API) sobre o gabarito de 10 imagens sob condições variadas (iluminação,
  sombras, desfoque e perfis esquerdo/direito).

O limite atual de 15° é heurístico e ainda precisa ser calibrado com os dados
de avaliação. Como a regra usa somente orelha e ombro, ela detecta deslocamento
horizontal da cabeça, mas não distingue se esse deslocamento é para a frente
ou para trás. Os testes automatizados cobrem a lógica geométrica, mas não
substituem a avaliação com imagens ou vídeos reais. O aplicativo não deve
apresentar uma estimativa experimental como medida clínica.

### Como a análise funciona

1. O usuário inicia o monitoramento e autoriza o uso da câmera.
2. O app envia cada quadro ao detector de pose do ML Kit, que roda no
   dispositivo; quadros só são analisados quando o processamento anterior
   terminou.
3. A análise usa apenas a orelha e o ombro detectados. O ângulo é calculado
   entre a linha que une esses pontos e o eixo vertical da imagem; um
   deslocamento acima de 15° pede ajuste. O app não usa nariz nem quadril e não
   diferencia deslocamento para a frente de deslocamento para trás.
4. Pontos ausentes ou com confiança abaixo de 0,5 resultam em pedido de ajuste
   do enquadramento. Um desvio é mostrado como persistente após dois segundos.

### Avaliação e Validação Experimental

A validação da regra de negócio foi executada em notebook Python (Google Colab)
utilizando a Tasks API do MediaPipe sobre um conjunto de teste contendo 10 imagens
rotuladas manualmente (*ground truth*):

- **Limiar Principal (15,0°):** Alcançou **100,0% de acurácia** (10/10 acertos),
  demonstrando estabilidade e resiliência a ruído, sombras laterais, desfoque e
  variações de perfil esquerdo/direito.
- **Limiar Alternativo Rígido (5,0°):** Apresentou queda na acurácia para **70,0%**
  devido ao surgimento de falsos positivos em posturas alinhadas, justificando
  empiricamente a escolha dos 15,0° para evitar alarmes falsos no uso contínuo.
## Enquadramento e ambiente

- Apoie o celular ou notebook para manter a câmera estável, aproximadamente na
  altura do tronco.
- No celular, o app mantém a tela na horizontal e mostra a prévia ao lado dos
  controles. A captura usa a resolução alta e prefere a câmera traseira.
- Sente-se de perfil para a câmera; mantenha a orelha e o ombro visíveis.
- Prefira luz uniforme de ambiente; evite ambiente escuro e contraluz forte.

## Organização do repositório

```text
.
├── README.md
└── mobile/
    ├── lib/
    │   ├── main.dart     # ponto de entrada do Flutter
    │   ├── aplicativo.dart
    │   ├── telas/        # tela do monitoramento
    │   ├── servicos/     # câmera e integração com o ML Kit
    │   ├── componentes/  # prévia da câmera, avisos e cartões de status
    │   ├── dominio/      # regra geométrica que avalia a postura
    ├── test/
    │   └── dominio/      # testes da avaliação de postura
    ├── android/
    └── ios/
```

Os nomes e comentários próprios do projeto são escritos em português. Termos
como `Widget`, `build`, `CameraController` e `PoseDetector` permanecem com os
nomes da linguagem e das bibliotecas que os fornecem.

### Como o código está dividido

- `mobile/lib/main.dart` inicia o aplicativo.
- `mobile/lib/aplicativo.dart` configura o tema e escolhe a tela inicial.
- `mobile/lib/telas/tela_monitoramento.dart` organiza a tela e responde às
  ações da pessoa usuária.
- `mobile/lib/servicos/servico_monitoramento.dart` controla a câmera, envia os quadros
  ao ML Kit e transforma os pontos detectados numa avaliação.
- `mobile/lib/dominio/avaliacao_postura.dart` contém a regra geométrica, sem depender da
  câmera ou da interface. Por isso, pode ser testada com pontos artificiais.
- `mobile/lib/componentes/` guarda partes visuais menores, como a prévia da câmera e
  os avisos.
- `mobile/test/dominio/` verifica os cenários da regra de postura.

O fluxo principal é: câmera → serviço de monitoramento → avaliação de postura →
tela. Assim, mudanças na interface não precisam alterar a matemática, e os
testes do domínio podem rodar sem abrir a câmera.

## Executar o aplicativo

É necessário ter Flutter instalado e um dispositivo Android ou iOS configurado.
O app pede autorização da câmera somente quando o monitoramento é iniciado.

```bash
cd mobile
flutter pub get
flutter run
```

Para executar as verificações locais:

```bash
flutter analyze
flutter test
```

O detector usado pelo protótipo requer Android com SDK mínimo 21 ou iOS 15.5+.

## Privacidade e uso responsável

O monitoramento pede uma ação explícita e analisa os quadros no próprio
dispositivo; esta versão não grava nem envia imagens. Imagens e vídeos usados na
avaliação do projeto só devem ser coletados com consentimento, usados para essa
finalidade e armazenados apenas se necessário e de forma controlada.

## Estado atual

O repositório já está organizado e contém uma primeira versão do monitor com
câmera ao vivo, detecção de pose e testes unitários do classificador geométrico.
Ainda faltam calibrar os limites, avaliar pelo menos 10 exemplos rotulados,
registrar métricas e verificar o comportamento em dispositivos reais e em
condições variadas de iluminação.
