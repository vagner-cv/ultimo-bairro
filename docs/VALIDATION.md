# Validação da versão 0.3.0

80/80 verificações em `tests/run_tests.gd`: movimentação normalizada, paredes,
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
