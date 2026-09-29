local function gh(repo) return 'https://github.com/' .. repo end

-- Download minuet-ai and plenary
vim.pack.add {
  gh 'milanglacier/minuet-ai.nvim',
  gh 'nvim-lua/plenary.nvim',
}

require('minuet').setup {
  -- Display suggestions as inline ghost text (like GitHub Copilot)
  virtualtext = {
    auto_trigger_ft = { 'python', 'cpp', 'c', 'javascript', 'typescript', 'lua', 'sh' },
    auto_trigger_ignore_ft = {},
    keymap = {
      -- Accept the full ghost text suggestion
      accept = '<A-y>', -- Alt + y
      -- Accept only the next line
      accept_line = '<A-l>', -- Alt + l
      -- Cycle through alternate suggestions
      prev = '<A-[>',
      next = '<A-]>',
      -- Dismiss ghost text
      dismiss = '<A-e>',
    },
  },
  context_window = 2048,
  context_ratio = 0.75,
  n_completions = 2,
  provider = 'openai_compatible',
  provider_options = {
    openai_compatible = {
      model = 'qwen', -- placeholder, llama-server serves whatever is loaded
      end_point = 'http://127.0.0.1:8080/v1/chat/completions',
      api_key = 'TERM',
      name = 'llama.cpp',
      stream = true,
      optional = {
        max_tokens = 64, -- Keep short for fast code snippet completions
        temperature = 0.2, -- Low temperature for deterministic, accurate code
        top_p = 0.95,
      },
    },
  },

  -- Time in milliseconds to wait after you stop typing before prompting the LLM
  throttle = 250,
  -- Time to wait before canceling a stalled LLM request
  request_timeout = 3,
}

-- Toggle AI suggestions on/off with <leader>at
vim.keymap.set('n', '<leader>at', '<cmd>Minuet virtualtext toggle<CR>', { desc = '[A]I [T]oggle suggestions' })
