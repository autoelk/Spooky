require "conf"
require "light"
HC = require "HC" -- this is a library that I did not create

function love.load()
  math.randomseed(os.time())
  lg = love.graphics
  lk = love.keyboard
  screenHeight = lg.getHeight()
  screenWidth = lg.getWidth()
  --load in textures
  crate = lg.newImage("Assets/crate.png")
  concrete = {}
  for i = 1, 6 do
    concrete[i] = lg.newImage("Assets/concrete" .. i - 1 .. ".png")
  end
  --generate floor
  floor = {}
  for i = 1, screenWidth / 30 + 1 do
    floor[i] = {}
    for j = 1, screenHeight / 30 + 1 do
      floor[i][j] = {}
      floor[i][j].tile = concrete[math.random(1, #concrete)]
      floor[i][j].rotation = math.random(1, 4) * math.pi / 2
    end
  end
  --place lights
  lights = {}
  for i = 1, 2 do
    table.insert(lights, Light:Create())
  end
  --place crates
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
    spr = lg.newImage("Assets/player.png")
  }
  player.col = HC.rectangle(player.x, player.y, player.w, player.h)
  --preload shadow collisions
  for i, l in ipairs(lights) do
    for j, c in ipairs(crates) do
      c.shadow = {}
      c.shadow[i] = HC.polygon(offsetsToPolygon(l, c))
      c.shadow[i].on = l.switch.on
      c.shadow[i].type = "shadow"
    end
  end
end

function love.update(dt)
  if lk.isDown("escape") or ((lk.isDown("lctrl") or lk.isDown("rctrl")) and lk.isDown("w")) then
    love.event.quit()
  end
  --movement
  player.vx, player.vy = 0, 0
  if lk.isDown("up") or lk.isDown("w") then
    player.vy = -player.speed * dt
    player.dir = 0
  end
  if lk.isDown("right") or lk.isDown("d") then
    player.vx = player.speed * dt
    player.dir = 1
  end
  if lk.isDown("down") or lk.isDown("s") then
    player.vy = player.speed * dt
    player.dir = 2
  end
  if lk.isDown("left") or lk.isDown("a") then
    player.vx = -player.speed * dt
    player.dir = 3
  end
  --apply movement
  player.x = player.x + player.vx
  player.y = player.y + player.vy
  player.col:move(player.vx, player.vy)
  --boundries
  if player.x < 0 then
    player.col:move(- player.x, 0)
    player.x = 0
  elseif player.x > screenWidth - 45 then
    player.col:move((screenWidth - 45) - player.x, 0)
    player.x = screenWidth - 45
  end
  if player.y < 0 then
    player.col:move(0, - player.y)
    player.y = 0
  elseif player.y > screenHeight - 45 then
    player.col:move(0, (screenHeight - 45) - player.y)
    player.y = screenHeight - 45
  end
  --check for and resolve collisions
  curSwitch = nil;
  for shape, delta in pairs(HC.collisions(player.col)) do
    -- print(shape.type)
    if shape.type == "crate" then
      -- print(delta.x .. ", " .. delta.y)
      player.col:move(delta.x, delta.y)
      player.x = player.x + delta.x
      player.y = player.y + delta.y
    elseif shape.type == "shadow" and shape.on then
      player.health = player.health - 200 * dt --deal damage to the player
    end
    if shape.type == "switch" then
      curSwitch = shape;
    end
  end
  --heal player
  player.health = player.health + 100 * dt
  if player.health > 100 then
    player.health = 100
  end
  if player.health < 0 then
    player.health = 0
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "e" and curSwitch then
    if curSwitch.on then
      curSwitch.on = false
    elseif not curSwitch.on then
      curSwitch.on = true
    end
  end
end

function love.draw()
  lg.setColor(1, 1, 1) -- reset color
  -- draw floor
  for i = 1, screenWidth / 30 + 1 do
    for j = 1, screenHeight / 30 + 1 do
      lg.draw(floor[i][j].tile, i * 30 - 30 / 2, j * 30 - 30 / 2, floor[i][j].rotation, 1, 1, 30 / 2, 30 / 2)
    end
  end
  --draw shadow
  for i, l in ipairs(lights) do
    if l.switch.on then
      for j, c in ipairs(crates) do
        lg.setColor(0, 0, 0, 0.85)
        lg.polygon("fill", offsetsToPolygon(l, c))
        -- lg.setColor(1, 1, 1)
        -- local distance = 200
        -- -- draw lines from light to corners
        -- lg.line(l.x, l.y, c.x + 80 + distance * (c.x + 80 - l.x), c.y + 80 + distance * (c.y + 80 - l.y))
        -- lg.line(l.x, l.y, c.x + 80 + distance * (c.x + 80 - l.x), c.y + distance * (c.y - l.y))
        -- lg.line(l.x, l.y, c.x + distance * (c.x - l.x), c.y + 80 + distance * (c.y + 80 - l.y))
        -- lg.line(l.x, l.y, c.x + distance * (c.x - l.x), c.y + distance * (c.y - l.y))
        -- -- draw circles on selected corners
        -- lg.circle("fill", c.x + topX, c.y + topY, 5)
        -- lg.circle("fill", c.x + botX, c.y + botY, 5)
      end
    end
  end
  lg.setColor(1, 1, 1) -- reset colors
  -- draw crates
  for i, c in ipairs(crates) do
    lg.draw(crate, c.x, c.y)
  end
  -- draw character
  lg.draw(player.spr, player.x + 45 / 2, player.y + 45 / 2, player.dir * math.pi / 2, 1, 1, 80 / 2, 45 / 2)
  -- draw lights
  for i, l in ipairs(lights) do
    -- attach light to player
    -- l.x = player.x + 20
    -- l.y = player.y + 20
    lg.setColor(l.color)
    lg.circle("fill", l.x, l.y, 10)
    lg.rectangle("fill", l.switch.x, l.switch.y, 20, 20)
  end
  -- draw health bar
  lg.setColor(1, 0, 0)
  lg.rectangle("fill", 25, screenHeight - 50, player.health * 2, 25)
  -- draw light switch overlay
  if curSwitch then
    lg.setColor(1, 1, 1)
    lg.rectangle("fill", (screenWidth - 200) / 2, screenHeight - 150, 200, 100)
    lg.setColor(0, 0, 0)
    lg.printf("Press E to Switch", (screenWidth - 200) / 2, screenHeight - 150, 200, "center")
  end
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
