Light = {}

function Light:Create(x, y)
  local light = {
    x = x or math.floor(math.random(0, screenWidth / 80)),
    y = y or math.floor(math.random(0, screenHeight / 80)),
  }
  table.insert(lights, light)
  return light
end
