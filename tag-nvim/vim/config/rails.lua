-- Rails.vim
vim.api.nvim_create_augroup('rails_shortcuts', { clear = true })

vim.g.rails_projections = {
  ["Gemfile"] = {
    command = "gem",
    alternate = "Gemfile.lock"
  },
  [".rubocop.yml"] = { command = "rubocop" },
  ["config/routes.rb"] = { command = "routes" },
  ["spec/factories.rb"] = { command = "factories" },
  ["spec/features/*_spec.rb"] = { command = "feature" },
  ["app/commands/*.rb"] = {
    command = "command",
    test = "spec/commands/%s_spec.rb"
  },
  ["app/jobs/*_job.rb"] = {
    command = "job",
    template = "# frozen_string_literal: true\nclass %SJob < ActiveJob::Job\nend",
    test = {
      "spec/jobs/%s_job_spec.rb"
    }
  }
}

-- custom settings for when Rails files are loaded. For more info:
-- :help rails-autocommands
vim.api.nvim_create_autocmd('User', {
  group = 'rails_shortcuts',
  pattern = 'Rails',
  callback = function()
    vim.keymap.set('n', '<Leader>m', ':Emodel<Space>', { buffer = true })
    vim.keymap.set('n', '<Leader>v', ':Eview<Space>', { buffer = true })
    vim.keymap.set('n', '<Leader>c', ':Econtroller<Space>', { buffer = true })
  end,
})

-- Exclude Javascript files in :Rtags via rails.vim due to warnings when parsing
vim.g.Tlist_Ctags_Cmd = "ctags --exclude='*.js'"