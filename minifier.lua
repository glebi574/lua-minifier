
function str_to_arr(str)
  local arr = {}
  for i = 1, #str do
    table.insert(arr, str:sub(i, i))
  end
  return arr
end

function is_in_arr(var, arr)
  for k, v in ipairs(arr) do
    if var == v then return true end
  end
  return false
end

local alph_special = '{}[]<->+=/*#%^:;.,()'
local alph_string  = '\'\"'
local alph_remove  = ' \t\n'

local arr_special  = str_to_arr(alph_special)
local arr_string   = str_to_arr(alph_string )
local arr_remove   = str_to_arr(alph_remove )

local string_state = false
local multiline_string_state = false
local post_comment_state = false
local comment_state = false
local multiline_comment_state = false
local state = 2

TYPE_CHAR      = 1
TYPE_SPECIAL   = 2
TYPE_STRING    = 3
TYPE_REMOVE    = 4
TYPE_BACKSLASH = 5

function get_type(char)
  if is_in_arr(char, arr_special) then
    return TYPE_SPECIAL
  elseif is_in_arr(char, arr_string) then
    return TYPE_STRING
  elseif is_in_arr(char, arr_remove) then
    return TYPE_REMOVE
  elseif char == '\\' then
    return TYPE_BACKSLASH
  else
    return TYPE_CHAR
  end
end

function decide_to_keep(c1, c2, c3, c4)
  local t1, t2, t3, t4 = get_type(c1), get_type(c2), get_type(c3), get_type(c4)
  
  if multiline_string_state then
    if c1 == ']' and c2 == ']' then
      multiline_string_state = false
    end
    return true
  elseif string_state then
    if t2 == TYPE_STRING and t1 ~= TYPE_BACKSLASH then
      string_state = false
    end
    return true
  elseif multiline_comment_state then
    if c1 == ']' and c2 == ']' then
      multiline_comment_state = false
    end
  elseif comment_state then
    if c3 == '\n' then
      comment_state = false
    end
    if c3 == '[' and c4 == '[' then
      comment_state = false
      multiline_comment_state = true
    end
  else
    if t2 == TYPE_STRING then
      string_state = true
      return true
    elseif c1 == '[' and c2 == '[' then
      multiline_string_state = true
      return true
    elseif c3 == '-' and c4 == '-' then
      comment_state = true
      post_comment_state = true
    end
    if t2 == TYPE_CHAR or t2 == TYPE_SPECIAL then
      return true
    end -- t1 ; t2 remove type
    
    if post_comment_state and not comment_state and not multiline_comment_state then
      post_comment_state = false
      if t3 == TYPE_CHAR and state == TYPE_CHAR then
        return true
      end
      return false
    end
    
    if t1 == TYPE_REMOVE then
      if t3 == TYPE_CHAR and state == TYPE_CHAR then
        return true
      end -- t1 remove type ; t2 remove type ; t3 special type / remove type / string type
    elseif t1 == TYPE_CHAR then
      if t3 == TYPE_CHAR then
        return true
      end -- t1 char type ; t2 remove type ; t3 special type / remove type / string type
    end -- none - only false previously
  end
  return false
end

function minify(input_path, output_path)
  local input_file = io.open(input_path, 'r')
  local input_str = input_file:read'*a'
  input_file:close()
  if #input_str < 4 then
    local output_file = io.open(output_path, 'w')
    output_file:write(input_str)
    output_file:close()
    return nil
  end
  local input_arr = {}
  for i = 1, #input_str do
    table.insert(input_arr, input_str:sub(i, i))
  end
  
  local output_arr = {}
  for i = 3, #input_arr + 2 do
    local c = {}
    if i < 4 then
      for f = 1, 4 - i do
        table.insert(c, ' ')
      end
      for f = 1, i do
        table.insert(c, input_arr[f])
      end
    elseif i > #input_arr then
      for f = i - 3, #input_arr do
        table.insert(c, input_arr[f])
      end
      for f = #input_arr + 1, i do
        table.insert(c, ' ')
      end
    else
      for k = i - 3, i do
        table.insert(c, input_arr[k])
      end
    end
    
    if decide_to_keep(c[1], c[2], c[3], c[4]) then
      state = get_type(c[2])
      if is_in_arr(c[2], arr_remove) and not string_state then
        table.insert(output_arr, ' ')
      else
        table.insert(output_arr, c[2])
      end
    end
    
    if post_comment_state and not comment_state and not multiline_comment_state and state == TYPE_CHAR and c[1] == ']' and c[2] == ']' and get_type(c[3]) == TYPE_CHAR then
      table.insert(output_arr, ' ')
    end
  end
  
  local output_file = io.open(output_path, 'w')
  output_file:write(table.concat(output_arr))
  output_file:close()
end