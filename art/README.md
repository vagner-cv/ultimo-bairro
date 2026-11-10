# Arte revisada — 0.1.1

As quatro imagens em `source/` foram criadas com geração de imagens para este
projeto. Não são sprites extraídos dos jogos de referência. O atlas de cenário
recebeu uma segunda passagem de remoção de fundo para uso com transparência.

- `source/environment.png`: atlas de 24 construções, plantas, móveis e objetos.
- `source/terrain.png`: seis materiais para o chão.
- `source/player.png`: quatro direções e quatro poses de caminhada do jogador.
- `source/people.png`: zumbi com caminhada e sobrevivente com poses de espera.

`tools/pack_art.py` recorta as células dos atlas, ajusta tamanhos e alinha os pés
nas animações. Não desenha os personagens ou objetos. As fontes de alta
resolução são preservadas para revisão; os executáveis incluem apenas as
texturas usadas no jogo.

Os assets continuam sendo uma primeira direção visual, sujeitos a revisão de
perspectiva, consistência e animação. Fontes DejaVu e o motor Godot possuem
suas licenças nos arquivos desta pasta.
