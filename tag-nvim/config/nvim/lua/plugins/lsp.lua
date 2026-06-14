local function as_path(arg)
	if type(arg) == "number" then
		local name = vim.api.nvim_buf_get_name(arg)
		return (name ~= "" and name) or vim.fn.getcwd()
	end
	return arg or vim.fn.getcwd()
end

local function find_root(arg, markers)
	local start = as_path(arg)
	local found = vim.fs.find(markers or { ".git" }, { path = start, upward = true })[1]
	return (found and vim.fs.dirname(found)) or vim.fn.getcwd()
end

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
			ruby_lsp = (function()
				local function build_cmd(root_dir)
					if root_dir and vim.fn.filereadable(root_dir .. "/Gemfile") == 1 then
						return { "bundle", "exec", "ruby-lsp" }
					end

					-- Fall back to Mason’s ruby-lsp if installed
					local ok, registry = pcall(require, "mason-registry")
					if ok then
						local pkg = registry.get_package("ruby-lsp")
						if pkg and pkg:is_installed() then
							return { pkg:get_install_path() .. "/bin/ruby-lsp" }
						end
					end

					-- Last resort: PATH
					return { "ruby-lsp" }
				end

				return {
					cmd = { "ruby-lsp" }, -- replaced in on_new_config
					root_dir = function(arg)
						-- Prefer Gemfile (project), fall back to .git
						return find_root(arg, { "Gemfile", ".git" })
					end,
					on_new_config = function(new_config, root_dir)
						new_config.cmd = build_cmd(root_dir)
					end,
					init_options = { formatter = "rubocop" },

					-- Optional: limit filetypes if you like
					-- filetypes = { "ruby", "eruby", "rake" },
				}
			end)(),
			docker_compose_language_service = {},
			dockerls = {},
			herb_ls = {},
			tailwindcss = {},
			stimulus_ls = {
				filetypes = { "html", "ruby", "eruby" },
				root_dir = function(fname)
					return find_root(fname, { "Gemfile", ".git" })
				end,
			},
			rubocop = (function()
				local function build_cmd(root_dir)
					if root_dir and vim.fn.filereadable(root_dir .. "/Gemfile") == 1 then
						return { "bundle", "exec", "rubocop", "--lsp" }
					end
					local ok, registry = pcall(require, "mason-registry")
					if ok then
						local pkg = registry.get_package("rubocop")
						if pkg and pkg:is_installed() then
							return { pkg:get_install_path() .. "/bin/rubocop", "--lsp" }
						end
					end
					return { "rubocop", "--lsp" }
				end
				return {
					cmd = { "rubocop", "--lsp" }, -- replaced below
					root_dir = function(arg)
						return find_root(arg, { "Gemfile", ".rubocop.yml", ".git" })
					end,
					on_new_config = function(new_config, root_dir)
						new_config.cmd = build_cmd(root_dir)
					end,
				}
			end)(),
		},
	},
	config = function(_, opts)
		require("mason").setup()

		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "eslint", "solargraph", "ruby_lsp", "stimulus_ls", "herb_ls" },
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
