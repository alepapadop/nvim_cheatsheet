local M = {}

M.api = {}

M.api.globals = {}


M.api.globals['current_win_width'] = 0
M.api.globals['current_win_height'] = 0
M.api.globals['win'] = nil

function GetApiKeyBuffer()
    return 'buffer'
end

function GetApiKeyWindow()
    return 'window'
end

function GetApiKeyCurrentWindowWidth()
    return 'current_win_width'
end

function GetApiKeyCurrentWindowLength()
    return 'current_win_height'
end

function GetApiKeyHeaderSectionHl()
    return 'HeaderSeactionFormat'
end

function GetHeaderSectitonHlForegroundColor()
    return '#56B6C2'
end


function GetHeaderSectitonHlBackgroundColor()
    return '#56B6C2'
end

M.api.KEY_MAP_DATA = {}

-- library function do not use it
function M.api.MapAddTableData(map, key, data)
    local clean_key = key:gsub('<CR>', '')
    if not map[clean_key] then
        map[clean_key] = {}
    end
    table.insert(map[clean_key], data)
end

-- function that creates a keymap and stores extra data for the user shortcut helper (HYDRA)
-- mode - the vim mode eg. 'n' for normal
-- key - the keymap eg. <leader>ce
-- cmd -- the command eg. :e $MYVIMRC<CR>
-- desc -- the description of the command eg. 'Edit the init.lua file'. Will be visible in the user shortcut helper
-- group -- the group of the keymap eg. 'Generic'. Keymap with the same group will be visible in the same user shortcut helper list
function M.api.KeyMap(mode, key, cmd, desc, group, remap)
    if remap == nil then
        remap = true
    end
    vim.M.api.nvim_set_keymap(mode, key, cmd, { noremap = remap, silent = true, desc = desc } )
    local data = { mode = mode, key = key, cmd = cmd, desc = desc }
    M.api.MapAddTableData(M.api.KEY_MAP_DATA, group, data)
end

-- function that creates a keymap for a specific buffer and stores extra data for the user shortcut helper (HYDRA)
-- buffer - the buffer number
-- mode - the vim mode eg. 'n' for normal
-- key - the keymap eg. <leader>ce
-- cmd -- the command eg. :e $MYVIMRC<CR>
-- desc -- the description of the command eg. 'Edit the init.lua file'. Will be visible in the user shortcut helper
-- group -- the group of the keymap eg. 'Generic'. Keymap with the same group will be visible in the same user shortcut helper list
function M.api.KeyMapBuffer(buffer, mode, key, cmd, desc, group, remap)
    if remap == nil then
        remap = true
    end
    vim.M.api.nvim_buf_set_keymap(buffer, mode, key, cmd, { noremap = remap, silent = true, desc = desc } )
    local data = { mode = mode, key = key, cmd = cmd, desc = desc }
    M.api.MapAddTableData(M.api.KEY_MAP_DATA, group, data)
end

-- function for presenting internal vim commands in the user shortcut helper
-- arguments are same with KeyMap
function M.api.HelpMap(key, desc, group)
    local data = { mode = '', key = key, cmd = key, desc = desc }
    M.api.MapAddTableData(M.api.KEY_MAP_DATA, group, data)
end

function GetWindowSize()
    local w = vim.api.nvim_win_get_width(0)
    local h = vim.api.nvim_win_get_height(0)

    return w, h
end

function CreateFlowtingWindowAndBuffer(w, h)
    local buf = vim.api.nvim_create_buf(false, true)

    local opts = {
        relative = 'editor',
        width = w,
        height = h,
        col = 10,
        row = 5,
        style = 'minimal',
        border = 'rounded' -- Optional: rounded, single, double, solid
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    return win, buf
end


function DecideColumnWidthAndNum()
    local w, h = GetWindowSize()
    local factor = 0.8
    local max_cols = 4
    local min_column_w = 200
    local max_column_w = 400
    local final_col_num = 1
    
    w = factor * w
    h = factor * h

    local calc_max_col = w / min_column_w
    local calc_min_col = w / max_column_w

    if calc_max_col > calc_min_col then
        final_col_num = calc_max_col
    end

    if calc_max_col > max_cols then
        final_col_num = max_cols
    end

    if calc_min_col < 1 then
        final_col_num = 1
    end

    return final_col_num, w / final_col_num
    
end

function CreateSection()
    
end

function CreateSectionEntry()
end



function RandomHexColorCode()
  local tokens = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9','a','b','c','d','e','f'}

  local hex_color = '#'

  while (string.len(hex_color) < 7) do
    hex_color = hex_color .. tokens[math.random(1, #tokens) ]
  end

  return hex_color
end


function CreateSectionHeaderHl(header_name)
    local color = RandomHexColorCode()
    vim.api.nvim_set_hl(0, header_name, { fg = color, bold = true })
end

function CreateSectionHeaders()
end

local count = 0;

function M.hello_world()
  count = count + 1
  print("Hello, World!", count)
  local win, buf = CreateFlowtingWindowAndBuffer(50,50)

  M.api.globals[GetApiKeyBuffer()] = buf
  M.api.globals[GetApiKeyWindow()] = win

  local line_content = "  <Leader>ff : Find Files"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line_content })
  CreateSectionHeaderHl(GetApiKeyHeaderSectionHl())

  vim.api.nvim_buf_add_highlight(buf, -1, GetApiKeyHeaderSectionHl(), 0, 2, -1)

  vim.keymap.set('n', 'q', '<cmd>hide<cr>', { buffer = buf, silent = true })

end

-- Map a command to the function

return M
