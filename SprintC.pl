/*

Como gestor de logística pretendo uma solução para o problema usando Algoritmos Genéticos

*/

:- consult('BaseDeConhecimento.pl').

:- include('US1.pl').
:- include('US2.pl').
:- include('US4.pl').

%entregas(NEntregas).
entregas(5).

% parameterização
inicializa :- 
    write('Numero de novas Geracoes: '),
    read(NG), 
    (retract(geracoes(_));true), asserta(geracoes(NG)),
    write('Dimensao da Populacao: '),
    read(DP), 
    (retract(populacao(_));true), asserta(populacao(DP)), 
    write('Probabilidade de Cruzamento (%):'), 
    read(P1),
    PC is P1/100,
    (retract(prob_cruzamento(_));true), asserta(prob_cruzamento(PC)), 
    write('Probabilidade de Mutacao (%):'), 
    read(P2),
    PM is P2/100,
    (retract(prob_mutacao(_));true), asserta(prob_mutacao(PM)).

gera :-
    inicializa,
    calcularCamioes(NumCamioes),
    entregasCamioes(EntregasDistribuidas, NumCamioes),
    gera_populacao(Pop),
    write('Pop='),
    write(Pop),
    nl,
    obterPopulacao(Pop, NumCamioes, EntregasDistribuidas, [], PopAtualizada),
    avalia_populacao(PopAtualizada, PopAv, NumCamioes, EntregasDistribuidas), 
    write('PopAv='),
    write(PopAv),
    nl, 
    ordena_populacao(PopAv, PopOrd), 
    geracoes(NG), 
    get_time(TempoExecucao),
    TempoMax is 3600,
	Estabilizacao is 1, 
	GenIguais is 0,
    gera_geracao(0, NG, PopOrd, TempoExecucao, TempoMax, 0, GenIguais, Estabilizacao, MelhorViagem*TempoViagem, NumCamioes, EntregasDistribuidas),
    nl,
	write('Melhor Viagem: '),write(MelhorViagem),
    nl,
	write('Tempo Viagem: '),write(TempoViagem).

/*gera(NG, DP, P1, P2) :-
    inicializa(NG, DP, P1, P2),
    calcularCamioes(NumCamioes),
    entregasCamioes(EntregasDistribuidas, NumCamioes),
    gera_populacao(Pop),
    write('Pop='),
    write(Pop),
    nl,
    obterPopulacao(Pop, NumCamioes, EntregasDistribuidas, [], PopAtualizada),
    avalia_populacao(PopAtualizada, PopAv, NumCamioes, EntregasDistribuidas), 
    write('PopAv='),
    write(PopAv),
    nl, 
    ordena_populacao(PopAv, PopOrd), 
    geracoes(NG), 
    get_time(TempoExecucao),
    TempoMax is 3600,
	Estabilizacao is 1, 
	GenIguais is 0,
    gera_geracao(0, NG, PopOrd, TempoExecucao, TempoMax, 0, GenIguais, Estabilizacao, MelhorViagem*TempoViagem, NumCamioes, EntregasDistribuidas),
    nl,
	write('Melhor Viagem: '),write(MelhorViagem),
    nl,
	write('Tempo Viagem: '),write(TempoViagem).
*/

calcularCamioes(NumCamioes) :-
    findall(Massa, entrega(_, 20221205, Massa, _, _, _), Cargas),
	obterCargaTotal(Cargas, 0, CargaTotal),
	carateristicasCam(eTruck01, _, CapCarga, _, _, _),
	NumeroCamioes is CargaTotal/CapCarga,
	numeroCamioesEntrega(NumeroCamioes, NumCamioes).

obterCargaTotal([], CargaTotal, CargaTotal) :- !.

obterCargaTotal([H|T], CargaTotal1, CargaTotal) :-
    CargaTotal2 is CargaTotal1+H,
	obterCargaTotal(T, CargaTotal2, CargaTotal).

numeroCamioesEntrega(NumeroCamioes, NumCamioes) :-
    Inteiro is float_integer_part(NumeroCamioes),
	Decimal is float_fractional_part(NumeroCamioes),
	((Decimal > 0.75, NumCamioes is Inteiro+2); NumCamioes is Inteiro+1).

entregasCamioes(EntregasDistribuidas, NumCamioes) :-
    entregas(NEntregas),
	EntregasDistribuidasAux is NEntregas/NumCamioes,
	EntregasDistribuidas is float_integer_part(EntregasDistribuidasAux).

gera_populacao(Pop) :-
    populacao(TamPop),
    findall(EntregaArm, entrega(_, 20221205, _, EntregaArm, _, _), ListaArmazens),
    length(ListaArmazens, NumT),
    gera_populacao(TamPop, ListaArmazens, NumT, Pop).

