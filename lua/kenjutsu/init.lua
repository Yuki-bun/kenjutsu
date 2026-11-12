local M = {}

---@param opts? kenjutsu.Config
function M.setup(opts)
  require("kenjutsu.config").setup(opts)
end

function M.log()
  require("kenjutsu.log").open()
end

return M
