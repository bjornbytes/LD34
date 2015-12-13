local Bubbles = class()
Bubbles.soundCount = 4

function Bubbles:init()
  self.list = {}

  self.soundIndex = 1
  self.sounds = {}
  for i = 1, self.soundCount do
    self.sounds[i] = love.audio.newSource('sound/bubble.ogg')
  end
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
