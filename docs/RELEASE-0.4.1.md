Mira livre com acerto pelo corpo visível e feedback de alvo.

- O tiro segue a direção do mouse: não é necessário deixar o cursor em cima
  do zumbi, e o primeiro corpo ou obstáculo intercepta a bala.
- Cabeça, tronco e pernas agora são atingidos por uma área do corpo separada
  da colisão pequena dos pés. O dano continua sendo definido pela arma.
- Mira e contorno verdes destacam o zumbi visível na trajetória, dentro do
  alcance e com munição. O destaque não revela inimigos sob telhados opacos.
- Paredes e portas fechadas bloqueiam, inclusive com o personagem encostado na porta.
- O tiro parte da posição visual da arma e o sangue aparece no ponto atingido.
- A mira abre com a dispersão: escopeta com seis projéteis e fuzil com recuo
  progressivo, limitado, que recupera precisão ao parar de atirar.
- A mesma verificação serve ao destaque e ao disparo, sem correção automática de mira.

**Windows:** baixe `UltimoBairro-0.4.1-Windows.zip`, extraia tudo e abra `UltimoBairro.exe`.
**Linux:** baixe `UltimoBairro-0.4.1-Linux.zip`, extraia e execute `UltimoBairro.x86_64`.

Controles mantidos: WASD/setas, mouse e botão esquerdo para mover/mirar/atirar;
F/direito faca, E interagir, I inventário, Tab mapa, Espaço pulo, H erva e 1–4 armas.

Validação: **121/121 testes**, revisão visual da mira no Godot e teste do executável
Linux com teclado/mouse. Windows foi exportado e ainda requer teste nativo em Windows.
Ainda não há salvamento entre sessões nem bônus de dano por região do corpo.
