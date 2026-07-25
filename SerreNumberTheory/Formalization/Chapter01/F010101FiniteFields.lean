/-
githubへの変更手順

git add .
git commit -m "変更内容"
git push
-/


import Mathlib

namespace SerreNumberTheory

/-!
# 体の標数
-/

section Characteristic

variable (K : Type*) [Field K]
variable (p : ℕ) [CharP K p]

include K in
/--
体の標数は素数または `0` である．
-/
theorem field_char_is_prime_or_zero :
    Nat.Prime p ∨ p = 0 := by
  exact CharP.char_is_prime_or_zero K p

end Characteristic

/-!
# Frobenius写像
-/

section Frobenius

variable (K : Type*) [Field K]
variable (p : ℕ) [Fact p.Prime] [CharP K p]


/-! ## `p`乗写像 -/

section PowerMap

/--
`p`乗写像を通常の関数として定義する。
-/
def myFrobeniusFun : K → K :=
  fun x ↦ x ^ p

/--
`p`乗写像は `0` を `0` に送る。
-/
theorem myFrobeniusFun_zero :
    myFrobeniusFun K p 0 = 0 := by
  unfold myFrobeniusFun
  exact zero_pow (expChar_ne_zero K p)

omit [Fact p.Prime] [CharP K p] in
/--
`p`乗写像は `1` を `1` に送る。
-/
theorem myFrobeniusFun_one :
    myFrobeniusFun K p 1 = 1 := by
  unfold myFrobeniusFun
  exact one_pow p

omit [Fact p.Prime] [CharP K p] in
/--
`p`乗写像は乗法を保つ。
-/
theorem myFrobeniusFun_mul (x y : K) :
    myFrobeniusFun K p (x * y) =
      myFrobeniusFun K p x * myFrobeniusFun K p y := by
  unfold myFrobeniusFun
  exact mul_pow x y p

/--
標数 `p` では、`p`乗写像は加法を保つ。
-/
theorem myFrobeniusFun_add (x y : K) :
    myFrobeniusFun K p (x + y) =
      myFrobeniusFun K p x + myFrobeniusFun K p y := by
  unfold myFrobeniusFun
  exact add_pow_expChar x y p

end PowerMap


/-! ## Frobenius環準同型 -/

section RingHom

/--
`x ↦ x ^ p`で与えられるFrobenius環準同型。
-/
def myFrobenius : K →+* K where
  toFun := myFrobeniusFun K p

  map_zero' := by
    exact myFrobeniusFun_zero K p

  map_one' := by
    exact myFrobeniusFun_one K p

  map_add' := by
    intro x y
    exact myFrobeniusFun_add K p x y

  map_mul' := by
    intro x y
    exact myFrobeniusFun_mul K p x y

/--
自作したFrobenius環準同型の値は `x ^ p` である。
-/
@[simp]
theorem myFrobenius_apply (x : K) :
    myFrobenius K p x = x ^ p := by
  rfl

/--
自作したFrobenius環準同型は単射である。
-/
theorem myFrobenius_injective :
    Function.Injective (myFrobenius K p) := by
  exact (myFrobenius K p).injective

end RingHom

/-! ## Frobenius写像の像との同型 -/

section Equivalence

/--
自作したFrobenius写像の像を、型 `K^p` とみなす。
-/
abbrev MyFrobeniusPowers : Type _ :=
  (myFrobenius K p).fieldRange

/--
Frobenius写像の終域を、その像 `K^p` に制限する。
-/
def myFrobeniusToPowers :
    K →+* MyFrobeniusPowers K p :=
  (myFrobenius K p).rangeRestrictField

/--
像に終域を制限したFrobenius写像は全単射である。
-/
theorem myFrobeniusToPowers_bijective :
    Function.Bijective (myFrobeniusToPowers K p) := by
  constructor

  · -- 単射性
    intro x y hxy
    apply myFrobenius_injective K p
    exact congrArg Subtype.val hxy

  · -- 全射性
    intro z
    rcases z with ⟨zValue, ⟨x, hx⟩⟩
    refine ⟨x, ?_⟩
    apply Subtype.ext
    exact hx

