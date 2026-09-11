import Mathlib

namespace SerreNumberTheory

/-!
# 有限体上のべき乗和
-/

section PowerSums

variable (K : Type*) [Field K] [Fintype K]

/--
有限体 `K` 上の `u` 乗和．
-/
def powerSum (u : ℕ) : K :=
  ∑ x : K, x ^ u

/--
正の指数では，有限体全体でのべき乗和は
非零元全体でのべき乗和に等しい．
-/
theorem powerSum_eq_sum_units
    [DecidableEq K]
    (u : ℕ)
    (hu : u ≠ 0) :
    powerSum K u =
      ∑ x : Kˣ, (x ^ u : K) := by
  classical

  let φ : Kˣ ↪ K :=
    ⟨fun x ↦ x, Units.val_injective⟩

  have hφ :
      Finset.univ.map φ =
        Finset.univ \ {(0 : K)} := by
    ext x
    simpa only [
      Finset.mem_map,
      Finset.mem_univ,
      Function.Embedding.coeFn_mk,
      true_and,
      Finset.mem_sdiff,
      Finset.mem_singleton,
      φ
    ] using! isUnit_iff_ne_zero

  unfold powerSum

  calc
    (∑ x : K, x ^ u)
        =
        ∑ x ∈ Finset.univ \ {(0 : K)}, x ^ u := by
          rw [
            ← Finset.sum_sdiff
              ({0} : Finset K).subset_univ,
            Finset.sum_singleton,
            zero_pow hu,
            add_zero
          ]

    _ = ∑ x : Kˣ, (x ^ u : K) := by
      simp [φ, ← hφ, Finset.univ.sum_map φ]

/--
有限体 `K` の位数を `q` とする．
べき乗和は，`u > 0` かつ `q - 1 ∣ u` のとき `-1` であり，
それ以外の場合は `0` である．
-/
theorem powerSum_eq (u : ℕ) :
    powerSum K u =
      if 0 < u ∧ Fintype.card K - 1 ∣ u then -1 else 0 := by
  classical

  by_cases hu : u = 0

  · subst u
    simp [powerSum]

  · have hu_pos : 0 < u := Nat.pos_of_ne_zero hu

    rw [powerSum_eq_sum_units K u hu]
    rw [FiniteField.sum_pow_units K u]

    simp [hu_pos]

end PowerSums

end SerreNumberTheory
