require "level"
HC = require "HC" -- this is a library that I did not create

function love.load()
  math.randomseed(os.time())
  lg = love.graphics
  lk = love.keyboard
  screenHeight = lg.getHeight()
  screenWidth = lg.getWidth()
  timer = 0
  won = false
  -- load in textures
  LFont = lg.newFont("Assets/Roboto-Regular.ttf", 96) -- I did not create this font
  MFont = lg.newFont("Assets/Roboto-Regular.ttf", 20) -- I did not create this font
  crate = lg.newImage("Assets/crate.png")
  concrete = {}
  for i = 1, 6 do
    concrete[i] = lg.newImage("Assets/concrete" .. i - 1 .. ".png")
  end
  -- generate floor
  floor = {}
  for i = 1, screenWidth / 30 + 1 do
    floor[i] = {}
    for j = 1, screenHeight / 30 + 1 do
      floor[i][j] = {}
      floor[i][j].tile = concrete[math.random(1, #concrete)]
      floor[i][j].rotation = math.random(1, 4) * math.pi / 2
    end
  end
  -- player
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
  -- load level
  currentLevel = 1
  Level:Load(currentLevel)
end

function love.update(dt)
  if lk.isDown("escape") or ((lk.isDown("lctrl") or lk.isDown("rctrl")) and lk.isDown("w")) then
    love.event.quit()
  end
  -- movement
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
  -- apply movement
  if player.health > 0 then
    player.x = player.x + player.vx
    player.y = player.y + player.vy
    player.col:move(player.vx, player.vy)
  end
  -- boundries
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
  -- check for and resolve collisions
  curSwitch = nil
  onStart = false
  onEnd = false
  takingDamage = false
  for shape, delta in pairs(HC.collisions(player.col)) do
    if shape.type == "crate" then
      player.col:move(delta.x, delta.y)
      player.x = player.x + delta.x
      player.y = player.y + delta.y
    elseif shape.type == "shadow" and shape.on then
      player.health = player.health - 350 * dt -- deal damage to the player
      takingDamage = true
    end
    if shape.type == "switch" then
      curSwitch = shape
    end
    if shape.type == "start" then
      onStart = true
    end
    if shape.type == "exit" then
      onEnd = true
    end
  end
  timer = timer + dt
  for i, l in pairs(lights) do
    -- sway lights
    if timer % 2 < 0.5 then
      l.x = l.x + (0.5 - (timer % 2)) * 50 * dt
      l.y = l.y + (0.5 - (timer % 2)) * 50 * dt
    elseif timer % 2 < 1 then
      l.x = l.x - ((timer % 2) - 0.5) * 50 * dt
      l.y = l.y - ((timer % 2) - 0.5) * 50 * dt
    elseif timer % 2 < 1.5 then
      l.x = l.x - (0.5 - ((timer % 2) - 1)) * 50 * dt
      l.y = l.y - (0.5 - ((timer % 2) - 1)) * 50 * dt
    elseif timer % 2 < 2 then
      l.x = l.x + ((timer % 2) - 1.5) * 50 * dt
      l.y = l.y + ((timer % 2) - 1.5) * 50 * dt
    end
    for j, c in pairs(crates) do
      -- update shadows
      HC.remove(l.shadow[j])
      l.shadow[j] = nil
      l.shadow[j] = HC.polygon(offsetsToPolygon(l, c))
      l.shadow[j].type = "shadow"
      l.shadow[j].on = l.switch.on
    end
  end
  -- heal player
  if player.health > 0 then
    player.health = player.health + 100 * dt
  end
  if player.health > 100 then
    player.health = 100
  end
  if player.health < 0 then
    player.health = 0
  end
end

function love.keypressed(key, scancode, isrepeat)
  -- interaction with "e"
  if key == "e"then
    if won then
      won = false
      player.health = 100
      currentLevel = 1
      Level:Reset()
      Level:Load(currentLevel)
    elseif player.health == 0 then
      player.health = 100
      Level:Reset()
      Level:Load(currentLevel)
    elseif onEnd then
      currentLevel = currentLevel + 1
      if currentLevel <= #levels then
        Level:Reset()
        Level:Load(currentLevel)
      end
      if currentLevel > #levels then
        won = true
      end
    elseif curSwitch then
      if curSwitch.on then
        curSwitch.on = false
      elseif not curSwitch.on then
        curSwitch.on = true
      end
      -- update shadow status
      for i, l in pairs(lights) do
        for j, c in pairs(crates) do
          l.shadow[j].on = l.switch.on
        end
      end
    elseif onStart then
      if currentLevel > 1 then
        currentLevel = currentLevel - 1
        Level:Reset()
        Level:Load(currentLevel)
      end
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
  -- draw start and end
  if levelstart and levelend then
    lg.setColor(0, 1, 0)
    lg.rectangle("fill", levelstart.x, levelstart.y, levelstart.w, levelstart.h)
    lg.setColor(1, 0, 0)
    lg.rectangle("fill", levelend.x, levelend.y, levelend.w, levelend.h)
    lg.setColor(0, 0, 0)
    lg.setFont(MFont)
    lg.printf("START", levelstart.x, levelstart.y + 40 - 13, levelstart.w, "center")
    lg.printf("END", levelend.x, levelend.y + 40 - 13, levelend.w, "center")
  end
  -- draw character
  lg.setColor(1, 1, 1)
  lg.draw(player.spr, player.x + 45 / 2, player.y + 45 / 2, player.dir * math.pi / 2, 1, 1, 80 / 2, 45 / 2)
  -- draw shadow
  for i, l in pairs(lights) do
    if l.switch.on then
      for j, c in pairs(crates) do
        lg.setColor(0, 0, 0, 0.5)
        lg.polygon("fill", offsetsToPolygon(l, c))
      end
    end
  end
  lg.setColor(1, 1, 1)
  -- draw crates
  for i, c in pairs(crates) do
    lg.draw(crate, c.x, c.y)
  end
  -- draw lights
  for i, l in pairs(lights) do
    lg.setColor(l.color)
    if l.switch.on then
      lg.circle("fill", l.x, l.y, 10)
      lg.rectangle("fill", l.switch.x, l.switch.y, 20, 20)
    else
      lg.circle("line", l.x, l.y, 10)
      lg.rectangle("line", l.switch.x, l.switch.y, 20, 20)
    end
  end
  -- draw level design grid
  -- lg.setColor(1, 1, 1)
  -- for i = 1, screenWidth / 80 do
  --   for j = 1, screenHeight / 80 do
  --     lg.line(80 * i, 0, 80 * i, screenHeight)
  --     lg.line(0, 80 * i, screenWidth, 80 * i)
  --   end
  -- end
  -- draw health bar
  lg.setColor(27 / 255, 113 / 255, 169 / 255)
  lg.rectangle("fill", 25, screenHeight - 50, player.health * 2, 25)
  lg.printf(math.floor(player.health), player.health * 2 + 25 + 10, screenHeight - 50, 100)
  -- draw taking damage overlay
  if takingDamage then
    lg.setColor(1, 0, 0, 0.25)
    lg.rectangle("fill", 0, 0, screenWidth, screenHeight)
  end
  -- draw text overlay
  if curSwitch then
    tooltip("Press E to Use")
  elseif onStart and currentLevel ~= 1 then
    tooltip("Press E to Go Back")
  elseif onEnd then
    if currentLevel == #levels then
      tooltip("Press E to Win")
    else
      tooltip("Press E to Continue")
    end
  end
  -- draw menu overlay
  if player.health == 0 then
    menu("YOU DIED", "Press E to Restart")
  end
  if won then
    menu("YOU WON!", "Press E to Restart")
  end
end

function tooltip(text)
  lg.setColor(1, 1, 1)
  lg.rectangle("fill", (screenWidth - 200) / 2, screenHeight - 150, 200, 100)
  lg.setColor(0, 0, 0)
  lg.setFont(MFont)
  lg.printf(text, (screenWidth - 200) / 2, screenHeight - 150 + 37, 200, "center")
end

function menu(title, option)
  lg.setColor(1, 1, 1)
  lg.rectangle("fill", 50, 50, screenWidth - 50 * 2, screenHeight / 2 - 50)
  lg.rectangle("fill", (screenWidth - 200) / 2, screenHeight - 150, 200, 100)
  lg.setColor(0, 0, 0)
  lg.setFont(LFont)
  lg.printf(title, 50, 50 + (screenHeight / 2 - 50) / 2 - 55, screenWidth - 50 * 2, "center")
  lg.setFont(MFont)
  lg.printf(option, (screenWidth - 200) / 2, screenHeight - 150 + 37, 200, "center")
end

function offsetsToPolygon(l, c)
  local top, bot = selectCorners(l, c)
  local topX, topY = cornerNumToOffset(top)
  local botX, botY = cornerNumToOffset(bot)
  local distance = 1440 / math.sqrt(math.abs((c.x + 40) - l.x) * math.abs((c.x + 40) - l.x) + math.abs((c.y + 40) - l.y) * math.abs((c.y + 40) - l.y))
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
