require "aux"
require "weapons"
require "input"
require "enemies"
require "anims"

debug = true

lifeSprite = "assets/img/life.png"

-- player shit, static, tunable
playerParams = {
  brake = 0.3,
  vc = 7, -- air resistance
  sprite = "assets/img/ship.png",
  acc = {x = 12000, y = 18000},
}

-- evolution params, static, tunable
evolParams = {
  thrsh = 0.01,
  thrshMultInit = 1.02
}

-- player params, dynamic
playerDyn = {
  img = nil,
  sounds = {},
}

-- evolution params, dynamic
evolDyn = {
  thrshm = evolParams.thrshMultInit,
  killed = nil,
  lv = nil,
  stopGettingHarder = true
}

bullets = {}

lives = 3
lifeImg = nil
player = {}

paused = false
gameover = false
gameoverTimeoutMax = 1
mute = false

backbars = {}
bgh = 80
music = nil
bgV = 20

white = {r = 255, g = 255, b = 255}
gameoverTimeout = gameoverTimeoutMax

shootMode = shootModes.primarySecondary

function resetLevelState()
  evolDyn.killed = 0
  evolDyn.lv = 1
  lives = 3
  evolDyn.thrshm = evolParams.thrshMultInit

  enemies = {}
  bullets = {}

  initPlayer()
end

function initBG()
  y = -5
  while y < love.graphics.getHeight() + 5 do
    bar = {y = y, col = white, h=6}
    table.insert(backbars, bar)
    y = y + bgh
  end
end

function moveBG(dt)
  my = 9999
  for i, bar in ipairs(backbars) do
    bar.y = bar.y + bgV*dt
    if bar.y > love.graphics.getHeight() + 1 then
      table.remove(backbars, i)
    end
    if bar.y < my then
      my = bar.y
    end
  end
  if my > -1 then
    table.insert(backbars, {y = my - bgh, col = white, h=6})
  end
end

function drawBG()
  r, g, b, a = love.graphics.getColor()
  for i, bar in ipairs(backbars) do
    love.graphics.setColor(bar.col.r, bar.col.g, bar.col.b)
    love.graphics.rectangle("fill", -5, gridPos(bar.y), love.graphics.getWidth() + 5, bar.h)
  end
  love.graphics.setColor(r, g, b, a)
end

function initPlayer()
  player.x = love.graphics.getWidth() / 2
  player.y = love.graphics.getHeight() - 100
  player.a = {x = playerParams.acc.x, y = playerParams.acc.y}
  player.v = {x = 0, y = 0}
end

function loseOneLife()
  enemies = {}
  enemyBullets = {}
  bullets = {}
  lives = lives - 1
  --playRandomSound(playerDyn.sounds)
  initPlayer()
  if lives == 0 then
    gameover = true
    gameoverTimeout = gameoverTimeoutMax
  end
end

function coreLoad(arg)
  resetLevelState()
  initEnemies()
  initWeapons()
  initBG()
  initAnimations()

  lifeImg = love.graphics.newImage(lifeSprite)
  player.img = love.graphics.newImage(playerParams.sprite)
end

function move(direction, dt)
  if direction == "left" then
    player.a.x = -playerParams.acc.x
  elseif direction == "right" then
    player.a.x = playerParams.acc.x
  elseif direction == "up" then
    player.a.y = -playerParams.acc.y
  elseif direction == "down" then
    player.a.y = playerParams.acc.y
  end
end

function byebye()
  love.event.push("quit")
end

-- moves the ship and constrains it to the viewing field
function moveShip(dt)
  if player.x > -1 and player.x < love.graphics.getWidth() + 1 then
    player.x = player.x + (player.v.x*dt)
  else
    player.v.x = 0
    if player.x < 20 then
      player.x = 0
    else
      player.x = love.graphics.getWidth()
    end
  end

  if player.y > -1 and player.y < love.graphics.getHeight() + 1 then
    player.y = player.y + (player.v.y*dt)
  else
    player.v.y = 0
    if player.y < 20 then
      player.y = 0
    else
      player.y = love.graphics.getHeight()
    end
  end
end

-- a very slow function
function evolveFunc(x)
  return math.log(305 + x) / math.log(1.1) - math.log(305)/math.log(1.1)
end

function nextLevel(dt)
  -- TODO: this will change very soon
  if evolveFunc(evolDyn.killed) > evolDyn.lv
    and not evolDyn.stopGettingHarder then
      evolDyn.thrshm = evolDyn.thrshm * evolDyn.thrshm
      evolParams.stopGettingHarder = true
      evolDyn.lv = evolDyn.lv + 1
      print(evolDyn.thrshm)
  end
end

function coreUpdate(dt)
  -- mute
  --if mute then music:setVolume(0) else music:setVolume(1) end

  -- paused
  if gameover then
    gameoverTimeout = gameoverTimeout - dt
  end

  if paused or gameover then return end

  -- game gets harder
  nextLevel(dt)

  handleKeyboard(dt)
  handleJoystick(dt)

  player.a.x = player.a.x - playerParams.vc*player.v.x
  player.a.y = player.a.y - playerParams.vc*player.v.y

  player.v.x = player.v.x + player.a.x*dt
  player.v.y = player.v.y + player.a.y*dt

  -- auto-brake: not very physics-y but necessary unless you want to
  -- add a brake key – you don't
  player.v.x = (1 - playerParams.brake)*player.v.x
  player.v.y = (1 - playerParams.brake)*player.v.y

  moveShip(dt)

  -- enable shooting
  adjustWeaponTimers(dt, currentWeapon)

  if shootMode == shootModes.primarySecondary then
    adjustWeaponTimers(dt, secondaryWeapon)
  end

  -- generate enemies
  enemiesGenerate(dt)

  -- move bullets around
  for i, bullet in ipairs(bullets) do
    moveBullet(dt, i)
  end

  enemiesMove(dt)

  -- collisions between enemies and stuff, including you
  enemiesCollide(dt)
  explosionsProcess(dt)

  moveBG(dt)
end

-- draw stuff
function coreDraw(dt)
  drawBG()

  love.graphics.draw(player.img,
                     gridPos(player.x - player.img:getWidth()/2),
                     gridPos(player.y - player.img:getHeight()/2))

  for i, bullet in ipairs(bullets) do
    drawBullet(bullet)
  end

  enemiesDraw(dt)
  explosionsDraw(dt)

  for i = 0, lives-1 do
    love.graphics.draw(lifeImg, 10 + i*(lifeImg:getWidth() + 6), 10)
  end

  font = love.graphics.newFont("assets/fonts/zig.regular.ttf", 27)
  love.graphics.setFont(font)

  tw = 400
  love.graphics.printf(string.format("%d killed - lv %d", evolDyn.killed, evolDyn.lv),
                       love.graphics.getWidth() - tw - 10, 10, tw, "right")

  if paused or gameover then
    font = love.graphics.newFont("assets/fonts/zig.regular.ttf", 80)
    love.graphics.setFont(font)
    txt = paused and "PAUSED" or "GAME OVER"
    love.graphics.printf(txt, love.graphics.getWidth() / 2 - 200,
                         love.graphics.getHeight() / 2 - 40, 400, "center")
  end
end
