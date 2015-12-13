----------------
-- Class
----------------
function new(x, ...)
  local t = extend(x)
  if t.init then
    t:init(...)
  end
  return t
end

function extend(x)
  local t = {}
  setmetatable(t, {__index = x, __call = new})
  return t
end

function class() return extend() end


----------------
-- Math
----------------
function math.sign(x) return x > 0 and 1 or x < 0 and -1 or 0 end
function math.round(x) return math.sign(x) >= 0 and math.floor(x + .5) or math.ceil(x - .5) end
function math.clamp(x, l, h) return math.min(math.max(x, l), h) end
function math.lerp(x1, x2, z) return x1 + (x2 - x1) * z end
function math.anglerp(d1, d2, z) return d1 + (math.anglediff(d1, d2) * z) end
function math.dx(len, dir) return len * math.cos(dir) end
function math.dy(len, dir) return len * math.sin(dir) end
function math.distance(x1, y1, x2, y2) return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ .5 end
function math.direction(x1, y1, x2, y2) return math.atan2(y2 - y1, x2 - x1) end
function math.vector(...) return math.distance(...), math.direction(...) end
function math.inside(px, py, rx, ry, rw, rh) return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh end
function math.anglediff(d1, d2) return math.rad((((math.deg(d2) - math.deg(d1) % 360) + 540) % 360) - 180) end


----------------
-- Table
----------------
function table.copy(x)
  local t = type(x)
  if t ~= 'table' then return x end
  local y = {}
  for k, v in next, x, nil do y[k] = table.copy(v) end
  setmetatable(y, getmetatable(x))
  return y
end

function table.has(t, x)
  local f = deep and rawequal
  for _, v in pairs(t) do if f(v, x) then return true end end
  return false
end

function table.each(t, f)
  if not t then return end
  for k, v in pairs(t) do if f(v, k) then break end end
end

function table.with(t, k, ...)
  return table.each(t, f.egoexe(k, ...))
end


----------------
-- Functions
----------------
f = {}
f.egoexe = function(f, ...) local a = {...} return function(x) if x[f] then x[f](x, unpack(a)) end end end
