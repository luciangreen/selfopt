% Theorems about selfopt, proved by exhaustion. Run: swipl -g main -t halt proofs/theorems.pl
:- module(theorems, [main/0]).
:- use_module('../prolog/selfopt').
:- use_module(prove).
:- discontiguous theorem/1.
:- use_module(library(lists)).
:- use_module(library(apply)).
main :- prove_all(theorems).

% Domain: every task; test sets drawn from every input of a small size (lists of length 0..3 over 0..2; fib of 0..7).
input(fib, N) :- !, between(0, 7, N).
input(_, L) :- between(0, 3, K), length(L, K), maplist([X]>>between(0, 2, X), L).
testset(T, Ts) :- findall(I, input(T, I), All), member(Ts, [All, [], [hd]]), Ts \== [hd].
testset(T, [I]) :- input(T, I).

% 1. Everything in the history agrees with the original on every test.
theorem(history_agrees_with_original) :-
    forall(( task(T, _, Vs), Vs = [V0-_|_], testset(T, Ts), evolve(T, Ts, H), member(N-_, H) ),
           ( total_steps(Vs, V0, Ts, O1, _), total_steps(Vs, N, Ts, O2, _), O1 == O2 )).

% 2. The history only gets faster: each kept version takes fewer steps than the one before.
theorem(history_strictly_faster) :-
    forall(( task(T, _, _), testset(T, Ts), evolve(T, Ts, H), nextto(_-A, _-B, H) ), B < A).

% 3. A version that is wrong on some test is never accepted.
theorem(wrong_versions_rejected) :-
    forall(( task(T, _, Vs), member(wrong-_, Vs), testset(T, Ts), Vs = [V0-_|_], total_steps(Vs, V0, Ts, O1, _), total_steps(Vs, wrong, Ts, O2, _), O1 \== O2 ),
           ( evolve(T, Ts, H), \+ memberchk(wrong-_, H) )).

% 4. The meta-interpreter gives the same answers as running the clauses as ordinary Prolog would (the
%    known results for reverse, sum and Fibonacci).
theorem(interpreter_is_correct) :-
    forall(( input(rev, L), task(rev, _, Vs), member(V, [naive, acc]) ), ( steps(Vs, V, L, O, _), reverse(L, O) )),
    forall(( input(sum, L), task(sum, _, Vs), member(V, [plain, acc]) ), ( steps(Vs, V, L, O, _), sum_list(L, O) )),
    forall(( input(fib, N), task(fib, _, Vs) ), ( steps(Vs, naive, N, A, _), steps(Vs, iter, N, B, _), A == B )).

% 5. Step counts are deterministic: the same run always counts the same steps.
theorem(steps_are_deterministic) :-
    forall(( task(T, _, Vs), member(V-_, Vs), input(T, I) ), ( findall(S, steps(Vs, V, I, _, S), [_]) )).
