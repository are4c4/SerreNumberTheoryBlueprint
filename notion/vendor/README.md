# VS Code highlighting vendor files

These files are pinned build-time inputs for the Notion Viewer.

- `lean4.json`: Lean 4 official TextMate grammar from `leanprover/vscode-lean4` at commit `608100d335395e29d2cb7fbb1a6f947d6db9205e` (release 0.0.240).
- `dark_plus.json` and `dark_vs.json`: VS Code default Dark+ theme inputs from `microsoft/vscode` at commit `c17dab998414ec681d2f7a4813fb98a25b5c8cd0`.

They are consumed only while generating the static viewer. The browser does not load TextMate or Oniguruma at runtime.