/--
Frobenius写像による `K` と `K^p` の環同型。
-/
noncomputable def myFrobeniusEquivPowers :
    K ≃+* MyFrobeniusPowers K p := by
  apply RingEquiv.ofBijective (myFrobeniusToPowers K p)
  exact myFrobeniusToPowers_bijective K p

end Equivalence

end Frobenius

/-!
# 有限体の位数
-/

section FiniteFieldCardinality

/--
有限体の標数は素数である．
-/
theorem finiteField_char_is_prime
    (K : Type*) [Field K] [Fintype K]
    (p : ℕ) [CharP K p] :
    Nat.Prime p := by
  rcases field_char_is_prime_or_zero K p with hp | hp
  · -- p=素数
    exact hp
  · -- p=0
    exact (CharP.char_ne_zero_of_finite K p hp).elim -- elim：矛盾Falseから任意の命題を導く

variable (K : Type*) [Field K] [Fintype K] -- Kは有限体
variable (p : ℕ) [Fact p.Prime] [CharP K p] --有限体Kの標数は素数p

local instance : Algebra (ZMod p) K :=
  ZMod.algebra K p

/--
標数 `p` の有限体 `K` の位数は，
`ZMod p` 上の次元を指数とする `p` の冪である．
-/
theorem finiteField_card_eq_pow_finrank :
    Fintype.card K =
      p ^ Module.finrank (ZMod p) K := by
  exact (FiniteField.pow_finrank_eq_card p K).symm

end FiniteFieldCardinality

/-!
# Galois体
-/

section GaloisField

variable (p f : ℕ) [Fact p.Prime]

/--
`f ≠ 0`ならば，`GaloisField p f`の位数は`p ^ f`である．
-/
theorem galoisField_card
    (hf : f ≠ 0) :
    Nat.card (GaloisField p f) = p ^ f := by
  exact GaloisField.card p f hf

/--
`GaloisField p f`は，`ZMod p`上で
`X ^ (p ^ f) - X`の分解体である．
-/
theorem galoisField_isSplittingField
    (hf : f ≠ 0) :
    Polynomial.IsSplittingField
      (ZMod p)
      (GaloisField p f)
      (Polynomial.X ^ (p ^ f) - Polynomial.X) := by
  apply FiniteField.isSplittingField_of_nat_card_eq p f
  exact galoisField_card p f hf

/--
`GaloisField p f`の任意の元は，
`p ^ f`乗しても変わらない．
-/
theorem galoisField_pow_eq_self
    (hf : f ≠ 0)
    (x : GaloisField p f) :
    x ^ (p ^ f) = x := by
  letI := Fintype.ofFinite (GaloisField p f)

  have hcard :
      Fintype.card (GaloisField p f) = p ^ f := by
    calc
      Fintype.card (GaloisField p f)
          = Nat.card (GaloisField p f) := by
              exact Nat.card_eq_fintype_card.symm
      _ = p ^ f := by
            exact GaloisField.card p f hf

  rw [← hcard]
  exact FiniteField.pow_card x

/--
`GaloisField p f`の任意の元は，
`X ^ (p ^ f) - X`の根である．
-/
theorem galoisField_isRoot_X_pow_sub_X
    (hf : f ≠ 0)
    (x : GaloisField p f) :
    Polynomial.IsRoot
      (Polynomial.X ^ (p ^ f) - Polynomial.X)
      x := by
  change
    Polynomial.eval x
        (Polynomial.X ^ (p ^ f) - Polynomial.X) = 0

  rw [
    Polynomial.eval_sub,
    Polynomial.eval_pow,
    Polynomial.eval_X
  ]

  exact sub_eq_zero.mpr (galoisField_pow_eq_self p f hf x)

