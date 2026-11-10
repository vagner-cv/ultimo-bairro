Bairro ampliado, sobrevivência por ondas e inventário completo durante a partida.

- Mapa com **4 vezes a área**, 27 construções acessíveis, bairros residencial,
  comercial e industrial, clínica, delegacia, escola, galpões e parques.
- Sprite próprio do **Leon de RE4**, filtro de suavização de diagonais e sombras suaves.
- Ondas automáticas: **18 → 26 → 34…**. Após limpar uma onda, há 12 segundos
  para se preparar; novos zumbis aparecem longe do personagem e entram aos poucos.
- Pistola, escopeta e fuzil com danos, cadências e munições diferentes.
- Faca com golpe em arco, caixas de papelão e madeira que podem ser quebradas.
- Ervas verdes (+45 de vida), drops aleatórios de zumbis e recipientes exploráveis.
- Armários, gaveteiros e lixeiras abrem com **E**. Menu com conteúdo do recipiente
  e inventário do jogador, sem limite de carregamento: pegar, guardar, pegar tudo,
  usar ervas e equipar armas. Conteúdos persistem durante a partida.
- Pulo com **Espaço**, incluindo pouso sobre obstáculos baixos.

**Controles:** WASD/setas: andar · mouse: mirar · esquerdo: atirar · F/direito: faca ·
E: interagir · I: inventário · Tab: mapa · Espaço: pular · H: erva · 1/2/3/4: armas ·
roda: zoom · F2: filtro gráfico · Esc: fechar/pausar · M: áudio · F11: tela cheia.

**Windows:** baixe `UltimoBairro-0.3.0-Windows.zip`, extraia tudo e abra `UltimoBairro.exe`.
**Linux:** baixe `UltimoBairro-0.3.0-Linux.zip`, extraia e execute `UltimoBairro.x86_64`.
Não precisa instalar Godot ou Python. Ainda não há build de navegador ou salvamento
entre sessões. O pacote Windows é exportado em Linux e requer validação em Windows.

Validação: 80/80 testes de gameplay, inspeção visual no Godot e teste nativo Linux
com teclado e mouse. A pipeline importa, testa e exporta ambos os pacotes.

O cenário mantém o kit CraftPix. Personagem e ícones novos são sprites próprios,
sem extrair arquivos dos jogos de referência. O ZIP de código fornece o preparador
do kit; os executáveis incluem a arte licenciada embutida no jogo.
