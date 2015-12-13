local Bubble = class()

function Bubble:init()
  self.size = 10 + love.math.random() * 10
  self.color = {love.math.random(20), love.math.random(50, 80), love.math.random(80, 150)}
  self.x = love.math.random() * g.getWidth()
  self.y = g.getHeight() + self.size
  self.floatSpeed = 3 + love.math.random(10)
  self.speed = 0
  self.direction = 0
end

function Bubble:update(dt)
  self.y = self.y - self.floatSpeed * dt
  if self.y < -self.size then
    bubbles:remove(self)
  elseif self.y > g.getHeight() + self.size then
    self.y = g.getHeight() + self.size
  end

  if self.x < self.size + 5 then
    self.x = self.size + 5
  elseif self.x > g.getWidth() - self.size - 5 then
    self.x = g.getWidth() - self.size - 5
  end

  if self.speed > 0 then
    self.x = self.x + math.dx(self.speed * dt, self.direction)
    self.y = self.y + math.dy(self.speed * dt, self.direction)
    self.speed = math.lerp(self.speed, 0, math.min(2 * dt, 1))
    if self.speed < 1 then self.speed = 0 end
  end
end

function Bubble:draw()
  g.setLineWidth(3)
  g.setColor(self.color[1], self.color[2], self.color[3], 80)
  g.circle('fill', self.x, self.y, self.size, 40)

  g.setColor(self.color[1], self.color[2], self.color[3], 255)
  g.circle('line', self.x, self.y, self.size, 40)
  g.setLineWidth(1)
end

return Bubble
