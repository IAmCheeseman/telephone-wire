local mathf = {}

function mathf.frac(x)
  return x - math.floor(x)
end

function mathf.lerp(a, b, t)
  return (b - a) * t + a
end

function mathf.deltaLerp(a, b, t)
  return mathf.lerp(b, a, 0.5^(love.timer.getDelta() * t))
end

function mathf.angleDiff(a, b)
  local diff = (b - a) % (math.pi * 2)
  return (2 * diff) % (math.pi * 2) - diff
end

function mathf.lerpAngle(a, b, t)
  return a + mathf.angleDiff(a, b) * (1 - 0.5^t)
end

function mathf.wrap(a, min, max)
  return (a - min) % (max - min) + min
end

function mathf.clamp(a, min, max)
  return math.min(math.max(a, min), max)
end

function mathf.map(a, min, max)
  return a * (max - min) + min
end

function mathf.sign(a)
  return a < 0 and -1 or 1
end

function mathf.snapped(a, step)
  if step ~= 0 then
    return math.floor(a / step + 0.5) * step
  end
  return step
end

function mathf.frandom(a, b)
  return a + love.math.random() * (b - a)
end

function mathf.length(x, y)
  return math.sqrt(x^2 + y^2)
end

function mathf.normalize(x, y)
  local l = mathf.length(x, y)
  if l == 0 then
    return 0, 0
  end
  return x / l, y / l
end

function mathf.dot(x, y, xx, yy)
  return x * xx + y * yy
end

function mathf.directionTo(x, y, xx, yy)
  return mathf.normalize(xx - x, yy - y)
end

function mathf.distanceBetween(x, y, xx, yy)
  return mathf.length(x - xx, y - yy)
end

function mathf.squareDistanceBetween(x, y, xx, yy)
  return (x-xx)^2 + (y-yy)^2
end

function mathf.angle(x, y)
  local angle = math.atan2(y, x)
  if angle < 0 then
    angle = angle + math.pi * 2
  end
  return angle
end

function mathf.angleBetween(x, y, xx, yy)
  return mathf.angle(xx - x, yy - y)
end

function mathf.rotated(x, y, r)
  local newRot = mathf.angle(x, y) + r
  local l = mathf.length(x, y)

  local nx = math.cos(newRot) * l
  local ny = math.sin(newRot) * l

  return nx, ny
end

-- amp, 0-1
-- freq, any
-- octaves, any
-- pers 0-1
-- lacun 0-100
function mathf.noise(x, y, amp, freq, octaves, pers, lacun, seed)
  local value = 0;

  for i=1, octaves do
    value = value + amp * love.math.noise(x * freq + i * 64, y * freq + i * 64, seed)
    amp = amp * pers
    freq = freq * lacun
  end

  return value
end

return mathf
