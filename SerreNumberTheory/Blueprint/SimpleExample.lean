import Verso
import VersoManual
import VersoBlueprint

open Verso.Genre
open Verso.Genre.Manual
open Informal

#doc (Manual) "自然数の加法の例" =>

# 加法と零

:::definition "natural_number"

自然数を考える。

:::

:::theorem "add_zero" (lean := "Nat.add_zero")

任意の自然数 $`n` に対して、

$$
n + 0 = n
$$

が成り立つ。

この定理は
{uses "natural_number"}[]
に依存する。

:::

:::proof "add_zero"

自然数の加法に関する既存定理 `Nat.add_zero`を用いる。

:::
