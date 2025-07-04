return {
	"kelly-lin/telescope-ag",
	dependencies = { "nvim-telescope/telescope.nvim" },
	keys = {
        {
            "<leader>ag",
            function()
                require('telescope.builtin').live_grep({ 
                    default_text = vim.fn.expand('<cword>') 
                })
            end,
            desc = "Live grep search"
        },
    },
}
