-- Keymaps and commands for the herdr runner pane.
--
-- Replaces lua/config/tmux.lua (raw `tmux` shell-outs) and the vim-tmux-runner
-- keymaps that used to live in lua/plugins/tmux.lua.

local runner = require("herdr.runner")

-- Visual selection, or the current line in normal mode.
local function selected_text()
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "\22" then
		local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		return table.concat(lines, "\n")
	end
	return vim.api.nvim_get_current_line()
end

-- Runner
vim.keymap.set({ "n", "v" }, "<leader>rs", function()
	runner.send_lines(selected_text())
end, { desc = "Send selection/line to herdr runner" })

vim.keymap.set("n", "<leader>rk", function()
	runner.kill()
end, { desc = "Kill herdr runner" })

vim.keymap.set("n", "<leader>rf", function()
	runner.focus()
end, { desc = "Focus herdr runner" })

vim.keymap.set("n", "<leader>rc", function()
	runner.clear()
end, { desc = "Clear herdr runner" })

-- Rubocop
vim.keymap.set("n", "<leader>ru", function()
	runner.run("rubocop -A")
end, { desc = "Run rubocop -A" })

vim.keymap.set("n", "<leader>bo", function()
	runner.run("rubocop -A " .. vim.fn.expand("%"))
end, { desc = "Run rubocop -A against this file" })

-- Commands
vim.api.nvim_create_user_command("HerdrRunnerOpen", function()
	runner.open()
end, { desc = "Open the herdr runner pane" })

vim.api.nvim_create_user_command("HerdrRunnerKill", function()
	runner.kill()
end, { desc = "Close the herdr runner pane" })

vim.api.nvim_create_user_command("HerdrRunnerFocus", function()
	runner.focus()
end, { desc = "Focus the herdr runner pane" })

vim.api.nvim_create_user_command("HerdrRunnerClear", function()
	runner.clear()
end, { desc = "Clear the herdr runner pane" })

vim.api.nvim_create_user_command("HerdrRunnerSend", function(opts)
	runner.run(opts.args)
end, { nargs = "+", desc = "Send a command to the herdr runner pane" })