/--
`GaloisField p f`の元全体は，
`X ^ (p ^ f) - X`の根全体である．
-/
theorem galoisField_setOf_isRoot_eq_univ
    (hf : f ≠ 0) :
    {x : GaloisField p f |
      Polynomial.IsRoot
        (Polynomial.X ^ (p ^ f) - Polynomial.X)
        x}
      = Set.univ := by
  ext x
  constructor
  · intro hx
    exact Set.mem_univ x
  · intro hx
    exact galoisField_isRoot_X_pow_sub_X p f hf x

end GaloisField

/-!
# 有限体の一意性
-/

section FiniteFieldUniqueness

variable (K : Type*) [Field K] [Fintype K]
variable (p f : ℕ) [Fact p.Prime] [CharP K p]

local instance : Algebra (ZMod p) K :=
  ZMod.algebra K p

/--
位数が`p ^ f`である有限体`K`は，
`GaloisField p f`と`ZMod p`上代数同型である．
-/
noncomputable def finiteFieldAlgEquivGaloisField
    (hcard : Fintype.card K = p ^ f) :
    K ≃ₐ[ZMod p] GaloisField p f :=
  GaloisField.algEquivGaloisFieldOfFintype p f hcard

/--
位数が`p ^ f`である有限体`K`は，
`GaloisField p f`と環同型である．
-/
noncomputable def finiteFieldRingEquivGaloisField
    (hcard : Fintype.card K = p ^ f) :
    K ≃+* GaloisField p f :=
  (finiteFieldAlgEquivGaloisField K p f hcard).toRingEquiv

end FiniteFieldUniqueness

/-!
# 代数閉体内の有限部分体
-/

section FiniteSubfieldInAlgebraicClosure

variable (Ω : Type*) [Field Ω]
variable (p f : ℕ) [Fact p.Prime] [CharP Ω p]

/--
標数`p`の体`Ω`において，
`x ^ (p ^ f) = x`を満たす元全体がなす部分体．
-/
def frobeniusFixedSubfield : Subfield Ω where
  carrier :=
    {x : Ω | (iterateFrobenius Ω p f) x = x}

  zero_mem' := by
    change (iterateFrobenius Ω p f) 0 = 0
    exact (iterateFrobenius Ω p f).map_zero

  one_mem' := by
    change (iterateFrobenius Ω p f) 1 = 1
    exact (iterateFrobenius Ω p f).map_one

  add_mem' := by
    intro x y hx hy
    change (iterateFrobenius Ω p f) x = x at hx
    change (iterateFrobenius Ω p f) y = y at hy
    change (iterateFrobenius Ω p f) (x + y) = x + y
    rw [(iterateFrobenius Ω p f).map_add, hx, hy]

  mul_mem' := by
    intro x y hx hy
    change (iterateFrobenius Ω p f) x = x at hx
    change (iterateFrobenius Ω p f) y = y at hy
    change (iterateFrobenius Ω p f) (x * y) = x * y
    rw [(iterateFrobenius Ω p f).map_mul, hx, hy]

  neg_mem' := by
    intro x hx
    change (iterateFrobenius Ω p f) x = x at hx
    change (iterateFrobenius Ω p f) (-x) = -x
    rw [(iterateFrobenius Ω p f).map_neg, hx]

  inv_mem' := by
    intro x hx
    change (iterateFrobenius Ω p f) x = x at hx
    change (iterateFrobenius Ω p f) x⁻¹ = x⁻¹
    rw [iterateFrobenius_def] at hx ⊢
    rw [inv_pow, hx]

/--
`x`が`frobeniusFixedSubfield Ω p f`に属することと，
`x ^ (p ^ f) = x`であることは同値である．
-/
@[simp]
theorem mem_frobeniusFixedSubfield_iff
    (x : Ω) :
    x ∈ frobeniusFixedSubfield Ω p f ↔
      x ^ (p ^ f) = x := by
  change
    (iterateFrobenius Ω p f) x = x ↔
      x ^ (p ^ f) = x
  rw [iterateFrobenius_def]

