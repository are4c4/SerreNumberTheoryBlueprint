import SerreNumberTheory.Formalization.Chapter01.F010101FiniteFields

namespace SerreNumberTheory

open Finset

/-!
# 有限体の乗法群
-/

/-!
## Euler の φ 関数
-/

section Totient

/--
補題1．任意の自然数 `n` について，
`n` はその約数 `d` に対する Euler の φ 関数の和に等しい．

原典では `n ≥ 1` を仮定しているが，
Mathlib の定理はより一般の形で与えられている．
-/
theorem nat_eq_sum_totient_divisors (n : ℕ) :
    n = ∑ d ∈ n.divisors, Nat.totient d := by
  exact (Nat.sum_totient n).symm

end Totient


/-!
## 有限群が巡回群となるための判定
-/

section CyclicCriterion

variable (H : Type*) [Group H] [Fintype H] [DecidableEq H]

/--
補題2．有限群 `H` の位数の任意の約数 `d` に対して，
`x ^ d = 1` を満たす元が高々 `d` 個ならば，
`H` は巡回群である．
-/
theorem finiteGroup_isCyclic_of_root_bound_on_divisors
    (hroots :
      ∀ d : ℕ,
        d ∣ Fintype.card H →
        #{x : H | x ^ d = 1} ≤ d) :
    IsCyclic H := by

  apply isCyclic_of_card_pow_eq_one_le

  intro m hm

  let d := Nat.gcd m (Fintype.card H)

  have hdvd :
      d ∣ Fintype.card H := by
    exact Nat.gcd_dvd_right m (Fintype.card H)

  have hdle :
      d ≤ m := by
    exact Nat.gcd_le_left _ hm

  calc
    #{x : H | x ^ m = 1}
        ≤ #{x : H | x ^ d = 1} := by

      apply Finset.card_le_card

      intro x hx

      simp only [
        Finset.mem_filter,
        Finset.mem_univ,
        true_and
      ] at hx ⊢

      rw [← orderOf_dvd_iff_pow_eq_one] at hx ⊢

      exact Nat.dvd_gcd hx orderOf_dvd_card

    _ ≤ d := hroots d hdvd

    _ ≤ m := hdle

end CyclicCriterion


/-!
## 有限体の乗法群
-/

section FiniteFieldMultiplicativeGroup

variable (K : Type*) [Field K] [Fintype K]

/--
有限体 `K` の乗法群 `Kˣ` は巡回群である．
-/
theorem finiteField_units_isCyclic :
    IsCyclic Kˣ := by

  classical

  apply
    finiteGroup_isCyclic_of_root_bound_on_divisors
      (H := Kˣ)

  intro d hdvd

  have hdpos :
      0 < d := by
    apply Nat.pos_of_dvd_of_pos hdvd
    exact Fintype.card_pos_iff.2 ⟨(1 : Kˣ)⟩

  calc
    #{x : Kˣ | x ^ d = 1}
        ≤ Multiset.card
            (Polynomial.nthRoots d (1 : K)) := by

      simpa using
        (card_nthRoots_subgroup_units
          (R := K)
          (G := Kˣ)
          (Units.coeHom K)
          Units.val_injective
          hdpos
          (1 : Kˣ))

    _ ≤ d := by
      exact Polynomial.card_nthRoots d (1 : K)


/--
有限体 `K` の乗法群 `Kˣ` の位数は
`Fintype.card K - 1` である．
-/
theorem finiteField_units_card :
    Nat.card Kˣ =
      Fintype.card K - 1 := by
  calc
    Nat.card Kˣ
        = Nat.card K - 1 := by
            exact Nat.card_units K

    _ = Fintype.card K - 1 := by
          rw [Nat.card_eq_fintype_card]


/-!
### 位数 `p ^ f` の有限体
-/

variable (p : ℕ) [Fact p.Prime] [CharP K p]

local instance : Algebra (ZMod p) K :=
  ZMod.algebra K p

/-!
### 位数 `p ^ f` の有限体
-/

variable (p : ℕ) [Fact p.Prime] [CharP K p]

local instance : Algebra (ZMod p) K :=
  ZMod.algebra K p

/--
定理2．`K` が標数 `p` の有限体で，
`ZMod p` 上の次元が `f` ならば，
その乗法群 `Kˣ` は位数 `p ^ f - 1` の巡回群である．
-/
theorem finiteField_multiplicativeGroup_cyclic
    (f : ℕ)
    (hfinrank :
      Module.finrank (ZMod p) K = f) :
    IsCyclic Kˣ ∧
      Nat.card Kˣ = p ^ f - 1 := by

  constructor

  · exact finiteField_units_isCyclic K

  · calc
      Nat.card Kˣ
          = Fintype.card K - 1 := by
              exact finiteField_units_card K

      _ = p ^ f - 1 := by
            rw [
              finiteField_card_eq_pow
                K p f hfinrank
            ]

end FiniteFieldMultiplicativeGroup

end SerreNumberTheory
