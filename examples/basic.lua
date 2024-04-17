
local str = ' text -- text '
local multiline_str = [[text
    -- owo  text    text    ]] -- this is multiline string
  
 cooler_string = [===[
   text
       text -- owo
             --[[ owo]]
  ]===]
 
  local obj = {
    
    1,
    4,
    2,
    v = {1, 5, 7},
    {9, 9},
    ' text     '
    
  }

--[[
  comment
]]

local x, y = 9, obj [ 2 ]
local--[[this comment is strange, but whatever, it will be replaced with space if necessary]]lenght = x ^ 2 + y ^ 2

function 
     obj 
       : 
    func 
      ()
  return
       0
     end