local Jellyfish = class()

Jellyfish.color = { 100, 0, 200 }
Jellyfish.thrust = 150
Jellyfish.gravityStrength = 20
Jellyfish.turnFactor = 2
Jellyfish.pushThreshold = 200
Jellyfish.controllerDeadZone = .25

Jellyfish.lineWidth = 4

function Jellyfish:init(input)
  self.input = input
  self.lastPressed = nil
  self.lastTriggerValues = {left = 0, right = 0}
  self.controlScheme = 1

  self.x = 400
  self.y = 450
  self.speed = 0
  self.direction = -math.pi / 2
  self.gravity = 0

  self.tentacleDistance = 1

  self.curves = {}
  self.curves.top = love.math.newBezierCurve(
    40, 30,
    50, 0,
    40, -20,
    20, -30,
    1,  -30
  )

  self.curves.topMirror = love.math.newBezierCurve(
    40, 30,
    50, 0,
    40, -20,
    20, -30,
    1,  -30
  )

  self.curves.bottom = love.math.newBezierCurve(
    -40, 30,
    -30, 26,
    -20, 22,
    -10, 20,
    -1,  20
  )

  self.curves.bottomMirror = love.math.newBezierCurve(
    -40, 30,
    -30, 26,
    -20, 22,
    -10, 20,
    -1,  20
  )

  self.tentacles = {}

  for i = 1, 4 do
    local points = { self.x, self.y }
    for j = 1, 9 do
      table.insert(points, self.x)
      table.insert(points, self.y)
    end

    local curve = love.math.newBezierCurve(points)

    local tentacle = { points = points, curve = curve }
    self.tentacles[i] = tentacle
  end

  self.outerLipStasis = { self.curves.top:getControlPoint(1) }
  self.outerLipOpenX = self.outerLipStasis[1] + 10
  self.outerLipClosedX = self.outerLipStasis[1] - 10
  self.outerLipX = self.outerLipStasis[1]

  self.innerWaterLevel = 0
  self.currentState = 'none'

  self.sounds = {
    open = love.audio.newSource('sound/in.ogg'),
    close = love.audio.newSource('sound/out.ogg')
  }
end

