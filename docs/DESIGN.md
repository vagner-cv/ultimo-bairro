# Último Bairro — design 0.4

Sobrevivência em um bairro pós-apocalíptico visto de cima. A primeira versão
expandida mantém uma área finita, um personagem e Mara, com exploração e combate.

O ciclo é explorar, vasculhar recipientes, administrar munição/ervas e sobreviver
à horda. A primeira onda tem 18 zumbis; cada seguinte adiciona oito. O intervalo
é de 12 segundos após o último inimigo. O contador inclui os inimigos ainda na
fila de entrada; até 42 podem permanecer ativos ao mesmo tempo.

Armas são recursos WeaponData: pistola 34/.22s, escopeta 6×19/.8s, fuzil 25/.105s.
Cada disparo consome uma unidade da respectiva munição diretamente do inventário.
Faca causa 36, alcance 70, arco frontal, intervalo .48s, sem atravessar paredes.
Madeira resiste a dois golpes; papelão a um. Disparos não quebram essas caixas.

Inventário usa pilhas de quantidades inteiras, sem capacidade/slots. Transferências
validam tudo antes de modificar ambos os lados e conservar o total. A faca é
permanente; guardar a última unidade da arma equipada seleciona a faca. Erva verde
cura até 45, limitada a 100; vida cheia não consome erva. Recipientes rolam loot
uma vez na construção do mundo, não ao abrir. Mortes têm 62% de chance de drop.

O salto simula altura, velocidade vertical e apoio sobre obstáculos baixos.
Paredes usam camada 1, jogador 2, zumbis 4, NPC 8 e plataformas 16. Apenas a
colisão com plataformas é suspensa enquanto o personagem supera sua altura.
A navegação dos zumbis sempre considera plataformas, portas fechadas e paredes.

Mapa: 4608×3072, 27 interiores. Tab mostra a planta completa e a posição atual.
Inventário e mapa pausam a simulação. Esc fecha a janela atual antes da pausa.
Reiniciar limpa o mundo, inventário, loot, contador e ondas. Sem save persistente.

A apresentação 0.4 usa materiais pintados e sprites detalhados. O renderer do
terreno desenha grandes quads repetidos em vez de milhares de tiles pequenos.
As plantas, portas e colisões mantêm a mesma escala; fachadas/telhados são sprites
por categoria e os interiores recebem mobília física. Os sprites novos de Mara
e zumbis usam frames 128×192, com pés alinhados ao mesmo ponto físico do Leon.

## Mira e acerto — 0.4.1

O mouse aponta livremente; não existe snap ou obrigação de manter o cursor no
inimigo. O disparo usa um raio desde a altura visual da arma. Zumbis e Mara
possuem uma Area2D na camada 32, com cápsula de 22×62 centrada em (0,-32),
separada da colisão dos pés. Cabeça, tronco e pernas recebem o dano da arma,
sem multiplicador por região nesta etapa. Mara intercepta os tiros e não recebe dano.

`ballistics.gd` é compartilhado pelo preview e pelo disparo. O raio identifica
o primeiro corpo visível e verifica os bloqueios na planta física, projetando
o impacto para a altura visual. Essa segunda verificação impede que a origem
alta da arma atravesse uma porta fechada próxima. Obstáculos baixos continuam
respeitando a altura do pulo. Mira/contorno não revelam zumbis sob telhado opaco.

O contorno usa o alfa do sprite, e a mira fica verde para um alvo válido com
munição. O marcador de impacto corresponde a dano de verdade. A escopeta mantém
seis projéteis com dispersão; o fuzil acumula abertura limitada em uma rajada,
com recuperação ao parar. WeaponData guarda recuo por tiro, máximo e recuperação;
o jogador guarda apenas o acúmulo atual. A visualização indica a direção central,
sem anular dispersão ou garantir cada projétil. Não foi adicionado bônus de headshot.
