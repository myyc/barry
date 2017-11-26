require "core"
require "menu"

gameStates = {
  menu = 1,
  level = 2,
}

i = 0

mshader = nil

gameState = gameStates.menu

r = math.random(0, 300)

function love.load(arg)
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  joysticks = love.joystick.getJoysticks()

  love.mouse.setVisible(false)

  mshader = love.graphics.newShader[[
  extern int r;
   vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
     vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
     number average = (pixel.r+pixel.b+pixel.g)/3.0;
     number factor = screen_coords.x/800;

     number col = fract(sin(dot(floor((r+screen_coords.xy)/3), vec2(12.9898,78.233)))*43758.5453123);
     pixel.r = 0.85*pixel.r + 0.15*col;
     pixel.g = 0.85*pixel.g + 0.15*col;
     pixel.b = 0.85*pixel.b + 0.15*col;
     return pixel;
     }
  ]]

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
  if i == 4 then
    r = math.random(0, 300)
    i = 0
  end

  mshader:send("r", r)
  love.graphics.setShader(mshader)

  if gameState == gameStates.level then
    coreDraw(dt)
  elseif gameState == gameStates.menu then
    menuDraw(dt)
  end
  i = i + 1
end
