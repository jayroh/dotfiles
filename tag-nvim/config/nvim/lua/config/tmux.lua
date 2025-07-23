-- Open pane below current editor pane
vim.keymap.set("n", "<leader>tj", function()
	vim.fn.system('tmux split-window -v -c "#{pane_current_path}"')
end, { desc = "Open tmux pane below in current directory" })

-- Open pane to right of current editor pane
vim.keymap.set("n", "<leader>tl", function()
	vim.fn.system('tmux split-window -h -c "#{pane_current_path}"')
end, { desc = "Open tmux pane to the right in current directory" })

-- Convert vertical panes to horizontal layout
vim.keymap.set("n", "<leader>tv", function()
	vim.fn.system("tmux select-layout main-horizontal")
end, { desc = "Convert to vertical pane layout" })

-- Convert horizontal panes to vertical layout
vim.keymap.set("n", "<leader>th", function()
	vim.fn.system("tmux select-layout main-vertical")
end, { desc = "Convert to horizontal pane layout" })
