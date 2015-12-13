local Jellyfish = class()

Jellyfish.color = { 100, 0, 200 }
Jellyfish.thrust = 150
Jellyfish.gravityStrength = 20
Jellyfish.turnFactor = 2
Jellyfish.pushThreshold = 200

Jellyfish.lineWidth = 4

function Jellyfish:init()
  self.x = 400
  self.y = 500

  self.tentacleDistance = 1 --25

  self.speed = 0
  self.direction = 0

  self.gravity = 0

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
    local points = { 0, 0 }
    for i = 1, 9 do
      table.insert(points, 0)
      table.insert(points, 5 * i)
    end

    local curve = love.math.newBezierCurve(points)

    local tentacle = { points = points, curve = curve }
    self.tentacles[i] = tentacle
  end

  self.outerLipStasis = { self.curves.top:getControlPoint(1) }
  self.outerLipOpenX = self.outerLipStasis[1] + 10
  self.outerLipClosedX = self.outerLipStasis[1] - 10
  self.outerLipX = self.outerLipStasis[1]

  self.eyeOffsetX = 0
  self.eyeOffsetY = 0

  self.innerWaterLevel = 0
  self.currentState = 'none'

  self.sounds = {
    open = love.audio.newSource('sound/in.ogg'),
    close = love.audio.newSource('sound/out.ogg')
  }
end

function Jellyfish:update(dt)
  if love.mouse.isDown('l') then
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

    self.outerLipX = math.lerp(self.outerLipX, self.outerLipOpenX, 6 * dt)

    -- Figure out how open we are and fill ourselves with water
    local openFactor = (math.max(self.outerLipX - self.outerLipStasis[1], 0) / (self.outerLipOpenX - self.outerLipStasis[1]))
    self.innerWaterLevel = openFactor
  elseif love.mouse.isDown('r') then
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

    self.outerLipX = math.lerp(self.outerLipX, self.outerLipClosedX, 6 * dt)

    if self.innerWaterLevel > 0 then
      --local closedFactor = math.max(self.outerLipStasis[1] - self.outerLipX, 0) / (self.outerLipStasis[1] - self.outerLipClosedX)
      self.speed = math.max(self.speed, self.thrust * self.innerWaterLevel)
      self.innerWaterLevel = self.innerWaterLevel - math.min(self.innerWaterLevel, dt)
    end
  else
    self.outerLipX = math.lerp(self.outerLipX, self.outerLipStasis[1], 2 * dt)
    self.innerWaterLevel = self.innerWaterLevel - math.min(self.innerWaterLevel, dt)
    self.currentState = 'none'
  end

  local x, y = unpack(self.outerLipStasis)
  self.curves.top:setControlPoint(1, self.outerLipX, y)
  self.curves.bottom:setControlPoint(1, -self.outerLipX + 1, y)

  self.direction = math.anglerp(self.direction, math.direction(self.x, self.y, love.mouse.getPosition()), self.turnFactor * dt)
  self.speed = self.speed - math.min(self.speed * dt, self.thrust * dt)
  if self.speed < 0 then self.speed = 0 end

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
        bubbles:remove(bubble)
        bubbles:playSound()
        self.tentacleDistance = self.tentacleDistance + .25
      end
    end)
  end)

  if next(bubbles.list) then
    local nearestBubble, mindis = nil, math.huge
    table.each(bubbles.list, function(bubble)
      local dis = math.distance(bubble.x, bubble.y, self.x, self.y)
      if dis < mindis then
        nearestBubble, mindis = bubble, dis
      end
    end)

    if nearestBubble then
      local dir = math.direction(self.x, self.y, nearestBubble.x, nearestBubble.y)
      self.eyeOffsetX = math.lerp(self.eyeOffsetX, math.dx(3, dir), 4 * dt)
      self.eyeOffsetY = math.lerp(self.eyeOffsetY, math.dy(3, dir), 4 * dt)
    end

  end

  local clamp = 35
  if self.x < clamp then self.x = clamp end
  if self.x > g.getWidth() - clamp then self.x = g.getWidth() - clamp end
  if self.y < clamp then self.y = clamp end
  if self.y > g.getHeight() - clamp then self.y = g.getHeight() - clamp end
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

function Jellyfish:draw()
  local points = {}
  local controlPoints = {}
  local debugPoints = {}

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
      table.insert(debugPoints, {x, y})
      table.insert(debugPoints, {rx, ry})
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

  g.setColor(self.color[1], self.color[2], self.color[3], 80)
  local triangles = love.math.triangulate(controlPoints)
  for i = 1, #triangles do
    g.polygon('fill', triangles[i])
  end

  g.setColor(self.color)
  g.setLineWidth(self.lineWidth)

  table.insert(points, points[1])
  table.insert(points, points[2])
  g.line(points)

  if love.keyboard.isDown('`') then
    g.setColor(255, 255, 255, 100)
    g.setPointSize(4)
    for i = 1, #debugPoints do
      g.point(unpack(debugPoints[i]))
    end

    g.setColor(255, 255, 255)
    g.print(self.innerWaterLevel .. '\n' .. self.tentacleDistance)
  end

  g.setLineWidth(4)
  g.setLineJoin('none')
  for i = 1, #self.tentacles do
    local tentacle = self.tentacles[i]
    local points = tentacle.curve:render(3)

    g.setColor(self.color[1], self.color[2], self.color[3], 200)
    g.line(points)

    g.setColor(200, 200, 0, 100)
    g.setPointSize(4)
    g.point(points[#points - 1], points[#points])
    g.setPointSize(1)
  end
  g.setLineJoin('miter')

  -- Googly eyes doe
  --[[g.setLineWidth(7)
  g.setColor(255, 255, 255, 100)
  g.circle('line', self.x + math.dx(20, self.direction - math.pi / 2), self.y + math.dy(20, self.direction - math.pi / 2), 4, 30)
  g.circle('line', self.x + math.dx(20, self.direction + math.pi / 2), self.y + math.dy(20, self.direction + math.pi / 2), 4, 30)

  g.setColor(0, 0, 0)
  g.setPointSize(6)
  g.point(self.x + self.eyeOffsetX + math.dx(20, self.direction - math.pi / 2), self.y + self.eyeOffsetY + math.dy(20, self.direction - math.pi / 2))
  g.point(self.x + self.eyeOffsetX + math.dx(20, self.direction + math.pi / 2), self.y + self.eyeOffsetY + math.dy(20, self.direction + math.pi / 2))
  g.setPointSize(1)]]
end

return Jellyfish
