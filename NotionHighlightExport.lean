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

private def renderToken (tok : Token) : String × String :=
  let cls := tok.kind.cssClass
  let title := tokenTitle tok.kind |>.map (fun t => s!" title=\"{escapeHtml t}\"") |>.getD ""
  (s!"<span class=\"lean-token {cls}\"{title}>{escapeHtml tok.content}</span>", tok.content)

private partial def renderHighlighted : Highlighted → String × String
  | .token tok => renderToken tok
  | .text s => (escapeHtml s, s)
  | .unparsed s => (s!"<span class=\"lean-token unknown\">{escapeHtml s}</span>", s)
  | .point _ _ => ("", "")
  | .span _ content => renderHighlighted content
  | .tactics _ _ _ content => renderHighlighted content
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
