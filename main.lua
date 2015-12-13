require 'lib/util'
g = love.graphics
setmetatable(_G, { __index = require('lib/cargo').init('/') })

waveStrength = .002
waveSpeed = 4

function love.load()
  time = 0
  drawTarget = g.newCanvas(g.getDimensions())
  backTarget = g.newCanvas(g.getDimensions())

  soundscape = love.audio.newSource('sound/background.ogg')
  soundscape:setVolume(.6)
  soundscape:setLooping(true)
  soundscape:play()

  local joysticks = love.joystick.getJoysticks()
  local inputSource = #joysticks > 0 and joysticks[1] or 'mouse'
  jellyfish = app.jellyfish(inputSource)
  bubbles = app.bubbles()

  local ratio = g.getWidth() / g.getHeight()
  media.wave:send('strength', {waveStrength * ratio, waveStrength})
end

function love.update(dt)
  time = time + dt
  jellyfish:update(dt)
  bubbles:update(dt)
  media.wave:send('time', time * waveSpeed)
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

function love.mousepressed(x, y, b)
  jellyfish:mousepressed(x, y, b)
end

function love.gamepadpressed(joystick, button)
  jellyfish:gamepadpressed(joystick, button)
end
