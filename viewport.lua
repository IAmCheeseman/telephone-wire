local cwd = (...):gsub("%.viewport$", "")

local viewport = {}

local default = ""
local instances = {}

local function frac(x)
  return x - math.floor(x)
end

local function getViewport(name)
  local v = instances[name] or instances[default]
  if not v then
    error("Cannot get viewport.")
  end
  return v
end

local function getViewportTransform(name)
  local v = getViewport(name)
  local sw, sh = v.width, v.height
  local ww, wh = love.graphics.getDimensions()

  local scale = math.min(ww / sw, wh / sh)
  local x = (ww - sw * scale) / 2
  local y = (wh - sh * scale) / 2

  return x, y, scale
end

function viewport.new(name, width, height, isDefault)
  instances[name] = {
    width = width,
    height = height,
    camerax = 0,
    cameray = 0,
    bgColor = {0, 0, 0, 1},
    canvas = love.graphics.newCanvas(width + 1, height + 1),
  }

  if isDefault then
    default = name
  end
end

function viewport.draw(name)
  local v = getViewport(name)
  local x, y, scale = getViewportTransform(name)

  local ox, oy = frac(v.camerax), frac(v.cameray)
  local quad = love.graphics.newQuad(ox, oy, v.width, v.height, v.canvas:getDimensions())

  love.graphics.draw(v.canvas, quad, x, y, 0, scale)
end

function viewport.drawTo(name, f)
  local v = getViewport(name)

  love.graphics.push()
  love.graphics.setCanvas(v.canvas)
  love.graphics.translate(-math.floor(v.camerax), -math.floor(v.cameray))

  love.graphics.clear(unpack(v.bgColor))

  f()

  love.graphics.setCanvas()
  love.graphics.pop()
end

function viewport.getSize(name)
  local v = getViewport(name)
  return v.width, v.height
end

function viewport.getBgColor(name)
  return unpack(getViewport(name).bgColor)
end

function viewport.setBgColor(name, r, g, b, a)
  a = a or 1
  getViewport(name).bgColor = {r, g, b, a}
end

function viewport.getCameraPos(name)
  local v = getViewport(name)
  return v.camerax, v.cameray
end

function viewport.setCameraPos(name, x, y)
  local v = getViewport(name)
  v.camerax = x
  v.cameray = y
end

function viewport.getMousePosition(name)
  local v = getViewport(name)
  local x, y, scale = getViewportTransform(name)
  local mx, my = love.mouse.getPosition()
  mx = mx - x
  my = my - y

  mx = math.floor(v.camerax + mx / scale)
  my = math.floor(v.cameray + my / scale)
  return mx, my
end

return viewport
