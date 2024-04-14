local object = require("object")
local viewport = require("viewport")
local mathf = require("mathf")

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")
viewport.new("default", 320, 180, true)
viewport.setBgColor("default", 0, 1, 1)

local ticktimer = 0
local tickrate = 1 / 30

local gravityx = 0
local gravityy = 98.1

local VerletParticle = object()

function VerletParticle:new(x, y)
  self.x = x
  self.y = y

  self.prevx = x
  self.prevy = y

  self.accelx = 0
  self.accely = 0

  self.isstatic = false
end

function VerletParticle:update()
  if self.isstatic then
    return
  end

  local cx = self.x
  local cy = self.y

  self.accelx = self.accelx + gravityx
  self.accely = self.accely + gravityy

  self.x = self.x * 2 - self.prevx + self.accelx * tickrate^2
  self.y = self.y * 2 - self.prevy + self.accely * tickrate^2

  self.accelx = 0
  self.accely = 0

  self.prevx = cx
  self.prevy = cy
end

local VerletRope = object()

function VerletRope:new(startx, starty, endx, endy, segdist)
  self.particles = {}
  self.segdist = segdist
  local dist = math.sqrt((endx-startx)^2 + (endy-starty)^2)
  local pcount = math.floor(dist / segdist)

  for i=0, pcount do
    local p = i / pcount
    local x = mathf.lerp(startx, endx, p)
    local y = mathf.lerp(starty, endy, p)

    local particle = VerletParticle(x, y)
    particle.isstatic = i == 0 or i == pcount

    table.insert(self.particles, particle)
  end
end

function VerletRope:update()
  for _, p in ipairs(self.particles) do
    p:update()
  end

  -- Apply constraints
  for _=1, 50 do
    for i=1, #self.particles-1 do
      local f = self.particles[i]
      local s = self.particles[i+1]

      local dist = mathf.distanceBetween(f.x, f.y, s.x, s.y)
      local error = dist - self.segdist
      local dirx, diry = mathf.directionTo(f.x, f.y, s.x, s.y)

      if f.isstatic and not s.isstatic then
        s.x = s.x - dirx * error
        s.y = s.y - diry * error
      elseif not f.isstatic and s.isstatic then
        f.x = f.x + dirx * error
        f.y = f.y + diry * error
      elseif not f.isstatic and not s.isstatic then
        f.x = f.x + 0.5 * dirx * error
        f.y = f.y + 0.5 * diry * error
        s.x = s.x - 0.5 * dirx * error
        s.y = s.y - 0.5 * diry * error
      end
    end
  end
end

local TelephoneWire = object()

function TelephoneWire:new(startx, starty, endx, endy)
  self.startx = startx
  self.starty = starty
  self.endx = endx
  self.endy = endy

  self.lwire = VerletRope(startx + 4, starty, endx - 4, endy - 3, 8)
  self.rwire = VerletRope(startx - 4, starty + 3, endx + 4, endy, 8)

  self.pole = love.graphics.newImage("pole.png")

  -- preprocess the wires for 15 seconds
  for _=1, 30 * 15 do
    self:update()
  end
end

function TelephoneWire:update()
  self.lwire:update()
  self.rwire:update()
end

function TelephoneWire:drawWire(wire)
  love.graphics.setColor(0, 0, 0)
  for i=1, #wire.particles-1 do
    local f = wire.particles[i]
    local s = wire.particles[i+1]
    love.graphics.line(f.x, f.y, s.x, s.y)
  end
end

function TelephoneWire:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.pole, self.startx, self.starty, 0, -1, 1, 8, 8)
  love.graphics.draw(self.pole, self.endx, self.endy, 0, 1, 1, 8, 8)

  self:drawWire(self.lwire)
  self:drawWire(self.rwire)
end

local hearts = {}

local Heart = object()

function Heart:new(x, y)
  self.heart = love.graphics.newImage("heart.png")

  self.x = x
  self.y = y
  self.dir = love.math.random() * math.pi / 4 - math.pi / 8
  self.dir = self.dir - math.pi / 2
  self.lt = math.floor(love.math.random(30, 60))
  self.mlt = self.lt
end

function Heart:update()
  self.x = self.x + math.cos(self.dir)
  self.y = self.y + math.sin(self.dir)

  self.lt = self.lt - 1

  if self.lt <= 0 then
    hearts[self] = nil
  end
end

function Heart:draw()
  local scale = self.lt / self.mlt
  love.graphics.draw(self.heart, self.x, self.y, 0, scale, scale, 3, 3)
end

local Bird = object()

