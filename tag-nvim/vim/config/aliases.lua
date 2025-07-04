local function setup_command_alias(from, to)
  vim.cmd(string.format('cnoreabbrev <expr> %s ((getcmdtype() is# ":" && getcmdline() is# "%s")? ("%s") : ("%s"))', from, from, to, from))
end

setup_command_alias("W", "w")
setup_command_alias("E", "e")