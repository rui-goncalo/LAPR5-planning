:- consult('BaseDeConhecimento.pl').
:- consult('US1.pl').
:- consult('US2.pl').


% --- Implementar heurísticas que possam rapidamente gerar uma solução 
% (não necessariamente a melhor) e avaliar a qualidade dessas heurísticas 
% (por exemplo, entregar no armazém mais próximo; efetuar de seguida a entrega
% com maior massa; combinar distância para a entrega com massa entregue) ---

/*
Heurística para a Entrega com o menor tempo

heuristicaDistancia(eTruck01, 20221205, R, T) vai procurar os armazens com entregas numa determinada data (20221205)
Vai buscar o id do armazém de Matosinhos e envia-o mais à lista para o predicado bfsDistancia. Este faz uma pesquisa em largura onde retorna, em R,
o caminho mais curto entre o armazem de Matosinhos e os armazens presentes na lista.
Por fim, usa o predicado calcularTempo da US2 para calcular o tempo da entrega tendo em conta a carga e restantes características.

bfsDistancia faz a pesquisa em largura recebendo o armazem atual, a lista de armazens e uma lista R.
Usa o predicado proximoArm para encontrar o próximo armazem a ser visitado e adiciona-o à lista R.
Esse é removido da lista de entregas e chama recursivamente até a lista de entregas ficar vazia.

proximoArm é usada para encontrar o proximo armazem a ser visitado pelo bfs.
Recebe o armazem atual, lista de armazens, tempo minimo e armazem inicial. A cada chamada recursiva, atualiza o tempo mínimo
e o armazem escolhido. Se o tempo de viagem entre o armazem atual e o proximo for menor que o minimo atual, então
o mínimo é atualizado e o armazém escolhido é atualizado para A1. Caso contrário, o mínimo e o armazém mantêm-se.
*/
heuristicaDistancia(T, D, R, Tempo) :-
    armazensEntregasData(L, D),
    idArmazem('Matosinhos', IdA),
    bfsDistancia(IdA, L, R),
    calcularTempo(D, T, R, Tempo), !,
    format('Tempo: ~3f~n', [Tempo]).

bfsDistancia(_, [], []) :- !.
bfsDistancia(S, [A|ResArms], [PA|R]) :-
    proximoArm(S, [A|ResArms], _, PA),
    delete([A|ResArms], PA, FA),
    bfsDistancia(PA, FA, R).

proximoArm(_, [], 0, _) :- !.
proximoArm(S, [A1|Arms], MenorTempo, Arm) :- 
    proximoArm(S, Arms, MenorTempo1, Arm1), 
    dadosCam_t_e_ta(_, S, A1, Tempo, _, _),
    ((Tempo < MenorTempo1, !, MenorTempo is Tempo, Arm = A1);
    MenorTempo is MenorTempo1, Arm = Arm1).



/* 
Heurística para a Entrega com a maior massa

heuristicaMassa(eTruck01, 20221205, R, T) vai procurar os armazens com entregas numa determinada data (20221205)
Passa a data e a lista para o predicado bfsMassa que realiza a pesquisa em largura (bfs) encontrando o caminho mais curto
entre o armazem de matosinhos e os de entrega e retorna em R.
Por fim, usa o predicado calcularTempo da US2 para calcular o tempo total da trajetoria tendo em conta a carga e restantes características.

bfsMassa faz a pesquisa em largura recebendo a data, a lista de armazens e uma lista R.
Usa o predicado entregaMassa para procurar o proximo armazem a ser visitado e adiciona-o à lista R.
Esse é removido da lista de entregas e chama recursivamente até a lista de entregas ficar vazia.

entregaMassa é usada para encontrar o proximo armazem pelo bfs.
Recebe uma lista de armazens, data, massa máxima e armazem inicial. A cada chamada recursiva, atualiza a massa máxima
e o armazem escolhido. Se a massa da entrega no armazem A1 for maior que a massa atual então a massa é atualizada e o armazem escolhido também. 
Caso contrário, a massa máxima e o armazém mantêm-se.
*/
heuristicaMassa(T, D, R, Tempo) :-
    armazensEntregasData(L, D),
    bfsMassa(D, L, R),
    calcularTempo(D, T, R, Tempo), !,
    entregaMassa(L, D, MaiorMassa, _).
    %format('Entrega com maior massa: ~0f~n', [MaiorMassa]),
    %format('Tempo: ~3f~n', [Tempo]).

bfsMassa(_, [], []) :- !.
bfsMassa(D, [A|ResArms], [PA|R]) :- 
    entregaMassa([A|ResArms], D, _, PA),
    delete([A|ResArms], PA, FA),
    bfsMassa(D, FA, R).

entregaMassa([], _, 0, _) :- !.
entregaMassa([A1|Arms], D, MaiorMassa , Arm) :-
    entregaMassa(Arms , D, MaiorMassa1, Arm1),
    entrega(_, D, Massa, A1, _, _),
    ((Massa > MaiorMassa1, !, MaiorMassa is Massa, Arm = A1);
    MaiorMassa is MaiorMassa1, Arm = Arm1), !.



/*
Heuristica para combinar o tempo de entrega com a massa entregue

heuristicaMassaTempo(eTruck01, 20221205, R, T) vai procurar a trajetória com maior lucro na relação massa/tempo.
Vai procurar os armazens com entregas numa determinada data e o id do armazem de matosinhos.
Passa a data, lista de armazéns, id de matosinhos e uma lista R para o predicado bfsMassaTempo que realiza a pesquisa em largura (bfs)

bfsMassaTempo faz a pesquisa em largura recebendo a data, armazem atual, lista de entregas e lista R.
usa o predicado relacaoMassaTempo para procurar o proximo armazem a ser visitado e adiciona-o à lista R.
Esse é removido da lista de entregas e chama recursivamente até a lista de entregas ficar vazia.

relacaoMassatempo é usada para calcular a relacao massa/tempo para cada armazem de entrega.
Recebe o armazem atual, lista de entregas, data e mais duas variaveis (Relacao e Arm) onde irão armazenar o valor máximo da Relacao e
e o Armazem (Arm) correspondente. Se a relação massa/tempo para o armazém atual for maior que a relação máxima encontrada
até ao momento, então atualiza o valor e o armazém, se não, continuam com os mesmos valores.
*/
heuristicaMassaTempo(T, D, R, Tempo) :-
    armazensEntregasData(L, D),
    idArmazem('Matosinhos', IdA),
    bfsMassaTempo(D, IdA, L, R),
    calcularTempo(D, T, R, Tempo), !,
    relacaoMassaTempo(IdA, L, D, Relacao, _).
    %format('Best Relation Mass/Time: ~3f~n', [Relacao]), 
    %format('Fastest Time rounded: ~3f~n', [Tempo]).

bfsMassaTempo(_, _, [], []) :- !.
bfsMassaTempo(D, S, [A|ResArms], [PA|R]) :-
    relacaoMassaTempo(S, [A|ResArms], D, _, PA),
    delete([A|ResArms], PA, FA),
    bfsMassaTempo(D, PA, FA, R).

relacaoMassaTempo(_, [], _, 0, _) :- !.
relacaoMassaTempo(S, [A1|Arms], D, Relacao, Arm):-
    relacaoMassaTempo(S, Arms, D, Relacao1, Arm1),
    dadosCam_t_e_ta(_, S, A1, Tempo, _, _),
    entrega(_, D, Massa, A1, _, _),
    (((Massa/Tempo) > Relacao1, !, Relacao is (Massa/Tempo), Arm = A1);
    Relacao is Relacao1, 
    Arm = Arm1), !.