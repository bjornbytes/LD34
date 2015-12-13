local Hud = class()

Hud.mouseSize = 30

function Hud:init()
  local s = self.mouseSize
  self.mouseCurve = love.math.newBezierCurve(
    s, 1,
    s, -s,
    1, -s
  )

  self.tutorial = true
  self.mx, self.my = 0, 0
end

function Hud:update(dt)
  local sin, cos = math.sin(time * 3), math.cos(time * 3)
  local rate = 5

  if sin > 0 then
    self.my = math.lerp(self.my, 10, math.min(rate * dt, 1))
  else
    self.my = math.lerp(self.my, -10, math.min(rate * dt, 1))
  end

  if cos > 0 then
    self.mx = math.lerp(self.mx, 10, math.min(rate * dt, 1))
  else
    self.mx = math.lerp(self.mx, -10, math.min(rate * dt, 1))
  end

  self.smallFont = love.graphics.newFont('font/pfArmaFive.ttf', 16)
end

function Hud:draw()
  if self.tutorial then
    local y = 200
    self:drawMouse(200 + self.mx, y + self.my, 0, 0)
    self:drawMouse(400, y, math.abs(math.cos(time * 1.5)), math.abs(math.sin(time * 1.5)))

    for x = 600 - 30, 600 + 30, 20 do
      local y = y + 10
      if x == 600 - 30 or x == 600 + 30 then
        y = y + 5
      end

      g.setColor(jellyfish.color)
      g.setLineWidth(4)
      g.line(x, y, x, y + 50)

      g.setLineWidth(2)
      g.setColor(255, 80, 80)
      g.circle('line', x, y + 50, 5, 20)
    end

    g.push()
    g.translate(600 - jellyfish.x, y - 10 - jellyfish.y)
    jellyfish.direction = -math.pi / 2
    jellyfish:draw(true)
    g.pop()

    g.setColor(255, 255, 255)
    g.setFont(self.smallFont)
    g.printf('Steer with mouse', 200 - 80, y + 100, 160, 'center')
    g.printf('Alternate mouse buttons to move', 400 - 80, y + 100, 160, 'center')
    g.printf('Pop bubbles with tips of tentacles', 600 - 80, y + 100, 160, 'center')

    g.printf('Don\'t let bubbles float away!', 0, y + 250, g.getWidth(), 'center')
  end
end

function Hud:mousepressed(x, y, b)
  self.tutorial = false
end

function Hud:drawMouse(x, y, l, r)
  local s = self.mouseSize
  self.mouseCurve:translate(x, y)
  local points = self.mouseCurve:render(5)
  g.setLineWidth(3)

  local leftButtonPoints = table.copy(points)
  local rightButtonPoints = {}

  for i = #points, 1, -2 do
    local x, y = 2 * x - points[i - 1], points[i]
    table.insert(rightButtonPoints, x)
    table.insert(rightButtonPoints, y)
    table.insert(points, x)
    table.insert(points, y)
  end

  -- Woah dude
  for i = 1, #points, 2 do
    table.insert(points, 2 * x - points[i])
    table.insert(points, s * 1.35 + 2 * y - points[i + 1])
  end

  table.insert(leftButtonPoints, x)
  table.insert(leftButtonPoints, y)

  table.insert(rightButtonPoints, x)
  table.insert(rightButtonPoints, y)

  g.setColor(255, 80, 80, 255 * math.clamp(l or 0, 0, 1))
  g.polygon('fill', leftButtonPoints)

  g.setColor(255, 80, 80, 255 * math.clamp(r or 0, 0, 1))
  g.polygon('fill', rightButtonPoints)

  g.setColor(200, 200, 200)
  g.polygon('line', points)

  g.line(x - s, y, x + s, y)
  g.line(x, y - s, x, y)

  g.setLineWidth(1)
  self.mouseCurve:translate(-x, -y)
end

return Hud
