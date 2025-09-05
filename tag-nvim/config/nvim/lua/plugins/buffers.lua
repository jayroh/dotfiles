return {
	"mistweaverco/bafa.nvim",
	keys = { { "<Leader>be", ":lua require('bafa.ui').toggle()<CR>", desc = "Open buffers" } },
	opts = {
		width = 70,
		height = 20,
		title = "Buffers",
		title_pos = "center",
		relative = "editor",
		border = "rounded",
		style = "minimal",
		diagnostics = true,
	},
}
