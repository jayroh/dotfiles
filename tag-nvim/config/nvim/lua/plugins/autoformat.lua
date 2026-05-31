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
					command = function(_, ctx)
						if vim.fs.find("Gemfile", { path = ctx.dirname, upward = true })[1] then
							return "bundle"
						end
						return "rubocop"
					end,
					prepend_args = function(_, ctx)
						if vim.fs.find("Gemfile", { path = ctx.dirname, upward = true })[1] then
							return { "exec", "rubocop" }
						end
						return {}
					end,
				},
				erb_formatter = {
					command = vim.fn.expand("~/.asdf/shims/erb-formatter"),
				},
			},
			format_on_save = {
				timeout_ms = 5000,
				lsp_format = "fallback",
				stop_after_first = false,
			},
		})
	end,
}
