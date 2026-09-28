import test from "node:test";
import assert from "node:assert/strict";
import { itemAtLine, resolveItem } from "../../notion/lib/manifest.mjs";

const manifest = {
  items: {
    a: {id:"a",file:"A.lean",startLine:10,endLine:20,primaryDeclaration:"Foo.demo"},
    b: {id:"b",file:"A.lean",startLine:30,endLine:35,primaryDeclaration:"Foo.other"},
    c: {id:"c",file:"B.lean",startLine:5,endLine:8,primaryDeclaration:"Bar.demo"}
  },
  declarations: {"Foo.demo":"a","Foo.other":"b","Bar.demo":"c"},
  shortNames: {demo:["a","c"],other:["b"]},
  files: {"A.lean":["a","b"],"B.lean":["c"]},
  legacyTargets: {"A.lean\u001fsection\u001fS":{id:"legacy",file:"A.lean",startLine:1,endLine:40}}
};

test("resolveItem resolves full declarations", () => {
  assert.equal(resolveItem(manifest, new URLSearchParams("decl=Foo.demo")).id, "a");
});
test("resolveItem disambiguates short names with file", () => {
  assert.equal(resolveItem(manifest, new URLSearchParams("decl=demo&file=B.lean")).id, "c");
});
test("itemAtLine chooses containing item and previous fallback", () => {
  assert.equal(itemAtLine(manifest, "A.lean", 12).id, "a");
  assert.equal(itemAtLine(manifest, "A.lean", 28).id, "a");
});
test("resolveItem preserves legacy targets", () => {
  assert.equal(resolveItem(manifest, new URLSearchParams("section=S&file=A.lean")).id, "legacy");
});
