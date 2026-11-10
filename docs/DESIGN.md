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
