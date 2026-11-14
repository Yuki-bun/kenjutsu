local M = {}

-- an empty buffer holds a single empty line, which must not count as content
---@param lines string[]
---@return boolean
local function is_empty(lines)
  return #lines == 0 or (#lines == 1 and lines[1] == "")
end

---@param lines string[]
---@return string
local function join(lines)
  return is_empty(lines) and "" or table.concat(lines, "\n") .. "\n"
end

--- Build a unified diff body limited to the new-side lines [first, last].
--- Removed lines are included when they sit directly before a selected line.
---@param old_lines string[]
---@param new_lines string[]
---@param first integer
---@param last integer
---@return string|nil body nil when the new side has nothing to select
function M.body(old_lines, new_lines, first, last)
  if is_empty(new_lines) then
    return nil
  end
  last = math.min(last, #new_lines)

  local indices = vim.diff(join(old_lines), join(new_lines), {
    result_type = "indices",
  }) --[[@as integer[][] ]]

  ---@type table<integer, integer[]> new line -> old line numbers removed just before it
  local removed_before = {}
  ---@type table<integer, boolean>
  local added = {}
  for _, h in ipairs(indices) do
    local start_a, count_a, start_b, count_b = h[1], h[2], h[3], h[4]
    -- start_b is the line *before* the gap when nothing was added
    local anchor = count_b == 0 and start_b + 1 or start_b
    removed_before[anchor] = removed_before[anchor] or {}
    for i = start_a, start_a + count_a - 1 do
      table.insert(removed_before[anchor], i)
    end
    for i = start_b, start_b + count_b - 1 do
      added[i] = true
    end
  end

  ---@param line integer unchanged new-side line
  ---@return integer
  local function old_number(line)
    local delta = 0
    for _, h in ipairs(indices) do
      local end_b = h[4] == 0 and h[3] or h[3] + h[4] - 1
      if end_b < line then
        delta = delta + h[2] - h[4]
      end
    end
    return line + delta
  end

  local body = {}
  local old_start, old_count, new_count = nil, 0, 0
  for line = first, last do
    for _, old_line in ipairs(removed_before[line] or {}) do
      table.insert(body, "-" .. old_lines[old_line])
      old_start = old_start or old_line
      old_count = old_count + 1
    end
    if added[line] then
      table.insert(body, "+" .. new_lines[line])
    else
      table.insert(body, " " .. new_lines[line])
      old_start = old_start or old_number(line)
      old_count = old_count + 1
    end
    new_count = new_count + 1
  end
  old_start = old_start or (old_number(first) - 1)
  local header = string.format("@@ -%d,%d +%d,%d @@", old_start, old_count, first, new_count)
  return header .. "\n" .. table.concat(body, "\n")
end

--- Label both sides by meaning rather than mimicking git's a/ b/ /dev/null.
---@param file kenjutsu.FileEntry
---@return string
function M.header(file)
  local before = file.status == "added" and "(none, new file)" or file.oldPath or file.newPath
  local after = file.status == "deleted" and "(none, deleted)" or file.newPath
  return string.format("before: %s\nafter: %s", before, after)
end

return M