/--
`x`が`frobeniusFixedSubfield Ω p f`に属することと，
`X ^ (p ^ f) - X`の根であることは同値である．
-/
theorem mem_frobeniusFixedSubfield_iff_isRoot
    (x : Ω) :
    x ∈ frobeniusFixedSubfield Ω p f ↔
      Polynomial.IsRoot
        (Polynomial.X ^ (p ^ f) - Polynomial.X)
        x := by
  rw [mem_frobeniusFixedSubfield_iff]

  change
    x ^ (p ^ f) = x ↔
      Polynomial.eval x
        (Polynomial.X ^ (p ^ f) - Polynomial.X) = 0

  rw [
    Polynomial.eval_sub,
    Polynomial.eval_pow,
    Polynomial.eval_X
  ]

  constructor
  · intro hx
    exact sub_eq_zero.mpr hx
  · intro hx
    exact sub_eq_zero.mp hx

omit [Fact p.Prime] [CharP Ω p] in
/--
代数閉体`Ω`上で，
`X ^ (p ^ f) - X`は完全に分解する．
-/
theorem frobeniusPolynomial_splits
    [IsAlgClosed Ω] :
    (Polynomial.X ^ (p ^ f) - Polynomial.X :
      Polynomial Ω).Splits := by
  exact IsAlgClosed.splits _

omit [Fact p.Prime] in
/--
標数`p`において，
`X ^ (p ^ f) - X`は分離多項式である．
-/
theorem frobeniusPolynomial_separable
    (hf : f ≠ 0) :
    (Polynomial.X ^ (p ^ f) - Polynomial.X :
      Polynomial Ω).Separable := by
  have hp_dvd : p ∣ p ^ f := by
    exact dvd_pow_self p hf

  have hsep :=
    Polynomial.separable_C_mul_X_pow_add_C_mul_X_add_C'
      p
      (p ^ f)
      (1 : Ω)
      (-1 : Ω)
      (0 : Ω)
      hp_dvd
      isUnit_neg_one

  simpa [sub_eq_add_neg] using hsep

omit [CharP Ω p] in
/--
`f ≠ 0`ならば，
`X ^ (p ^ f) - X`の次数は`p ^ f`である．
-/
theorem frobeniusPolynomial_natDegree
    (hf : f ≠ 0) :
    (Polynomial.X ^ (p ^ f) - Polynomial.X :
      Polynomial Ω).natDegree = p ^ f := by
  have hp_one_lt : 1 < p :=
    (Fact.out : Nat.Prime p).one_lt

  have hpow_one_lt : 1 < p ^ f := by
    exact Nat.one_lt_pow hf hp_one_lt

  calc
    (Polynomial.X ^ (p ^ f) - Polynomial.X :
        Polynomial Ω).natDegree
        =
        (Polynomial.X ^ (p ^ f) :
          Polynomial Ω).natDegree := by
      apply Polynomial.natDegree_sub_eq_left_of_natDegree_lt
      simpa using hpow_one_lt

    _ = p ^ f := by
      exact Polynomial.natDegree_X_pow (p ^ f)

/--
代数閉体`Ω`において，
`X ^ (p ^ f) - X`の異なる根の個数は`p ^ f`である．
-/
theorem frobeniusPolynomial_rootSet_card
    [IsAlgClosed Ω]
    (hf : f ≠ 0) :
    Fintype.card
      ↑((Polynomial.X ^ (p ^ f) - Polynomial.X :
          Polynomial Ω).rootSet Ω)
      = p ^ f := by
  calc
    Fintype.card
        ↑((Polynomial.X ^ (p ^ f) - Polynomial.X :
            Polynomial Ω).rootSet Ω)
        =
        (Polynomial.X ^ (p ^ f) - Polynomial.X :
          Polynomial Ω).natDegree := by
      apply Polynomial.card_rootSet_eq_natDegree
      · exact frobeniusPolynomial_separable Ω p f hf
      · simpa using frobeniusPolynomial_splits Ω p f
    _ = p ^ f :=
      frobeniusPolynomial_natDegree Ω p f hf

