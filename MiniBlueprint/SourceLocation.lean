import MiniBlueprint.Entry

set_option autoImplicit false

namespace MiniBlueprint

private def declarationShortName (entry : Entry) : String :=
  let name :=
    if entry.externalDeclaration.isEmpty then
      match entry.declaration with
      | some declaration => toString declaration
      | none => ""
    else
      entry.externalDeclaration
  match (name.splitOn ".").reverse with
  | shortName :: _ => shortName
  | [] => name

private def isDeclarationBoundary (line : String) : Bool :=
  let line := line.trim
  line.startsWith "/--" ||
  line.startsWith "/-!" ||
  line.startsWith "section " ||
  line.startsWith "end " ||
  line.startsWith "omit " ||
  line.startsWith "include " ||
  line.startsWith "theorem " ||
  line.startsWith "lemma " ||
  line.startsWith "def " ||
  line.startsWith "abbrev " ||
  line.startsWith "noncomputable def " ||
  line.startsWith "instance "

private def hasDeclarationPrefix
    (line keyword declarationName : String) : Bool :=
  let prefix := s!"{keyword} {declarationName}"
  line == prefix ||
  line.startsWith (prefix ++ " ") ||
  line.startsWith (prefix ++ " :") ||
  line.startsWith (prefix ++ " (") ||
  line.startsWith (prefix ++ " [")

private def isTargetDeclaration (line declarationName : String) : Bool :=
  let trimmed := line.trim
  hasDeclarationPrefix trimmed "theorem" declarationName ||
  hasDeclarationPrefix trimmed "lemma" declarationName ||
  hasDeclarationPrefix trimmed "def" declarationName ||
  hasDeclarationPrefix trimmed "abbrev" declarationName ||
  hasDeclarationPrefix trimmed "noncomputable def" declarationName

private structure DeclarationSource where
  startLine : Nat
  endLine : Nat
  code : String

private def findDeclarationSource
    (source declarationName : String) : Option DeclarationSource :=
  if declarationName.isEmpty then
    none
  else
    Id.run do
      let lines := source.splitOn "\n" |>.toArray
      let startIndex? := lines.findIdx? fun line =>
        isTargetDeclaration line declarationName
      match startIndex? with
      | none => return none
      | some startIndex =>
          let mut endIndex := lines.size
          for i in [startIndex + 1:lines.size] do
            if isDeclarationBoundary lines[i]! then
              endIndex := i
              break
          let mut last := endIndex
          while last > startIndex + 1 && lines[last - 1]!.trim.isEmpty do
            last := last - 1
          let codeLines := (lines.extract startIndex last).toList
          return some {
            startLine := startIndex + 1
            endLine := last
            code := String.intercalate "\n" codeLines
          }

/-- 同じリポジトリ内の実 Lean ファイルからコードと行番号を読み直します。 -/
def refreshEntrySource (root : System.FilePath) (entry : Entry) : IO Entry := do
  if entry.sourcePath.isEmpty then
    return entry
  let path := root / entry.sourcePath
  try
    let source ← IO.FS.readFile path
    match findDeclarationSource source (declarationShortName entry) with
    | some found =>
        return {
          entry with
          sourceLineStart := some found.startLine
          sourceLineEnd := some found.endLine
          leanCode := found.code
        }
    | none => return entry
  catch _ =>
    return entry

/-- 文書内の全 Entry を実ソースから更新します。 -/
def refreshDocumentSources
    (root : System.FilePath)
    (document : Array DocumentBlock) : IO (Array DocumentBlock) := do
  let mut result : Array DocumentBlock := #[]
  for block in document do
    match block with
    | .entry entry =>
        let refreshed ← refreshEntrySource root entry
        result := result.push (.entry refreshed)
    | other =>
        result := result.push other
  return result

end MiniBlueprint
