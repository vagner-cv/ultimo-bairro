# Validação da versão 0.4.1

121/121 verificações em `tests/run_tests.gd`: movimentação normalizada, paredes,
portas e navegação, tiro/oclusão, perseguição/ataque, diálogo, pausa, morte,
reinício, ondas automáticas, mapa ampliado, inventário sem limite, transações
atômicas, cura, munições independentes, armas não possuídas, recipientes
persistentes, pegar/guardar parcial/tudo, equipar/fallback de arma, faca e
caixas, remoção de colisão, loot aleatório, salto e apoio, mapa/inventário.

`tools/capture_preview.gd` captura título, interior, exterior, combate,
diálogo, inventário, mapa, indústria e pausa no renderer Compatibility.

`tools/smoke_linux_export.py` exercita o executável Linux com eventos reais
X11: início, I, Tab, pulo, faca, movimentação, porta, NPC, tiro, pausa,
reinício e saída. Os pacotes Windows/Linux embutem o PCK e os avisos de licença.
Windows foi exportado em Linux; seu funcionamento nativo precisa ser validado
em uma máquina Windows. Não foi feita medição em hardware antigo.

A versão 0.4 substitui toda a arte do cenário e dos coadjuvantes. A revisão visual
confere fachadas, portas abertas/fechadas, interiores, mobília, terreno repetido,
vegetação e iluminação no renderer Compatibility. O checkout atual abre sem
preparação ou download de gráficos externos; a pipeline não usa mais o kit antigo.

`tests/aim_checks.gd` verifica cabeça, tronco e pernas, cursor antes/depois,
primeiro inimigo na trajetória, ausência de auto-aim, alcance, bloqueio por
paredes e portas próximas, corpo de Mara, munição, limpeza de alvo em menus,
interiores ocultos, cadáveres, recuo do fuzil e dispersão real dos seis projéteis
da escopeta. O módulo retorna uma confirmação de conclusão para que uma falha
intermediária não produza um resultado parcial aparentemente aprovado.

`docs/aim.png` registra a mira verde e o contorno no renderer do jogo. Os tiros
agora partem do ponto visual da arma, e os efeitos de sangue acompanham o impacto.
