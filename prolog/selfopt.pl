% selfopt: a repo that rewrites its own code and keeps a change only when it is proven equal on
% the tests and measurably faster. Speed is counted in resolution steps by a small
% meta-interpreter, so it is the same on every machine. Each accepted version goes into the
% history, so the history only ever gets faster.
% A version is Name-Clauses, where Clauses are (Head :- Body) terms run by the meta-interpreter.
%?- task(rev, T, Vs), steps(Vs, naive, [1,2,3], Out, S).       % Out = [3,2,1], S = naive's step count
%?- evolve(rev, [[], [1,2], [1,2,3,4]], H).                    % H = [naive-Steps0, acc-Steps1], Steps1 < Steps0
%?- accept(sum, plain, wrong, [[1,2]], D).                     % D = reject(wrong_on([1,2]))
:- module(selfopt, [task/3, solve/5, steps/5, total_steps/5, accept/5, evolve/3]).
:- use_module(library(lists)).
:- use_module(library(apply)).

% task(Name, In^Out^Goal, Versions): the entry goal and its versions, the original first.
task(rev, In^Out^rev(In, Out), [
    naive-[ (rev([], []) :- true), (rev([H|T], R) :- rev(T, RT), app(RT, [H], R)),
            (app([], L, L) :- true), (app([H|T], L, [H|R]) :- app(T, L, R)) ],
    acc-[ (rev(L, R) :- rev3(L, [], R)), (rev3([], A, A) :- true), (rev3([H|T], A, R) :- rev3(T, [H|A], R)) ],
    wrong-[ (rev(L, L) :- true) ] ]).
task(sum, In^Out^sum(In, Out), [
    plain-[ (sum([], 0) :- true), (sum([X|Xs], S) :- sum(Xs, S0), S is S0 + X) ],
    acc-[ (sum(L, S) :- sum3(L, 0, S)), (sum3([], A, A) :- true), (sum3([X|Xs], A, S) :- A1 is A + X, sum3(Xs, A1, S)) ],
    wrong-[ (sum([], 0) :- true), (sum([_|Xs], S) :- sum(Xs, S0), S is S0 + 1) ] ]).
task(fib, In^Out^fib(In, Out), [
    naive-[ (fib(0, 0) :- true), (fib(1, 1) :- true), (fib(N, F) :- N > 1, A is N - 1, B is N - 2, fib(A, FA), fib(B, FB), F is FA + FB) ],
    iter-[ (fib(N, F) :- fib4(N, 0, 1, F)), (fib4(0, A, _, A) :- true), (fib4(N, A, B, F) :- N > 0, M is N - 1, C is A + B, fib4(M, B, C, F)) ] ]).

% solve(+Clauses, +Goal, +Steps0, -Steps, +Limit): first solution, counting steps.
solve(_, true, S, S, _) :- !.
solve(P, (A, B), S0, S, L) :- !, solve(P, A, S0, S1, L), solve(P, B, S1, S, L).
solve(_, G, S0, S, _) :- builtin(G), !, call(G), S is S0 + 1.
solve(P, G, S0, S, L) :- S0 < L, member(C, P), copy_term(C, (H :- B)), H = G, S1 is S0 + 1, solve(P, B, S1, S, L).
builtin(G) :- functor(G, F, A), memberchk(F/A, [(is)/2, (=)/2, (<)/2, (>)/2, (=<)/2, (>=)/2, (=:=)/2]).

% steps(+Versions, +Name, +Input, -Output, -Steps)
steps(Vs, Name, In, Out, S) :- memberchk(Name-P, Vs), member(T-Vs, [_-Vs]), task_goal(T, Vs, In, Out, G), once(solve(P, G, 0, S0, 100000)), S = S0.
task_goal(_, Vs, In, Out, G) :- task(_, Tpl, Vs), !, copy_term(Tpl, In^Out^G).
total_steps(Vs, Name, Tests, Outs, Total) :- maplist([I, O-S]>>steps(Vs, Name, I, O, S), Tests, OS), pairs_keys_values(OS, Outs, Ss), sum_list(Ss, Total).

% accept(+Task, +Current, +Candidate, +Tests, -Decision): accept(Before, After), or reject(Why).
accept(Task, Cur, Cand, Tests, D) :- task(Task, _, Vs),
    total_steps(Vs, Cur, Tests, O1, T1), total_steps(Vs, Cand, Tests, O2, T2),
    (   nth1(I, Tests, In), nth1(I, O1, A), nth1(I, O2, B), A \== B -> D = reject(wrong_on(In))
    ;   T2 >= T1 -> D = reject(not_faster(T1, T2))
    ;   D = accept(T1, T2) ).

% evolve(+Task, +Tests, -History): try each later version in turn; keep it if accepted.
evolve(Task, Tests, H) :- task(Task, _, [V0-_|Vs]), task(Task, _, All), total_steps(All, V0, Tests, _, T0),
    foldl([Name-_, Cur-Hist0, Next-Hist]>>( accept(Task, Cur, Name, Tests, accept(_, T)) -> Next = Name, append(Hist0, [Name-T], Hist) ; Next = Cur, Hist = Hist0 ),
          Vs, V0-[V0-T0], _-H0), H = H0.
