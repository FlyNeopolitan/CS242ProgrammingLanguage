local types = require "class.types"

local Object
Object = {
  new = function()
    local inst = {}
    inst.type = Object.type
    return inst
  end,

  constructor = function() end,

  is = function(class, val)
    -- TODO: fill in this function
  end,

  type = function(_) return Object end,

  datatypes = {},

  bases = {}
}

-- check if table contain key
local function containsKey(table, key)
  for k, _ in pairs(table) do 
    if k == key then
      return true
    end
  end
  return false
end


local function class(bases, methods, datatypes)
  -- TODO: 
  local Class = {}
  methods(Class)
  -- inheritance
  setmetatable(Class, {__index = function (t, k)
    for _, base in pairs(bases) do 
      local v = base[k]
      if v then return v end
    end
  end})


  Class.datatypes = datatypes
  setmetatable(Class.datatypes, {__index = function (t, k)
    for _, base in pairs(bases) do 
      local v = bases.datatypes[k]
      if v then return v end
    end
  end
  })

  -- 'new' method
  function Class:new(...) 
    local t = {}
    setmetatable(t, {__newindex = function (t, k, v)
      local type = self.datatypes[k]
      if type then
        if type:is(v) then
          rawset(k, v)
        end
      end
    end})
    setmetatable(t, {__index = self})
    t:constructor(...)
    return t
  end

  -- retun
  return Class
end

return {
  Object = Object,
  class = class,
}
