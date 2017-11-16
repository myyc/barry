menuTimeoutMax = 1

menuTimeout = menuTimeoutMax

function isMenuIdle()
  return menuTimeout < 0
end

function switchToMenu()
  gameState = gameStates.menu
  menuTimeout = menuTimeoutMax
end

function menuLoad()
end

function menuUpdate(dt)
  menuTimeout = menuTimeout - dt
end

function menuDraw(dt)
  font = love.graphics.newFont("assets/fonts/zig.regular.ttf", 100)
  love.graphics.setFont(font)
  txt = "barry"
  love.graphics.printf(txt, love.graphics.getWidth() / 2 - 250,
                       300, 500, "center")

  font = love.graphics.newFont("assets/fonts/zig.regular.ttf", 40)
  love.graphics.setFont(font)
  txt = "press any reasonable key to play"
  love.graphics.printf(txt, love.graphics.getWidth() / 2 - 250,
                       500, 500, "center")
end
