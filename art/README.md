# Arte ativa — versão 0.2.0

O jogo usa o **Free Zombie Apocalypse Top-Down Pixel Art Kit**, da CraftPix:
https://free-game-assets.itch.io/free-zombie-apocalypse-top-down-pixel-art-kit

O kit gratuito foi escolhido por reunir terreno, construções, objetos,
sobreviventes e infectados na mesma escala e paleta. O autor fornece animações
laterais, que o jogo espelha; a mira é independente em 360 graus.

`tools/prepare_assets.py` obtém o download gratuito, valida o SHA-256, copia
os PNGs necessários e recorta regiões do tileset para uso pelo Godot. O terreno
é montado com tiles do pacote, e os prédios são compostos pelo renderer do jogo.
Não há geração de imagens nesse processo.

Os arquivos preparados ficam em `art/vendor/craftpix/`, ignorado pelo Git.
Conforme a licença de freebies da CraftPix, os executáveis usam a arte como
parte do jogo. O repositório e o ZIP de código fornecem o script de preparação,
sem redistribuir os arquivos gráficos do pacote.

Licença: https://craftpix.net/file-licenses/ — seção Freebie Products.
Veja `CRAFTPIX-NOTICE.txt`. Fontes e motor mantêm os respectivos avisos.

As artes anteriores foram substituídas nesta revisão e continuam no histórico
Git para referência. Os sons próprios podem ser regenerados com
`python tools/generate_audio.py`.
