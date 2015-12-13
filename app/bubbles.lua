local Bubbles = class()
Bubbles.soundCount = 4

function Bubbles:init()
  self.list = {}

  self.particleCanvas = g.newCanvas(32, 32)
  g.setCanvas(self.particleCanvas)
  self.particleCanvas:clear(255, 255, 255, 0)
  g.setPointSize(31)
  g.setColor(255, 255, 255)
  g.point(16, 16)
  g.setCanvas()

  self.particles = g.newParticleSystem(self.particleCanvas, 256)
  self.particles:setOffset(32, 32)
  self.particles:setParticleLifetime(.3, .5)
  self.particles:setSpeed(100, 400)
  self.particles:setLinearDamping(4, 8)
  self.particles:setSpread(2 * math.pi)
  self.particles:setSizes(.4, 0)
  self.particles:setSizeVariation(.5)

  self.soundIndex = 1
  self.sounds = {}
  for i = 1, self.soundCount do
    self.sounds[i] = love.audio.newSource('sound/bubble.ogg')
  end

  for i = 1, 10 do
    local bubble = app.bubble()
    self.list[bubble] = bubble
    bubble.direction = -math.pi / 2
    bubble.speed = love.math.random(100, 250)
  end
end

function Bubbles:update(dt)
  if hud.tutorial then return end

  self.particles:update(dt)
  table.with(self.list, 'update', dt)

  if love.math.random() < .35 * dt then
    local bubble = app.bubble()
    self.list[bubble] = bubble
  end
end

function Bubbles:draw()
  g.setColor(255, 255, 255)
  g.draw(self.particles)
  table.with(self.list, 'draw')
end

function Bubbles:remove(instance)
  self.particles:setPosition(instance.x, instance.y)
  for i = 1, 3 do
    local c = instance.color
    self.particles:setColors(c[1], c[2], c[3], 255, c[1], c[2], c[3], 0)
    self.particles:emit(10)
  end
  self.list[instance] = nil
end

function Bubbles:playSound()
  local sound = self.sounds[self.soundIndex]
  if sound:isPlaying() then
    sound:rewind()
  else
    sound:play()
  end
  sound:setPitch(.9 + love.math.random() * .2)
  sound:setVolume(.3)

  self.soundIndex = self.soundIndex + 1
  if self.soundIndex > #self.sounds then
    self.soundIndex = 1
  end
end

return Bubbles
