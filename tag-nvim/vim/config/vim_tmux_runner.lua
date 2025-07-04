vim.g.VtrDetachedName = "detached"
vim.g.VtrPercentage = 30

vim.keymap.set('n', '<leader>rf', ':VtrFocusRunner<cr>', { silent = true })
vim.keymap.set('n', '<leader>ro', ':VtrOpenRunner<cr>', { silent = true })
vim.keymap.set('n', '<leader>rx', ':VtrKillRunner<cr>', { silent = true })
vim.keymap.set('n', '<leader>rc', ':VtrKillRunner<cr>', { silent = true })
vim.keymap.set('n', '<leader>rd', ':VtrSendCtrlD<cr>', { silent = true })
vim.keymap.set('n', '<leader>rcl', ':VtrClearRunner<cr>', { silent = true })

-- send `q` to pane
vim.keymap.set('n', '<leader>q', ':VtrSendCommandToRunner q<cr>:VtrKillRunner<cr>', { silent = true })

-- run test suite in the pane
vim.keymap.set('n', '<leader>ta', ':VtrOpenRunner<cr>:VtrSendCommandToRunner be rake<cr>', { silent = true })

-- repeat last command in the pane
vim.keymap.set('n', '<leader>ll', ':VtrSendCommandToRunner !!<cr><cr>', { silent = true })

-- send `bundle` to pane
vim.keymap.set('n', '<leader>bun', ':VtrOpenRunner<cr>:VtrSendCommandToRunner bundle install<cr>', { silent = true })

-- display git status in pane
vim.keymap.set('n', '<leader>gs', ':VtrOpenRunner<cr>:VtrSendCommandToRunner g s<cr>:VtrFocusRunner<cr>', { silent = true })

-- display git diff in pane
vim.keymap.set('n', '<leader>gd', ':VtrOpenRunner<cr>:VtrSendCommandToRunner g diff<cr>:VtrFocusRunner<cr>', { silent = true })

-- run rails server using local .port file
vim.keymap.set('n', '<leader>ser', ':VtrOpenRunner<cr>:VtrSendCommandToRunner rails server puma -p `cat .port`<cr>', { silent = true })

-- run rake
vim.keymap.set('n', '<leader>bra', ':VtrOpenRunner<cr>:VtrSendCommandToRunner rake<cr>', { silent = true })

-- send lines to runner
vim.keymap.set('v', '<leader>s', ':VtrSendLinesToRunner<cr>', { silent = true })