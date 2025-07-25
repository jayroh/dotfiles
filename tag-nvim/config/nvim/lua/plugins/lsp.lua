return {
	"williamboman/mason.nvim",

	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"neovim/nvim-lspconfig",
	},

	opts = {
		servers = {
			lua_ls = {
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim", "Snacks" },
						},
					},
				},
			},
			rubocop = {
				cmd = { vim.fn.expand("~/.asdf/shims/rubocop"), "--lsp" },
			},
			solargraph = {},
			docker_compose_language_service = {},
			dockerls = {},
			tailwindcss = {},
		},
	},
	config = function(_, opts)
		require("mason").setup()

		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "eslint" },
		})

		for server, config in pairs(opts.servers) do
			vim.lsp.config(server, config)
			vim.lsp.enable(server)
		end

		vim.diagnostic.config({
			virtual_text = true,
			underline = true,
		})
	end,
}
