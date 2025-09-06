return {
	"saghen/blink.cmp",
	dependencies = { "rafamadriz/friendly-snippets" },

	version = "1.*",

	opts = {
		keymap = { preset = "super-tab" },

		appearance = { nerd_font_variant = "mono" },

		completion = { documentation = { auto_show = true } },

		fuzzy = { implementation = "prefer_rust_with_warning" },

		signature = { enabled = true },

		sources = {
			default = { "path", "snippets", "buffer", "lsp" },
		},
	},
}
