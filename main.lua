require "core"
require "menu"

gameStates = {
  menu = 1,
  level = 2,
}

gameState = gameStates.menu

function love.load(arg)
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  joysticks = love.joystick.getJoysticks()

  love.mouse.setVisible(false)

  menuLoad(arg)
  coreLoad(arg)
end

function love.update(dt)
  if gameState == gameStates.level then
    coreUpdate(dt)
  elseif gameState == gameStates.menu then
    menuUpdate(dt)
  end
end

function love.draw(dt)
  if gameState == gameStates.level then
    coreDraw(dt)
  elseif gameState == gameStates.menu then
    menuDraw(dt)
  end
end
