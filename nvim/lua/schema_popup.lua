local M = {}

local IRREGULARS = {
  person = "people", child = "children", man = "men", woman = "women",
  mouse = "mice", goose = "geese", tooth = "teeth", foot = "feet",
  datum = "data", medium = "media", analysis = "analyses", basis = "bases",
  crisis = "crises", diagnosis = "diagnoses", ox = "oxen", index = "indices",
  matrix = "matrices", vertex = "vertices", status = "statuses",
  alias = "aliases", bus = "buses",
}

local function pluralize(word)
  if IRREGULARS[word] then return IRREGULARS[word] end
  if word:match("[sxz]$") or word:match("[cs]h$") then return word .. "es" end
  if word:match("[^aeiou]y$") then return word:sub(1, -2) .. "ies" end
  return word .. "s"
end

local function table_name_from_buffer()
  local filepath = vim.fn.expand('%:p')
  local model_path = filepath:match('app/models/(.+)%.rb$')
  if not model_path then return nil end

  local lines = vim.api.nvim_buf_get_lines(0, 0, 50, false)
  for _, line in ipairs(lines) do
    local custom = line:match('self%.table_name%s*=%s*["\']([^"\']+)["\']')
    if custom then return custom end
  end

  local parts = vim.split(model_path, '/')
  parts[#parts] = pluralize(parts[#parts])
  return table.concat(parts, '_')
end

local function find_schema()
  local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if not root or root == '' then return nil end
  local path = root .. '/db/schema.rb'
  if vim.fn.filereadable(path) == 1 then return path end
  return nil
end

local function extract_table_block(schema_path, table_name)
  local file = io.open(schema_path, 'r')
  if not file then return nil, 'Could not open schema.rb' end

  local content = file:read('*all')
  file:close()

  local needle = 'create_table "' .. table_name .. '"'
  local start = content:find(needle, 1, true)
  if not start then return nil, 'Table "' .. table_name .. '" not found in schema.rb' end

  local block = content:sub(start)
  local result = {}
  local depth = 0

  for line in block:gmatch('[^\n]+') do
    table.insert(result, line)
    if line:match('do%s*|') or line:match('do%s*$') then depth = depth + 1 end
    if line:match('^%s*end%s*$') then
      depth = depth - 1
      if depth <= 0 then break end
    end
  end

  -- Strip common leading whitespace for cleaner display
  local min_indent = math.huge
  for _, line in ipairs(result) do
    local indent = line:match('^(%s*)')
    if #indent < min_indent and #line > 0 then min_indent = #indent end
  end
  if min_indent > 0 and min_indent < math.huge then
    for i, line in ipairs(result) do
      result[i] = line:sub(min_indent + 1)
    end
  end

  return result
end

local function show_float(lines, table_name)
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, #line)
  end
  local width = math.min(max_width + 2, math.floor(vim.o.columns * 0.9))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.8))

  local ui = vim.api.nvim_list_uis()[1]
  local col = math.floor((ui.width - width) / 2)
  local row = math.floor((ui.height - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'ruby'

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. table_name .. ' ',
    title_pos = 'center',
  })

  vim.wo[win].cursorline = true

  for _, key in ipairs({ '<Esc>', 'q' }) do
    vim.keymap.set('n', key, ':close<CR>', { buffer = buf, noremap = true, silent = true, nowait = true })
  end

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  vim.keymap.set('n', '/', '/', { buffer = buf, noremap = true })
  vim.keymap.set('n', 'n', 'n', { buffer = buf, noremap = true })
  vim.keymap.set('n', 'N', 'N', { buffer = buf, noremap = true })
end

function M.show(opts)
  opts = opts or {}
  local table_name = opts.table_name

  if not table_name or table_name == '' then
    table_name = table_name_from_buffer()
  end

  if not table_name then
    vim.notify('Schema: Not in a model file. Use :Schema <table_name>', vim.log.levels.ERROR)
    return
  end

  local schema_path = find_schema()
  if not schema_path then
    vim.notify('Schema: Could not find db/schema.rb', vim.log.levels.ERROR)
    return
  end

  local lines, err = extract_table_block(schema_path, table_name)
  if not lines then
    vim.notify('Schema: ' .. err, vim.log.levels.ERROR)
    return
  end

  show_float(lines, table_name)
end

local function complete_table_names(arg_lead, _, _)
  local schema_path = find_schema()
  if not schema_path then return {} end

  local file = io.open(schema_path, 'r')
  if not file then return {} end
  local content = file:read('*all')
  file:close()

  local names = {}
  for name in content:gmatch('create_table "([^"]+)"') do
    if name:find('^' .. vim.pesc(arg_lead)) then
      table.insert(names, name)
    end
  end
  return names
end

vim.api.nvim_create_user_command('Schema', function(cmd)
  M.show({ table_name = cmd.args ~= '' and cmd.args or nil })
end, {
  nargs = '?',
  complete = complete_table_names,
  desc = 'Show ActiveRecord schema for current model (or given table name)',
})

return M
