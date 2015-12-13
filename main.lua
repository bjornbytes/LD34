require 'lib/util'
g = love.graphics
setmetatable(_G, { __index = require('lib/cargo').init('/') })

waveStrength = .002
waveSpeed = 4

firstGame = true

function love.load()
  time = 0
  lives = 1
  maxLives = lives

  drawTarget = g.newCanvas(g.getDimensions())
  backTarget = g.newCanvas(g.getDimensions())

  soundscape = love.audio.newSource('sound/background.ogg')
  soundscape:setVolume(.7)
  soundscape:setLooping(true)
  soundscape:play()

  local joysticks = love.joystick.getJoysticks()
  local inputSource = #joysticks > 0 and joysticks[1] or 'mouse'
  bubbles = app.bubbles()
  jellyfish = app.jellyfish(inputSource)
  hud = app.hud()

  local ratio = g.getWidth() / g.getHeight()
  media.wave:send('strength', {waveStrength * ratio, waveStrength})

  firstGame = false
end

function love.update(dt)
  time = time + dt
  if not hud.dead then
    jellyfish:update(dt)
    bubbles:update(dt)
  end
  hud:update(dt)
  media.wave:send('time', time * waveSpeed)
end

function love.draw()
  g.setCanvas(drawTarget)

  g.setColor(35, 35, 50)
  g.rectangle('fill', 0, 0, g.getDimensions())
  if not hud.tutorial then
    bubbles:draw()
    if not hud.dead then
      jellyfish:draw()
    end
  end
  g.setColor(255, 255, 255)

  g.setCanvas(backTarget)
  g.setShader(media.wave)
  g.draw(drawTarget)
  g.setShader()

  g.setCanvas()
  g.draw(backTarget)

  hud:draw()
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end

function love.mousepressed(x, y, b)
  hud:mousepressed(x, y, b)
  jellyfish:mousepressed(x, y, b)
end

function love.gamepadpressed(joystick, button)
  jellyfish:gamepadpressed(joystick, button)
end
