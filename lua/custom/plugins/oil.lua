local function gh(repo)
  return 'https://github.com/' .. repo
end

vim.pack.add {
  gh 'stevearc/oil.nvim',
  gh 'nvim-tree/nvim-web-devicons', -- optional, for file icons
}

require('oil').setup {
  view_options = {
    show_hidden = true,
  },
}

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory in Oil' })
