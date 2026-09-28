import test from "node:test";
import assert from "node:assert/strict";
import { proofGutterCells, proofStateForItem } from "../../notion/lib/proof.mjs";

test("proof status matches any declaration defined by an item", () => {
  const item = {defines:["Foo.demo"]};
  const statuses = {theorems:[{name:"Foo.demo",status:"proved"}]};
  assert.equal(proofStateForItem(item, statuses).status, "proved");
});
test("proof marker uses declarationLine when the item starts at a doc comment", () => {
  const item = {startLine:9,declarationLine:12};
  const rows = [
    {line:3,context:true,text:"variable (p : Nat)"},
    {line:9,context:false,text:"/--"},
    {line:10,context:false,text:"docs"},
    {line:11,context:false,text:"-/"},
    {line:12,context:false,text:"private theorem demo : True := by"},
    {line:13,context:false,text:"  trivial"}
  ];
  const cells = proofGutterCells(item, rows, {status:"proved"});
  assert.match(cells[4], /proof-gutter-marker proved/);
  assert.doesNotMatch(cells[1], /proof-gutter-marker/);
  assert.doesNotMatch(cells[2], /proof-gutter-marker/);
  assert.doesNotMatch(cells[3], /proof-gutter-marker/);
});

test("proof marker falls back to startLine for old manifests", () => {
  const cells = proofGutterCells({startLine:10}, [{line:10}], {status:"proved"});
  assert.match(cells[0], /proof-gutter-marker proved/);
});

test("proved gutter marker uses Lean VS Code's 16px double-check geometry", () => {
  const cells = proofGutterCells({startLine:10}, [{line:10}], {status:"proved"});
  assert.match(cells[0], /<svg/);
  assert.equal((cells[0].match(/<path /g) || []).length, 2);
  assert.match(cells[0], /viewBox="0 0 16 16"/);
  assert.match(cells[0], /16\.211845,3\.8542521/);
});
