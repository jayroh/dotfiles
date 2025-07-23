return {
	"kelly-lin/telescope-ag",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	keys = {
		{
			"<leader>ag",
			function()
				require("telescope.builtin").live_grep()
			end,
			desc = "Live grep search",
		},
	},
}