gera_populacao(0, _, _, []) :- !.
gera_populacao(TamPop, ListaArmazens, NumT, [Ind|Resto]) :-
    TamPop1 is TamPop-1,
    gera_populacao(TamPop1, ListaArmazens, NumT, Resto),
    ((TamPop1 == 0, heuristicaDistancia(20221205, eTruck01, Ind, _), !);
	((TamPop1 == 1, heuristicaMassaTempo(eTruck01, 20221205, Ind, _), !);
    (gera_individuo(ListaArmazens, NumT, Ind)))),
    not(member(Ind, Resto)).

gera_populacao(TamPop, ListaArmazens, NumT, L):- 
    gera_populacao(TamPop, ListaArmazens, NumT, L).

gera_individuo([G], 1, [G]) :- !.

gera_individuo(ListaArmazens, NumT, [G|Resto]):-
    NumTemp is NumT + 1,
    random(1, NumTemp, N),
    retira(N, ListaArmazens, G, NovaLista),
    NumT1 is NumT-1,
    gera_individuo(NovaLista, NumT1, Resto).

avaliaInd(_, _, _, _, 1, ValidaViagem) :-
    ValidaViagem is 1, !.

avaliaInd(_, _, _, _, 2, ValidaViagem) :-
    ValidaViagem is 0, !.

avaliaInd(Ind, Avaliacoes, NumCamioes, EntregasDistribuidas, 0, ValidaViagem):-
	((Avaliacoes < (NumCamioes), obterElementos(EntregasDistribuidas, Ind, EntregasCamiao),
  obterCargaCamiao(20221205, EntregasCamiao, CargaV, CargaTotal), Flag is 0);
  (obterCargaCamiao(20221205, Ind, CargaV, CargaTotal), Flag is 2)),
	((CargaTotal > 4300, avaliaInd(_, NumCamioes, NumCamioes, _, 1, ValidaViagem));
	(AvaliacaoAtual is Avaliacoes+1, removerElementos(EntregasDistribuidas, Ind, IndAtualizada),
	avaliaInd(IndAtualizada, AvaliacaoAtual, NumCamioes, EntregasDistribuidas, Flag, ValidaViagem))).

obterPopulacao([], _, _, PopRes, PopAtual) :-
    PopAtual = PopRes,!.

obterPopulacao([P1|Resto], NumCamioes, EntregasDistribuidas, PopRes, Sol):-
	avaliaInd(P1, 1, NumCamioes, EntregasDistribuidas, 0, ValidaViagem),
	((ValidaViagem == 1, random_permutation(P1, NovoMembro), append(Resto, [NovoMembro], PopNova),
	 obterPopulacao(PopNova, NumCamioes, EntregasDistribuidas, PopRes, Sol));
	 (append(PopRes, [P1], PopAtual), obterPopulacao(Resto, NumCamioes, EntregasDistribuidas, PopAtual, Sol))).

obterElementos(0.0, _, []) :- !.	

obterElementos(X,[H|T], [H|Resto]) :-
	X1 is X-1,
	obterElementos(X1, T, Resto).

removerElementos(_, [], []) :- !.
removerElementos(0.0, L, L) :- !.
removerElementos(N, [_|T], L) :-
    N1 is N - 1,
    removerElementos(N1, T, L).

retira(1, [G|Resto], G, Resto). 
retira(N, [G1|Resto], G, [G1|Resto1]):- 
    N1 is N-1,
    retira(N1, Resto, G, Resto1).

avalia_populacao([], [], _, _) :- !.
avalia_populacao([Ind|Resto], [Ind*V|Resto1], NumCamioes, EntregasDistribuidas) :-
    Camioes is truncate(NumCamioes),
    calcularTempo(20221205, eTruck01, Ind, V),
    avalia_populacao(Resto, Resto1, NumCamioes, EntregasDistribuidas).

%avalia(Seq,V):- 
    %avalia(Seq,0,V).

%avalia([ ],_,0).
%avalia([T|Resto],Inst,V):-
    %tarefa(T,Dur,Prazo,Pen)(Id,TempoProcessamento,TempConc,PesoPenalizacao),
    %entrega(_,Dur,Prazo,Pen,_,_),
    %InstFim is Inst+Dur,
    %avalia(Resto,InstFim,VResto),
    %((InstFim =< Prazo,!, VT is 0) ; (VT is (InstFim-Prazo)*Pen)), 
    %V is VT+VResto.

ordena_populacao(PopAv, PopAvOrd):- 
    bsort(PopAv, PopAvOrd).

bsort([X],[X]) :- !.
bsort([X|Xs], Ys):-
    bsort(Xs, Zs), 
    btroca([X|Zs], Ys).

btroca([X],[X]) :- !.
btroca([X*VX,Y*VY|L1], [Y*VY|L2]):- 
    VX>VY, !,
    btroca([X*VX|L1], L2).

