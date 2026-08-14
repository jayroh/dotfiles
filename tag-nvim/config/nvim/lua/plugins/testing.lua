return {
	"vim-test/vim-test",
	config = function()
		vim.keymap.set("n", "<leader>t", ":TestNearest<CR>", {})
		vim.keymap.set("n", "<leader>T", ":TestFile<CR>", {})
		vim.keymap.set("n", "<leader>a", ":TestSuite<CR>", {})
		vim.keymap.set("n", "<leader>l", ":TestLast<CR>", {})
		vim.keymap.set("n", "<leader>g", ":TestVisit<CR>", {})

		-- vim-test dispatches through g:test#custom_strategies, a dict of
		-- funcrefs — built in vimscript because a Lua table holding a funcref
		-- does not round-trip through vim.g.
		vim.cmd([[
			function! HerdrTestStrategy(cmd) abort
				call luaeval('require("herdr.runner").run(_A)', a:cmd)
			endfunction

			let g:test#custom_strategies = get(g:, 'test#custom_strategies', {})
			let g:test#custom_strategies['herdr'] = function('HerdrTestStrategy')
		]])

		-- Outside herdr fall back to vim-test's built-in strategy rather than
		-- silently sending tests nowhere.
		vim.g["test#strategy"] = require("herdr.runner").available() and "herdr" or "basic"
	end,
}
