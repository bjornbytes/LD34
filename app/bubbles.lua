local Bubbles = class()

function Bubbles:init()
  self.list = {}
end

function Bubbles:update(dt)
  table.with(self.list, 'update', dt)

  if love.math.random() < .5 * dt then
    local bubble = app.bubble()
    self.list[bubble] = bubble
  end
end

function Bubbles:draw()
  table.with(self.list, 'draw')
end

function Bubbles:remove(instance)
  self.list[instance] = nil
end

return Bubbles
