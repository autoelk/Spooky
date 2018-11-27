require "conf"
HC = require "HC"

function love.load()
  math.randomseed(os.time())
  screenHeight = love.graphics.getHeight()
  screenWidth = love.graphics.getWidth()
  crate = love.graphics.newImage("Assets/crate.png")
  concrete = {}
  for i = 1, 6 do
    concrete[i] = love.graphics.newImage("Assets/concrete" .. i - 1 .. ".png")
  end
  floor = {}
  for i = 1, screenWidth / 30 + 1 do
    floor[i] = {}
    for j = 1, screenHeight / 30 + 1 do
      floor[i][j] = {}
      floor[i][j].tile = concrete[math.random(1, #concrete)]
      floor[i][j].rotation = math.random(1, 4) * math.pi / 2
    end
  end
  lights = {}
  for i = 1, 2 do
    lightCreate(math.random(0, screenWidth), math.random(0, screenHeight))
  end
  crates = {}
  for i = 1, 10 do
    local box = {
      x = 80 * math.random(0, math.floor(screenWidth / 80)),
      y = 80 * math.random(0, math.floor(screenHeight / 80)),
    }
    box.col = HC.rectangle(box.x, box.y, 80, 80)
    box.col.type = "crate"
    table.insert(crates, box)
  end
  player = {
    x = 500,
    y = 500,
    vx = 0,
    vy = 0,
    w = 45,
    h = 45,
    dir = 0,
    speed = 200,
    health = 100,
    sprite = love.graphics.newImage("Assets/player.png")
  }
  player.col = HC.rectangle(player.x, player.y, player.w, player.h)
  --preload shadow collisions
  for i, l in ipairs(lights) do
    for j, c in ipairs(crates) do
      c.shadow = {}
      c.shadow[i] = HC.polygon(offsetsToPolygon(l, c))
      c.shadow[i].on = l.on
      c.shadow[i].type = "shadow"
    end
  end
end

function love.update(dt)
  player.vx, player.vy = 0, 0
  if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
    player.vy = -player.speed * dt
    player.dir = 0
  end
  if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
    player.vx = player.speed * dt
    player.dir = 1
  end
  if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
    player.vy = player.speed * dt
    player.dir = 2
  end
  if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
    player.vx = -player.speed * dt
    player.dir = 3
  end
  if love.keyboard.isDown("escape") then
    love.event.quit()
  end
  player.x = player.x + player.vx
  player.y = player.y + player.vy
  player.col:move(player.vx, player.vy)
  --check for and resolve collisions
  for shape, delta in pairs(HC.collisions(player.col)) do
    print(shape.type)
    if shape.type == "crate" then
      -- print(delta.x .. ", " .. delta.y)
      player.col:move(delta.x, delta.y)
      player.x = player.x + delta.x
      player.y = player.y + delta.y
    elseif shape.type == "shadow" and shape.on then
      --deal damage to the player
      player.health = player.health - 10 * dt
    end
  end
  player.health = player.health + 5 * dt
end

function love.draw()
  love.graphics.setColor(1, 1, 1) -- reset color
  -- draw floor
  for i = 1, screenWidth / 30 + 1 do
    for j = 1, screenHeight / 30 + 1 do
      love.graphics.draw(floor[i][j].tile, i * 30 - 30 / 2, j * 30 - 30 / 2, floor[i][j].rotation, 1, 1, 30 / 2, 30 / 2)
    end
  end
  -- draw lights
  for i, l in ipairs(lights) do
    -- attach light to player
    -- l.x = player.x + 20
    -- l.y = player.y + 20
    love.graphics.circle("fill", l.x, l.y, 10)
  end
  --draw shadow
  for i, l in ipairs(lights) do
    if l.on then
      for j, c in ipairs(crates) do
        love.graphics.setColor(0, 0, 0)
        love.graphics.polygon("fill", offsetsToPolygon(l, c))
        -- local distance = 200
        -- love.graphics.setColor(1, 1, 1)
        -- -- draw lines from light to corners
        -- love.graphics.line(l.x, l.y, c.x + 80 + distance * (c.x + 80 - l.x), c.y + 80 + distance * (c.y + 80 - l.y))
        -- love.graphics.line(l.x, l.y, c.x + 80 + distance * (c.x + 80 - l.x), c.y + distance * (c.y - l.y))
        -- love.graphics.line(l.x, l.y, c.x + distance * (c.x - l.x), c.y + 80 + distance * (c.y + 80 - l.y))
        -- love.graphics.line(l.x, l.y, c.x + distance * (c.x - l.x), c.y + distance * (c.y - l.y))
        -- -- draw circles on selected corners
        -- love.graphics.circle("fill", c.x + topX, c.y + topY, 5)
        -- love.graphics.circle("fill", c.x + botX, c.y + botY, 5)
      end
    end
  end
  love.graphics.setColor(1, 1, 1)
  -- draw crates
  for i, c in ipairs(crates) do
    love.graphics.draw(crate, c.x, c.y)
  end
  -- draw character
  love.graphics.draw(player.sprite, player.x + 45 / 2, player.y + 45 / 2, player.dir * math.pi / 2, 1, 1, 80 / 2, 45 / 2)
  -- draw health overlay
  love.graphics.setColor(1, 0, 0, (100 - player.health) / 100)
  love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
end

function offsetsToPolygon(l, c)
  local top, bot = selectCorners(l, c)
  local topX, topY = cornerNumToOffset(top)
  local botX, botY = cornerNumToOffset(bot)
  local distance = 200
  return c.x + botX,
  c.y + botY,
  c.x + topX,
  c.y + topY,
  c.x + topX + distance * (c.x + topX - l.x),
  c.y + topY + distance * (c.y + topY - l.y),
  c.x + botX + distance * (c.x + botX - l.x),
  c.y + botY + distance * (c.y + botY - l.y)
end

function selectCorners(l, c)
  local slopes = {}
  slopes[1] = findSlope(l.x, l.y, c.x + 80, c.y + 80) -- bottom right
  slopes[2] = findSlope(l.x, l.y, c.x + 80, c.y) -- top right
  slopes[3] = findSlope(l.x, l.y, c.x, c.y + 80) -- bottom left
  slopes[4] = findSlope(l.x, l.y, c.x, c.y) -- top left
  local max, min = -10000000, 10000000
  local top, bot = 0, 0
  for i = 1, 4 do
    if slopes[i] > max then
      max = slopes[i]
      if l.x >= c.x and l.x <= c.x + 80 then
        top = 5 - i
      else
        top = i
      end
    end
    if slopes[i] < min then
      min = slopes[i]
      if l.x >= c.x and l.x <= c.x + 80 then
        bot = 5 - i
      else
        bot = i
      end
    end
  end
  return top, bot
end

function cornerNumToOffset(cornerNum)
  if cornerNum == 1 then
    return 80, 80
  elseif cornerNum == 2 then
    return 80, 0
  elseif cornerNum == 3 then
    return 0, 80
  elseif cornerNum == 4 then
    return 0, 0
  else
    return 160, 160 -- error state
  end
end

function findSlope(x1, y1, x2, y2)
  return (-y2 + y1) / (x2 - x1)
end

function lightCreate(x, y)
  local light = {
    x = x or math.floor(math.random(0, screenWidth / 80)),
    y = y or math.floor(math.random(0, screenHeight / 80)),
    on = true,
  }
  table.insert(lights, light)
  return light
end
