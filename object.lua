local function instantiate(obj, ...)
  local instance = setmetatable({}, obj)
  if instance.new then
    instance:new(...)
  end
  return instance
end

local function object()
  local obj = {}
  obj.__index = obj

  setmetatable(obj, {
    __call = instantiate,
  })

  return obj
end

return object
