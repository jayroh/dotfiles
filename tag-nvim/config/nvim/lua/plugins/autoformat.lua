return {
	"stevearc/conform.nvim",

	opts = {},

	config = function()
		require("conform").setup({
			formatters_by_ft = {
				lua = { "stylua" },
				ruby = { "rubocop" },
				javascript = { "oxfmt" },
				typescript = { "oxfmt" },
				javascriptreact = { "oxfmt" },
				eruby = { "erb-formatter" },
				typescriptreact = { "oxfmt" },
			},
			formatters = {
				rubocop = {
					command = vim.fn.expand("~/.asdf/shims/rubocop"),
				},
				stylua = {
					command = vim.fn.expand("~/.asdf/shims/stylua"),
				},
				erb_formatter = {
					command = vim.fn.expand("~/.asdf/shims/erb-formatter"),
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
