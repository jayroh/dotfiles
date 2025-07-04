return {
  "catppuccin/nvim",
  lazy = false,     -- Load immediately on startup
  priority = 1000,  -- Load before other plugins
  name = "catppuccin",
  config = function()
    require("catppuccin").setup({
      integrations = {
        -- your integrations here
      },
    })
    vim.cmd.colorscheme("catppuccin")  -- Apply the colorscheme
  end,
  opts = {
	-- Opts go here
  },
}
