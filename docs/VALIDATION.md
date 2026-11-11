# Validação da versão 0.5.0

**154/154 verificações** em `tests/run_tests.gd`: movimentação normalizada,
paredes, portas e navegação, tiro/oclusão, perseguição/ataque, diálogo, pausa,
morte, reinício, ondas automáticas, mapa ampliado, inventário sem limite,
transações atômicas, cura, munições independentes, recipientes persistentes,
pegar/guardar parcial/tudo, equipar/fallback, faca/caixas, remoção de colisão,
loot, salto/apoio e menus.

`tests/aim_checks.gd` verifica cabeça, tronco e pernas, cursor antes/depois,
primeiro inimigo, ausência de auto-aim, alcance, paredes e portas próximas,
corpo de Mara, munição, limpeza do alvo nos menus, interiores ocultos, morte,
recuo do fuzil e seis trajetórias distintas da escopeta (semente fixa).

`tests/animation_checks.gd` valida os 128 quadros completos, oito direções,
base dos pés e posição do tronco durante os passos, deslocamento conjunto
no pulo, estados de repouso/disparo/faca e a saída dos tiros no cano do quadro.
Também verifica que os oito modelos de construção, três portas e oito árvores
são realmente colocados no mundo.

`tools/capture_weapon_poses.gd` renderiza as quatro armas em oito direções com
o mesmo código do jogador e registra repouso, dois passos, disparo e pulo.
`docs/character-animation.gif` foi montado das capturas do Godot. A inspeção
visual detectou e corrigiu a oscilação do tronco causada pela ancoragem no pé
que alternava e o contorno excessivo do alvo; esses casos têm cobertura de
animação e capturas atualizadas.

`tools/capture_preview.gd` captura título, interior, exterior, mira, combate,
diálogo, inventário, mapa, indústria, vegetação do parque e pausa no renderer
Compatibility. Conferidos escala, empunhadura, fachadas, recortes dos atlas sem partes de vizinhos, portas, jardins,
vegetação, interiores e materiais repetidos.

`tools/smoke_linux_export.py` exercita o executável Linux com eventos reais
X11: início, inventário, mapa, pulo, faca, movimento, porta, conversa, tiro,
pausa, reinício e saída. Os pacotes Windows/Linux embutem o PCK e as licenças.
Windows foi exportado em Linux; validação nativa em Windows continua pendente.
Não foi feita medição em hardware antigo. Não há salvamento entre sessões.
