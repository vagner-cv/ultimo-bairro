# Arte ativa — versão 0.3.0

O cenário e os infectados usam **Free Zombie Apocalypse Top-Down Pixel Art Kit**, da CraftPix:
https://free-game-assets.itch.io/free-zombie-apocalypse-top-down-pixel-art-kit

`tools/prepare_assets.py` obtém o download gratuito, valida seu SHA-256 e prepara
os PNGs usados em `art/vendor/craftpix/`, ignorado pelo Git. Os executáveis usam
os assets embutidos no jogo; o repositório não redistribui o pacote gráfico.
Licença: https://craftpix.net/file-licenses/ — Freebie Products.
Veja `CRAFTPIX-NOTICE.txt`, além dos avisos das fontes e do Godot.

O usuário pediu Leon de Resident Evil 4 e itens de sobrevivência. Os sprites em
`art/survival/` foram gerados para este projeto e empacotados em frames/ícones:
Leon em quatro direções, armas, munições, erva, caixas, armário, gaveteiro e lixeira.
São representações próprias; nenhum asset foi extraído de Resident Evil.
Os direitos sobre o personagem e a marca de referência pertencem a seus titulares.

`shaders/soft_pixel.gdshader` reconstrói cantos diagonais (Scale2x) em tempo de
renderização sem alterar as fontes de arte. F2 alterna o filtro suave e a
apresentação clássica. Sombras de contato usam gradiente radial; prédios e árvores
têm projeções suaves. Os sons próprios podem ser regenerados por `tools/generate_audio.py`.