function Jellyfish:update(dt)
  if hud.tutorial then
    self.curves.top:setControlPoint(1, self.outerLipX, self.outerLipStasis[2])
    self.curves.bottom:setControlPoint(1, -self.outerLipX + 1, self.outerLipStasis[2])
    return
  end

  local state = self:getState()
  if state == 'open' then
    if self.currentState ~= 'open' then
      self.currentState = 'open'
      if self.sounds.open:isPlaying() then
        self.sounds.open:rewind()
      else
        self.sounds.open:play()
      end
      local volumeFactor = -math.min(0, self.outerLipX - self.outerLipStasis[1]) / (self.outerLipOpenX - self.outerLipStasis[1])
      self.sounds.open:setVolume(.5 + volumeFactor * .5)
    end

    self.outerLipX = math.lerp(self.outerLipX, self.outerLipOpenX, math.min(6 * dt, 1))

    -- Figure out how open we are and fill ourselves with water
    local openFactor = (math.max(self.outerLipX - self.outerLipStasis[1], 0) / (self.outerLipOpenX - self.outerLipStasis[1]))
    self.innerWaterLevel = openFactor
  elseif state == 'close' then
    if self.currentState ~= 'close' then
      self.currentState = 'close'
      if self.sounds.close:isPlaying() then
        self.sounds.close:rewind()
      else
        self.sounds.close:play()
      end
      self.sounds.close:setVolume(self.innerWaterLevel)

      -- Push bubbles
      if next(bubbles.list) then
        if self.innerWaterLevel > .25 then
          table.each(bubbles.list, function(bubble)
            local dis, dir = math.vector(self.x, self.y, bubble.x, bubble.y)
            local angleDiff = math.abs(math.anglediff(dir, self.direction))
            local angleThreshold = 3 * math.pi / 4
            if dis < 35 and angleDiff < angleThreshold then
              dir = self.direction + math.pi
              angleDiff = 2 * math.pi
            end

            if dis < self.pushThreshold and angleDiff > angleThreshold then
              local magnitude = (1 - (dis / self.pushThreshold))
              bubble.speed = math.max(bubble.speed, self.thrust * magnitude * self.innerWaterLevel)
              bubble.direction = dir
            end
          end)
        end
      end
    end

    self.outerLipX = math.lerp(self.outerLipX, self.outerLipClosedX, math.min(6 * dt, 1))

    if self.innerWaterLevel > 0 then
      self.speed = math.max(self.speed, self.thrust * self.innerWaterLevel)
      self.innerWaterLevel = self.innerWaterLevel - math.min(self.innerWaterLevel, dt)
    end
  else
    self.outerLipX = math.lerp(self.outerLipX, self.outerLipStasis[1], math.min(2 * dt, 1))
    self.innerWaterLevel = self.innerWaterLevel - math.min(self.innerWaterLevel, dt)
    self.currentState = 'none'
  end

  self.curves.top:setControlPoint(1, self.outerLipX, self.outerLipStasis[2])
  self.curves.bottom:setControlPoint(1, -self.outerLipX + 1, self.outerLipStasis[2])

  self:setDirection(dt)
  self.speed = math.max(self.speed - math.min(self.speed * dt, self.thrust * dt), 0)

  if self.speed > 0 then
    local dx, dy = math.dx(self.speed, self.direction), math.dy(self.speed, self.direction)
    self.x = self.x + dx * dt
    self.y = self.y + dy * dt
  end

  if self.speed > self.thrust / 2 then
    self.gravity = math.max(self.gravity - self.gravityStrength * dt, self.gravityStrength)
  else
    self.gravity = math.min(self.gravity + self.gravityStrength * dt, self.gravityStrength)
  end

  if self.gravity > 0 then
    self.y = self.y + self.gravity * dt
  end

  table.each(self.tentacles, function(tentacle, i)
    local points = tentacle.points
    local openFactor = (self.outerLipX - self.outerLipStasis[1]) / (self.outerLipOpenX - self.outerLipStasis[1])

    local x, y
    if i > 2 then
      local factor
      if i == 4 then
        factor = .75 + (.1 * openFactor)
      else
        factor = .25 + (.08 * openFactor)
      end
      x, y = self.curves.bottomMirror:evaluate(factor)
    else
      local curve = self.curves.bottom
      curve:translate(self.x, self.y)
      curve:rotate(self.direction + math.pi / 2, self.x, self.y)
      local factor
      if i == 1 then
        factor = .25 - (.1 * openFactor)
      else
        factor = .75 - (.08 * openFactor)
      end
      x, y = self.curves.bottom:evaluate(factor)
      curve:rotate(-self.direction - math.pi / 2, self.x, self.y)
      curve:translate(-self.x, -self.y)
    end

    points[1] = x
    points[2] = y

    for j = 3, #points, 2 do
      local px, py = points[j - 2], points[j - 1]
      local x, y = points[j], points[j + 1]
      local dis, dir = math.vector(px, py, x, y)
      local maxDis = self.tentacleDistance
      if dis > maxDis then
        points[j] = px + math.dx(maxDis, dir)
        points[j + 1] = py + math.dy(maxDis, dir)
      end

      if self.gravity > 0 then
        points[j + 1] = points[j + 1] + self.gravity * 2 * dt
      end
    end

    for j = 1, #points / 2 do
      tentacle.curve:setControlPoint(j, points[j * 2 - 1], points[j * 2])
    end

    table.each(bubbles.list, function(bubble)
      if math.distance(bubble.x, bubble.y, points[#points - 1], points[#points]) < bubble.size then
        bubbles:remove(bubble, true)
        bubbles:playSound()
        self.tentacleDistance = self.tentacleDistance + .25
      end
    end)
  end)

  local clamp = 35
  self.x = math.clamp(self.x, clamp, g.getWidth() - clamp)
  self.y = math.clamp(self.y, clamp, g.getHeight() - clamp)

  if self.input ~= 'mouse' then
    local left, right = self.input:getGamepadAxis('triggerleft'), self.input:getGamepadAxis('triggerright')
    if self.lastTriggerValues.left < .5 and left > .5 then
      self.lastPressed = 'left'
    elseif self.lastTriggerValues.right < .5 and right > .5 then
      self.lastPressed = 'right'
    end

    self.lastTriggerValues.left = self.input:getGamepadAxis('triggerleft')
    self.lastTriggerValues.right = self.input:getGamepadAxis('triggerright')
  end
end

local function reflect(px, py, x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  local a = (dx ^ 2 - dy ^ 2) / (dx ^ 2 + dy ^ 2)
  local b = 2 * dx * dy / (dx ^ 2 + dy ^ 2)
  local xx = a * (px - x1) + b * (py - y1) + x1
  local yy = b * (px - x1) - a * (py - y1) + y1
  return xx, yy
end

function Jellyfish:draw(onlyBody)
  local points = {}
  local controlPoints = {}
  local alpha = (not onlyBody and hud.dead) and (1 - hud.deadFactor) or 1

  local function drawCurve(curve, mirror)
    curve:translate(self.x, self.y)
    curve:rotate(self.direction + math.pi / 2, self.x, self.y)

    local curvePoints = curve:render()
    for i = 1, #curvePoints do
      table.insert(points, curvePoints[i])
    end

    local dx, dy = math.dx(10, self.direction), math.dy(10, self.direction)
    local x1, y1, x2, y2 = self.x - dx, self.y - dy, self.x + dx, self.y + dy
    local ct = curve:getControlPointCount()
    for i = 1, ct do
      local x, y = curve:getControlPoint(ct - i + 1)
      local rx, ry = reflect(x, y, x1, y1, x2, y2)
      mirror:setControlPoint(i, rx, ry)
    end

    curvePoints = mirror:render()
    for i = 1, #curvePoints do
      table.insert(points, curvePoints[i])
    end

    local roughPoints = curve:render(1)
    for i = 1, #roughPoints, 2 do
      table.insert(controlPoints, roughPoints[i])
      table.insert(controlPoints, roughPoints[i + 1])
    end

    local roughPoints = mirror:render(1)
    for i = 1, #roughPoints, 2 do
      table.insert(controlPoints, roughPoints[i])
      table.insert(controlPoints, roughPoints[i + 1])
    end

    curve:rotate(-self.direction - math.pi / 2, self.x, self.y)
    curve:translate(-self.x, -self.y)
  end

  drawCurve(self.curves.top, self.curves.topMirror)
  drawCurve(self.curves.bottom, self.curves.bottomMirror)

  g.setColor(self.color[1], self.color[2], self.color[3], 80 * alpha)
  local triangles = love.math.triangulate(controlPoints)
  for i = 1, #triangles do
    g.polygon('fill', triangles[i])
  end

  g.setColor(self.color[1], self.color[2], self.color[3], 255 * alpha)
  g.setLineWidth(self.lineWidth)

  table.insert(points, points[1])
  table.insert(points, points[2])
  g.line(points)

  if onlyBody then return end

  g.setLineWidth(4)
  g.setLineJoin('none')
  for i = 1, #self.tentacles do
    local points = self.tentacles[i].curve:render(3)

    g.setColor(self.color[1], self.color[2], self.color[3], 200 * alpha ^ 3)
    g.line(points)

    g.setColor(200, 200, 0, 100 * alpha)
    g.setPointSize(4)
    g.point(points[#points - 1], points[#points])
  end
  g.setLineJoin('miter')
end

function Jellyfish:keypressed(key)
  if key == 'z' then self.lastPressed = 'left'
  elseif key == 'x' then self.lastPressed = 'right' end
end

function Jellyfish:mousepressed(x, y, b)
  if self.input == 'mouse' then
    self.lastPressed = b == 'l' and 'left' or (b == 'r' and 'right' or self.lastPressed)
  end
end

function Jellyfish:gamepadpressed(joystick, button)
  if joystick == self.input then
    if button == 'leftshoulder' then
      self.lastPressed = 'left'
    elseif button == 'rightshoulder' then
      self.lastPressed = 'right'
    elseif button == 'select' then
      self.controlScheme = 1 - self.controlScheme
    end
  end
end

function Jellyfish:getState()
  if self.input == 'mouse' then
    if (love.mouse.isDown('l') or love.keyboard.isDown('z')) and self.lastPressed == 'left' then
      return 'open'
    elseif (love.mouse.isDown('r') or love.keyboard.isDown('x')) and self.lastPressed == 'right' then
      return 'close'
    else
      return 'none'
    end
  else
    if (self.input:isGamepadDown('leftshoulder') or self.input:getGamepadAxis('triggerleft') > .5) and self.lastPressed == 'left' then
      return 'open'
    elseif (self.input:isGamepadDown('rightshoulder') or self.input:getGamepadAxis('triggerright') > .5) and self.lastPressed == 'right' then
      return 'close'
    else
      return 'none'
    end
  end
end

function Jellyfish:setDirection(dt)
  if self.input == 'mouse' then
    self.direction = math.anglerp(self.direction, math.direction(self.x, self.y, love.mouse.getPosition()), math.min(self.turnFactor * dt, 1))
  else
    local function getAxisDirection(axis)
      local x = self.input:getGamepadAxis(axis .. 'x')
      local y = self.input:getGamepadAxis(axis .. 'y')
      local dis, dir = math.vector(0, 0, x, y)
      if self.controlScheme == 1 then
        return dis > self.controllerDeadZone and dir or nil
      else
        if x > self.controllerDeadZone then return self.direction + math.pi / 2
        elseif x < -self.controllerDeadZone then return self.direction - math.pi / 2 end
      end
    end

    local targetDirection = getAxisDirection('left') or getAxisDirection('right')
    if targetDirection then
      self.direction = math.anglerp(self.direction, targetDirection, math.min(self.turnFactor * dt, 1))
    end
  end
end

return Jellyfish
