:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(dcg/basics)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/json_convert)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/json)).

%:- consult('BaseDeConhecimento.pl').
:- include('US1.pl').
:- include('US2.pl').
%:- include('US3.pl').
:- include('US4.pl').

:- http_handler('/getBestRoute', obterMelhorViagem, []).
:- http_handler('/getHDist', obterHDistancia, []).
:- http_handler('/getHMassa', obterHMassa, []).
:- http_handler('/getHMassaTempo', obterHMassaTempo, []).

:- json_object melhorViagem(melhor_Viagem:list(string)).
:- json_object heuristicaDistancia(h_dist:list(string)).
:- json_object heuristicaMassa(h_massa:list(string)).
:- json_object heuristicaMassaTempo(h_massa_tempo:list(string)).
:- set_setting(http:cors, [*]).

% ---------------------

startServer :-
    http_server(http_dispatch, [port(3500)]),
    write("Server iniciado.").

stopServer :-
    http_stop_server(3500, _).

% ---------------------

/*welcome(Request) :-
    write('HTTP Server - PROLOG - Is ready!').*/

trim(S, T) :-
    string_codes(S, C),
    phrase(trimmed(D), C),
    string_codes(T, D).

trimmed(S) --> blanks, string(S), blanks, eos, !.

% 'http://localhost:3500/getBestRoute?date=20221205&truck=eTruck01'
obterMelhorViagem(Request) :-
    cors_enable(Request, [methods([get])]),
    format('Access-Control-Allow-Origin: ~w~n', [*]),
    format('Access-Control-Allow-Headers: ~w~n', [*]),
    http_parameters(Request,
                        [date(Date, []),
                        truck(Truck, [])]
                    ),
    %write("TESTE: "), write([date(Date, [])]),
    %write("Date antes TRIM- "), write(Date),
    trim(Date, O),
    %write("Date- "), write(Date),
    %write("O-"), write(O),
    number_string(DD, O),
    melhorViagem(DD, Truck, List, _),
    /* prolog_to_json(melhorViagem(L), JSONObject), */
    %write("Antes do prolog_json"),
    prolog_to_json(melhorViagem(List), JSONObject),
    reply_json(JSONObject, [json_object(dict)]).

% 'http://localhost:3500/getHDist?date=20221205&truck=eTruck01'
obterHDistancia(Request) :-
    cors_enable(Request, [methods([get])]),
    format('Access-Control-Allow-Origin: ~w~n', [*]),
    format('Access-Control-Allow-Headers: ~w~n', [*]),
    http_parameters(Request,
                        [date(Date, []),
                        truck(Truck, [])]
                    ),
    trim(Date, O),
    number_string(DD, O),
    heuristicaDistancia(Truck, DD, List, _),
    prolog_to_json(heuristicaDistancia(List), JSONObject),
    reply_json(JSONObject, [json_object(dict)]).

% 'http://localhost:3500/getHMassa?date=20221205&truck=eTruck01'
obterHMassa(Request) :-
    cors_enable(Request, [methods([get])]),
    format('Access-Control-Allow-Origin: ~w~n', [*]),
    format('Access-Control-Allow-Headers: ~w~n', [*]),
    http_parameters(Request,
                        [date(Date, []),
                        truck(Truck, [])]
                    ),
    trim(Date, O),
    number_string(DD, O),
    heuristicaMassa(Truck, DD, List, _),
    prolog_to_json(heuristicaMassa(List), JSONObject),
    reply_json(JSONObject, [json_object(dict)]).

% 'http://localhost:3500/getHMassaTempo?date=20221205&truck=eTruck01'
obterHMassaTempo(Request) :-
    cors_enable(Request, [methods([get])]),
    format('Access-Control-Allow-Origin: ~w~n', [*]),
    format('Access-Control-Allow-Headers: ~w~n', [*]),
    http_parameters(Request,
                        [date(Date, []),
                        truck(Truck, [])]
                    ),
    trim(Date, O),
    number_string(DD, O),
    heuristicaMassaTempo(Truck, DD, List, _),
    prolog_to_json(heuristicaMassaTempo(List), JSONObject),
    reply_json(JSONObject, [json_object(dict)]).