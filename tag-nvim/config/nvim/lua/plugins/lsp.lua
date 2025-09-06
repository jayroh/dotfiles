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
			solargraph = {},
			ruby_lsp = {},
			docker_compose_language_service = {},
			dockerls = {},
			tailwindcss = {},
		},
	},
	config = function(_, opts)
		require("mason").setup()

		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "eslint", "solargraph", "ruby_lsp" },
		})

		for server, config in pairs(opts.servers) do
			vim.lsp.config(server, config)
			vim.lsp.enable(server)
		end

		vim.diagnostic.config({
			virtual_text = true,
			underline = true,
		})

		-- Override go to definition to open in new tab
		vim.keymap.set("n", "grd", function()
			vim.cmd("tab split")
			vim.lsp.buf.definition()
		end, { desc = "Go to definition in new tab" })
	end,
}
