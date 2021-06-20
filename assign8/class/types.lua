local Any = {}
function Any:is() return true end

local String = {}
function String:is(v) return type(v) == "string" end

local Number = {}
function Number:is(v) return type(v) == "number" end

local Function = {}
function Function:is(v) return type(v) == "function" end

local Boolean = {}
function Boolean:is(v) return type(v) == "boolean" end

local Nil = {}
function Nil:is(v) return type(v) == "nil" end

local List = function(t)
  local current = {}
  function current:is(v)
    if not (type(v) == "table") then
      return false
    end
    for _, val in pairs(v) do
      if not t:is(val) then
        return false 
      end
    end
    return true
  end
  return current
end


local Table = function(kType, vType)
  local current = {}
  function current:is(v)
    if not (type(v) == "table") then
      return false
    end
    for key, val in pairs(v) do
      if not (kType:is(key) and vType:is(val)) then
        return false 
      end
    end
    return true
  end
  return current
end

return {
  Any = Any,
  String = String,
  Number = Number,
  Function = Function,
  Boolean = Boolean,
  Nil = Nil,
  List = List,
  Table = Table,
}
