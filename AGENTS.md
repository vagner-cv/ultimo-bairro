# Orientações do projeto

- Projeto nativo Godot 4.6.3 Standard, GDScript, renderer Compatibility.
- Idioma do produto e da documentação: português brasileiro.
- Escopo autorizado 0.3: ondas, inventário sem limite, loot, ervas, três armas
  com munições próprias, faca, pulo e bairro ampliado. Sem multiplayer/fome/sede.
- Use a arte pintada de `art/environment/` e `art/survival/`, documentada
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
- Escopo visual 0.4 autorizado: substituir o cenário CraftPix por arte pintada
  detalhada, coerente com Leon e os itens. Use sprites próprios e preserve os
  avisos de licença dos assets ainda usados; não extraia arquivos de outros jogos.
