require "conf"
require "crate"
require "light"
local bump = require "bump"
local cols_len = 0 -- how many collisions are happening
local world = bump.newWorld() -- World creation

function love.load()
  math.randomseed(os.time())
  screenHeight = love.graphics.getHeight()
  screenWidth = love.graphics.getWidth()
  crate = love.graphics.newImage("Assets/crate.png")
  concrete = {}
  for i = 1, 6 do
    concrete[i] = love.graphics.newImage("Assets/concrete" .. i - 1 .. ".png")
  end
  level = {}
  for i = 1, screenWidth / 30 + 1 do
    level[i] = {}
    for j = 1, screenHeight / 30 + 1 do
      level[i][j] = {}
      level[i][j].tile = concrete[math.random(1, #concrete)]
      level[i][j].rotation = math.random(1, 4) * math.pi / 2
    end
  end
  lights = {}
  for i = 1, 2 do
    Light:Create(math.random(0, screenWidth), math.random(0, screenHeight))
  end
  crates = {}
  for i = 1, 5 do
    Crate:Create(math.random(0, screenWidth / 80 - 1), math.random(0, screenHeight / 80 - 1))
  end
  for i = 1, #crates do
    world:add("crate" .. i, crates[i].x, crates[i].y, 80, 80)
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
    sprite = love.graphics.newImage("Assets/player.png")
  }
  world:add(player, player.x, player.y, player.w, player.h)
end

function love.update(dt)
  cols_len = 0
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

  if dx ~= 0 or dy ~= 0 then
    local cols
    player.x, player.y, cols, cols_len = world:move(player, player.x + player.vx, player.y + player.vy)
  end
end

function love.draw()
  love.graphics.setColor(1, 1, 1) -- reset color
  love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
  -- draw floor
  for i = 1, screenWidth / 30 + 1 do
    for j = 1, screenHeight / 30 + 1 do
      love.graphics.draw(level[i][j].tile, i * 30 - 30 / 2, j * 30 - 30 / 2, level[i][j].rotation, 1, 1, 30 / 2, 30 / 2)
    end
  end
  -- draw lights
  for i, l in ipairs(lights) do
    -- attach light to player
    -- l.x = player.x + 40
    -- l.y = player.y + 20
    love.graphics.circle("fill", l.x, l.y, 10)
  end
  --draw light & shadow
  for i, l in ipairs(lights) do
    for j, c in ipairs(crates) do
      local topX, topY, botX, botY = selectCorners(l, c)
      love.graphics.setColor(0, 0, 0, 0.85)
      local distance = 500
      love.graphics.polygon(
        "fill",
        c.x + botX,
        c.y + botY,
        c.x + topX,
        c.y + topY,
        c.x + topX + distance * (c.x + topX - l.x),
        c.y + topY + distance * (c.y + topY - l.y),
        c.x + botX + distance * (c.x + botX - l.x),
        c.y + botY + distance * (c.y + botY - l.y)
      )
      -- draw lines from light to corners
      -- love.graphics.line(l.x, l.y, c.x + 80 + 5 * (c.x + 80 - l.x), c.y + 80 + 5 * (c.y + 80 - l.y))
      -- love.graphics.line(l.x, l.y, c.x + 80 + 5 * (c.x + 80 - l.x), c.y + 5 * (c.y - l.y))
      -- love.graphics.line(l.x, l.y, c.x + 5 * (c.x - l.x), c.y + 80 + 5 * (c.y + 80 - l.y))
      -- love.graphics.line(l.x, l.y, c.x + 5 * (c.x - l.x), c.y + 5 * (c.y - l.y))
      -- draw circles on selected corners
      -- love.graphics.setColor(1, 1, 1)
      -- love.graphics.circle("fill", c.x + topX, c.y + topY, 5)
      -- love.graphics.circle("fill", c.x + botX, c.y + botY, 5)
    end
  end
  love.graphics.setColor(1, 1, 1)
  -- draw crates
  for i, c in ipairs(crates) do
    love.graphics.draw(crate, c.x, c.y)
  end
  -- draw character
  love.graphics.draw(player.sprite, player.x + 45 / 2, player.y + 45 / 2, player.dir * math.pi / 2, 1, 1, 80 / 2, 45 / 2)
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
  local topX, topY = cornerNumToOffset(top)
  local botX, botY = cornerNumToOffset(bot)
  return topX, topY, botX, botY
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
