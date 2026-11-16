:- module(cases, [title/1, case/3]).
:- use_module('../prolog/selfopt').
:- use_module(engine).
title('selfopt').
list_g(L) :- rnd_int(0, 7, N), length(L, N), maplist([X]>>rnd_int(0, 9, X), L).
in_g(fib, N) :- !, rnd_int(0, 12, N).
in_g(_, L) :- list_g(L).
task_g(T) :- rnd_pick([rev, sum, fib], T).
case(steps, [T, V, I], steps_of) :- task_g(T), task(T, _, Vs), findall(N, member(N-_, Vs), Ns), rnd_pick(Ns, V), in_g(T, I).
case(evolve, [T, Ts], evolve) :- task_g(T), rnd_int(0, 4, K), length(Ts, K), maplist(in_g(T), Ts).
case(accept, [T, A, B, Ts], accept) :- task_g(T), task(T, _, Vs), findall(N, member(N-_, Vs), Ns), rnd_pick(Ns, A), rnd_pick(Ns, B), rnd_int(1, 3, K), length(Ts, K), maplist(in_g(T), Ts).
steps_of(T, V, I, O-S) :- task(T, _, Vs), steps(Vs, V, I, O, S).
