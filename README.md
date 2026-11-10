# Último Bairro

Protótipo de sobrevivência para PC em **Godot 4.6.3**. Explore Vila Aurora,
converse com Mara e enfrente 18 infectados com uma pistola de munição infinita.
A versão **0.2.0** usa o kit pronto de pixel art da CraftPix.

![Partida com o kit CraftPix integrado](docs/gameplay.png)

## Baixar e jogar

Abra [Releases](https://github.com/vagner-cv/ultimo-bairro/releases) e baixe:

- **Windows x64:** `UltimoBairro-0.2.0-Windows.zip`. Extraia tudo e abra
  `UltimoBairro.exe`.
- **Linux x64:** `UltimoBairro-0.2.0-Linux.zip`. Extraia e execute
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
| Portas / conversa / avançar fala | E |
| Pausa / encerrar conversa | Esc |
| Ativar ou desativar áudio | M |
| Tela cheia | F11 |

Você começa na casa 07. Use **E** perto da porta para sair; Mara está no jardim
à direita. Tiros atraem infectados. Paredes e portas fechadas bloqueiam o tiro
e o caminho. A partida pode ser reiniciada pelo menu de pausa ou após morrer.

## Escopo atual

- Um jogador, uma pistola infinita, vida, dano, morte e reinício.
- Zumbis com percepção por visão/som, perseguição, navegação e ataque.
- Cinco construções acessíveis, ruas, praça, árvores, cercas, lixeiras e barricadas.
- Uma NPC com diálogo, minimapa, interface e áudio.
- Animações prontas de espera, caminhada, disparo, ataque e corpo morto.

O kit oferece personagens com animações laterais, usadas com espelhamento;
movimentação e mira continuam livres. Os personagens são os skins do pacote.
Não há inventário, coleta, saque, recarga, fome/sede, salvamento ou multiplayer.
O bairro é uma área contínua de 2304 × 1536 unidades.

## Abrir o código no Godot

1. Instale [Godot 4.6.3 Standard](https://godotengine.org/download/archive/4.6.3-stable/)
   e Python 3.10 ou superior.
2. Clone este repositório.
3. Prepare os assets gratuitos do autor:

```sh
python3 -m venv .venv
# Linux/macOS: source .venv/bin/activate
# Windows PowerShell: .venv\Scripts\Activate.ps1
python -m pip install -r requirements-tools.txt
python tools/prepare_assets.py
```

Também é possível baixar o ZIP gratuito na página do autor e executar:

```sh
python tools/prepare_assets.py --archive /caminho/para/o/kit.zip
```

4. Importe `project.godot` no Godot e pressione **F5**.

A arte licenciada fica em `art/vendor/`, ignorada pelo Git. O código de
preparação baixa o arquivo público do autor, verifica seu SHA-256 e prepara
apenas os PNGs usados pelo jogo. Os PNGs não acompanham os arquivos de código
do GitHub; os executáveis incluem a arte embutida na partida.

## Validar e exportar

Depois de preparar os assets:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd
```

Há 32 verificações de movimentação, física, tiros, navegação, portas, diálogo,
pausa, dano, morte e reinício. Para exportar, instale os modelos 4.6.3 em
Editor → Gerenciar modelos de exportação e execute `python tools/build.py`.
O comando valida, exporta Windows/Linux e monta ZIPs em `builds/` com os avisos
de licença e instruções. A pipeline do GitHub valida os pushes e oferece builds
pela execução manual ou por uma tag `v*`.

## Estrutura e créditos

`src/actors/` contém os personagens, `src/world/` o bairro e portas,
`src/systems/` armas/áudio/arte, e `src/ui/` a interface. A pistola é configurada
em `resources/pistol.tres`.

- Arte: [Free Zombie Apocalypse Top-Down Pixel Art Kit — CraftPix](https://free-game-assets.itch.io/free-zombie-apocalypse-top-down-pixel-art-kit).
- [Aviso de uso da CraftPix](art/CRAFTPIX-NOTICE.txt), [fontes DejaVu](art/FONT-LICENSE.txt)
  e [Godot](art/GODOT-LICENSE.txt).
- [Design](docs/DESIGN.md), [evolução](docs/ROADMAP.md) e [validação](docs/VALIDATION.md).

O código e os sons próprios ainda não receberam licença pública. A arte da
CraftPix segue a licença do autor e não pode ser redistribuída como asset pack.
