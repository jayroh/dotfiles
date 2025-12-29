return {
	"stevearc/conform.nvim",

	opts = {},

	config = function()
		require("conform").setup({
			formatters_by_ft = {
				lua = { "stylua" },
				ruby = { "rubocop" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
			},
			formatters = {
				rubocop = {
					command = vim.fn.expand("~/.asdf/shims/rubocop"),
				},
				stylua = {
					command = vim.fn.expand("~/.asdf/shims/stylua"),
				},
			},
			format_on_save = {
				timeout_ms = 5000,
				lsp_format = "fallback",
				stop_after_first = false, -- Run both eslint_d AND prettier
			},
		})
	end,
}
