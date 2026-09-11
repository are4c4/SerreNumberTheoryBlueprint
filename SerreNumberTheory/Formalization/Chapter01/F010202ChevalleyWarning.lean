import Mathlib.FieldTheory.ChevalleyWarning

namespace SerreNumberTheory

open MvPolynomial
open scoped BigOperators

/-!
# Chevalley-Warning の定理
-/

section ChevalleyWarning

variable (K : Type*) [Field K] [Fintype K] [DecidableEq K]
variable (p n : ℕ) [CharP K p]

/--
`n` 変数多項式 `f` の有限体 `K` 上での値の総和．
-/
noncomputable def evalSum
    (f : MvPolynomial (Fin n) K) : K :=
  ∑ x : Fin n → K, eval x f

/--
共通零点の特性関数として働く多項式．
-/
noncomputable def chevalleyAuxiliaryPolynomial
    {ι : Type*}
    [Fintype ι]
    (f : ι → MvPolynomial (Fin n) K) :
    MvPolynomial (Fin n) K :=
  ∏ i, (1 - f i ^ (Fintype.card K - 1))

omit [DecidableEq K] in
/--
全次数が `(q - 1) * n` より小さい多項式について，
有限体 `K` 上での値の総和は `0` である．
-/
theorem evalSum_eq_zero_of_totalDegree_lt
    (f : MvPolynomial (Fin n) K)
    (hdeg :
      f.totalDegree <
        (Fintype.card K - 1) * n) :
    evalSum (K := K) (n := n) f = 0 := by
  unfold evalSum

  apply MvPolynomial.sum_eval_eq_zero

  simpa using hdeg

omit [DecidableEq K] in
/--
`x` がすべての `f i` の共通零点ならば，
補助多項式の `x` における値は `1` である．
-/
theorem chevalleyAuxiliaryPolynomial_eval_eq_one
    {ι : Type*}
    [Fintype ι]
    (f : ι → MvPolynomial (Fin n) K)
    (x : Fin n → K)
    (hx : ∀ i, eval x (f i) = 0) :
    eval x
      (chevalleyAuxiliaryPolynomial
        (K := K) (n := n) f) = 1 := by
  classical

  have hq : 0 < Fintype.card K - 1 := by
    have hcard : 1 < Fintype.card K :=
      Fintype.one_lt_card
    omega

  simp [
    chevalleyAuxiliaryPolynomial,
    hx,
    zero_pow hq.ne'
  ]

omit [DecidableEq K] in
/--
ある `f i` が `x` で非零ならば，
補助多項式の `x` における値は `0` である．
-/
theorem chevalleyAuxiliaryPolynomial_eval_eq_zero
    {ι : Type*}
    [Fintype ι]
    (f : ι → MvPolynomial (Fin n) K)
    (x : Fin n → K)
    (hx : ∃ i, eval x (f i) ≠ 0) :
    eval x
      (chevalleyAuxiliaryPolynomial
        (K := K) (n := n) f) = 0 := by
  classical

  rcases hx with ⟨i, hi⟩

  have hpow :
      eval x (f i) ^ (Fintype.card K - 1) = 1 := by
    exact FiniteField.pow_card_sub_one_eq_one
      (eval x (f i)) hi

  rw [chevalleyAuxiliaryPolynomial]
  rw [eval_prod]

  apply Finset.prod_eq_zero (Finset.mem_univ i)

  simp [hpow]

/--
補助多項式は，共通零点集合の特性関数として働く．
-/
theorem chevalleyAuxiliaryPolynomial_eval
    {ι : Type*}
    [Fintype ι]
    (f : ι → MvPolynomial (Fin n) K)
    (x : Fin n → K) :
    eval x
      (chevalleyAuxiliaryPolynomial
        (K := K) (n := n) f) =
      if ∀ i, eval x (f i) = 0 then 1 else 0 := by
  classical

  by_cases hx : ∀ i, eval x (f i) = 0

  · rw [if_pos hx]
    exact chevalleyAuxiliaryPolynomial_eval_eq_one
      (K := K) (n := n) f x hx

  · rw [if_neg hx]
    apply chevalleyAuxiliaryPolynomial_eval_eq_zero
      (K := K) (n := n) f x

    push Not at hx
    exact hx

