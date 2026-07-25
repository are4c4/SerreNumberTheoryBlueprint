/- 各章をまとめて依存関係グラフと進捗を管理する -/

import Verso
import VersoManual
import VersoBlueprint
import VersoBlueprint.Commands.Graph
import VersoBlueprint.Commands.Summary

import SerreNumberTheory.Blueprint.Chapter01.B010101FiniteFields

open Verso.Genre
open Verso.Genre.Manual
open Informal

#doc (Manual) "セール『数論講義』の形式化" =>

この文書では、セール『数論講義』に現れる定義・命題・定理を
Lean 4とmathlibを用いて形式化する。

{include 0 SerreNumberTheory.Blueprint.Chapter01.B010101FiniteFields}

# 定理の依存関係

{blueprint_graph}

# 形式化の進捗

{blueprint_summary}
