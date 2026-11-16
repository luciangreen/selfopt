# selfopt

a repo that rewrites its own code and keeps a change only when it is proven equal on the tests and measurably faster. Speed is counted in resolution steps by a small meta-interpreter, so it is the same on every machine. Each accepted version goes into the history, so the history only ever gets faster. A version is Name-Clauses, where Clauses are (Head :- Body) terms run by the meta-interpreter.

## Use

```prolog
?- use_module(prolog/selfopt).
?- task(rev, T, Vs), steps(Vs, naive, [1,2,3], Out, S).       % Out = [3,2,1], S = naive's step count
?- evolve(rev, [[], [1,2], [1,2,3,4]], H).                    % H = [naive-Steps0, acc-Steps1], Steps1 < Steps0
?- accept(sum, plain, wrong, [[1,2]], D).                     % D = reject(wrong_on([1,2]))
```

## Proofs

`proofs/theorems.pl` proves 5 theorems by exhaustion: each one is checked for every case in a finite domain that covers every branch of the definitions. every task; test sets drawn from every input of a small size (lists of length 0..3 over 0..2; fib of 0..7).

1. Everything in the history agrees with the original on every test.
2. The history only gets faster: each kept version takes fewer steps than the one before.
3. A version that is wrong on some test is never accepted.
4. The meta-interpreter gives the same answers as running the clauses as ordinary Prolog would (the known results for reverse, sum and Fibonacci).
5. Step counts are deterministic: the same run always counts the same steps.

```sh
swipl -g main -t halt proofs/theorems.pl
```

## 200 inputs and outputs

`io/ios.txt` lists 200 inputs and outputs from real runs, and `io/ios.pl` has the same as Prolog facts. The inputs come from a fixed seed (`io/cases.pl`). `swipl -g check -t halt io/run.pl` runs them again. It fails if any output changes, or if a predicate doesn't confirm its own recorded output, which checks steadfastness. GitHub Actions runs the proofs and the examples on every push, and records the examples on the first push.

Licence: BSD-3-Clause.
