import MiniBlueprint.Entry

set_option autoImplicit false

namespace MiniBlueprint.Registry.Chapter01.Section010101

private def serreRepo : String := "are4c4/SerreNumberTheoryBlueprint"
private def serreSource : String := "Serre, A Course in Arithmetic"
private def formalizationPath : String :=
  "SerreNumberTheory/Formalization/Chapter01/F010101FiniteFields.lean"

/-- 原典上の「体の標数」。Lean 側では Mathlib の `CharP` を利用します。 -/
def fieldCharacteristic : Entry where
  id := "field_characteristic"
  title := "体の標数"
  kind := .definition
  description := "体 \\(K\\) において、\\[n\\cdot 1_K=0\\] を満たす最小の正整数 \\(n\\) が存在するとき、その \\(n\\) を \\(K\\) の標数という。そのような正整数が存在しないとき、標数は \\(0\\) であるという。"
  remark := "Lean では標数を表すために `CharP K p` という型クラスを利用する。"
  leanExplanation := "この概念専用の自作宣言は置かず、Mathlib の `CharP` を利用しています。"
  progress := .planned
  source := serreSource
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := serreRepo
  sourcePath := formalizationPath
  tags := #["finite-field", "characteristic"]

def fieldCharIsPrimeOrZero : Entry where
  id := "field_char_is_prime_or_zero"
  title := "体の標数は素数または0"
  kind := .theorem
  externalDeclaration := "SerreNumberTheory.field_char_is_prime_or_zero"
  description := "体 \\(K\\) の標数 \\(p\\) は、素数または \\(0\\) である。"
  proofExplanation := "正の標数 \\(p\\) が合成数 \\(p=ab\\) なら、\\[(a\\cdot 1_K)(b\\cdot 1_K)=p\\cdot 1_K=0.\\] 体は整域なので一方が 0 となり、標数の最小性に反する。"
  proofSteps := #[
    { natural := "目標は標数 \\(p\\) が素数または \\(0\\) であること。", lean := "Nat.Prime p ∨ p = 0" },
    { natural := "Mathlib の一般定理を適用する。", lean := "exact CharP.char_is_prime_or_zero K p" }
  ]
  leanExplanation := "`CharP.char_is_prime_or_zero K p` が主張を直接与えます。"
  leanReferences := #[
    { name := "CharP.char_is_prime_or_zero", typeText := "Nat.Prime p ∨ p = 0", description := "`CharP K p` のもとで標数が素数または0であることを与える定理。" }
  ]
  dependencies := #["field_characteristic"]
  progress := .formalized
  source := serreSource
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := serreRepo
  sourcePath := formalizationPath
  tags := #["finite-field", "characteristic"]

def frobeniusMap : Entry where
  id := "frobenius_map"
  title := "Frobenius写像"
  kind := .definition
  externalDeclaration := "SerreNumberTheory.myFrobeniusFun"
  description := "標数 \\(p\\) の体 \\(K\\) に対し、\\[F:K\\to K,\\qquad F(x)=x^p\\] で定まる写像を Frobenius 写像という。"
  leanExplanation := "`myFrobeniusFun` は `x : K` を `x ^ p` に送る関数です。"
  progress := .formalized
  source := serreSource
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := serreRepo
  sourcePath := formalizationPath
  tags := #["finite-field", "frobenius"]

def frobeniusZero : Entry where
  id := "frobenius_zero"
  title := "Frobenius写像は0を保つ"
  kind := .theorem
  externalDeclaration := "SerreNumberTheory.myFrobeniusFun_zero"
  description := "Frobenius 写像 \\(F\\) は \\(0\\) を \\(0\\) に送る：\\[F(0)=0.\\]"
  proofExplanation := "定義より \\(F(0)=0^p\\) であり、正の標数では \\(p\\neq0\\) なので \\(0^p=0\\)。"
  leanExplanation := "定義を展開し `zero_pow` を使います。"
  dependencies := #["frobenius_map"]
  progress := .formalized
  source := serreSource
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := serreRepo
  sourcePath := formalizationPath
  tags := #["finite-field", "frobenius"]

