# Validação da entrega 0.2.0

Validado em 10 de novembro de 2026, com Godot 4.6.3 Standard, em Linux x64.

A revisão 0.2.0 integra o kit pronto gratuito da CraftPix, incluindo tiles,
objetos e animações nativas. Os PNGs são preparados a partir do arquivo do autor,
com verificação de SHA-256. As capturas mostram esse kit dentro do jogo.

## Verificações concluídas

- Importação e execução de uma cópia limpa do projeto, sem cache `.godot`.
- **32/32 testes de gameplay aprovados**, sem erros de script ou recursos.
- Exportação release para Windows x64 e Linux x64, com pacote embutido.
- Verificação de integridade dos ZIPs gerados.
- Inspeção visual de menu, interior, bairro, diálogo, combate e pausa.
- Teste do executável Linux com eventos reais de teclado e mouse em X11:
  iniciar pelo menu, abrir a porta, caminhar até Mara, conversar, atirar,
  pausar, reiniciar e sair. Encerramento com código 0 e sem erros no log.
- Sintaxe das ferramentas Python e leitura do YAML da pipeline verificadas.

O teste visual usa renderização por software Mesa/llvmpipe em uma tela virtual.
O aviso de V-Sync indisponível nesse driver não é usado para avaliar o hardware
alvo do jogo. Ainda não foi medido o desempenho em um PC representativo.

## Limites desta validação

O executável Windows foi exportado e seu formato PE x64 foi verificado, mas
não foi executado em Windows. Não há uma sessão Windows neste ambiente.
A pipeline do GitHub prepara os assets e executa as verificações em cada push.
O estado de cada commit fica na aba Actions do repositório privado:
https://github.com/vagner-cv/ultimo-bairro/actions.

Os logs e capturas do teste nativo ficam em `builds/`, fora do histórico Git.
As capturas de referência do projeto estão nesta pasta `docs/`.
