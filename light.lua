Light = {}

function Light:Create (x, y, switchx, switchy)
  local light = {
    x = x or math.random(0, screenWidth),
    y = y or math.random(0, screenHeight),
    color = {math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255 / 255)},
  }
  light.switch = Light:CreateSwitch(switchx, switchy)
  return light
end

function Light:CreateSwitch(x, y)
  local temp = {
    x = x or math.random(0, screenWidth),
    y = y or math.random(0, screenHeight),
  }
  local switch = HC.rectangle(temp.x, temp.y, 20, 20)
  switch.x = temp.x
  switch.y = temp.y
  switch.type = "switch"
  switch.on = true
  return switch
end
