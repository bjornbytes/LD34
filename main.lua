require 'lib/util'
g = love.graphics
setmetatable(_G, { __index = require('lib/cargo').init('/') })

function love.load()
  time = 0
  drawTarget = g.newCanvas(g.getDimensions())
  backTarget = g.newCanvas(g.getDimensions())

  jellyfish = app.jellyfish()
  bubbles = app.bubbles()

  local ratio = g.getWidth() / g.getHeight()
  media.wave:send('strength', {.002 * ratio, .002})
end

function love.update(dt)
  time = time + dt
  jellyfish:update(dt)
  bubbles:update(dt)
  media.wave:send('time', time * 2)
end

function love.draw()
  g.setCanvas(drawTarget)

  g.setColor(35, 35, 50)
  g.rectangle('fill', 0, 0, g.getDimensions())
  bubbles:draw()
  jellyfish:draw()
  g.setColor(255, 255, 255)

  g.setCanvas(backTarget)
  g.setShader(media.wave)
  g.draw(drawTarget)
  g.setShader()

  g.setCanvas()
  g.draw(backTarget)
end
