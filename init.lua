local M = {}

M.api = {}

M.api.KEY_MAP_DATA = {}
M.api.globals = {}
M.api.globals['current_win_width'] = 0
M.api.globals['current_win_height'] = 0
M.api.globals['win'] = nil
M.api.globals['number_of_columns'] = 0
M.api.globals['column_width'] = 0

M.papi = {}
M.papi.HeaderLines = {}
M.papi.HeaderLinesMeta = {}

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
    local data = { mode = ' ', key = key, cmd = key, desc = desc }
    M.api.MapAddTableData(M.api.KEY_MAP_DATA, group, data)
end










local function GetWindowSize()
    local w = vim.api.nvim_win_get_width(0)
    local h = vim.api.nvim_win_get_height(0)

    return w, h
end

local function CreateFlowtingWindowAndBuffer(w, h)
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


local function DecideColumnWidthAndNum()
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


local function RandomHexColorCode()
  local tokens = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9','a','b','c','d','e','f'}
  local hex_color = '#'

  while (string.len(hex_color) < 7) do
    hex_color = hex_color .. tokens[math.random(1, #tokens) ]
  end

  return hex_color
end

local function CreateSectionHeaderHl(header_name)
    local color = RandomHexColorCode()
    -- vim.api.nvim_set_hl(0, header_name, { fg = color, bold = true })
end

local function CreateSectionHeadersHl()
  for key, _ in pairs(M.papi.HeaderLines) do
    CreateSectionHeaderHl(key)
  end
end

local function CreateSectionHeaderAndTextMap()

  for key, data_table in pairs(M.api.KEY_MAP_DATA) do

    for _, data in pairs(data_table) do

    local mode_max_len = vim.api.nvim_strwidth(data.mode)
    local key_max_len = vim.api.nvim_strwidth(data.key)
    local desc_max_len = vim.api.nvim_strwidth(data.desc)

    if not M.papi.HeaderLines[key] then
        M.papi.HeaderLines[key] = {}
    end
    local section_data = { mode = data.mode, key = data.key, desc = data.desc }
    table.insert(M.papi.HeaderLines[key], section_data)

    if not M.papi.HeaderLinesMeta[key] then
      M.papi.HeaderLinesMeta[key] = { mode_max_len = mode_max_len, key_max_len = key_max_len, desc_max_len = desc_max_len }
    else
      if mode_max_len > M.papi.HeaderLinesMeta[key].mode_max_len then
        M.papi.HeaderLinesMeta[key].mode_max_len = mode_max_len
      end
      if key_max_len > M.papi.HeaderLinesMeta[key].key_max_len then
        M.papi.HeaderLinesMeta[key].key_max_len = key_max_len
      end
      if desc_max_len > M.papi.HeaderLinesMeta[key].desc_max_len then
        M.papi.HeaderLinesMeta[key].desc_max_len = desc_max_len
      end
    end

    end

  end
end

local function AlignText(text, width, alignment)
    local text_width = vim.api.nvim_strwidth(text)
    local padding = width - text_width

    if alignment == 'center' then
        local left_pad = math.floor(padding / 2)
        return string.rep(' ', left_pad) .. text
    elseif alignment == 'right' then
        return string.rep(' ', padding) .. text
    elseif alignment == 'left' then
      return text .. string.rep(' ', padding)
    else
        return text
    end
end

local function IsBlankString(s)
    if #s == 0 then return true end

    for i = 1, #s do
        local b = s:byte(i)
        if not (b == 32 or (b >= 9 and b <= 13)) then
            return false
        end
    end

    return true
end

local function TextToWidthTokens(text, max_width)
    local lines = {}
    local start_idx = 1
    local i = 1
    local len = #text

    while i <= len do
        local char_end = i + 1
        while char_end <= len and text:byte(char_end) >= 128 and text:byte(char_end) <= 191 do
            char_end = char_end + 1
        end

        local chunk = text:sub(start_idx, char_end - 1)
        local current_w = vim.api.nvim_strwidth(chunk)

        if current_w > max_width then
            if i == start_idx then
                table.insert(lines, text:sub(start_idx, char_end - 1))
                start_idx = char_end
                i = char_end
            else
                table.insert(lines, text:sub(start_idx, i - 1))
                start_idx = i
            end
        else
            i = char_end

            if i > len then
                table.insert(lines, text:sub(start_idx, len))
            end
        end
    end

    return lines
end



function FormatCheatSheetLines()

  local max_width = 50
  local buf = M.api.globals[GetApiKeyBuffer()]
  local line = 0

  local keys = {}
  for key, _ in pairs(M.papi.HeaderLines) do
      table.insert(keys, key)
  end

  for _, header in ipairs(keys) do
    local new_block = 0
    local mode_max_len = 0
    local key_max_len = 0
    local desc_max_len = 0
    for i, data in ipairs(M.papi.HeaderLines[header]) do

        local align = 'left'

        if new_block == 0 then
            mode_max_len = M.papi.HeaderLinesMeta[header].mode_max_len
            key_max_len = M.papi.HeaderLinesMeta[header].key_max_len
            desc_max_len = M.papi.HeaderLinesMeta[header].desc_max_len

            local mode_str_len = vim.api.nvim_strwidth('Mode')
            if mode_str_len > mode_max_len then
                mode_max_len = mode_str_len;
            end
            local key_str_len = vim.api.nvim_strwidth('Key')
            if key_str_len > key_max_len then
                key_max_len = key_str_len;
            end
            local desc_str_len = vim.api.nvim_strwidth('Description')
            if desc_str_len > desc_max_len then
                desc_max_len = desc_str_len;
            end

            local header_format = AlignText(header, max_width, 'center')
            local heading_mode_format = AlignText('Mode', mode_max_len, align)
            local heading_key_format = AlignText('Key', key_max_len, align)
            local heading_desc_format = AlignText('Description', desc_max_len, align)
            local heading = ' ' .. heading_mode_format .. '  ' .. heading_key_format .. '  ' .. heading_desc_format .. ' '

            line = line + 1
            vim.api.nvim_buf_set_lines(buf, line, line, false, { header_format })
            line = line + 1
            vim.api.nvim_buf_set_lines(buf, line, line, false, { heading })

            new_block = new_block + 1
        end

        local mode = AlignText(data.mode, mode_max_len, align)
        local key = AlignText(data.key, key_max_len, align)
        local desc = AlignText(data.desc, desc_max_len, align)

        local remaining_width = vim.api.nvim_strwidth(' ' .. mode .. '  ' .. key .. '  ' .. ' ')

        local desc_lines = TextToWidthTokens(desc, remaining_width)
--      print(vim.inspect(desc_lines))
        local padding_text = ''
        for k, desc_line in ipairs(desc_lines) do
            local entry = ''

            if not IsBlankString(desc_line) then

              line = line + 1
              if #desc_line and desc_line:sub(1,1) == ' ' then
                  desc_line = desc_line:sub(2) .. ' '
              end
              if k == 1 then
                  entry = ' ' .. mode .. '  ' .. key .. '  ' .. desc_line .. ' '
                  padding_text = string.rep(' ', mode_max_len + key_max_len + 5)
              else
                  entry = padding_text .. desc_line .. ' '
              end
              vim.api.nvim_buf_set_lines(buf, line, line, false, { entry })

              line = line + 1
            end
        end

    end
    line = line + 3
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {  "", "" ,"" })

  end
end

M.api.HelpMap('<leader>aa', 'a key', 'Find')
M.api.HelpMap('<leader>ab', 'b this is a key with a long line!', 'Find')
M.api.HelpMap('<leader>ac', 'c this is a key with an even longer line than the previous one!', 'Find')
M.api.HelpMap('<leader>ad', 'd this a short!', 'Find')
M.api.HelpMap('<leader>ae', 'e this is a key with an even longer line than the previous one an it is really a very long line and will wrap many times!', 'Find')

-- M.api.HelpMap('<leader>ba', 'a key', 'Beta Find')
-- M.api.HelpMap('<leader>bb', 'b this is a key with a long line!', 'Beta Find')
-- M.api.HelpMap('<leader>bc', 'c this is a key with an even longer line than the previous one!', 'Beta Find')
-- M.api.HelpMap('<leader>bd', 'd this a short!', 'Beta Find')
-- M.api.HelpMap('<leader>be', 'e this is a key with an even longer line than the previous one an it is really a very long line and will wrap many times!', 'Beta Find')
-- 
-- M.api.HelpMap('<leader>ca', 'a key', 'Ceta Find')
-- M.api.HelpMap('<leader>cb', 'b this is a key with a long line!', 'Ceta Find')
-- M.api.HelpMap('<leader>cc', 'c this is a key with an even longer line than the previous one!', 'Beta Find')
-- M.api.HelpMap('<leader>cd', 'd this a short!', 'Ceta Find')
-- M.api.HelpMap('<leader>ce', 'e this is a key with an even longer line than the previous one an it is really a very long line and will wrap many times!', 'Ceta Find')
-- 
-- M.api.HelpMap('<leader>da', 'a key', 'Deta Find')
-- M.api.HelpMap('<leader>db', 'b this is a key with a long line!', 'Deta Find')
-- M.api.HelpMap('<leader>dc', 'c this is a key with an even longer line than the previous one!', 'Deta Find')
-- M.api.HelpMap('<leader>dd', 'd this a short!', 'Deta Find')
-- M.api.HelpMap('<leader>de', 'e this is a key with an even longer line than the previous one an it is really a very long line and will wrap many times!', 'Deta Find')
-- M.api.HelpMap('<leader>df', 'f short', 'Deta Find')


local count = 0;

function M.hello_world()
  count = count + 1
  print("Hello, World!", count)
  local win, buf = CreateFlowtingWindowAndBuffer(50,50)

  M.api.globals[GetApiKeyBuffer()] = buf
  M.api.globals[GetApiKeyWindow()] = win

  local line_content = "  <Leader>ff : Find Files"
  -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line_content })

  CreateSectionHeaderAndTextMap()
  CreateSectionHeadersHl()
  FormatCheatSheetLines()

  -- vim.api.nvim_buf_add_highlight(buf, -1, GetApiKeyHeaderSectionHl(), 0, 2, -1)

  vim.keymap.set('n', 'q', '<cmd>hide<cr>', { buffer = buf, silent = true })

end


return M
