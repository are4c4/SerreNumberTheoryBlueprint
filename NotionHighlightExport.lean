import Lean
import SubVerso.Module

open Lean
open SubVerso
open SubVerso.Highlighting
open SubVerso.Module

private def escapeHtml (s : String) : String :=
  s.replace "&" "&amp;"
    |>.replace "<" "&lt;"
    |>.replace ">" "&gt;"
    |>.replace "\"" "&quot;"

private def tokenTitle : Token.Kind → Option String
  | .const _ signature docs _ _ => docs.orElse (fun _ => some signature)
  | .anonCtor _ signature docs _ => docs.orElse (fun _ => some signature)
  | .var _ type _ => some type
  | .wildcard type _ => some type
  | .option _ _ docs => docs
  | .sort docs => docs
  | .withType type => some type
  | .num type _ => type
  | _ => none

private def docsMetadata (docs : Option String) : String :=
  docs.map (fun d => s!" data-docs=\"{escapeHtml d}\"") |>.getD ""

private def tokenMetadata : Token.Kind → String
  | .const name signature docs isDef _ =>
      s!" data-semantic=\"const\" data-const-name=\"{escapeHtml (toString name)}\" data-signature=\"{escapeHtml signature}\" data-definition-site=\"{toString isDef}\"{docsMetadata docs}"
  | .anonCtor name signature docs _ =>
      s!" data-semantic=\"constructor\" data-const-name=\"{escapeHtml (toString name)}\" data-signature=\"{escapeHtml signature}\"{docsMetadata docs}"
  | .var _ type _ =>
      s!" data-semantic=\"variable\" data-signature=\"{escapeHtml type}\""
  | .wildcard type _ =>
      s!" data-semantic=\"wildcard\" data-signature=\"{escapeHtml type}\""
  | .sort docs => s!" data-semantic=\"sort\"{docsMetadata docs}"
  | .moduleName name =>
      s!" data-semantic=\"module\" data-const-name=\"{escapeHtml (toString name)}\""
  | .num type _ =>
      let ty := type.map (fun t => s!" data-signature=\"{escapeHtml t}\"") |>.getD ""
      s!" data-semantic=\"number\"{ty}"
  | .str _ _ => " data-semantic=\"string\""
  | .char _ => " data-semantic=\"char\""
  | .docComment => " data-semantic=\"doc-comment\""
  | .lineComment | .blockComment | .commentDelim => " data-semantic=\"comment\""
  | .keyword .. => " data-semantic=\"keyword\""
  | .operator .. => " data-semantic=\"operator\""
  | .bracket .. => " data-semantic=\"bracket\""
  | .separator .. => " data-semantic=\"separator\""
  | .delim .. => " data-semantic=\"delimiter\""
  | .option _ _ docs => s!" data-semantic=\"option\"{docsMetadata docs}"
  | .withType type => s!" data-semantic=\"typed\" data-signature=\"{escapeHtml type}\""
  | .levelVar .. => " data-semantic=\"level-var\""
  | .levelConst .. => " data-semantic=\"level-const\""
  | .levelOp .. => " data-semantic=\"level-op\""
  | .unknown => " data-semantic=\"unknown\""

private def renderToken (tok : Token) : String × String :=
  let cls := tok.kind.cssClass
  let title := tokenTitle tok.kind |>.map (fun t => s!" title=\"{escapeHtml t}\"") |>.getD ""
  let metadata := tokenMetadata tok.kind
  (s!"<span class=\"lean-token {cls}\"{title}{metadata}>{escapeHtml tok.content}</span>", tok.content)

private partial def plainHighlighted : Highlighted → String
  | .token tok => tok.content
  | .text s => s
  | .unparsed s => s
  | .point _ _ => ""
  | .span _ content => plainHighlighted content
  | .tactics _ _ _ content => plainHighlighted content
  | .seq highlights => highlights.foldl (fun text h => text ++ plainHighlighted h) ""

private def goalToJson (goal : Highlighted.Goal Highlighted) : Json :=
  let hypotheses := goal.hypotheses.map fun h =>
    Json.mkObj [
      ("names", toJson (h.names.map (fun tok => tok.content))),
      ("type", toJson (plainHighlighted h.typeAndVal))
    ]
  Json.mkObj [
    ("name", toJson goal.name),
    ("goalPrefix", toJson goal.goalPrefix),
    ("hypotheses", .arr hypotheses),
    ("conclusion", toJson (plainHighlighted goal.conclusion))
  ]

private def goalMarker (goals : Array (Highlighted.Goal Highlighted)) : String :=
  if goals.isEmpty then
    ""
  else
    let json := Json.compress (.arr (goals.map goalToJson))
    s!"<span class=\"lean-goal-marker\" data-goals=\"{escapeHtml json}\" title=\"このタクティク開始時のゴールを表示\" tabindex=\"0\"></span>"

private partial def renderHighlighted : Highlighted → String × String
  | .token tok => renderToken tok
  | .text s => (escapeHtml s, s)
  | .unparsed s => (s!"<span class=\"lean-token unknown\">{escapeHtml s}</span>", s)
  | .point _ _ => ("", "")
  | .span _ content => renderHighlighted content
  | .tactics goals _ _ content =>
      let (html, text) := renderHighlighted content
      (goalMarker goals ++ html, text)
  | .seq highlights =>
      highlights.foldl
        (fun (html, text) h =>
          let (hHtml, hText) := renderHighlighted h
          (html ++ hHtml, text ++ hText))
        ("", "")

private def itemToJson (item : ModuleItem) : Json :=
  let (html, text) := renderHighlighted item.code
  let startLine := item.range.map (fun r => r.1.line) |>.getD 1
  let endLine := item.range.map (fun r => r.2.line) |>.getD startLine
  Json.mkObj [
    ("defines", toJson (item.defines.map toString)),
    ("kind", toJson (toString item.kind)),
    ("startLine", toJson startLine),
    ("endLine", toJson endLine),
    ("html", toJson html),
    ("text", toJson text)
  ]

private def run (input output : System.FilePath) : IO UInt32 := do
  let raw ← IO.FS.readFile input
  let json ← match Json.parse raw with
    | .ok json => pure json
    | .error err =>
        IO.eprintln s!"Failed to parse SubVerso JSON: {err}"
        return 2
  let mod : SubVerso.Module.Module ← match FromJson.fromJson? json with
    | .ok mod => pure mod
    | .error err =>
        IO.eprintln s!"Failed to decode SubVerso module JSON: {err}"
        return 3
  if let some parent := output.parent then
    IO.FS.createDirAll parent
  let out := Json.mkObj [("items", .arr (mod.items.map itemToJson))]
  IO.FS.writeFile output (toString out)
  return 0

def main (args : List String) : IO UInt32 := do
  match args with
  | [input, output] => run input output
  | _ =>
      IO.eprintln "Usage: notion-highlight-export INPUT.json OUTPUT.json"
      return 1
