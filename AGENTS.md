# Orientações do projeto

- Projeto nativo Godot 4.6.3 Standard, GDScript, renderer Compatibility.
- Idioma do produto e da documentação: português brasileiro.
- Escopo autorizado 0.3: ondas, inventário sem limite, loot, ervas, três armas
  com munições próprias, faca, pulo e bairro ampliado. Sem multiplayer/fome/sede.
- Use a pixel art de `art/pixel/`, documentada
  em `art/README.md`. Não adicione assets extraídos de jogos de referência.
- Use recursos `WeaponData` para os atributos de armas. Atualize a navegação
  sempre que uma porta mudar seu estado de colisão.
- Teste alterações de gameplay com:
  `godot --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd`.
- Em um checkout limpo, importe primeiro:
  `godot --headless --path . --editor --import --quit`.
- A arte atual está versionada; abrir e exportar não exige download de kits.
  `tools/prepare_assets.py` é legado e `art/vendor/` fica fora dos pacotes.
- Para mudanças visuais, execute o jogo e confira capturas; a ferramenta
  `tools/capture_preview.gd` registra uma sequência no próprio Godot.
- Não versionar `.godot/`, executáveis, credenciais ou pacotes de builds.
- Evite adicionar bibliotecas e frameworks até haver uma necessidade concreta.
- Não versione os PNGs/ZIPs da CraftPix nem inclua-os no ZIP de código-fonte.
  Distribua-os embutidos no jogo. As versões anteriores de arte estão no histórico.
- A versão 0.4 substituiu o cenário CraftPix por arte própria. A direção atual
  é a pixel art da 0.5 descrita abaixo. Preserve os avisos das dependências
  ainda usadas; não extraia arquivos de outros jogos.

- Mira 0.4.1 autorizada: tiro livre por direção, áreas de acerto do corpo
  separadas dos pés e destaque do alvo usando a mesma verificação do disparo.
  Respeite alcance, paredes e portas; não exija cursor sobre o alvo nem aplique
  correção automática de direção. Recuo e dispersão são atributos WeaponData.

- Direção visual 0.5 autorizada pelo usuário: pixel art detalhada em `art/pixel/`.
  Esta direção substitui a arte pintada e a montagem de membros da 0.4.2.
  `pixel_actor.gd` desenha corpo, mãos e arma juntos em cada quadro, com oito
  direções visuais e mira física livre. Não volte a compor braços separados.
- Preserve a variedade de casas, portas e vegetação, a escala e a paleta comuns.
  Portas visuais abertas/fechadas devem acompanhar a colisão e a navegação.
