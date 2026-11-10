# Arte ativa — versão 0.4.0

A direção visual atual é arte pintada detalhada, com materiais naturais,
paleta desgastada e acabamento coerente entre cenário, personagens e itens.
Os PNGs próprios estão versionados em `art/environment/` e `art/survival/`.

## Ambiente

Texturas de gramado, asfalto, calçada e piso de madeira foram geradas para o
projeto. Fachadas/telhados de casa, loja, prédio público e galpão, vegetação,
cercas, banco, barricada, barril, poste, carro, móveis e peças arquitetônicas
foram gerados em atlas com transparência e separados em sprites para o Godot.

O preparo técnico recorta células, remove margens transparentes e ajusta a
resolução/âncora dos frames. O desenho vem das imagens geradas, sem montagem de
cenário por primitivas. As fontes originais ficam no diretório de imagens
geradas da sessão; os sprites finais necessários ao projeto estão no Git.

O terreno usa texturas repetidas em quads grandes, com filtragem linear e
mipmaps. Construções são sprites próprios sobre a planta física existente;
as portas mantêm alinhamento com a passagem e o telhado oculta-se ao entrar.
A mobília possui colisão e participa da navegação; objetos baixos aceitam pulo.
Sombras suaves usam gradientes e projeções; postes têm luz quente sem sombras
dinâmicas pesadas. Não é usado o shader Scale2x na arte atual.

## Personagens e itens

Leon, Mara, zumbis, armas, ervas, munições e recipientes são representações
geradas para o projeto. Não foram extraídos arquivos de Resident Evil.
Os direitos sobre personagens e marcas usados como referência permanecem
com seus titulares. Os zumbis usam animações laterais espelhadas; Leon tem
quatro direções e mira livre.

## Arte anterior e dependências

A CraftPix foi usada nas versões anteriores. `tools/prepare_assets.py` e
`CRAFTPIX-NOTICE.txt` ficam como registro histórico; `art/vendor/` é ignorado
no Git e excluído das exportações. Não é necessário baixar esse kit agora.
Fontes DejaVu e Godot mantêm seus avisos de licença nos pacotes.
