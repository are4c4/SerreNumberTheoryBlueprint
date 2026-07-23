/-
webページを確認する方法

ターミナルで次を実行（ローカルサーバー）
lake exe vbp build
python3 -m http.server 8000 --directory _out/site/html-multi
open http://localhost:8000/

停止する時はCtrl+C

内容を更新する時は
lake exe vbp build
をした後にブラウザを更新する
-/


import Verso
import VersoManual
import VersoBlueprint

import ProjectTemplate.Formalization.Chapter01.Frobenius

open Verso.Genre
open Verso.Genre.Manual
open Informal


/-
Manualという文書形式を使って、
タイトルが" "であるVerso文書を作成し、
以下にその本文を記述する。
-/
#doc (Manual) "有限体" =>

# 有限体の性質

## 有限体

 $`K` を体とする．

### 標数の定義


:::definition "field_characteristic"
*体上の標数の定義*

体 $`K` において，
$$`
n \cdot 1_K = 0
`
を満たす最小の正の整数 $`n` が存在するとき，その $`n` を $`K` の*標数（characteristic）*という．

そのような正の整数が存在しないとき， $`K` の標数は $`0` であるという．
:::


:::lemma_ "field_char_is_prime_or_zero" (lean := "SerreNumberTheory.field_char_is_prime_or_zero") (uses := "field_characteristic")

体 $`K` の標数は素数 $`p` または $`0` である．
:::
:::proof "field_char_is_prime_or_zero"
体は整域である．

体 $`K` の標数が合成数 $`p=ab` であると仮定すると、
$$`
(a\cdot 1_K)(b\cdot 1_K)
=
p\cdot 1_K
=
0
`
となる。体には零因子がないので、
$$`
a\cdot 1_K=0
\qquad\text{または}\qquad
b\cdot 1_K=0
`
である。これは標数 $`p` の最小性に反する。

したがって、正の標数は素数である。
:::

### 体上のFrobenius写像の定義

:::definition "frobenius_map" (lean := "SerreNumberTheory.myFrobeniusFun")
*体上のFrobenius写像の定義*

 $`K` を標数 $`p` の体とする．

このとき，写像
$$`
F \colon K \longrightarrow K,
\qquad
F(x)=x^p
`
を体 $`K` 上の*Frobenius写像*という．
:::


:::lemma_ "frobenius_zero"  (lean := "SerreNumberTheory.myFrobeniusFun_zero")
体 $`K` 上のFrobenius写像 $`F` は $`0` を $`0` に送る：
$$`
F(0) = 0
`
:::


:::lemma_ "frobenius_one" (lean := "SerreNumberTheory.myFrobeniusFun_one")
体 $`K` 上のFrobenius写像 $`F` は $`1` を $`1` に送る：
$$`
F(1) = 1
`
:::


:::lemma_ "frobenius_mul" (lean := "SerreNumberTheory.myFrobeniusFun_mul")
体 $`K` 上のFrobenius写像 $`F` は積を保つ．
すなわち，任意の $`x,y\in K` に対して、
$$`
F(xy) = F(x)F(y)
`
が成り立つ．
:::


:::lemma_ "frobenius_add" (lean := "SerreNumberTheory.myFrobeniusFun_add")
標数 $`p>0` の体 $`K` 上のFrobenius写像 $`F` は和を保つ．
すなわち，任意の $`x,y\in K` に対して、
$$`
F(x+y) = F(x) + F(y)
`
が成り立つ．
:::
:::proof "frobenius_add"

指数標数 $`p` の環では、二項展開に現れる中間の項が消えるため、

$$`
(x+y)^p=x^p+y^p
`

となる。

Leanでは、この事実は定理 `add_pow_expChar`として用意されている。
したがって、これを $`x`、$`y`、$`p` に適用すればよい。

:::


:::lemma_ "frobenius_ring_hom" (lean := "SerreNumberTheory.myFrobenius") (uses := "frobenius_map")
標数 $`p>0` の体 $`K` 上のFrobenius写像
$$`
F \colon K \longrightarrow K,
\qquad
F(x)=x^p
`
は環準同型である．
:::
:::proof "frobenius_ring_hom"
任意の $`x,y\in K` に対して、
$$`
F(xy) = (xy)^p = x^py^p = F(x)F(y)
`
である。

また、二項定理より、

$$`
(x+y)^p
=
\sum_{i=0}^{p}
\binom{p}{i}x^iy^{p-i}
`
である。$`0<i<p` に対して二項係数
$`\binom{p}{i}` は $`p` で割り切れるため、
標数 $`p` の体では中間項がすべて消える。したがって、
$$`
F(x+y)=x^p+y^p=F(x)+F(y)
`
となる。
さらに、
$$`
F(0)=0,
\qquad
F(1)=1
`
である。よって、$`F` は環準同型である。
:::


:::lemma_ "frobenius_injective" (lean := "SerreNumberTheory.frobenius_injective") (uses := "frobenius_map")
体 $`K` 上のFrobenius写像は単射である。
:::
:::proof "frobenius_injective"
$`x,y\in K`について、
$$`
x^p=y^p
`
とする。標数 $`p` では、
$$`
(x-y)^p=x^p-y^p=0
`
である。体は整域であるから $`x-y=0`、したがって $`x=y` である。
:::


:::lemma_ "dd"
体 $`K` の標数が $`p > 0` であるとする．

このとき，Frobenius写像
$$`
F \colon K \longrightarrow K,
\qquad
F(x)=x^p
`
により，
$`K` はその像 $`K^p` と環同型となる．
:::