function Bird:new(twire)
  self.bird = love.graphics.newImage("bird.png")

  self.twire = twire

  self:selectTarget()
  self.isperched = true
  self.changepost = 0

  self.xframes = 3
  self.framewidth = self.bird:getWidth() / self.xframes
  self.frameheight = self.bird:getHeight()
  self.animt = 0
  self.fps = 30 / 10
  self.frame = 0

  self.shader = love.graphics.newShader("palette.fs")
  self.rc = {love.math.random(), love.math.random(), love.math.random(), 1}
  self.bc = {love.math.random(), love.math.random(), love.math.random(), 1}
  self.gc = {love.math.random(), love.math.random(), love.math.random(), 1}

  self.x = self.target.x
  self.y = self.target.y

  self.lovet = 1
end

local taken = {}

function Bird:selectTarget()
  local wire
  if love.math.random() < 0.5 then
    wire = self.twire.lwire.particles
  else
    wire = self.twire.rwire.particles
  end

  local targetindex = math.floor(love.math.random(1, #wire))
  local tries = 0
  while taken[targetindex] do
    targetindex = targetindex + 1
    if targetindex > #wire then
      targetindex = 1
    end

    tries = tries + 1
    if tries > 100 then
      break
    end
  end

  taken[self.targetindex or 0] = nil
  taken[targetindex] = {
    wire = wire,
    by = self,
  }
  self.prevtarget = self.target
  self.target = wire[targetindex]
  self.targetindex = targetindex
end

function Bird:animate()
  self.animt = self.animt + 1

  if self.animt > self.fps then
    self.frame = self.frame + 1
    if self.frame >= self.xframes then
      self.frame = 0
    end
    self.animt = self.animt - self.fps
  end
end

-- If they love eachother and are flapping their wings, they should affect the wire
function Bird:flapWingForce()
  if self.frame == 1 then
    self.target.accely = self.target.accely + 1500
  elseif self.frame == 2 then
    self.target.accely = self.target.accely + 500
  else
    self.target.accely = self.target.accely + 1000
  end
end

function Bird:update()
  if not self.target then
    self:selectTarget()
  end

  local t = self.target
  if not self.isperched then
    local pt = self.prevtarget
    local percentage = 1 - self.changet / self.maxchanget
    self.x = mathf.lerp(pt.x, t.x, percentage)
    self.y = mathf.lerp(pt.y, t.y, percentage) - math.sin(percentage * math.pi) * self.flightheight

    self.changet = self.changet - 1
    if self.changet <= 0 then
      self.isperched = true
      self.changepost = (love.math.random()^2) * 300
      t.accely = t.accely + 2500
    end

    self.scalex = self.target.x < self.x and -1 or 1

    self:animate()
  else

    self.x = t.x
    self.y = t.y

    self.changepost = self.changepost - 1
    if self.changepost <= 0 then
      t.accely = t.accely - 1200

      self:selectTarget()
      local nt = self.target
      self.changet = mathf.distanceBetween(self.x, self.y, nt.x, nt.y) * 0.75
      self.maxchanget = self.changet
      self.flightheight = self.changet * 0.5
      self.isperched = false
    end

    self.lovet = self.lovet - 1
    local next = taken[self.targetindex + 1]

    if next and next.by.isperched then
      if self.lovet <= 0 then
        local nextparticle = next.wire[self.targetindex + 1]
        local x = (t.x + nextparticle.x) / 2
        local y = (t.y + nextparticle.y) / 2
        hearts[Heart(x, y)] = true

        self.lovet = love.math.random(10, 30)
      end

      self:animate()
      self.scalex = 1
      self:flapWingForce()
    else
      local last = taken[self.targetindex - 1]
      if last and last.by.isperched then
        self:animate()
        self.scalex = -1
        self:flapWingForce()
      else
        self.frame = 0
        self.target.accely = self.target.accely + 1000
      end
    end

  end
end

function Bird:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.setShader(self.shader)
  self.shader:send("rc", self.rc)
  self.shader:send("gc", self.gc)
  self.shader:send("bc", self.bc)

  local quad = love.graphics.newQuad(
    self.framewidth * self.frame, 0,
    self.framewidth, self.frameheight,
    self.bird:getDimensions())
  love.graphics.draw(self.bird, quad, self.x, self.y, 0, self.scalex, 1, 3, 6)

  love.graphics.setShader(nil)

end

local wire = TelephoneWire(24, 25, 320 - 25, 120)
local birds = {}
local time = 0
local bg = love.graphics.newImage("bg.png")

for _=1, 6 do
  table.insert(birds, Bird(wire))
end

function love.update(dt)
  ticktimer = ticktimer + dt

  if ticktimer >= tickrate then
    time = time + 1
    wire:update()

    for _, bird in ipairs(birds) do
      bird:update()
    end

    for heart, _ in pairs(hearts) do
      heart:update()
    end

    ticktimer = ticktimer - tickrate
  end
end

function love.draw()
  viewport.drawTo("default", function()
    love.graphics.draw(bg, 0, 0)

    wire:draw()

    for _, bird in ipairs(birds) do
      bird:draw()
    end

    for heart, _ in pairs(hearts) do
      heart:draw()
    end
  end)

  love.graphics.setColor(1, 1, 1)
  viewport.draw("default")
end

