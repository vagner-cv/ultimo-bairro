# Último Bairro

Protótipo de sobrevivência para PC em **Godot 4.6.3**. Explore Vila Aurora,
converse com Mara e sobreviva a ondas crescentes de infectados.
A versão **0.4.0** refaz o cenário em arte pintada detalhada, no mesmo estilo
do personagem e dos itens.

![Partida com o cenário pintado integrado](docs/gameplay.png)

## Baixar e jogar

Abra [Releases](https://github.com/vagner-cv/ultimo-bairro/releases) e baixe:

- **Windows x64:** `UltimoBairro-0.4.0-Windows.zip`. Extraia tudo e abra
  `UltimoBairro.exe`.
- **Linux x64:** `UltimoBairro-0.4.0-Linux.zip`. Extraia e execute
  `./UltimoBairro.x86_64`. Se necessário, use `chmod +x UltimoBairro.x86_64`.

Os executáveis não precisam de Godot, Python ou instalação de assets.
O pacote Windows foi exportado em Linux e ainda precisa de validação em Windows.
Esta entrega é para PC; ainda não há versão publicada para navegador.

## Controles

| Ação | Controle |
| --- | --- |
| Caminhar | WASD ou setas |
| Mirar | Mouse, em qualquer direção |
| Ajustar zoom | Roda do mouse |
| Atirar | Botão esquerdo; segure para repetir |
| Portas / recipientes / conversa | E |
| Inventário sem limite | I |
| Mapa do bairro | Tab |
| Faca / quebrar caixas | F ou botão direito |
| Pular / subir em obstáculos baixos | Espaço |
| Pistola / escopeta / fuzil / faca | 1 / 2 / 3 / 4 |
| Usar erva verde (+45 de vida) | H |
| Filtro suave / pixel clássico | F2 |
| Pausa / encerrar conversa | Esc |
| Ativar ou desativar áudio | M |
| Tela cheia | F11 |

Você começa na casa 07. Use **E** perto da porta para sair; Mara está no jardim
à direita. Tiros atraem infectados. Paredes e portas fechadas bloqueiam o tiro
e o caminho. A partida pode ser reiniciada pelo menu de pausa ou após morrer.

## Escopo atual

- Bairro contínuo de **4608 × 3072 unidades**, quatro vezes a área anterior,
  com **27 construções acessíveis**, comércio, clínica, delegacia, escola,
  galpões, áreas residenciais e dois parques.
- Ondas: 18, 26, 34… infectados; **12 segundos** de intervalo após eliminar
  todos. A próxima onda chega longe do jogador e entra gradualmente, com
  até 42 inimigos ativos simultaneamente para limitar o custo de simulação.
- Pistola (34 de dano), fuzil (25, disparo rápido) e escopeta (6 × 19 por tiro),
  cada um consumindo sua munição. As reservas são usadas diretamente, sem recarga.
- Faca (36 de dano), caixas de madeira (dois golpes) e papelão (um golpe).
- Ervas verdes recuperam 45 de vida. Drops aleatórios dos zumbis e loot em
  armários, gaveteiros, lixeiras e caixas; alguns recipientes podem estar vazios.
- Inventário sem limite, com listas lado a lado para transferir quantidades,
  pegar tudo, guardar itens, equipar e usar ervas. A faca permanece com o jogador.
- Pulo com altura e pouso sobre objetos baixos; paredes continuam bloqueando.
- Arte pintada detalhada em terreno, asfalto, calçadas, pisos, fachadas e telhados.
- Casas, lojas, prédios públicos e galpões com aparências próprias; interiores
  mobiliados, árvores, cercas, carros abandonados e iluminação dos postes.
- Leon em quatro direções, Mara e zumbis no mesmo acabamento visual dos itens.
- Sombras suaves, hera nas fachadas e sinalização dos prédios.

Você começa com pistola, 60 munições 9 mm, faca e uma erva. O armário da primeira
casa contém um fuzil; a caixa de madeira tem uma escopeta. A mira é livre em 360°.
O conteúdo dos recipientes e o inventário duram **a partida atual**. Ainda não
há salvamento entre sessões, multiplayer ou fome/sede.

![Inventário e conteúdo do armário](docs/inventory.png)
![Mapa ampliado de Vila Aurora](docs/map.png)

## Abrir o código no Godot

1. Instale [Godot 4.6.3 Standard](https://godotengine.org/download/archive/4.6.3-stable/).
2. Clone o repositório e importe `project.godot`.
3. Pressione **F5**.

A arte atual acompanha o código. Não é necessário instalar plugin, biblioteca
ou baixar um kit para abrir o projeto. Python só é necessário para os scripts
de empacotamento e ferramentas de desenvolvimento. `tools/prepare_assets.py`
permanece como ferramenta histórica da versão CraftPix, sem uso na versão atual.

## Validar e exportar

No diretório do projeto:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd
```

Há 80 verificações de gameplay, incluindo inventário, munições, loot, ondas,
faca, salto, navegação, portas, diálogos, pausa e reinício. Para exportar, instale os modelos 4.6.3 em
Editor → Gerenciar modelos de exportação e execute `python tools/build.py`.
O comando valida, exporta Windows/Linux e monta ZIPs em `builds/` com os avisos
de licença e instruções. A pipeline do GitHub valida os pushes e oferece builds
pela execução manual ou por uma tag `v*`.

## Estrutura e créditos

`src/actors/` contém os personagens, `src/world/` o bairro e portas,
`src/systems/` armas/áudio/arte, e `src/ui/` a interface. As armas são configuradas
em `resources/*.tres`; itens, inventário e loot ficam em `src/systems/`.

- Arte pintada gerada para o projeto: `art/environment/` e `art/survival/`.
- Fontes [DejaVu](art/FONT-LICENSE.txt) e motor [Godot](art/GODOT-LICENSE.txt).
- [Arte e proveniência](art/README.md), [design](docs/DESIGN.md),
  [evolução](docs/ROADMAP.md) e [validação](docs/VALIDATION.md).

O código, os sons e a arte do projeto ainda não receberam licença pública.
O cenário CraftPix das versões anteriores continua no histórico; seus PNGs
não são usados nem incluídos nos pacotes atuais.
