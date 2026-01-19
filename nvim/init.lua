local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' ' -- Make sure to set `mapleader` before lazy so your mappings are correct
vim.g.maplocalleader = '\\' -- Same for `maplocalleader`

local plugins_manifest = require('plugins_manifest')
require('lazy').setup(plugins_manifest)
require('gen_prompts') -- custom prompts for gen llm interface
require('cheatsheet')  -- vim cheatsheet floating window

-- general settings
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 2
vim.opt.sidescrolloff = 5
vim.opt.wildignore:append({'**/node_modules/**'})
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.cmdheight = 2
vim.opt.updatetime = 300
vim.opt.switchbuf:append({ 'useopen', 'usetab' })
vim.opt.colorcolumn = "80"
vim.opt.foldmethod = 'indent'
vim.opt.foldlevel = 20
vim.opt.signcolumn = 'number'
vim.g.netrw_banner = 0

-- whitespace
vim.opt.wrap = false
vim.opt.tabstop = 8 -- recommended default, use below settings for 'actual' tabsize
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true -- use spaces, not tabs (optional)
vim.opt.backspace = { 'indent', 'eol', 'start' } -- backspace through everything in insert mode
-- TODO: check on this setting
-- :set list will show all whitespace characters
vim.opt.listchars = { tab = '>\\', trail = '-', extends = '>', precedes = '<', nbsp = '+' }


vim.opt.iskeyword:append('?') -- include question marks in autocomplete

-- statusline
vim.opt.laststatus = 2                      -- always display statusline
vim.opt.statusline = ''                     -- clear for reload
vim.opt.statusline:append('%3.3n')          -- buffer number
vim.opt.statusline:append(' %F%M')          -- full file path + modified flag
vim.opt.statusline:append(' %L/%l:%c')      -- linetotal/line:col
vim.opt.statusline:append(' %h%m%r%w')      -- status flags
vim.opt.statusline:append(' %#warningmsg#') -- highlight switch
vim.opt.statusline:append(' %*')            -- highlight exit

-- guitabline
-- local function GuiTabLabel()
--   -- TODO: learn Lua and make sure this is well-factored
--   local label = ''
--   local bufnrlist = vim.api.nvim_tabpage_list_bufs(0) -- tabpagebuflist in Neovim API
--
--    -- Add '+' if one of the buffers in the tab page is modified
--   for _, bufnr in ipairs(bufnrlist) do
--     local buf = vim.api.nvim_get_current_win() or 0
--     if vim.api.nvim_buf_get_option(buf, "modified") then
--       label = '+'
--       break
--     end
--   end
--
--    -- Append the number of windows in the tab page if more than one
--   local wincount = vim.api.nvim_tabpage_get_win_count(0) or 0
--   if wincount > 1 then
--     label = label .. wincount
--   end
--   if label ~= '' then
--     label = label .. ' '
--   end
--
--    -- Append the buffer name
--   local bufname = vim.api.nvim_buf_get_name(bufnrlist[#bufnrlist]) or ''
--   return label .. bufname
-- end
-- vim.api.nvim_set_option('guitablabel', '')                     -- clear for reload
-- vim.api.nvim_set_option('guitablabel', '%{GuiTabLabel()}')

-- prompt if file is changed
vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter', 'FocusGained'}, {
  pattern = '*',
  command = 'checktime'
})

-- make markdown files more readable
vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter'}, {
  pattern = {'*.md', '*.markdown'},
  command = 'set wrap'
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'vue',
  callback = function()
    vim.bo.commentstring = '// %s'
  end
})

-- mappings
vim.keymap.set({'n', 'v'}, '<Leader>w', '<C-w>')
vim.keymap.set({'n', 'v'}, '<Leader>y', '"+y')
vim.keymap.set({'n', 'v'}, '<Leader>p', '"+p')
vim.keymap.set({'n', 'v'}, '<Leader>P', '"+P')
vim.keymap.set('n', '<Leader>v', 'viw"0p')

vim.keymap.set('n', '<Leader>?', require('cheatsheet').open, { desc = 'Open cheatsheet' })

vim.keymap.set('n', '<Leader>f', ':GFiles<Cr>')
vim.keymap.set('n', '<Leader>F', ':Files<Cr>')
vim.keymap.set('n', '<Leader>b', ':Buffers<CR>')
vim.keymap.set('n', '<Leader>h', ':History<CR>')

vim.keymap.set('n', '<Leader>g', ':grep <C-r><C-w><Cr>')
vim.keymap.set('n', '<Leader>G', ':tabnew +grep <C-r><C-w><Cr> :copen<Cr>')

-- Grep word under cursor
vim.keymap.set('n', '<Leader>l', ':grep<space><C-r><C-w><Cr> :copen<Cr>')
vim.keymap.set('n', '<Leader>L', ':tabnew +grep<space><C-r><C-w><Cr> :copen<Cr>')

-- Grep literal (no regex interpretation)
vim.api.nvim_create_user_command('Grepl', function(opts)
  vim.cmd('grep --fixed-strings ' .. vim.fn.shellescape(opts.args))
  vim.cmd('copen')
end, { nargs = '+', desc = 'Grep literal string (no regex)' })

vim.keymap.set('v', '<Leader>gl', function()
  vim.cmd('normal! "zy')
  local selection = vim.fn.getreg('z')
  vim.cmd('grep --fixed-strings ' .. vim.fn.shellescape(selection))
  vim.cmd('copen')
end, { desc = 'Grep literal visual selection' })

-- Go to file line in GitHub
vim.keymap.set({'n', 'v'}, '<Leader>B', ":'<,'>GBrowse!<Cr>")

-- Open alternate file in below split
vim.keymap.set('n', '<Leader>S', ':sp<Cr>:A<Cr><C-w>J')

-- yank filename
vim.keymap.set('n', '<leader>yf', function()
  vim.cmd('let @+ = expand("%")')
  vim.cmd('echo "File path copied to clipboard"')
end)

-- commands
vim.keymap.set('ia', 'def@', 'def<CR>end<Up>')
vim.keymap.set('ia', 'info@', 'Rails.logger.info()<Left>')

-- Below is a function to run a command in given directory, followed by two keymappings that use
-- that function. If the keymappings were adapted from Vimscript, and they were found incorrect,
-- they are updated so they will correctly call the function with the intended arguments.

-- Rubocop
-- Utility function to run commands in given directory
-- TODO: fix me, does not navigate a directory up
local RunCommandInDir = function(dir, command, args)
  local old_dir = vim.fn.getcwd()  -- get current working directory
  vim.cmd('cd ' .. dir)  -- change to the specified directory
  local full_command = command .. (args ~= '' and ' ' .. args or '')  -- construct full command
  vim.cmd(full_command)  -- execute it
  vim.cmd('cd ' .. old_dir)  -- go back to previous working directory
end

-- vim.keymap.set('n', '<Leader>r', function() RunCommandInDir('server', 'RuboCop', '') end, { silent = true })
-- vim.keymap.set('n', '<Leader>R', function() RunCommandInDir('server', 'RuboCop', '-a') end, { silent = true })

if vim.fn.executable('rg') == 1 then
  vim.o.grepprg = 'rg --vimgrep --no-heading --smart-case --ignore-file ~/.rgignore'
  vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'
end
