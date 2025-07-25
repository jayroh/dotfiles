return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		bigfile = { enabled = true },
		dashboard = { enabled = false },
		explorer = { enabled = false },
		indent = {
			enabled = true,
			animate = {
				duration = 0,
			},
		},
		input = { enabled = true },
		lazygit = { enabled = true },
		picker = { enabled = false },
		notifier = { enabled = true },
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
	},
	keys = {
		{ "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
		{ "<leader>rn", function() Snacks.rename.rename_file() end, desc = "Rename File" },
		{ "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
	},
}
