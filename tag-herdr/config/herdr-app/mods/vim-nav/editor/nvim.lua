-- vim-nav: Neovim side for the Herdr desktop app (not the TUI).
-- Ctrl+h/j/k/l moves between Neovim splits; at an edge it asks the app to move
-- pane focus (`herdr-app do pane.go:<dir>`). Does nothing outside the app, so
-- it can be dofile()d after vim-herdr-navigation's nvim.lua (TUI) safely.
if vim.env.__CFBundleIdentifier ~= "dev.herdr.app" or (vim.env.HERDR_PANE_ID or "") ~= "" then
  return
end

local function nav(wincmd, dir)
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() == prev then
    vim.fn.system({ "herdr-app", "do", "pane.go:" .. dir })
  end
end

for lhs, spec in pairs({
  ["<C-h>"] = { "h", "left" },
  ["<C-j>"] = { "j", "down" },
  ["<C-k>"] = { "k", "up" },
  ["<C-l>"] = { "l", "right" },
}) do
  vim.keymap.set("n", lhs, function()
    nav(spec[1], spec[2])
  end, { silent = true, noremap = true, desc = "Navigate " .. spec[2] .. " (vim/herdr app)" })
end
