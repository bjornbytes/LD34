local Hud = class()

Hud.mouseSize = 30

function Hud:init()
  local s = self.mouseSize
  self.mouseCurve = love.math.newBezierCurve(
    s, 1,
    s, -s,
    1, -s
  )
end

function Hud:drawMouse(x, y, l, r)
  local s = self.mouseSize
  self.mouseCurve:translate(x, y)
  local points = self.mouseCurve:render()
  g.setLineWidth(3)
  g.setColor(255, 255, 255)

  for i = #points, 1, -2 do
    table.insert(points, 2 * x - points[i - 1])
    table.insert(points, points[i])
  end

  -- Woah dude
  for i = 1, #points, 2 do
    table.insert(points, 2 * x - points[i])
    table.insert(points, s * 1.35 + 2 * y - points[i + 1])
  end

  g.polygon('line', points)

  g.line(x - s, y, x + s, y)
  g.line(x, y - s, x, y)

  g.setLineWidth(1)
  self.mouseCurve:translate(-x, -y)
end

return Hud
