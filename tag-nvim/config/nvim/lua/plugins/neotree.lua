return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	lazy = false,
	keys = {
		{ "<leader>nt", "<cmd>Neotree toggle filesystem<cr>", desc = "Toggle Neo-tree filesystem" },
		{ "<leader>nb", "<cmd>Neotree toggle buffers<cr>", desc = "Toggle Neo-tree buffers" },
		{ "<leader>be", "<cmd>Neotree toggle buffers<cr>", desc = "Toggle Neo-tree buffers" },
	},
}
