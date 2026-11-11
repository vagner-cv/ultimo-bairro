# Arte ativa — versão 0.5.0

A direção atual é pixel art detalhada, com paleta de verdes, couro, tijolo e
azuis acinzentados. Todas as texturas ativas ficam em `art/pixel/` e acompanham
o código: não há download de assets nem plugin obrigatório para abrir o jogo.
São imagens geradas para o projeto com a ferramenta de geração de imagens;
PixelLab não foi usado nesta versão. Não foram extraídos arquivos de jogos.

## Personagem

Quatro atlas `hero_*.png`, cada um com 4 colunas × 8 linhas. Cada célula mede
96 × 80 pixels; o corpo tem aproximadamente 64 pixels de altura, com pés na
linha 74. Linhas: sul, sudeste, leste, nordeste, norte, noroeste, oeste e sudoeste.
Colunas: repouso, passo esquerdo, passo direito e disparo/golpe.

Corpo, braços, mãos e arma formam uma única imagem em cada quadro. A montagem
separada de membros da versão 0.4.2 foi substituída. `pixel_actor.gd` seleciona
o quadro e guarda o ponto do cano para cada pose. A mira física permanece livre
em 360°, enquanto o sprite representa a direção em oito ângulos.

## Bairro

- Cinco casas: reboco/telha, madeira azul, tijolo, cabana e sobrado amarelo.
- Loja, clínica e galpão; a planta física e a entrada acompanham as fachadas.
- Portas de madeira, azuis e metálicas, cada uma aberta/fechada.
- Oito árvores: carvalho, pinheiro, bétula, palmeira, salgueiro, bordo de outono,
  árvore seca e frutífera; seis variações de plantas, arbustos e flores.
- Móveis, cercas, destroços, recipientes, itens e quatro materiais de terreno.

O terreno repete texturas em quads grandes. A filtragem padrão é nearest;
F2 permite suavização opcional. Plantas pequenas não bloqueiam caminhada;
troncos e mobília mantêm colisão/navegação, e portas atualizam o caminho dos
zumbis. Sombras de contato e projeções continuam leves.

## Preparo e proveniência

Os atlas foram criados diretamente com instruções de pixel art; a pixelização
não é um filtro aplicado sobre a arte pintada anterior. O preparo em
`tools/import_pixel_atlases.py` apenas recorta, redimensiona por nearest e
empacota quadros, mantendo eixo do corpo e base dos pés. Nos objetos, procura
as margens transparentes entre células para evitar recortar partes de vizinhos.
Recebe um JSON com os
caminhos dos atlas originais; esse passo opcional requer Pillow. Os sprites
finais estão versionados, e os originais permanecem em `/workspace/generated_images/`
na sessão que os criou. Os pontos de cano são metadados revistos por quadro.

Os diretórios `art/environment/`, `art/survival/` e `art/rig/` registram a arte
anterior e ficam excluídos dos executáveis. CraftPix e `tools/prepare_assets.py`
também são históricos. Fontes DejaVu e Godot mantêm avisos nos pacotes. Os direitos
sobre personagens e marcas de referência pertencem aos respectivos titulares.
O projeto ainda não recebeu licença pública para seu código e sua arte.
