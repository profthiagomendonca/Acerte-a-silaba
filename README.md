# Acerte a Sílaba - Jogo Educativo de Alfabetização

Este é um jogo educativo desenvolvido para auxiliar no processo de alfabetização de crianças, focando na consciência fonológica e na síntese silábica. O jogo desafia o jogador a completar palavras selecionando a sílaba correta entre opções geradas dinamicamente.

## 🚀 Funcionalidades

- **Geração Dinâmica de Desafios**: Para cada palavra, o jogo sorteia aleatoriamente qual sílaba estará faltando, garantindo que o jogador não decore apenas uma posição.
- **Distratores Inteligentes**: As opções incorretas são geradas com base na sílaba correta (trocando apenas as vogais), trabalhando especificamente a percepção visual e fonética das vogais.
- **Progressão Didática**: O jogo utiliza um banco de dados com palavras de diferentes complexidades:
  - 🟢 **Dissílabas** (ex: BOLA, GATO)
  - 🟡 **Trissílabas** (ex: PIPOCA, CAVALO)
  - 🟠 **Polissílabas** (4 sílabas - ex: ABACAXI, TELEFONE)
  - 🔴 **Palavras Complexas** (5+ sílabas - ex: HELICÓPTERO, HIPOPÓTAMO)
- **Feedback Visual e Sonoro**: Mascote com diferentes expressões para acertos e erros, efeitos sonoros e trilha sonora lúdica.
- **Sistema de Confetes**: Celebração ao concluir a rodada de 22 palavras.
- **Interface Responsiva**: Desenvolvido para funcionar em diferentes proporções de tela, ideal para dispositivos móveis (Android).

## 🛠️ Tecnologias Utilizadas

- **Engine**: [Godot Engine 4.x](https://godotengine.org/)
- **Linguagem**: GDScript
- **Formatos**: JSON para banco de dados de níveis, PNG/SVG para artes.

## 📁 Estrutura do Projeto

- `assets/`: Contém imagens, sons e o banco de dados `levels.json`.
- `scenes/`: Cenas principais do jogo (main scene).
- `scripts/`: Toda a lógica programada em GDScript.
- `export_presets.cfg`: Configurações de exportação para Android (APK).

## 🎮 Como Jogar

1. Clique em **INICIAR JOGO**.
2. Observe a imagem e a palavra com uma lacuna (`___`).
3. Escolha entre as 3 opções de sílabas a que completa corretamente a palavra.
4. Acerte todas as palavras da rodada para vencer!

---

Desenvolvido como parte do projeto de Mestrado focado em tecnologias educacionais.
