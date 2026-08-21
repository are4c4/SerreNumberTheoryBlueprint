import MiniBlueprint.Entry
import MiniBlueprint.Registry.Chapter01.Section010101FiniteFields

set_option autoImplicit false

namespace MiniBlueprint

namespace FiniteFields

open Registry.Chapter01.Section010101

/-- 1.1.1 を通常本文と必要な Definition/Theorem ブロックで構成します。 -/
def document : Array DocumentBlock := #[
  .heading 2 "section-1-1-1" "1.1.1 有限体",
  .paragraph "この節では、有限体を調べるための準備として体の標数と Frobenius 写像を扱う。まず体の標数について確認し、その後、正標数の体に特有の写像 \\(x\\mapsto x^p\\) の基本的な性質を調べる。",

  .heading 3 "topic-characteristic" "標数",
  .paragraph "体 \\(K\\) では、整数を単位元 \\(1_K\\) の倍数として見ることで標数を考えることができる。以下ではこの概念を定義し、体の標数にどのような制約があるかを見る。",
  .entry fieldCharacteristic,
  .paragraph "体が整域であることを使うと、正の標数が合成数になることはない。",
  .entry fieldCharIsPrimeOrZero,

  .heading 3 "topic-frobenius" "Frobenius写像",
  .paragraph "ここから \\(K\\) を標数 \\(p>0\\) の体とする。正標数では \\(p\\) 乗写像が加法と乗法の両方とよく整合し、重要な自己写像を与える。",
  .entry frobeniusMap,
  .paragraph "まず、この写像が環の基本演算を保つことを順に確認する。",
  .entry frobeniusZero,
  .entry frobeniusOne,
  .entry frobeniusMul,
  .entry frobeniusAdd,
  .paragraph "以上の性質をまとめると、Frobenius 写像は単なる関数ではなく環準同型として扱える。",
  .entry frobeniusRingHom,
  .paragraph "さらに体から体へのこの環準同型は単射になる。",
  .entry frobeniusInjective
]

end FiniteFields

/-- 定義・定理メタデータ一覧。 -/
def entries : Array Entry :=
  Registry.Chapter01.Section010101.entries

/-- HTMLに表示する文書の流れ。 -/
def document : Array DocumentBlock :=
  FiniteFields.document

end MiniBlueprint
