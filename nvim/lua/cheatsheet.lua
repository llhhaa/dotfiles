-- Vim Cheatsheet floating window
-- Reads configuration from vim-cheatsheet.yaml
local M = {}
local yaml = require('tinyyaml')

local WIDTH = 81
local config_path = vim.fn.expand('~/.config/vim-cheatsheet.yaml')

-- Parse the YAML config file
local function parse_config(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    return nil, 'Could not open file: ' .. filepath
  end

  local content = file:read('*all')
  file:close()

  local ok, data = pcall(yaml.parse, content)
  if not ok then
    return nil, 'Failed to parse YAML: ' .. tostring(data)
  end

  return data
end

-- Get list of available cheatsheet IDs
local function get_cheatsheet_ids()
  local data, _ = parse_config(config_path)
  if not data or not data.cheatsheets then return {} end

  local ids = {}
  for _, sheet in ipairs(data.cheatsheets) do
    table.insert(ids, sheet.id)
  end
  return ids
end

-- Find cheatsheet by ID
local function find_cheatsheet(data, id)
  for _, sheet in ipairs(data.cheatsheets) do
    if sheet.id == id then
      return sheet
    end
  end
  return nil
end

local function build_header(cheatsheet, lines, highlights)
  -- Header
  local title = cheatsheet.title or 'CHEATSHEET'
  local header_line = string.format('║%s║',
    string.rep(' ', math.floor((WIDTH - 2 - #title) / 2)) ..
    title ..
    string.rep(' ', math.ceil((WIDTH - 2 - #title) / 2)))

  table.insert(lines, '╔' .. string.rep('═', WIDTH - 2) .. '╗')
  table.insert(highlights, { #lines, 'CheatHeader', 0, -1 })

  table.insert(lines, header_line)
  table.insert(highlights, { #lines, 'CheatHeader', 0, -1 })

  table.insert(lines, '╚' .. string.rep('═', WIDTH - 2) .. '╝')
  table.insert(highlights, { #lines, 'CheatHeader', 0, -1 })

  table.insert(lines, '')
end

-- Build content lines from cheatsheet data
local function build_content(cheatsheet)
  local lines = {}
  local highlights = {} -- { line_num, hl_group, col_start, col_end }

  build_header(cheatsheet, lines, highlights)

  -- Sections
  for _, section in ipairs(cheatsheet.sections) do
    -- Section header
    local section_header = '─── ' .. section.name .. ' '
    section_header = section_header .. string.rep('─', WIDTH - #section_header)
    table.insert(lines, section_header)
    table.insert(highlights, { #lines, 'CheatSection', 0, -1 })

    -- Section entries
    if section.type == 'plugins' then
      -- Two-column plugin layout
      local col_width = 40
      for i = 1, #section.entries, 2 do
        local e1 = section.entries[i]
        local e2 = section.entries[i + 1]

        local left = string.format('  %-14s %s', e1.name, e1.desc or '')
        local right = e2 and string.format('%-14s %s', e2.name, e2.desc or '') or ''
        local line = left .. string.rep(' ', col_width - #left) .. right

        table.insert(lines, line)
        -- Highlight plugin names
        table.insert(highlights, { #lines, 'CheatPlugin', 2, 2 + #e1.name })
        if e2 then
          table.insert(highlights, { #lines, 'CheatPlugin', col_width, col_width + #e2.name })
        end
      end

    elseif section.type == 'settings' then
      -- Settings layout: label: value pairs
      local parts = {}
      for _, entry in ipairs(section.entries) do
        table.insert(parts, { label = entry.label, value = entry.value })
      end

      -- Render 3 per line
      for i = 1, #parts, 3 do
        local line_parts = {}
        local col_positions = {}
        local col = 2

        for j = 0, 2 do
          local p = parts[i + j]
          if p then
            local part = p.label .. ': ' .. p.value
            table.insert(line_parts, part)
            table.insert(col_positions, { col = col, label_len = #p.label, value_start = col + #p.label + 2, value_len = #p.value })
            col = col + #part + 4
          end
        end

        local line = '  ' .. table.concat(line_parts, '    ')
        table.insert(lines, line)

        -- Highlight values
        for _, pos in ipairs(col_positions) do
          table.insert(highlights, { #lines, 'CheatValue', pos.value_start, pos.value_start + pos.value_len })
        end
      end

    else
      -- Standard keybinding layout
      for _, entry in ipairs(section.entries) do
        local key = entry.key or ''
        local desc = entry.desc or ''
        local prefix = entry.arrow and '→ ' or ''
        local note = entry.note and (' ' .. entry.note) or ''

        local line = string.format('  %-18s    %s%s%s', key, prefix, desc, note)
        table.insert(lines, line)

        -- Highlight key
        table.insert(highlights, { #lines, 'CheatKey', 2, 2 + #key })

        -- Highlight note if present
        if entry.note then
          local note_start = #line - #entry.note
          table.insert(highlights, { #lines, 'CheatDim', note_start, #line })
        end
      end
    end

    table.insert(lines, '')
  end

  -- Footer
  local footer = 'Press / to search, <Esc> or q to close'
  local footer_line = string.rep(' ', math.floor((WIDTH - #footer) / 2)) .. footer
  table.insert(lines, footer_line)
  table.insert(highlights, { #lines, 'CheatDim', 0, -1 })

  return lines, highlights
end

-- Define highlight groups
local function setup_highlights()
  vim.api.nvim_set_hl(0, 'CheatHeader', { fg = '#5fafaf', bold = true })
  vim.api.nvim_set_hl(0, 'CheatSection', { fg = '#d7af5f', bold = true })
  vim.api.nvim_set_hl(0, 'CheatKey', { fg = '#5faf5f', bold = true })
  vim.api.nvim_set_hl(0, 'CheatPlugin', { fg = '#af87d7' })
  vim.api.nvim_set_hl(0, 'CheatValue', { fg = '#5fafaf' })
  vim.api.nvim_set_hl(0, 'CheatDim', { fg = '#808080' })
end

-- Apply highlights to buffer
local function apply_highlights(buf, highlights)
  local ns = vim.api.nvim_create_namespace('cheatsheet')
  for _, hl in ipairs(highlights) do
    local row, group, col_start, col_end = hl[1], hl[2], hl[3], hl[4]
    vim.api.nvim_buf_add_highlight(buf, ns, group, row - 1, col_start, col_end)
  end
end

local function create_window(lines, highlights)
  -- Calculate window size
  local height = #lines
  local ui = vim.api.nvim_list_uis()[1]
  local col = math.floor((ui.width - WIDTH) / 2)
  local row = math.floor((ui.height - height) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'cheatsheet')

  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = WIDTH,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
  })

  -- Window options
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  vim.api.nvim_win_set_option(win, 'winblend', 0)

  -- Apply syntax highlighting
  apply_highlights(buf, highlights)

  -- Close on Esc or q
  for _, key in ipairs({ '<Esc>', 'q' }) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, ':close<CR>', {
      noremap = true,
      silent = true,
      nowait = true,
    })
  end

  -- Allow search with /
  vim.api.nvim_buf_set_keymap(buf, 'n', '/', '/', { noremap = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'n', 'n', { noremap = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'N', 'N', { noremap = true })
end

function M.open(id)
  setup_highlights()

  local data, err = parse_config(config_path)
  if not data or not data.cheatsheets then
    vim.notify('Cheatsheet: ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
    return
  end

  -- Default to first cheatsheet if no id provided
  local cheatsheet
  if id and id ~= '' then
    cheatsheet = find_cheatsheet(data, id)
    if not cheatsheet then
      vim.notify('Cheatsheet: No cheatsheet found with id "' .. id .. '"', vim.log.levels.ERROR)
      return
    end
  else
    cheatsheet = data.cheatsheets[1]
    if not cheatsheet then
      vim.notify('Cheatsheet: No cheatsheets defined', vim.log.levels.ERROR)
      return
    end
  end

  local lines, highlights = build_content(cheatsheet)

  create_window(lines, highlights);
end


-- Tab completion for cheatsheet IDs
local function complete_cheatsheet(arg_lead, _, _)
  local ids = get_cheatsheet_ids()
  local matches = {}
  for _, id in ipairs(ids) do
    if id:find('^' .. arg_lead) then
      table.insert(matches, id)
    end
  end
  return matches
end

-- Create user command with completion
vim.api.nvim_create_user_command('Cheatsheet', function(opts)
  M.open(opts.args)
end, {
  nargs = '?',
  complete = complete_cheatsheet,
  desc = 'Open cheatsheet (optional: specify id)',
})

return M
