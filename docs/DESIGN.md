# Design — protótipo 0.2

## Experiência

Um sobrevivente acorda em uma casa de Vila Aurora. O bairro é pequeno,
mas pode ser explorado livremente. A primeira meta é conversar com Mara;
depois, explorar e eliminar os infectados. Ao limpar a área, a exploração
continua. Não há condição de fuga ou campanha nesta versão.

O controle deve permitir caminhar em uma direção e apontar em outra. O
mouse oferece mira livre em 360 graus. O kit pronto oferece animações laterais
com espelhamento; a arma acompanha o ângulo real da mira.

## Regras atuais

- Jogador: 100 de vida, 125 unidades/s, sem corrida ou stamina.
- Pistola: 34 de dano, intervalo de 0,22 s, alcance de 600 unidades, munição
  infinita e sem recarga. Os valores ficam em `resources/pistol.tres`.
- Zumbis: 90 de vida, três tiros para morrer; velocidades entre 37 e 49
  unidades/s. Ataque de 12 de dano a cada 1,1 s, com breve proteção do jogador
  após receber dano.
- Percepção: visão a até 270 unidades, bloqueada por paredes/portas; disparos
  atraem zumbis em até 490 unidades. Perder contato causa busca pela última
  posição conhecida, seguida por retorno à movimentação ociosa.
- Caminhos: AStarGrid2D com células de 32 unidades. Obstáculos são ampliados
  para considerar o raio dos personagens. Portas recalculam ocupação da grade.
- Tiros: raycast instantâneo, bloqueado pelo cenário. A animação do traço é
  visual. NPCs bloqueiam disparos, mas não sofrem dano nesta etapa.
- Corpos: permanecem como elementos visuais; não podem ser saqueados.
- Conversas: E avança as falas. Durante a fala, o jogador para de caminhar
  e atirar; o restante do bairro continua em movimento. Esc encerra a conversa.
- Pausa: congela mundo, áudio e relógio da partida. Reiniciar restaura o bairro.
- Não há respawn de zumbis, geração de mundo, coleta ou salvamento.

## Limites e desempenho

Mapa contínuo de 2304 × 1536 unidades, com cinco construções e 18 zumbis.
O chão é desenhado em um único CanvasItem estático, com texturas pequenas e
filtro nearest. Os obstáculos são corpos estáticos. Os zumbis escalonam as
consultas de caminho. Não há iluminação dinâmica, física 3D ou dependência de IA
generativa durante o jogo.

O renderer Compatibility é uma escolha inicial para ampliar a compatibilidade.
Requisitos mínimos e meta de FPS precisam ser medidos em um PC representativo;
os testes do ambiente cloud não estabelecem requisitos mínimos de hardware.

## Preparação para a expansão

- Armas usam um Resource próprio, separado do jogador.
- Portas e NPC compartilham `interact(actor)` e `interaction_text()` no grupo
  `interactables`. Móveis pesquisáveis podem implementar o mesmo contrato depois.
- Morte de zumbis passa por `take_damage()` e `zombie_killed()`, pontos de entrada
  possíveis para persistência ou saque quando esses sistemas forem solicitados.
- Bairro, atores, efeitos e interface estão em scripts separados.
- Não foi criado um inventário vazio ou uma simulação antecipada de sistemas
  futuros. A estrutura atual pode ser refatorada conforme as próximas decisões.

## Validação e limites conhecidos

A suíte exercita a física real do Godot, tiros e bloqueios, portas, navegação,
conversa, pausa, morte e reinício. Capturas complementam a inspeção da interface.
Os sprites e efeitos são provisórios. Ainda não há salvamento de preferências,
controle por gamepad, remapeamento de teclas, animações de ataque ou navegação
por múltiplos mapas. O executável Windows é exportado em Linux; precisa de
validação no Windows antes de uma distribuição mais ampla.
