return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    -- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  lazy = false, -- neo-tree will lazily load itself
  ---@module "neo-tree"
  ---@type neotree.Config?
  opts = {
    -- fill any relevant options here
  },
  config = function()
    require("neo-tree").setup({
  	  -- your other config options here
    })

	-- Custom keymaps

	-- ***************************
	-- Toggle Neotree w/Filesystem
	vim.keymap.set('n', '<leader>nt', function()
		require("neo-tree.command").execute({ toggle = true, source = "filesystem" })
	end, { desc = "Toggle Neo-tree filesystem" })

	-- ***************************
	-- Toggle Neotree w/Buffers
	vim.keymap.set('n', '<leader>nb', function()
		require("neo-tree.command").execute({ toggle = true, source = "buffers" })
	end, { desc = "Toggle Neo-tree buffers" })
  end,
}
