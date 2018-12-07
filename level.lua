Level = {}
levels = {
  {
    {"start", 0, 0},
    {"end", 6, 0},
    {"crate", 3, 6},
    {"crate", 1, 4},
    {"crate", 2, 6},
    {"crate", 3, 2},
    {"crate", 4, 6},
    {"light", 3, 4, - 1, - 1, true},
  },
  {
    {"start", 0, 0},
    {"end", 9, 4},
    {"crate", 3, 2},
    {"crate", 5, 4},
    {"light", 3, 4, 6, 2, true},
  },
  {
    {"start", 0, 0},
    {"end", 9, 4},
    {"crate", 5, 4},
    {"crate", 5, 1},
    {"light", 3, 4, 6, 2, true},
    {"light", 3, 0, 2, 6, true},
  },
}

function Level:Load(num)
  crates = {}
  lights = {}
  levelstart = {}
  levelend = {}
  if num == 0 then
    levelstart = Level:CreateStart()
    levelend = Level:CreateEnd()
    --create crates
    for i = 1, 5 do
      table.insert(crates, Level:CreateCrate())
    end
    --create lights
    for i = 1, 2 do
      table.insert(lights, Level:CreateLight())
    end
  else
    for i, object in pairs(levels[num]) do
      if object[1] == "start" then
        levelstart = Level:CreateStart(object[2] * 80, object[3] * 80)
      elseif object[1] == "crate" then
        table.insert(crates, Level:CreateCrate(object[2] * 80, object[3] * 80))
      elseif object[1] == "light" then
        table.insert(lights, Level:CreateLight(object[2] * 80 + 40, object[3] * 80 + 40, object[4] * 80 + 40 - 10, object[5] * 80 + 40 - 10, object[6]))
      elseif object[1] == "end" then
        levelend = Level:CreateEnd(object[2] * 80, object[3] * 80)
      end
    end
  end
  player.x = levelstart.x
  player.y = levelstart.y
  player.col:moveTo(levelstart.x + 45 / 2, levelstart.y + 45 / 2)
end

function Level:Reset()
  for i, l in pairs(lights) do
    for j, c in pairs(crates) do
      HC.remove(l.shadow[j])
      l.shadow[j] = nil
    end
  end
  for i, l in pairs(lights) do
    HC.remove(l.switch)
    lights[i] = nil
  end
  for i, c in pairs(crates) do
    HC.remove(c.col)
    crates[i] = nil
  end
  HC.remove(levelstart.col)
  levelstart = nil
  HC.remove(levelend.col)
  levelend = nil
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

function Level:CreateLight (x, y, switchx, switchy, on)
  local light = {
    x = x or 80 * math.floor(math.random(0, screenWidth / 80)) + 40,
    y = y or 80 * math.floor(math.random(0, screenHeight / 80)) + 40,
    color = {math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255 / 255)},
  }
  light.switch = Level:CreateSwitch(switchx, switchy, on)
  light.shadow = {}
  for i, c in pairs(crates) do
    light.shadow[i] = HC.polygon(offsetsToPolygon(light, c))
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
