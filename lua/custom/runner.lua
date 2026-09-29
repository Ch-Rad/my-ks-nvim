local M = {}

local runner_buf = nil
local runner_win = nil
local runner_chan = nil

---Resolves the build/run command based on project files or filetype
---@return string|nil
local function get_command()
  local file = vim.fn.expand('%:p')
  local filename = vim.fn.expand('%:t')
  local ft = vim.bo.filetype

  -- Find root based on common markers
  local root = vim.fs.root(0, { 'CMakeLists.txt', 'Makefile', 'package.json', 'Cargo.toml', '.git' }) or vim.fn.getcwd()

  -----------------------------------------------------------
  -- 1. Project-Level Runners (takes precedence)
  -----------------------------------------------------------
  -- CMake (C / C++ / Game Dev)
  if vim.fn.filereadable(root .. '/CMakeLists.txt') == 1 and (ft == 'c' or ft == 'cpp' or ft == 'cmake') then
    -- Builds with cmake. If you use a standard binary target name, append it here (e.g. `&& ./build/bin/my_game`)
    return string.format('cd "%s" && cmake --build build', root)
  end

  -- Makefile
  if vim.fn.filereadable(root .. '/Makefile') == 1 and (ft == 'c' or ft == 'cpp') then
    return string.format('cd "%s" && make', root)
  end

  -- Node / Web (Vue, JS, TS)
  if vim.fn.filereadable(root .. '/package.json') == 1 and (ft == 'javascript' or ft == 'typescript' or ft == 'vue' or ft == 'html') then
    return string.format('cd "%s" && npm run dev', root)
  end

  -----------------------------------------------------------
  -- 2. Single-File Fallbacks
  -----------------------------------------------------------
  -- Python (auto-detects virtual environment in project root or active shell)
  if ft == 'python' then
    local python_bin = 'python3'
    if vim.fn.filereadable(root .. '/.venv/bin/python') == 1 then
      python_bin = root .. '/.venv/bin/python'
    elseif vim.fn.filereadable(root .. '/venv/bin/python') == 1 then
      python_bin = root .. '/venv/bin/python'
    elseif os.getenv('VIRTUAL_ENV') then
      python_bin = os.getenv('VIRTUAL_ENV') .. '/bin/python'
    end
    return string.format('%s "%s"', python_bin, file)
  end

  -- C++ (isolated single file compilation)
  if ft == 'cpp' then
    return string.format('clang++ -Wall -Wextra -std=c++20 "%s" -o /tmp/cpp_bin && /tmp/cpp_bin', file)
  end

  -- C (isolated single file compilation)
  if ft == 'c' then
    return string.format('clang -Wall -Wextra -O2 "%s" -o /tmp/c_bin && /tmp/c_bin', file)
  end

  -- Bash / Shell script
  if ft == 'sh' or ft == 'bash' then
    return string.format('bash "%s"', file)
  end

  -- Lua script (executed via Neovim's embedded runtime or system lua)
  if ft == 'lua' then
    return string.format('nvim -l "%s"', file)
  end

  -- JavaScript / TypeScript single script
  if ft == 'javascript' then
    return string.format('node "%s"', file)
  elseif ft == 'typescript' then
    return string.format('npx tsx "%s"', file)
  end

  -- HTML preview
  if ft == 'html' then
    return string.format('xdg-open "%s"', file)
  end

  return nil
end

---Ensures the bottom-docked terminal window and buffer exist
local function open_runner_window()
  -- If buffer does not exist, create a clean scratch buffer
  if not runner_buf or not vim.api.nvim_buf_is_valid(runner_buf) then
    runner_buf = vim.api.nvim_create_buf(false, true)
  end

  -- If window is not currently open, split at bottom across full width
  if not runner_win or not vim.api.nvim_win_is_valid(runner_win) then
    vim.cmd('botright 14split')
    runner_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(runner_win, runner_buf)

    -- If shell is not running, spawn one
    if not runner_chan then
      runner_chan = vim.fn.termopen(vim.o.shell, {
        detach = false,
        on_exit = function()
          runner_buf = nil
          runner_chan = nil
          runner_win = nil
        end,
      })
    end
  else
    vim.api.nvim_win_set_buf(runner_win, runner_buf)
  end
end

---Run the current file or project
function M.run()
  local cmd = get_command()
  if not cmd then
    vim.notify('No run command configured for this file/project type', vim.log.levels.WARN)
    return
  end

  -- Save current buffer
  vim.cmd('silent write')

  local origin_win = vim.api.nvim_get_current_win()

  open_runner_window()

  -- Send clear and the command to the persistent shell
  if runner_chan then
    vim.api.nvim_chan_send(runner_chan, string.format('clear && %s\n', cmd))
  end

  -- Keep editor focus in the code window so you can keep typing
  vim.api.nvim_set_current_win(origin_win)
end

---Toggle the runner terminal open/closed without re-running
function M.toggle()
  if runner_win and vim.api.nvim_win_is_valid(runner_win) then
    vim.api.nvim_win_close(runner_win, true)
    runner_win = nil
  else
    open_runner_window()
  end
end

return M
