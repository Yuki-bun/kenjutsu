---@class kenjutsu.ReviewConfig
---@field file_list_width integer

---@class kenjutsu.Config
---@field review kenjutsu.ReviewConfig

local M = {}

---@type kenjutsu.Config
local defaults = {
  review = {
    file_list_width = 40,
  },
}

---@type kenjutsu.Config
M.options = vim.deepcopy(defaults)

---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