omit [DecidableEq K] in
/--
多項式族 `f i` の全次数の和が変数の個数 `n` より小さければ，
補助多項式の全次数は
`(Fintype.card K - 1) * n` より小さい．
-/
theorem chevalleyAuxiliaryPolynomial_totalDegree_lt
    {ι : Type*}
    [Fintype ι]
    (f : ι → MvPolynomial (Fin n) K)
    (hdeg : (∑ i, (f i).totalDegree) < n) :
    (chevalleyAuxiliaryPolynomial
      (K := K) (n := n) f).totalDegree <
      (Fintype.card K - 1) * n := by
  classical

  have hq : 0 < Fintype.card K - 1 := by
    have hcard : 1 < Fintype.card K :=
      Fintype.one_lt_card
    omega

  calc
    (chevalleyAuxiliaryPolynomial
        (K := K) (n := n) f).totalDegree
        ≤
        ∑ i,
          (1 - f i ^ (Fintype.card K - 1)).totalDegree := by
      rw [chevalleyAuxiliaryPolynomial]
      simpa using
        (totalDegree_finsetProd
          (Finset.univ : Finset ι)
          (fun i =>
            1 - f i ^ (Fintype.card K - 1)))

    _ ≤
        ∑ i,
          (Fintype.card K - 1) * (f i).totalDegree := by
      apply Finset.sum_le_sum
      intro i hi

      calc
        (1 - f i ^ (Fintype.card K - 1)).totalDegree
            ≤
            max
              (1 : MvPolynomial (Fin n) K).totalDegree
              (f i ^ (Fintype.card K - 1)).totalDegree := by
          exact totalDegree_sub _ _

        _ ≤
            (f i ^ (Fintype.card K - 1)).totalDegree := by
          simp

        _ ≤
            (Fintype.card K - 1) * (f i).totalDegree := by
          exact totalDegree_pow _ _

    _ =
        (Fintype.card K - 1) *
          ∑ i, (f i).totalDegree := by
      rw [Finset.mul_sum]

    _ <
        (Fintype.card K - 1) * n := by
      gcongr

omit [DecidableEq K] in
/--
多項式族 `f i` の全次数の和が変数の個数 `n` より小さければ，
補助多項式の有限体 `K` 上での値の総和は `0` である．
-/
theorem evalSum_chevalleyAuxiliaryPolynomial_eq_zero
    {ι : Type*}
    [Fintype ι]
    (f : ι → MvPolynomial (Fin n) K)
    (hdeg : (∑ i, (f i).totalDegree) < n) :
    evalSum
      (K := K)
      (n := n)
      (chevalleyAuxiliaryPolynomial
        (K := K) (n := n) f) = 0 := by
  apply evalSum_eq_zero_of_totalDegree_lt
      (K := K)
      (n := n)

  exact chevalleyAuxiliaryPolynomial_totalDegree_lt
      (K := K)
      (n := n)
      f
      hdeg

/--
補助多項式の値の総和は，
共通零点の個数を `K` に写したものに等しい．
-/
theorem evalSum_chevalleyAuxiliaryPolynomial_eq_card
    {ι : Type*}
    [Fintype ι]
    (f : ι → MvPolynomial (Fin n) K) :
    evalSum
      (K := K)
      (n := n)
      (chevalleyAuxiliaryPolynomial
        (K := K) (n := n) f) =
      (Fintype.card
        {x : Fin n → K // ∀ i, eval x (f i) = 0} : K) := by
  classical

  let V : Finset (Fin n → K) :=
    {x | ∀ i, eval x (f i) = 0}

  have hV (x : Fin n → K) :
      x ∈ V ↔ ∀ i, eval x (f i) = 0 := by
    simp [V]

  have hP (x : Fin n → K) :
      eval x
        (chevalleyAuxiliaryPolynomial
          (K := K) (n := n) f) =
        if x ∈ V then 1 else 0 := by
    rw [
      chevalleyAuxiliaryPolynomial_eval
        (K := K) (n := n) f x
    ]
    simp [hV]

  unfold evalSum

  rw [
    Fintype.card_of_subtype V hV,
    Finset.card_eq_sum_ones,
    Nat.cast_sum,
    Nat.cast_one,
    ← Fintype.sum_extend_by_zero V,
    Finset.sum_congr rfl (fun x _ ↦ hP x)
  ]

/--
Chevalley-Warning の定理．

多項式族 `f i` の全次数の和が変数の個数 `n` より小さければ，
共通零点の個数は標数 `p` で割り切れる．
-/
theorem chevalley_warning
    {ι : Type*}
    [Fintype ι]
    (f : ι → MvPolynomial (Fin n) K)
    (hdeg : (∑ i, (f i).totalDegree) < n) :
    p ∣ Fintype.card
      {x : Fin n → K // ∀ i, eval x (f i) = 0} := by
  classical

  rw [← CharP.cast_eq_zero_iff K]

  calc
    (Fintype.card
        {x : Fin n → K // ∀ i, eval x (f i) = 0} : K)
        =
        evalSum
          (K := K)
          (n := n)
          (chevalleyAuxiliaryPolynomial
            (K := K) (n := n) f) := by
      symm
      exact evalSum_chevalleyAuxiliaryPolynomial_eq_card
        (K := K)
        (n := n)
        f

    _ = 0 := by
      exact evalSum_chevalleyAuxiliaryPolynomial_eq_zero
        (K := K)
        (n := n)
        f
        hdeg

end ChevalleyWarning

end SerreNumberTheory
