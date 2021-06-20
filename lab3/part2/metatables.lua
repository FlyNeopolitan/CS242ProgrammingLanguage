-- helper function: determine if keys : list contains the key : val
local function contains(keys, key)
  for _, val in pairs(keys) do 
    if val == key then
      return true
    end
  end
  return false
end


local function guard(t, keys)
  setmetatable(t, {__newindex = function (t, k, v)
    if contains(keys, k) then
      rawset(t, k, v)
    else
      error("insert an missing key")
    end
  end})
end



local t = {d = 0}
guard(t, {"a", "b"})
assert(pcall(function() t.a = 0 end))
assert(pcall(function() t.b = 0 end))
assert(not pcall(function() t.c = 0 end))
assert(pcall(function() t.d = 1 end))


local function multilink(t, parents)
  setmetatable(t, {__index = parents[1]})
  for i = 1, #parents - 1 do 
    setmetatable(parents[i], {__index= parents[i + 1]})
  end
end

local t = {a = 0}
multilink(t, {{x = 1}, {x = 2, y = 2}, {z = 3}})
assert(t.a == 0)
assert(t.x == 1)
assert(t.y == 2)
assert(t.z == 3)
