use Test;
use Test::Propositional;

use Propositional;
use Propositional::AST;

plan 13;

# TODO: rewrite returns spread formulas. We should not rely on
# string comparison with hardcoded strings in the expectations,
# but use `φ.spread` for the correct φ.

is `:p, `:p, 'variable caching works';

is (¬(¬`:p ∧ `:q)).rewrite((^:p ∧ `:q) => { $:p }),
    "(¬ (¬ p))",
    "rewrite does not swallow operators";

is (¬¬¬`:p).rewrite((¬¬^:p) => { ¬$:p }),
    "(¬ p)",
    "performs multiple rewrites";

is (¬¬`:p).rewrite((¬¬^:p) => { $:p }, :1ce),
    "p",
    "operator can produce variable";

subtest 'matcher' => {
    plan 4;

    is (¬¬`:p).rewrite((¬^:p) => { $:p ∧ $:p }),
    "(∧ (∧ (∧ p p) p) p)",
    "default matcher is True";

    is (¬¬`:p).rewrite((¬^:p(Propositional::Variable)) => { $:p ∧ $:p }),
    "(¬ (∧ p p))",
    "variable matcher restricts correctly";

    is (`:a ∧ `:m ∧ `:n ∧ `:z).rewrite(:1ce, (^:p(subset :: of Var where *.name.ord ≤ 109)) => { ¬$:p }).squish,
    "(∧ (¬ a) (¬ m) n z)",
    "non-trivial subset matcher";

    is (`:a ∧ `:m ∧ `:n ∧ `:z).rewrite(:1ce, (^:p({ quietly .?name ~~ /^<[a..m]>$/ })) => { ¬$:p }).squish,
    "(∧ (¬ a) (¬ m) n z)",
    "non-trivial callable matcher";
}

subtest 'rewrite times' => {
    plan 4;

    is (¬`:p ⇒ `:q).rewrite(:1ce,
        (  ^:p(Propositional::Variable)) => { ¬$:p },
        (¬¬^:p(Propositional::Variable)) => {  $:p },
        ),
        "(⇒ p (¬ q))",
        ":1ce";

    is (¬`:p ⇒ `:q).rewrite(:2ce,
        (  ^:p(Propositional::Variable)) => { ¬$:p },
        (¬¬^:p(Propositional::Variable)) => {  $:p },
        ),
        "(⇒ (¬ p) q)",
        ":2ce";

    is (¬`:p ⇒ `:q).rewrite(:3ce,
        (  ^:p(Propositional::Variable)) => { ¬$:p },
        (¬¬^:p(Propositional::Variable)) => {  $:p },
        ),
        "(⇒ p (¬ q))",
        ":3ce";

    is (¬`:p ⇒ `:q).rewrite(:4times,
        (  ^:p(Propositional::Variable)) => { ¬$:p },
        (¬¬^:p(Propositional::Variable)) => {  $:p },
        ),
        "(⇒ (¬ p) q)",
        ":4times";
}

is (¬`:p ⇒ `:q)\
    .rewrite((  ^:p(Propositional::Variable)) => { ¬$:p }, :1ce)
    .rewrite((¬¬^:p(Propositional::Variable)) => {  $:p }, :1ce),
    "(⇒ p (¬ q))",
    "toggle negations at variables";

is (¬(¬`:p ⇒ `:q))\
    .rewrite((  ^:p(Propositional::Variable)) => { ¬$:p }, :1ce)
    .rewrite((¬¬^:p(Propositional::Variable)) => {  $:p }, :1ce),
    "(¬ (⇒ p (¬ q)))",
    "toggle negations at variables only";

subtest "listy operators" => {
    plan 3;

    is (`:p ∧ `:q ∧ `:r).rewrite((^:p ∧ ^:q) => { $:p ∨ $:q }).squish,
        "(∨ p q r)",
        "rewrite works on listy operators";

    is (`:p ∧ `:q ∧ `:r).spread.rewrite((^:p ∧ ^:q ∧ ^:r) => { $:p ∨ $:q ∨ $:r }).squish,
        "(∨ p q r)",
        "rewrite works with listy pattern";

    is (`:p ∧ `:q ∧ (¬`:p ∨ `:r ∨ `:s) ∧ `:t).rewrite(
        (^:p ∧ ^:__ ∧ (^:r ∨ ^:__) ∧ ^:t) => {
            # Touch them all to give this callable the right signature
            sink $:p, $:r, $:t, $:__;
            $:p ∨ $:r ∨ $:t
        }).squish,
        "(∨ p (¬ p) r t)",
        "complex listy rewrite";
}

is (`:x ⇔ `:y ∨ (`:z ∧ `:x)).rewrite(
    (  ^:p ⇔ ^:q)       => { ($:p ⇒  $:q) ∧ ($:q ⇒ $:p) },
    (  ^:p ⇒ ^:q)       => { ¬$:p ∨  $:q                },
    (¬(^:p ∨ ^:q))      => { ¬$:p ∧ ¬$:q                },
    (¬(^:p ∧ ^:q))      => { ¬$:p ∨ ¬$:q                },
    (¬¬^:p)             => {  $:p                       },
    (^:p ∨ (^:q ∧ ^:r)) => { ($:p ∨  $:q) ∧ ($:p ∨ $:r) },
    ((^:q ∧ ^:r) ∨ ^:p) => { ($:p ∨  $:q) ∧ ($:p ∨ $:r) },
    ).squish,
    "(∧ (∨ z (¬ x) y) (∨ z (¬ y) x) (∨ x (¬ x) y) (∨ x (¬ y) x))",
    "CNF with all rewrite rules at once";

subtest 'NNF' => {
    plan 12;

    skip 'NNF not implemented for variable';
    #ok-NNF   `:x;
    ok-NNF  ¬`:x;
    ok-NNF   `:x ∧ `:y;
    ok-NNF ¬(`:x ∧ `:y);
    ok-NNF   `:x ∨ `:y;
    ok-NNF ¬(`:x ∨ `:y);
    ok-NNF   `:x ⇒ `:y;
    ok-NNF  ¬`:x ⇒ `:y;
    ok-NNF ¬(`:x ⇒ `:y);
    ok-NNF   `:x ⇔ `:y;
    ok-NNF ¬(`:x ⇔ `:y);
    ok-NNF  `:x ⇔ `:y ∨ (`:z ∧ `:x);
}

subtest 'CNF' => {
    plan 12;

    skip 'CNF not implemented for variable';
    #ok-CNF  `:x;
    ok-CNF  ¬`:x;
    ok-CNF   `:x ∧ `:y;
    ok-CNF ¬(`:x ∧ `:y);
    ok-CNF   `:x ∨ `:y;
    ok-CNF ¬(`:x ∨ `:y);
    ok-CNF   `:x ⇒ `:y;
    ok-CNF  ¬`:x ⇒ `:y;
    ok-CNF ¬(`:x ⇒ `:y);
    ok-CNF   `:x ⇔ `:y;
    ok-CNF ¬(`:x ⇔ `:y);
    ok-CNF  `:x ⇔ `:y ∨ (`:z ∧ `:x);
}

subtest 'DNF' => {
    plan 12;

    skip 'DNF not implemented for variable';
    #ok-DNF  `:x;
    ok-DNF  ¬`:x;
    ok-DNF   `:x ∧ `:y;
    ok-DNF ¬(`:x ∧ `:y);
    ok-DNF   `:x ∨ `:y;
    ok-DNF ¬(`:x ∨ `:y);
    ok-DNF   `:x ⇒ `:y;
    ok-DNF  ¬`:x ⇒ `:y;
    ok-DNF ¬(`:x ⇒ `:y);
    ok-DNF   `:x ⇔ `:y;
    ok-DNF ¬(`:x ⇔ `:y);
    ok-DNF  `:x ⇔ `:y ∨ (`:z ∧ `:x);
}