/--
`frobeniusFixedSubfield Ω p f`の台集合は，
`X ^ (p ^ f) - X`の根集合と一致する．
-/
theorem frobeniusFixedSubfield_carrier_eq_rootSet
    [IsAlgClosed Ω]
    (hf : f ≠ 0) :
    (frobeniusFixedSubfield Ω p f : Set Ω)
      =
    ↑((Polynomial.X ^ (p ^ f) - Polynomial.X :
        Polynomial Ω).rootSet Ω) := by
  let P : Polynomial Ω :=
    Polynomial.X ^ (p ^ f) - Polynomial.X

  have hP_degree :
      P.natDegree = p ^ f := by
    exact frobeniusPolynomial_natDegree Ω p f hf

  have hp_one_lt : 1 < p :=
    (Fact.out : Nat.Prime p).one_lt

  have hpow_one_lt : 1 < p ^ f := by
    exact Nat.one_lt_pow hf hp_one_lt

  have hP_ne : P ≠ 0 := by
    intro hP
    rw [hP] at hP_degree
    simp at hP_degree

    have hpow_ne : p ^ f ≠ 0 :=
      ne_of_gt (lt_trans Nat.zero_lt_one hpow_one_lt)

    exact hpow_ne hP_degree.symm

  ext x

  change
    (x ∈ frobeniusFixedSubfield Ω p f) ↔
      x ∈ P.rootSet Ω

  constructor
  · intro hx

    have hroot : Polynomial.IsRoot P x := by
      simpa [P] using
        (mem_frobeniusFixedSubfield_iff_isRoot Ω p f x).mp hx

    rw [Polynomial.mem_rootSet]

    constructor
    · exact hP_ne
    · simpa [Polynomial.IsRoot] using hroot

  · intro hx

    have hx' :
        P ≠ 0 ∧ Polynomial.aeval x P = 0 := by
      exact Polynomial.mem_rootSet.mp hx

    apply
      (mem_frobeniusFixedSubfield_iff_isRoot Ω p f x).mpr

    simpa [P, Polynomial.IsRoot] using hx'.2

/--
代数閉体`Ω`の部分体`frobeniusFixedSubfield Ω p f`は，
`p ^ f`個の元を持つ．
-/
theorem frobeniusFixedSubfield_natCard
    [IsAlgClosed Ω]
    (hf : f ≠ 0) :
    Nat.card (frobeniusFixedSubfield Ω p f) = p ^ f := by
  let P : Polynomial Ω :=
    Polynomial.X ^ (p ^ f) - Polynomial.X

  let e :
      frobeniusFixedSubfield Ω p f
        ≃
      ↑(P.rootSet Ω) := by
    exact Equiv.setCongr
      (frobeniusFixedSubfield_carrier_eq_rootSet Ω p f hf)

  calc
    Nat.card (frobeniusFixedSubfield Ω p f)
        =
        Nat.card ↑(P.rootSet Ω) := by
      exact Nat.card_congr e

    _ = Fintype.card ↑(P.rootSet Ω) := by
      exact Nat.card_eq_fintype_card

    _ = p ^ f := by
      simpa [P] using
        frobeniusPolynomial_rootSet_card Ω p f hf

/--
`p ^ f`個の元を持つ`Ω`の有限部分体は，
`frobeniusFixedSubfield Ω p f`に含まれる．
-/
theorem subfield_le_frobeniusFixedSubfield
    (L : Subfield Ω)
    [Fintype L]
    (hcard : Fintype.card L = p ^ f) :
    L ≤ frobeniusFixedSubfield Ω p f := by
  intro x hx

  rw [mem_frobeniusFixedSubfield_iff]

  let y : L := ⟨x, hx⟩

  have hy :
      y ^ Fintype.card L = y := by
    exact FiniteField.pow_card y

  have hyΩ :
      (y : Ω) ^ Fintype.card L = (y : Ω) := by
    exact congrArg ((↑) : L → Ω) hy

  simpa [y, hcard] using hyΩ

