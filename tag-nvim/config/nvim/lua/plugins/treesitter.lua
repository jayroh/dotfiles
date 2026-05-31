return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false, -- main branch does not support lazy-loading
	dependencies = {
		"nvim-treesitter/nvim-treesitter-context",
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		local parsers = {
			"bash",
			"css",
			"diff",
			"embedded_template",
			"html",
			"javascript",
			"json",
			"lua",
			"markdown",
			"markdown_inline",
			"query",
			"regex",
			"ruby",
			"scss",
			"svelte",
			"toml",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
			"vue",
			"yaml",
		}
		require("nvim-treesitter").install(parsers)

		-- Activate highlight + indent for any buffer whose filetype has a parser.
		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local ft = vim.bo[args.buf].filetype
				local lang = vim.treesitter.language.get_lang(ft)
				if not lang then
					return
				end
				if pcall(vim.treesitter.start, args.buf, lang) then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})

		require("treesitter-context").setup({
			max_lines = 3,
			trim_scope = "outer",
			mode = "cursor",
		})

		require("ts_context_commentstring").setup({
			enable_autocmd = false,
		})
	end,
}
