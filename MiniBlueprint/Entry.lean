import Lean

set_option autoImplicit false

namespace MiniBlueprint

inductive EntryKind where
  | definition
  | theorem
deriving Repr, BEq

inductive Progress where
  | planned
  | inProgress
  | formalized
deriving Repr, BEq

structure ProofStep where
  natural : String
  lean : String
deriving Repr

structure LeanReference where
  name : String
  typeText : String := ""
  description : String := ""
  source : String := "Mathlib"
deriving Repr

structure Entry where
  id : String
  title : String
  kind : EntryKind
  declaration : Option Lean.Name := none
  externalDeclaration : String := ""
  leanCode : String := ""
  description : String
  proofExplanation : String := ""
  proofSteps : Array ProofStep := #[]
  remark : String := ""
  leanExplanation : String := ""
  leanReferences : Array LeanReference := #[]
  dependencies : Array String := #[]
  progress : Progress := .planned
  source : String := ""
  chapter : String := ""
  sectionId : String := ""
  page : Option Nat := none
  sourceRepository : String := ""
  sourceRef : String := "main"
  sourcePath : String := ""
  sourceLineStart : Option Nat := none
  sourceLineEnd : Option Nat := none
  notionPageUrl : String := ""
  notionPageTitle : String := ""
  tags : Array String := #[]
  notes : String := ""
deriving Repr

/-- 通常本文・見出し・定義/定理を同じ文書の流れに混在させます。 -/
inductive DocumentBlock where
  | heading (level : Nat) (id : String) (title : String)
  | paragraph (text : String)
  | entry (value : Entry)
deriving Repr

end MiniBlueprint