/--
代数閉体`Ω`において，`p ^ f`個の元を持つ部分体は，
`frobeniusFixedSubfield Ω p f`に等しい．
-/
theorem subfield_eq_frobeniusFixedSubfield
    [IsAlgClosed Ω]
    (L : Subfield Ω)
    [Fintype L]
    (hf : f ≠ 0)
    (hcard : Fintype.card L = p ^ f) :
    L = frobeniusFixedSubfield Ω p f := by
  let P : Polynomial Ω :=
    Polynomial.X ^ (p ^ f) - Polynomial.X

  let e :
      frobeniusFixedSubfield Ω p f
        ≃
      ↑(P.rootSet Ω) := by
    exact Equiv.setCongr
      (frobeniusFixedSubfield_carrier_eq_rootSet Ω p f hf)

  letI : Fintype (frobeniusFixedSubfield Ω p f) :=
    Fintype.ofEquiv
      ↑(P.rootSet Ω)
      e.symm

  apply SetLike.coe_injective
  apply Set.eq_of_subset_of_card_le

  · exact subfield_le_frobeniusFixedSubfield Ω p f L hcard

  · let eFixed :
        ↥((frobeniusFixedSubfield Ω p f : Subfield Ω) : Set Ω)
          ≃
        frobeniusFixedSubfield Ω p f :=
      Equiv.refl _

    let eL :
        ↥((L : Subfield Ω) : Set Ω) ≃ L :=
      Equiv.refl _

    have hfixed :
        Fintype.card
            ↥((frobeniusFixedSubfield Ω p f :
                Subfield Ω) : Set Ω)
          =
        p ^ f := by
      calc
        Fintype.card
            ↥((frobeniusFixedSubfield Ω p f :
                Subfield Ω) : Set Ω)
            =
            Fintype.card
              (frobeniusFixedSubfield Ω p f) := by
              exact Fintype.card_congr eFixed
        _ = p ^ f := by
              rw [← Nat.card_eq_fintype_card]
              exact frobeniusFixedSubfield_natCard Ω p f hf

    have hL :
        Fintype.card ↥((L : Subfield Ω) : Set Ω)
          =
        p ^ f := by
      calc
        Fintype.card ↥((L : Subfield Ω) : Set Ω)
            = Fintype.card L := by
                exact Fintype.card_congr eL
        _ = p ^ f := hcard

    rw [hfixed, hL]

/--
代数閉体`Ω`の中には，`p ^ f`個の元を持つ部分体が一意に存在する．
その部分体は`frobeniusFixedSubfield Ω p f`である．
-/
theorem existsUnique_subfield_natCard_eq_pow
    [IsAlgClosed Ω]
    (hf : f ≠ 0) :
    ∃! L : Subfield Ω,
      Nat.card L = p ^ f := by
  refine
    ⟨frobeniusFixedSubfield Ω p f,
      frobeniusFixedSubfield_natCard Ω p f hf,
      ?_⟩

  intro L hL

  have hpow_pos : 0 < p ^ f := by
    exact pow_pos (Fact.out : Nat.Prime p).pos f

  have hL_ne : Nat.card L ≠ 0 := by
    rw [hL]
    exact ne_of_gt hpow_pos

  letI : Finite L :=
    Nat.finite_of_card_ne_zero hL_ne

  letI : Fintype L :=
    Fintype.ofFinite L

  have hcard :
      Fintype.card L = p ^ f := by
    rw [← Nat.card_eq_fintype_card]
    exact hL

  exact
    subfield_eq_frobeniusFixedSubfield
      Ω p f L hf hcard

end FiniteSubfieldInAlgebraicClosure

end SerreNumberTheory
