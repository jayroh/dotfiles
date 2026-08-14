-- vim-herdr-navigation supersedes vim-tmux-navigator's mappings when present:
-- it handles herdr panes and falls back to tmux itself. Guarded so machines
-- without the herdr plugin keep vim-tmux-navigator's own mappings.
local herdr_nav = vim.fn.expand("~/.config/herdr/vim-herdr-navigation/editor/nvim.lua")
local has_herdr_nav = vim.uv.fs_stat(herdr_nav) ~= nil

return {
	{
		"christoomey/vim-tmux-navigator",
		lazy = false,
		init = function()
			vim.g.tmux_navigator_no_mappings = has_herdr_nav and 1 or nil
		end,
		config = function()
			if has_herdr_nav then
				dofile(herdr_nav)
			end
		end,
	},
}
