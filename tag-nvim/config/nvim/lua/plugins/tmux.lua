-- vim-herdr-navigation supersedes vim-tmux-navigator's mappings when present:
-- it handles herdr panes and falls back to tmux itself. Guarded so machines
-- without the herdr plugin keep vim-tmux-navigator's own mappings.
local herdr_nav = vim.fn.expand("~/.config/herdr/vim-herdr-navigation/editor/nvim.lua")
local has_herdr_nav = vim.uv.fs_stat(herdr_nav) ~= nil

return {
	{
		"christoomey/vim-tmux-navigator",
		lazy = false,
		init = function()
			vim.g.tmux_navigator_no_mappings = has_herdr_nav and 1 or nil
		end,
		config = function()
			if has_herdr_nav then
				dofile(herdr_nav)
			end
		end,
	},
	{
		"christoomey/vim-tmux-runner",
		enabled = true and os.getenv("TMUX") ~= nil,
		lazy = false,

		keys = {
			-- send all visually selected lines to attached pane
			{ "<leader>tl", "<cmd>VtrSendLinesToRunner<cr>", "desc = Send Lines to Tmux Runner" },

			-- rubocop helpers
			{
				"<leader>bo",
				":VtrSendCommandToRunner rubocop -A <C-R>=expand('%')<CR><CR>",
				desc = "Run rubocop against this file",
			},

			{ "<leader>ru", "<cmd>VtrSendCommandToRunner rubocop -A<cr>", "desc = Run rubocop against this file" },
			-- add current file to claude code
			{
				"<leader>ab",
				":VtrSendCommandToRunner @./<C-R>=expand('%')<CR> ",
				desc = "Add full path, with @, to Claude Code",
			},
		},
	},
}
