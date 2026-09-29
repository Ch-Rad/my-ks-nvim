local function gh(repo)
  return 'https://github.com/' .. repo
end

vim.pack.add { gh 'akinsho/toggleterm.nvim' }

require('toggleterm').setup {
  open_mapping = [[<C-\>]],
  direction = 'float',
  float_opts = {
    border = 'curved',
  },
}
