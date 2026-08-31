import SerreNumberTheory.Blueprint
import Lean.Util.CollectAxioms

open Lean
open Lean.Elab
open Lean.Elab.Command

private def isProjectTheorem (n : Name) : Bool :=
  (toString n).startsWith "SerreNumberTheory."

private def statusEntry (n : Name) (axioms : NameSet) : Json :=
  let incomplete := axioms.contains ``sorryAx
  Json.mkObj [
    ("name", toJson (toString n)),
    ("shortName", toJson (toString n.getString!)),
    ("status", toJson (if incomplete then "incomplete" else "proved")),
    ("hasSorry", toJson incomplete),
    ("axioms", toJson (axioms.toList.map toString))
  ]

run_cmd do
  let env ← getEnv
  let mut entries : Array Json := #[]
  for (n, info) in env.constants.toList do
    match info with
    | .thmInfo _ =>
        if isProjectTheorem n then
          let axioms ← liftCoreM <| collectAxioms n
          entries := entries.push (statusEntry n axioms)
    | _ => pure ()
  let out := Json.mkObj [("theorems", .arr entries)]
  liftIO <| IO.FS.writeFile "_out/site/html-multi/proof-status.json" (toString out)
