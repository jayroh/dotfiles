return {
	{
		"christoomey/vim-tmux-navigator",

		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
			"TmuxNavigatorProcessList",
		},

		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
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
