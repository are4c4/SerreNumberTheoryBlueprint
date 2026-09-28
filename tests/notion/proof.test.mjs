import test from "node:test";
import assert from "node:assert/strict";
import { proofGutterCells, proofStateForItem } from "../../notion/lib/proof.mjs";

test("proof status matches any declaration defined by an item", () => {
  const item = {defines:["Foo.demo"]};
  const statuses = {theorems:[{name:"Foo.demo",status:"proved"}]};
  assert.equal(proofStateForItem(item, statuses).status, "proved");
});
test("proof marker uses item.startLine rather than reparsing Lean text", () => {
  const item = {startLine:10};
  const rows = [
    {line:3,context:true,text:"variable (p : Nat)"},
    {line:9,context:true,text:"/-- docs -/"},
    {line:10,context:false,text:"private theorem demo : True := by"},
    {line:11,context:false,text:"  trivial"}
  ];
  const cells = proofGutterCells(item, rows, {status:"proved"});
  assert.match(cells[2], /proof-gutter-marker proved/);
  assert.doesNotMatch(cells[0], /proof-gutter-marker/);
  assert.doesNotMatch(cells[1], /proof-gutter-marker/);
});