btroca([X|L1],[X|L2]) :-
    btroca(L1, L2).

ordenaPopProbabilidade(PopAv, PopAvOrd) :-
	bsortProbabilidade(PopAv, PopAvOrd).

bsortProbabilidade([X], [X]) :- !.
bsortProbabilidade([X|Xs], Ys) :-
	bsortProbabilidade(Xs, Zs),
	btrocaProbabilidade([X|Zs], Ys).

btrocaProbabilidade([X],[X]) :- !.

btrocaProbabilidade([X*VX*VZ,Y*VY*VW|L1], [Y*VY*VW|L2]) :-
	VZ>VW, !,
	btrocaProbabilidade([X*VX*VZ|L1], L2).

btrocaProbabilidade([X|L1], [X|L2]) :-
    btrocaProbabilidade(L1, L2).

gera_geracao(G, G, Pop, _, _, 0, _, _, MViagem, _, _) :- !,
    Pop = [MViagem | _],
    write('Geração '), write(G), write(':'), nl, write(Pop), nl.

gera_geracao(G, _, Pop, _, _, 1, _, _, MViagem, _, _) :- !,
	Pop = [MViagem | _],
	write('Geracao '), write(G), write(':'), nl, write(Pop), nl,
	write('Tempo Maximo Atingido.'),nl.

gera_geracao(G, _, Pop, _, _, 0, Estabilizacao, Estabilizacao, MViagem, _, _) :- !,
	Pop = [MViagem | _],
	write('Geracao '), write(G), write(':'), nl, write(Pop), nl,
	write('Geracao Estabilizada.'),nl.

gera_geracao(N, G, Pop, TempoInicial, TempoMax, 0, GenIguaisAnt, Estabilizacao, MViagem, NumCamioes, EntregasDistribuidas) :-
    write('Geração '), write(N), write(':'), nl, write(Pop), nl,
    random_permutation(Pop, PopAleatoria),
    cruzamento(PopAleatoria, NPop1),
    mutacao(NPop1, NPop),
    obterPopulacao(NPop, NumCamioes, EntregasDistribuidas, [], PopAtualizada),
    avalia_populacao(PopAtualizada, NPopAv, NumCamioes, EntregasDistribuidas),
    append(Pop, NPopAv, Populacao),
	sort(Populacao, Aux),
	ordena_populacao(Aux, NPopOrd),
	obterMelhores(NPopOrd, 2, Melhores, Restantes),
    probabilidadeRes(Restantes, ProbRestantes),
	ordenaPopProbabilidade(ProbRestantes, ProbRestantesOrd),
	populacao(TamPop),
	ElementosF is TamPop-2,
	retirarExtra(ProbRestantesOrd, ElementosF, ListaMelhores),
	append(Melhores, ListaMelhores, ProxGen),
	ordena_populacao(ProxGen, ProxGenOrd),
	N1 is N+1,
	get_time(Tf),
	TempExec is Tf-TempoInicial,
	obterTempoExec(TempExec, TempoMax, FlagFim),
	verificarPopEstabilizada(Pop,ProxGenOrd, GenIguaisAnt, GenIguais),
	gera_geracao(N1, G, ProxGenOrd, TempoInicial, TempoMax, FlagFim, GenIguais, Estabilizacao, MViagem, NumCamioes, EntregasDistribuidas).

obterMelhores([H|NPopOrd], 0, [], [H|NPopOrd]).
obterMelhores([Ind|NPopOrd], P, [Ind|Melhores], Restantes) :-
	P1 is P-1,
	obterMelhores(NPopOrd, P1, Melhores, Restantes).

probabilidadeRes([],[]) :- !.
probabilidadeRes([Ind*Tempo|Restantes], [Ind*Tempo*Prob|ListaProb]) :-
	probabilidadeRes(Restantes, ListaProb), 
	random(0.0, 1.0, NumAl), Prob is NumAl * Tempo.

retirarExtra([H|ListaProdutoRestantesOrd], 0, []).
retirarExtra([Ind*Tempo*Prob|ListaProdutoRestantesOrd], NP, [Ind*Tempo|ListaMelhores]) :-
	NP1 is NP-1,
	retirarExtra(ListaProdutoRestantesOrd, NP1, ListaMelhores).

obterTempoExec(TempExec, TempoMax, FlagFim):- 
	((TempExec < TempoMax, FlagFim is 0); (FlagFim is 1)).

verificarPopEstabilizada(Pop, ProxGenOrd, GenIguaisAnt, GenIguais):-
	((verificarPopulacoes(Pop,ProxGenOrd), !, GenIguais is GenIguaisAnt+1);
	(GenIguais is 0)).

