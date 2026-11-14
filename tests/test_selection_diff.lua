local t = require("tests.test")

local selection_diff = require("kenjutsu.selection_diff")

---@param n integer
---@return string[]
local function numbered(n)
  local lines = {}
  for i = 1, n do
    lines[i] = "l" .. i
  end
  return lines
end

---@param ... string
---@return string
local function body(...)
  return table.concat({ ... }, "\n")
end

-- body ------------------------------------------------------------------------

t.run_case("body shows unchanged lines as context when selection has no change", function()
  local new = numbered(10)
  new[3] = "X3"
  t.eq(selection_diff.body(numbered(10), new, 6, 8), body("@@ -6,3 +6,3 @@", " l6", " l7", " l8"))
end)

t.run_case("body handles a single unchanged line", function()
  t.eq(selection_diff.body(numbered(10), numbered(10), 2, 2), body("@@ -2,1 +2,1 @@", " l2"))
end)

t.run_case("body shows an added line", function()
  local new = numbered(10)
  table.insert(new, 3, "NEW")
  t.eq(selection_diff.body(numbered(10), new, 3, 3), body("@@ -2,0 +3,1 @@", "+NEW"))
end)

t.run_case("body shows a replaced line as removal then addition", function()
  local new = numbered(10)
  new[3] = "X3"
  t.eq(selection_diff.body(numbered(10), new, 3, 3), body("@@ -3,1 +3,1 @@", "-l3", "+X3"))
end)

t.run_case("body keeps order when selection spans context and a change", function()
  local new = numbered(10)
  new[3] = "X3"
  t.eq(selection_diff.body(numbered(10), new, 2, 4), body("@@ -2,3 +2,3 @@", " l2", "-l3", "+X3", " l4"))
end)

t.run_case("body shows whole replaced block when selection starts at the hunk start", function()
  local new = numbered(10)
  new[3], new[4], new[5] = "A", "B", "C"
  t.eq(selection_diff.body(numbered(10), new, 3, 4), body("@@ -3,3 +3,2 @@", "-l3", "-l4", "-l5", "+A", "+B"))
end)

t.run_case("body omits removals when selection starts inside a hunk", function()
  local new = numbered(10)
  new[3], new[4], new[5] = "A", "B", "C"
  t.eq(selection_diff.body(numbered(10), new, 4, 4), body("@@ -3,0 +4,1 @@", "+B"))
end)

t.run_case("body shows multiple inserted lines", function()
  local new = numbered(10)
  table.insert(new, 3, "N2")
  table.insert(new, 3, "N1")
  t.eq(selection_diff.body(numbered(10), new, 3, 4), body("@@ -2,0 +3,2 @@", "+N1", "+N2"))
end)

t.run_case("body shows a deletion before the selected line", function()
  local new = numbered(10)
  table.remove(new, 5)
  t.eq(selection_diff.body(numbered(10), new, 5, 5), body("@@ -5,2 +5,1 @@", "-l5", " l6"))
end)

t.run_case("body leaves out a deletion right after the selection", function()
  local new = numbered(10)
  table.remove(new, 5)
  t.eq(selection_diff.body(numbered(10), new, 4, 4), body("@@ -4,1 +4,1 @@", " l4"))
end)

t.run_case("body accounts for earlier hunks in old line numbers", function()
  local new = numbered(10)
  table.insert(new, 1, "N2")
  table.insert(new, 1, "N1")
  t.eq(selection_diff.body(numbered(10), new, 6, 6), body("@@ -4,1 +6,1 @@", " l4"))
end)

t.run_case("body clamps a selection past the end of the file", function()
  t.eq(selection_diff.body(numbered(3), numbered(3), 2, 99), body("@@ -2,2 +2,2 @@", " l2", " l3"))
end)

t.run_case("body treats every line of an added file as added", function()
  t.eq(selection_diff.body({ "" }, { "a", "b" }, 1, 2), body("@@ -0,0 +1,2 @@", "+a", "+b"))
end)

t.run_case("body returns nil when the new side is empty", function()
  t.eq(selection_diff.body(numbered(3), { "" }, 1, 1), nil)
  t.eq(selection_diff.body(numbered(3), {}, 1, 1), nil)
end)

-- header ----------------------------------------------------------------------

t.run_case("header labels before and after with the same path", function()
  local file = { newPath = "src/x.lua", oldPath = "src/x.lua", status = "modified" }
  t.eq(selection_diff.header(file), "before: src/x.lua\nafter: src/x.lua")
end)

t.run_case("header shows the old path for a rename", function()
  local file = { newPath = "src/new.lua", oldPath = "src/old.lua", status = "renamed" }
  t.eq(selection_diff.header(file), "before: src/old.lua\nafter: src/new.lua")
end)

t.run_case("header marks an added file as having no before", function()
  local file = { newPath = "src/x.lua", status = "added" }
  t.eq(selection_diff.header(file), "before: (none, new file)\nafter: src/x.lua")
end)

t.run_case("header marks a deleted file as having no after", function()
  local file = { oldPath = "src/x.lua", status = "deleted" }
  t.eq(selection_diff.header(file), "before: src/x.lua\nafter: (none, deleted)")
end)
