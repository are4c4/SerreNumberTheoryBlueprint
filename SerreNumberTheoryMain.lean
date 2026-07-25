import VersoManual
import VersoBlueprint.PreviewManifest
import SerreNumberTheory.Blueprint

open Verso Doc
open Verso.Genre Manual

def main (args : List String) : IO UInt32 :=
  Informal.PreviewManifest.blueprintMainWithPreviewData
    (%doc SerreNumberTheory.Blueprint)
    args
    (extensionImpls := by exact extension_impls%)
