import Lake
open Lake DSL

require VersoBlueprint from git
  "https://github.com/leanprover/verso-blueprint"@"v4.32.0"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.32.0"

package SerreNumberTheory where
  precompileModules := false
  leanOptions := #[⟨`experimental.module, true⟩]

@[default_target]
lean_lib SerreNumberTheory where

/-- Natural-language / Lean parallel Blueprint generator. -/
lean_lib MiniBlueprint where

/-- Generate `blueprint.html` from the real formalization files in this repository. -/
lean_exe «miniblueprint-html» where
  root := `HtmlMain
