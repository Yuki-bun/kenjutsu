vim.api.nvim_create_user_command("Kenjutsu", function(opts)
  local subcmd = opts.fargs[1]
  if subcmd == "log" then
    require("kenjutsu").log()
  else
    vim.notify("Unknown subcommand: " .. (subcmd or ""), vim.log.levels.ERROR)
  end
end, {
  nargs = "+",
  complete = function()
    return { "log" }
  end,
})
