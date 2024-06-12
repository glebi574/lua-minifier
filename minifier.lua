local states = {
  code = 0, -- nothing weird
  comment_start = 1, -- -
  comment_just_started = 2, -- --
  comment = 3, -- --
  multiline_comment_start = 4, -- --[
  multiline_comment = 5, -- --[[
  multiline_comment_end = 6, -- ]
  string = 7, -- ' or "
  string_not_end = 8, -- \
  multiline_string_start = 9, -- [ or [==========
  multiline_string = 10, -- [[
  multiline_string_end = 11, -- ] or ==========]
}

local chars = {
  char = 1,
  number = 2,
  special = 3,
}

local special_char = {'(', ')', '{', '}', '[', ']', '<', '>', '#', '+', '-', '*', '/', '=', ',', '.', ':', ';', '~', '^', '%', '\'', '\"'}

local removable_char = {' ', '\t', '\n'}

function minify_file(input_path, output_path)
  local input_file = io.open(input_path, 'r')
  local output_file = io.open(output_path, 'w+')
  output_file:write(minify(input_file:read('*a')))
  input_file:close()
  output_file:close()
end

local function contains(arr, v)
  for _, q in ipairs(arr) do
    if q == v then
      return true
    end
  end
end

local b0 = string.byte'0'
local b9 = string.byte'9'

function minify(str)
  local state = states.code -- previous character
  local previous_char = chars.special -- latest not removable character type
  local need_space = false
  local current_str = 1 -- ' or "
  local abomination_len = 0 -- [==========[
  local abomination_counter = 0 -- ]==========]
  local tmp_str = {}
  local i = 1
  while i <= #str do
    local char = str:sub(i, i)
    if state == states.code then
      if contains(special_char, char) then
        if char == '\'' then
          state = states.string
          current_str = 1
        elseif char == '\"' then
          state = states.string
          current_str = 2
        elseif char == '[' then
          state = states.multiline_string_start
          abomination_len = 0
        elseif char == '-' then
          state = states.comment_start
        elseif char == '.' and previous_char == chars.number and str:sub(i + 1, i + 1) == '.' then -- 1 .. something will be malformed
          table.insert(tmp_str, ' ')
        end
        if char ~= '-' then
          previous_char = chars.special
        end
        table.insert(tmp_str, char)
      elseif contains(removable_char, char) then
        if previous_char == chars.char or previous_char == chars.number then
          need_space = true
        end
      else
        if need_space then
          if previous_char ~= chars.special then
            table.insert(tmp_str, ' ')
          end
          need_space = false
        end
        local bc = string.byte(char)
        if bc >= b0 and bc <= b9 then
          previous_char = chars.number
        else
          previous_char = chars.char
        end
        table.insert(tmp_str, char)
      end
    elseif state == states.comment_start then
      if char == '-' then
        state = states.comment_just_started
        need_space = true
        table.remove(tmp_str, #tmp_str)
      else
        state = states.code
        previous_char = chars.special
        i = i - 1
      end
    elseif state == states.comment_just_started then
      if char == '[' then
        state = states.multiline_comment_start
      elseif char == '\n' then
        state = states.code
      else
        state = states.comment
      end
    elseif state == states.comment then
      if char == '\n' then
        state = states.code
      end
    elseif state == states.multiline_comment_start then
      if char == '[' then
        state = states.multiline_comment
      elseif char == '\n' then
        state = states.code
      else
        state = states.comment
      end
    elseif state == states.multiline_comment then
      if char == ']' then
        state = states.multiline_comment_end
      end
    elseif state == states.multiline_comment_end then
      if char == ']' then
        state = states.code
      else
        state = states.multiline_comment
      end
    elseif state == states.string then
      if char == '\\' then
        state = states.string_not_end
      elseif (current_str == 1 and char == '\'') or (current_str == 2 and char == '\"') then
        state = states.code
      end
      table.insert(tmp_str, char)
    elseif state == states.string_not_end then
      state = states.string
      table.insert(tmp_str, char)
    elseif state == states.multiline_string_start then
      if char == '[' then
        state = states.multiline_string
        table.insert(tmp_str, char)
      elseif char == '=' then
        abomination_len = abomination_len + 1
        table.insert(tmp_str, char)
      else
        state = states.code
        i = i - 1
      end
    elseif state == states.multiline_string then
      if char == ']' then
        state = states.multiline_string_end
        abomination_counter = 0
      end
      table.insert(tmp_str, char)
    elseif state == states.multiline_string_end then
      if char == ']' then
        if abomination_counter == abomination_len then
          state = states.code
        else
          state = states.multiline_string
        end
      elseif char == '=' then
        abomination_counter = abomination_counter + 1
      end
      table.insert(tmp_str, char)
    end
    i = i + 1
  end
  return table.concat(tmp_str)
end
