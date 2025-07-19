return {
	"tpope/vim-projectionist",
	event = "VeryLazy",
	config = function()
		-- Rails-specific projections
		vim.g.projectionist_heuristics = {
			-- Rails application detection
			["config/application.rb"] = {
				-- Models
				["app/models/*.rb"] = {
					type = "model",
					alternate = "spec/models/{}_spec.rb",
					template = {
						"class {camelcase|capitalize|colons}",
						"end",
					},
				},
				["spec/models/*_spec.rb"] = {
					type = "spec",
					alternate = "app/models/{}.rb",
					template = {
						"require 'rails_helper'",
						"",
						"RSpec.describe {camelcase|capitalize|colons}, type: :model do",
						'  pending "add some examples to (or delete) #{__FILE__}"',
						"end",
					},
				},

				-- Controllers
				["app/controllers/*_controller.rb"] = {
					type = "controller",
					alternate = "spec/controllers/{}_controller_spec.rb",
					template = {
						"class {camelcase|capitalize|colons}Controller < ApplicationController",
						"end",
					},
				},
				["spec/controllers/*_controller_spec.rb"] = {
					type = "spec",
					alternate = "app/controllers/{}_controller.rb",
					template = {
						"require 'rails_helper'",
						"",
						"RSpec.describe {camelcase|capitalize|colons}Controller, type: :controller do",
						'  pending "add some examples to (or delete) #{__FILE__}"',
						"end",
					},
				},

				-- Views
				["app/views/*/*.html.erb"] = {
					type = "view",
					alternate = "spec/views/{}.html.erb_spec.rb",
				},

				-- Jobs
				["app/jobs/*_job.rb"] = {
					type = "job",
					alternate = "spec/jobs/{}_job_spec.rb",
					template = {
						"class {camelcase|capitalize|colons}Job < ApplicationJob",
						"  queue_as :default",
						"",
						"  def perform(*args)",
						"    # Do something later",
						"  end",
						"end",
					},
				},
				["spec/jobs/*_job_spec.rb"] = {
					type = "spec",
					alternate = "app/jobs/{}_job.rb",
					template = {
						"require 'rails_helper'",
						"",
						"RSpec.describe {camelcase|capitalize|colons}Job, type: :job do",
						'  pending "add some examples to (or delete) #{__FILE__}"',
						"end",
					},
				},

				-- Helpers
				["app/helpers/*_helper.rb"] = {
					type = "helper",
					alternate = "spec/helpers/{}_helper_spec.rb",
					template = {
						"module {camelcase|capitalize|colons}Helper",
						"end",
					},
				},
				["spec/helpers/*_helper_spec.rb"] = {
					type = "spec",
					alternate = "app/helpers/{}_helper.rb",
					template = {
						"require 'rails_helper'",
						"",
						"RSpec.describe {camelcase|capitalize|colons}Helper, type: :helper do",
						'  pending "add some examples to (or delete) #{__FILE__}"',
						"end",
					},
				},

				-- Mailers
				["app/mailers/*_mailer.rb"] = {
					type = "mailer",
					alternate = "spec/mailers/{}_mailer_spec.rb",
					template = {
						"class {camelcase|capitalize|colons}Mailer < ApplicationMailer",
						"end",
					},
				},
				["spec/mailers/*_mailer_spec.rb"] = {
					type = "spec",
					alternate = "app/mailers/{}_mailer.rb",
					template = {
						"require 'rails_helper'",
						"",
						"RSpec.describe {camelcase|capitalize|colons}Mailer, type: :mailer do",
						'  pending "add some examples to (or delete) #{__FILE__}"',
						"end",
					},
				},

				-- Feature/Request specs
				["spec/features/*_spec.rb"] = {
					type = "feature",
					template = {
						"require 'rails_helper'",
						"",
						"RSpec.feature '{capitalize}', type: :feature do",
						"  scenario 'User can' do",
						'    pending "add some examples to (or delete) #{__FILE__}"',
						"  end",
						"end",
					},
				},
				["spec/requests/*_spec.rb"] = {
					type = "request",
					alternate = "app/controllers/{}_controller.rb",
					template = {
						"require 'rails_helper'",
						"",
						"RSpec.describe '{capitalize}', type: :request do",
						"  describe 'GET /' do",
						"    it 'returns http success' do",
						"      get '/'",
						"      expect(response).to have_http_status(:success)",
						"    end",
						"  end",
						"end",
					},
				},

				-- Factories
				["spec/factories.rb"] = {
					type = "factory",
					template = {
						"FactoryBot.define do",
						"  factory :{} do",
						"  end",
						"end",
					},
				},

				-- Lib files
				["lib/*.rb"] = {
					type = "lib",
					alternate = "spec/lib/{}_spec.rb",
					template = {
						"class {camelcase|capitalize|colons}",
						"end",
					},
				},
				["spec/lib/*_spec.rb"] = {
					type = "spec",
					alternate = "lib/{}.rb",
					template = {
						"require 'rails_helper'",
						"",
						"RSpec.describe {camelcase|capitalize|colons} do",
						'  pending "add some examples to (or delete) #{__FILE__}"',
						"end",
					},
				},

				-- Config files
				["config/routes.rb"] = { type = "config" },
				["config/application.rb"] = { type = "config" },
				["config/environment.rb"] = { type = "config" },
				["config/environments/*.rb"] = { type = "config" },
				["config/initializers/*.rb"] = { type = "config" },

				-- Database
				["db/migrate/*.rb"] = { type = "migration" },
				["db/schema.rb"] = { type = "schema" },
				["db/seeds.rb"] = { type = "seed" },

				-- Rake tasks
				["lib/tasks/*.rake"] = {
					type = "task",
					template = {
						"namespace :{} do",
						"  desc 'TODO'",
						"  task {} => :environment do",
						"  end",
						"end",
					},
				},
			},
		}

		-- Key mappings for common projectionist commands
		local function map(mode, lhs, rhs, opts)
			opts = opts or {}
			opts.silent = opts.silent ~= false
			vim.keymap.set(mode, lhs, rhs, opts)
		end

		-- Navigation commands
		map("n", "<leader>pa", ":A<CR>", { desc = "Switch to alternate file" })
		map("n", "<leader>pv", ":AV<CR>", { desc = "Split alternate file vertically" })
		map("n", "<leader>ps", ":AS<CR>", { desc = "Split alternate file horizontally" })
		map("n", "<leader>pt", ":AT<CR>", { desc = "Open alternate file in new tab" })

		-- Related files
		map("n", "<leader>pr", ":R<CR>", { desc = "Switch to related file" })
		map("n", "<leader>pR", ":RV<CR>", { desc = "Split related file vertically" })

		-- File creation with templates
		map("n", "<leader>pE", ":E<CR>", { desc = "Create/edit file" })
		map("n", "<leader>pS", ":SV<CR>", { desc = "Create file in vertical split" })
		map("n", "<leader>pV", ":VS<CR>", { desc = "Create file in vertical split" })
		map("n", "<leader>pT", ":T<CR>", { desc = "Create file in new tab" })

		-- Quick access to common Rails files
		vim.api.nvim_create_user_command("Routes", "edit config/routes.rb", {})
		vim.api.nvim_create_user_command("Gemfile", "edit Gemfile", {})
		vim.api.nvim_create_user_command("Schema", "edit db/schema.rb", {})
		vim.api.nvim_create_user_command("Seeds", "edit db/seeds.rb", {})
		vim.api.nvim_create_user_command("Application", "edit config/application.rb", {})
	end,
}
