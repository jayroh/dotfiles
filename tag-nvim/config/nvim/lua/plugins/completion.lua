return {
	"saghen/blink.cmp",
	dependencies = {
		"rafamadriz/friendly-snippets",
		"moyiz/blink-emoji.nvim",
		{
			"mikavilpas/blink-ripgrep.nvim",
			version = "*", -- use the latest stable version
		},
	},

	version = "1.*",

	opts = {
		keymap = { preset = "super-tab" },

		appearance = { nerd_font_variant = "mono" },

		completion = { documentation = { auto_show = true } },

		fuzzy = { implementation = "prefer_rust_with_warning" },

		signature = { enabled = true },

		sources = {
			default = { "snippets", "path", "ripgrep", "buffer", "lsp", "emoji" },

			providers = {
				snippets = {
					opts = {
						search_paths = { vim.fn.stdpath("config") .. "/snippets" },
					},
				},
				ripgrep = {
					module = "blink-ripgrep",
					name = "Ripgrep",
					-- see the full configuration below for all available options
					---@module "blink-ripgrep"
					---@type blink-ripgrep.Options
					opts = {},
				},
				emoji = {
					module = "blink-emoji",
					name = "Emoji",
					score_offset = 15, -- Tune by preference
					opts = {
						insert = true, -- Insert emoji (default) or complete its name
						---@type string|table|fun():table
						trigger = function()
							return { ":" }
						end,
					},
					should_show_items = function()
						return vim.tbl_contains(
							-- Enable emoji completion only for git commits and markdown.
							-- By default, enabled for all file-types.
							{ "gitcommit", "markdown" },
							vim.o.filetype
						)
					end,
				},
			},
		},
	},
}
