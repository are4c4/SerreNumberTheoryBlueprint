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
    体の標数は素数または `0` である。
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

end SerreNumberTheory
