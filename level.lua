Level = {}
levels = {}

levels[1] = {
  {"start", 0, 0},
  {"end", 100, 100},
  {"crate", 500, 600},
  {"light", 300, 400, 400, 300, true},
}

function Level:Load(num)
  crates = {}
  lights = {}
  if num == 0 then
    levelstart = Level:CreateStart()
    levelend = Level:CreateEnd()
    --create crates
    for i = 1, 5 do
      table.insert(crates, Level:CreateCrate())
    end
    --create lights
    for i = 1, 3 do
      table.insert(lights, Level:CreateLight())
    end
  else
    for i, object in ipairs(levels[num]) do
      if object[1] == "start" then
        levelstart = Level:CreateStart(object[2], object[3])
      elseif object[1] == "crate" then
        table.insert(crates, Level:CreateCrate(object[2], object[3]))
      elseif object[1] == "light" then
        table.insert(lights, Level:CreateLight(object[2], object[3], object[4], object[5]))
      elseif object[1] == "end" then
        levelend = Level:CreateEnd(object[2], object[3])
      end
    end
  end
  player.x = levelstart.x
  player.y = levelstart.y
  player.col:moveTo(levelstart.x + 45 / 2, levelstart.y + 45 / 2)
end

function Level:CreateCrate (x, y)
  local box = {
    x = x or 80 * math.random(0, math.floor(screenWidth / 80)),
    y = y or 80 * math.random(0, math.floor(screenHeight / 80)),
  }
  box.col = HC.rectangle(box.x, box.y, 80, 80)
  box.col.type = "crate"
  return box
end

function Level:CreateLight (x, y, switchx, switchy, on)
  local light = {
    x = x or math.random(0, screenWidth),
    y = y or math.random(0, screenHeight),
    color = {math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255 / 255)},
  }
  light.switch = Level:CreateSwitch(switchx, switchy, on)
  light.shadow = {}
  for i, c in ipairs(crates) do
    light.shadow[i] = HC.polygon(offsetsToPolygon(light, c))
    light.shadow[i].type = "shadow"
    light.shadow[i].on = light.switch.on
  end
  return light
end

function Level:CreateSwitch(x, y, on)
  local temp = {
    x = x or math.random(0, screenWidth),
    y = y or math.random(0, screenHeight),
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
    x = x or math.random(0, screenWidth),
    y = y or math.random(0, screenHeight),
    w = 64,
    h = 64,
  }
  return start
end

function Level:CreateEnd(x, y)
  local temp = {
    x = x or math.random(0, screenWidth),
    y = y or math.random(0, screenHeight),
    w = 64,
    h = 64,
  }
  local exit = HC.rectangle(temp.x, temp.y, temp.w, temp.h)
  exit.type = "exit"
  exit.x = temp.x
  exit.y = temp.y
  exit.w = temp.w
  exit.h = temp.h
  return exit
end
