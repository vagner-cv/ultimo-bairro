# Próximas versões

Esta é uma sequência de propostas, não um compromisso de implementar todos
os sistemas. Cada etapa deve produzir algo pequeno e jogável para avaliação.

## 0.1 — Base jogável

Movimentação, mira, pistola infinita, zumbis, dano/morte, portas, conversa,
bairro finito e interface. Primeira entrega para experimentar o combate.

## 0.2 — Sensação de jogo

Ajustar velocidade, câmera, cadência e dificuldade depois de jogar. Melhorar
sprites, animação de ataque e morte, som dos zumbis, feedback de impacto e
legibilidade do cenário. Validar Windows e medir desempenho no PC alvo.

## 0.3 — Persistência e configurações

Salvar/carregar a partida e o estado das portas/zumbis; opções de áudio e
vídeo persistentes, remapeamento de teclas e suporte a gamepad se desejado.

## 0.4 — Inventário e coleta

Definir itens, capacidade, interface e regras de transferência. Só então
implementar objetos no chão, busca em móveis e saque de corpos. Manter esses
dados separados da representação visual e cobrir salvamento com testes.

## 0.5 — Sobrevivência e expansão

Outras armas e munição, necessidades do personagem, NPCs com objetivos e
novos quarteirões. Escolher cada sistema pelo efeito na experiência; expansão
do mapa exige pensar em carregamento por regiões e persistência.

Multiplayer permanece uma decisão separada: afeta arquitetura, custo e testes.
