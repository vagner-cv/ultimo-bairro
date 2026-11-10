# Orientações do projeto

- Projeto nativo Godot 4.6.3 Standard, GDScript, renderer Compatibility.
- Idioma do produto e da documentação: português brasileiro.
- Mantenha a primeira versão focada: um jogador, uma arma infinita, zumbis,
  portas, um NPC e bairro finito. Novos sistemas precisam fazer parte do pedido.
- Não ative inventário, coleta, saque, fome/sede ou multiplayer por conta própria.
- Use o kit pronto documentado em `art/README.md`, preservando sua licença.
  Não adicione assets extraídos dos jogos usados como referência.
- Use recursos `WeaponData` para os atributos de armas. Atualize a navegação
  sempre que uma porta mudar seu estado de colisão.
- Teste alterações de gameplay com:
  `godot --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd`.
- Em um checkout limpo, importe primeiro:
  `godot --headless --path . --editor --import --quit`.
- Antes da importação, instale `requirements-tools.txt` em um venv e execute
  `python tools/prepare_assets.py`. `art/vendor/` é gerado e ignorado pelo Git.
- Para mudanças visuais, execute o jogo e confira capturas; a ferramenta
  `tools/capture_preview.gd` registra uma sequência no próprio Godot.
- Não versionar `.godot/`, executáveis, credenciais ou pacotes de builds.
- Evite adicionar bibliotecas e frameworks até haver uma necessidade concreta.
- Não versione os PNGs/ZIPs da CraftPix nem inclua-os no ZIP de código-fonte.
  Distribua-os embutidos no jogo. As versões anteriores de arte estão no histórico.
- Não substitua a arte do kit por imagens geradas ou figuras geométricas.
