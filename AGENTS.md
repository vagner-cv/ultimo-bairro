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

- Mira 0.4.1 autorizada: tiro livre por direção, áreas de acerto do corpo
  separadas dos pés e destaque do alvo usando a mesma verificação do disparo.
  Respeite alcance, paredes e portas; não exija cursor sobre o alvo nem aplique
  correção automática de direção. Recuo e dispersão são atributos WeaponData.

- Empunhadura 0.4.2: use `weapon_rig.gd` e a arte de `art/rig/`; preserve
  as ligações ombro/cotovelo/punho e os pontos de pegada/apoio/cano por arma.
  Ícones de inventário não devem ser usados como armas orbitando o personagem.
  Recuo, caminhada e pulo movem a montagem inteira; mantenha a saída do tiro
  na mesma linha do cano e a oclusão pelo corpo quando o personagem mira ao norte.