verificarPopulacoes([], []) :- !.
verificarPopulacoes([P1|Populacao], [P2|ProxGen]):-
	P1=P2, 
	verificarPopulacoes(Populacao, ProxGen).

gerar_pontos_cruzamento(P1, P2):- 
    gerar_pontos_cruzamento1(P1, P2).

gerar_pontos_cruzamento1(P1,P2):- 
    entregas(N),
    NTemp is N+1,
    random(1, NTemp, P11),
    random(1, NTemp, P21),
    P11\==P21, !,
    ((P11<P21, !, P1=P11, P2=P21); P1=P21, P2=P11).

gerar_pontos_cruzamento1(P1, P2):-   
    gerar_pontos_cruzamento1(P1, P2).

cruzamento([ ], [ ]).
cruzamento([Ind*_], [Ind]).
cruzamento([Ind1*_, Ind2*_|Resto], [NInd1,NInd2|Resto1]) :-
    gerar_pontos_cruzamento(P1, P2), 
    prob_cruzamento(Pcruz),
    random(0.0, 1.0, Pc), 
    ((Pc =< Pcruz, !, cruzar(Ind1,Ind2,P1,P2,NInd1), cruzar(Ind2,Ind1,P1,P2,NInd2)); 
    (NInd1=Ind1, NInd2=Ind2)),
    cruzamento(Resto, Resto1).

preencheh([ ],[ ]).
preencheh([_|R1], [h|R2]):- 
    preencheh(R1, R2).

sublista(L1, I1, I2, L):-
    I1 < I2, 
    !, 
    sublista1(L1, I1, I2, L).

sublista(L1, I1, I2, L):-
    sublista1(L1, I2, I1, L). 

sublista1([X|R1], 1, 1, [X|H]) :- !, 
    preencheh(R1, H). 
    
sublista1([X|R1], 1, N2, [X|R2]) :-
    !,
    N3 is N2 - 1,
    sublista1(R1, 1, N3, R2).

sublista1([_|R1], N1, N2, [h|R2]) :-
    N3 is N1 - 1, 
    N4 is N2 - 1,
    sublista1(R1, N3, N4, R2).

rotate_right(L, K, L1):- 
    entregas(N),
    T is N - K,
    rr(T, L, L1).
    
rr(0, L, L) :- !.
rr(N, [X|R], R2) :- 
    N1 is N - 1, 
    append(R, [X], R1),
    rr(N1, R1, R2).

elimina([], _, []) :- !.
elimina([X|R1], L, [X|R2]):- 
    not(member(X, L)),
    !, 
    elimina(R1, L, R2).

elimina([_|R1], L, R2):- 
    elimina(R1, L, R2).

insere([], L, _, L) :- !.

insere([X|R], L, N, L2) :-
    entregas(T),
    ((N>T, !, N1 is N mod T); N1 = N), 
    insere1(X, N1, L, L1),
    N2 is N + 1,
    insere(R, L1, N2, L2).

insere1(X, 1, L, [X|L]) :- !. 
insere1(X, N, [Y|L], [Y|L1]) :-
    N1 is N-1, 
    insere1(X, N1, L, L1).

cruzar(Ind1, Ind2, P1, P2, NInd11):- 
    sublista(Ind1, P1, P2, Sub1),
    entregas(NumT),
    R is NumT-P2, 
    rotate_right(Ind2, R, Ind21), 
    elimina(Ind21, Sub1, Sub2), 
    P3 is P2 + 1, 
    insere(Sub2, Sub1, P3, NInd1), 
    eliminah(NInd1, NInd11).

eliminah([],[]).
eliminah([h|R1], R2) :- !, 
    eliminah(R1, R2).

eliminah([X|R1], [X|R2]) :- 
    eliminah(R1, R2).

mutacao([], []).
mutacao([Ind|Rest], [NInd|Rest1]):-
    prob_mutacao(Pmut),
    random(0.0, 1.0, Pm),
    ((Pm < Pmut, !, mutacao1(Ind,NInd)); NInd = Ind), 
    mutacao(Rest, Rest1).

mutacao1(Ind, NInd):- 
    gerar_pontos_cruzamento(P1, P2),
    mutacao22(Ind, P1, P2, NInd).

mutacao22([G1|Ind], 1, P2, [G2|NInd]) :- !, 
    P21 is P2-1,
    mutacao23(G1, P21, Ind, G2, NInd). 

mutacao22([G|Ind], P1, P2, [G|NInd]) :-
    P11 is P1-1, 
    P21 is P2-1, 
    mutacao22(Ind, P11, P21, NInd).

mutacao23(G1, 1, [G2|Ind], G2, [G1|Ind]) :- !.
mutacao23(G1, P, [G|Ind], G2, [G|NInd]) :-
    P1 is P-1, 
    mutacao23(G1, P1, Ind, G2, NInd).