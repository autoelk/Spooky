Level = {}
levels = {
  {
    -- level 1
    {"start", 0, 0},
    {"end", 6, 0},
    {"crate", 1, 5},
    {"crate", 2, 6},
    {"crate", 2, 2},
    {"crate", 3, 2},
    {"crate", 3, 6},
    {"crate", 4, 6},
    {"crate", 5, 5},
    {"crate", 6, 4},
    {"light", true, - 1, - 1, 2, 4},
  },
  {
    -- level 2
    {"start", 0, 0},
    {"end", 7, 6},
    {"crate", 3, 5},
    {"crate", 4, 2},
    {"crate", 4, 6},
    {"crate", 4, 7},
    {"crate", 5, 3},
    {"crate", 6, 2},
    {"crate", 7, 5},
    {"light", true, - 1, - 1, 1, 2},
  },
  {
    -- level 3
    {"start", 0, 0},
    {"end", 9, 4},
    {"crate", 2, 6},
    {"crate", 3, 2},
    {"crate", 5, 4},
    {"light", true, 6, 2, 3, 4},
  },
  {
    -- level 4
    {"start", 0, 0},
    {"end", 0, 6},
    {"crate", 1, 4},
    {"crate", 2, 6},
    {"crate", 3, 3},
    {"crate", 4, 5},
    {"crate", 6, 1},
    {"crate", 7, 2},
    {"crate", 7, 4},
    {"crate", 7, 6},
    {"light", true, 7, 5, 5, 3},
  },
  {
    -- level 5
    {"start", 0, 0},
    {"end", 9, 4},
    {"crate", 5, 1},
    {"crate", 5, 4},
    {"light", true, 6, 2, 3, 4},
    {"light", true, 2, 6, 3, 0},
  },
  {
    -- level 6
    {"start", 5, 4},
    {"end", 9, 2},
    {"crate", 3, 1},
    {"crate", 4, 3},
    {"crate", 8, 3},
    {"light", true, 2, 0, 0, 4},
    {"light", true, 3, 6, 7, 1},
  },
  {
    -- level 7
    {"start", 0, 3},
    {"end", 9, 3},
    {"crate", 5, 1},
    {"crate", 5, 2},
    {"crate", 5, 3},
    {"crate", 5, 4},
    {"crate", 5, 5},
    {"light", true, 1, 1, 10, - 5},
    {"light", true, 2, 2, 7, 8},
    {"light", true, 3, 3, - 1, - 1},
  },
}

function Level:Load(num)
  crates = {}
  lights = {}
  levelstart = {}
  levelend = {}
  --create floor
  floor = Level:CreateFloor()
  if levels[num][1][1] == "random" or num == 0 then
    levelstart = Level:CreateStart()
    levelend = Level:CreateEnd()
    local amtCrates = levels[num][1][2] or math.random(2, 5)
    local amtLights = levels[num][1][3] or math.random(1, 3)
    -- create crates
    for i = 1, amtCrates do
      table.insert(crates, Level:CreateCrate())
    end
    -- create lights
    for i = 1, amtLights do
      table.insert(lights, Level:CreateLight())
    end
  else
    for i, object in pairs(levels[num]) do
      if object[1] == "start" then
        levelstart = Level:CreateStart(object[2] * 80, object[3] * 80)
      elseif object[1] == "crate" then
        table.insert(crates, Level:CreateCrate(object[2] * 80, object[3] * 80))
      elseif object[1] == "light" then
        table.insert(lights, Level:CreateLight(object[2], object[3] * 80 + 40 - 10, object[4] * 80 + 40 - 10, object[5] * 80 + 40, object[6] * 80 + 40))
      elseif object[1] == "end" then
        levelend = Level:CreateEnd(object[2] * 80, object[3] * 80)
      end
    end
  end
  timer = 0
  player.health = player.maxhealth
  player.x = levelstart.x + (80 - 45) / 2
  player.y = levelstart.y + (80 - 45) / 2
  player.dir = 2
  player.col:moveTo(levelstart.x + 40, levelstart.y + 40)
end

function Level:Reset()
  -- reset shadows
  for i, l in pairs(lights) do
    for j, c in pairs(crates) do
      HC.remove(l.shadow[j])
      l.shadow[j] = nil
    end
  end
  -- reset lights
  for i, l in pairs(lights) do
    HC.remove(l.switch)
    lights[i] = nil
  end
  -- reset crates
  for i, c in pairs(crates) do
    HC.remove(c.col)
    crates[i] = nil
  end
  HC.remove(levelstart.col)
  levelstart = nil
  HC.remove(levelend.col)
  levelend = nil
end

function Level:CreateFloor()
  -- generate floor
  local ground = {}
  for i = 1, screenWidth / 30 + 1 do
    ground[i] = {}
    for j = 1, screenHeight / 30 + 1 do
      ground[i][j] = {}
      ground[i][j].tile = concrete[math.random(1, #concrete)]
      ground[i][j].rotation = math.random(1, 4) * math.pi / 2
    end
  end
  return ground
end

function Level:CreateCrate (x, y)
  local box = {
    x = x or 80 * math.floor(math.random(0, screenWidth / 80)),
    y = y or 80 * math.floor(math.random(0, screenHeight / 80)),
  }
  box.col = HC.rectangle(box.x, box.y, 80, 80)
  box.col.type = "crate"
  return box
end

function Level:CreateLight (on, switchx, switchy, x, y)
  local light = {
    x = x or 80 * math.floor(math.random(0, screenWidth / 80)) + 40,
    y = y or 80 * math.floor(math.random(0, screenHeight / 80)) + 40,
    color = {math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255 / 255)},
  }

  light.switch = Level:CreateSwitch(switchx, switchy, on)
  -- generate shadows
  light.shadow = {}
  for i, c in pairs(crates) do
    light.shadow[i] = HC.polygon(GenShadow(light, c))
    light.shadow[i].type = "shadow"
    light.shadow[i].on = light.switch.on
  end
  return light
end

function Level:CreateSwitch(x, y, on)
  local temp = {
    x = x or 80 * math.floor(math.random(0, screenWidth / 80)) + 40 - 10,
    y = y or 80 * math.floor(math.random(0, screenHeight / 80)) + 40 - 10,
  }
  local switch = HC.rectangle(temp.x, temp.y, 20, 20)
  switch.type = "switch"
  switch.x = temp.x
  switch.y = temp.y
  switch.on = on or true
  return switch
end

function Level:CreateStart(x, y)
  local start = {
    x = x or 80 * math.floor(math.random(0, screenWidth / 80)),
    y = y or 80 * math.floor(math.random(0, screenHeight / 80)),
    w = 80,
    h = 80,
  }
  start.col = HC.rectangle(start.x, start.y, start.w, start.h)
  start.col.type = "start"
  return start
end

function Level:CreateEnd(x, y)
  local exit = {
    x = x or 80 * math.floor(math.random(0, screenWidth / 80)),
    y = y or 80 * math.floor(math.random(0, screenHeight / 80)),
    w = 80,
    h = 80,
  }
  exit.col = HC.rectangle(exit.x, exit.y, exit.w, exit.h)
  exit.col.type = "exit"
  return exit
end
