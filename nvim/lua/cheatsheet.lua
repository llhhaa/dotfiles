-- Vim Cheatsheet floating window
-- Reads configuration from cheatsheet.yaml
local M = {}

local WIDTH = 81

-- Simple YAML parser for our specific format
local function parse_yaml(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    return nil, 'Could not open file: ' .. filepath
  end

  local content = file:read('*all')
  file:close()

  local data = { sections = {} }
  local current_section = nil
  local current_entry = nil
  local in_entries = false

  for line in content:gmatch('[^\n]+') do
    -- Title
    local title = line:match('^title:%s*(.+)$')
    if title then
      data.title = title
    end

    -- Section start (only at 2-space indent, not inside entries)
    local section_name = line:match('^  %- name:%s*(.+)$')
    if section_name and not in_entries then
      current_section = { name = section_name, entries = {} }
      table.insert(data.sections, current_section)
      current_entry = nil
    end

    -- Section type
    local section_type = line:match('^%s+type:%s*(.+)$')
    if section_type and current_section then
      current_section.type = section_type
    end

    -- Entries marker
    if line:match('^%s+entries:') then
      in_entries = true
    end

    -- New section resets in_entries (check for next section at proper indent)
    if line:match('^  %- name:') and in_entries then
      in_entries = false
      local new_section_name = line:match('^  %- name:%s*(.+)$')
      if new_section_name then
        current_section = { name = new_section_name, entries = {} }
        table.insert(data.sections, current_section)
        current_entry = nil
      end
    end

    -- Entry start (key, name, or label) - deeper indent
    if in_entries and current_section then
      local key = line:match('^%s+%- key:%s*"(.+)"$')
      local entry_name = line:match('^%s+%- name:%s*"(.+)"$')
      local label = line:match('^%s+%- label:%s*"(.+)"$')

      if key then
        current_entry = { key = key }
        table.insert(current_section.entries, current_entry)
      elseif entry_name then
        current_entry = { name = entry_name }
        table.insert(current_section.entries, current_entry)
      elseif label then
        current_entry = { label = label }
        table.insert(current_section.entries, current_entry)
      end

      -- Entry properties (on same or subsequent lines)
      if current_entry then
        local desc = line:match('desc:%s*"(.+)"$')
        local value = line:match('value:%s*"(.+)"$')
        local note = line:match('note:%s*"(.+)"$')
        local arrow = line:match('arrow:%s*(.+)$')

        if desc then current_entry.desc = desc end
        if value then current_entry.value = value end
        if note then current_entry.note = note end
        if arrow == 'true' then current_entry.arrow = true end
      end
    end
  end

  return data
end

-- Build content lines from parsed YAML
local function build_content(data)
  local lines = {}
  local highlights = {} -- { line_num, hl_group, col_start, col_end }

  -- Header
  local title = data.title or 'CHEATSHEET'
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

  -- Sections
  for _, section in ipairs(data.sections) do
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

function M.open()
  setup_highlights()

  -- Find vim-cheatsheet.yaml (symlinked to ~/.config/)
  local config_path = vim.fn.expand('~/.config/vim-cheatsheet.yaml')
  local data, err = parse_yaml(config_path)

  if not data then
    vim.notify('Cheatsheet: ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
    return
  end

  local lines, highlights = build_content(data)

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

return M
