local Bubble = class()

function Bubble:init()
  self.size = 10 + love.math.random() * 10
  self.color = {love.math.random(20), love.math.random(100, 200), love.math.random(100, 255)}
  self.x = love.math.random() * g.getWidth()
  self.y = g.getHeight() + self.size
  self.speed = 3 + love.math.random(10)
end

function Bubble:update(dt)
  self.y = self.y - self.speed * dt
  if self.y < -self.size then
    bubbles:remove(self)
  end
end

function Bubble:draw()
  g.setLineWidth(3)
  g.setColor(self.color[1], self.color[2], self.color[3], 40)
  g.circle('fill', self.x, self.y, self.size, 40)

  g.setColor(self.color[1], self.color[2], self.color[3], 80)
  g.circle('line', self.x, self.y, self.size, 40)
  g.setLineWidth(1)
end

return Bubble