def frobeniusOne : Entry where
  id := "frobenius_one"
  title := "Frobenius写像は1を保つ"
  kind := .theorem
  externalDeclaration := "SerreNumberTheory.myFrobeniusFun_one"
  description := "Frobenius 写像 \\(F\\) は \\(1\\) を \\(1\\) に送る：\\[F(1)=1.\\]"
  proofExplanation := "定義より \\(F(1)=1^p=1\\)。"
  leanExplanation := "定義を展開した後 `one_pow p` を使います。"
  dependencies := #["frobenius_map"]
  progress := .formalized
  source := serreSource
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := serreRepo
  sourcePath := formalizationPath
  tags := #["finite-field", "frobenius"]

def frobeniusMul : Entry where
  id := "frobenius_mul"
  title := "Frobenius写像は積を保つ"
  kind := .theorem
  externalDeclaration := "SerreNumberTheory.myFrobeniusFun_mul"
  description := "任意の \\(x,y\\in K\\) に対して、\\[F(xy)=F(x)F(y).\\]"
  proofExplanation := "\\((xy)^p=x^py^p\\) なので定義から従う。"
  leanExplanation := "積の冪に関する `mul_pow x y p` を使います。"
  dependencies := #["frobenius_map"]
  progress := .formalized
  source := serreSource
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := serreRepo
  sourcePath := formalizationPath
  tags := #["finite-field", "frobenius"]

def frobeniusAdd : Entry where
  id := "frobenius_add"
  title := "Frobenius写像は和を保つ"
  kind := .theorem
  externalDeclaration := "SerreNumberTheory.myFrobeniusFun_add"
  description := "任意の \\(x,y\\in K\\) に対して、\\[F(x+y)=F(x)+F(y).\\]"
  proofExplanation := "二項定理で \\((x+y)^p\\) を展開すると、標数 \\(p\\) では中間項が消えるため、\\[(x+y)^p=x^p+y^p.\\]"
  proofSteps := #[
    { natural := "Frobenius 写像の定義を使い、目標を p 乗の等式に直す。", lean := "unfold myFrobeniusFun" },
    { natural := "標数 \\(p\\) では二項展開の中間項が消える。", lean := "exact add_pow_expChar x y p" }
  ]
  leanExplanation := "`add_pow_expChar x y p` が \\((x+y)^p=x^p+y^p\\) を与えます。"
  leanReferences := #[
    { name := "add_pow_expChar", typeText := "(x + y) ^ p = x ^ p + y ^ p", description := "指数標数 p の環における Freshman's dream を表す Mathlib の定理。" }
  ]
  dependencies := #["frobenius_map"]
  progress := .formalized
  source := serreSource
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := serreRepo
  sourcePath := formalizationPath
  tags := #["finite-field", "frobenius"]

def frobeniusRingHom : Entry where
  id := "frobenius_ring_hom"
  title := "Frobenius写像は環準同型"
  kind := .definition
  externalDeclaration := "SerreNumberTheory.myFrobenius"
  description := "標数 \\(p\\) の体 \\(K\\) 上の Frobenius 写像 \\(F(x)=x^p\\) は環準同型としてまとめられる。"
  proofExplanation := "\\(0,1\\) を保ち、和と積を保つ性質を構造体の各フィールドに与える。"
  leanExplanation := "`K →+* K` の各構造フィールドに直前の補題を与えています。"
  dependencies := #["frobenius_map", "frobenius_zero", "frobenius_one", "frobenius_mul", "frobenius_add"]
  progress := .formalized
  source := serreSource
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := serreRepo
  sourcePath := formalizationPath
  tags := #["finite-field", "frobenius", "ring-hom"]

def frobeniusInjective : Entry where
  id := "frobenius_injective"
  title := "Frobenius写像は単射"
  kind := .theorem
  externalDeclaration := "SerreNumberTheory.myFrobenius_injective"
  description := "体 \\(K\\) 上の Frobenius 写像は単射である。"
  proofExplanation := "体から体への単位元を保つ環準同型は単射になる。"
  leanExplanation := "Mathlib が体から出る環準同型に与える `.injective` を使います。"
  dependencies := #["frobenius_ring_hom"]
  progress := .formalized
  source := serreSource
  chapter := "1"
  sectionId := "1.1.1"
  sourceRepository := serreRepo
  sourcePath := formalizationPath
  tags := #["finite-field", "frobenius", "injective"]

def entries : Array Entry := #[
  fieldCharacteristic,
  fieldCharIsPrimeOrZero,
  frobeniusMap,
  frobeniusZero,
  frobeniusOne,
  frobeniusMul,
  frobeniusAdd,
  frobeniusRingHom,
  frobeniusInjective
]

end MiniBlueprint.Registry.Chapter01.Section010101
