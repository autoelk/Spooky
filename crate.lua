Crate = {}

function Crate:Create(x, y)
  local box = {
    x = x or math.floor(math.random(0, screenWidth / 80)),
    y = y or math.floor(math.random(0, screenHeight / 80)),
  }
  box.x = box.x * 80
  box.y = box.y * 80
  table.insert(crates, box)
  return box
end
