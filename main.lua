require "aux"
require "weapons"
require "input"
require "enemies"

debug = true

lifeSprite = "assets/img/life.png"

-- player shit, static, tunable
playerParams = {
  friction = 0.1,
  maxSpeed = 500,
  sprite = "assets/img/ship.png",
  accel = {x = 4000, y = 9000},
}

-- evolution params, static, tunable
evolParams = {
  thrsh = 0.02,
  thrshMultInit = 1.01
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
mute = false

backbars = {}
bgh = 80
music = nil
bgV = 20

white = {r = 255, g = 255, b = 255}

function initValues()
  evolDyn.killed = 0
  evolDyn.lv = 1
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
  player.accel = playerParams.accel
  player.speed = {x = 0, y = 0}
end

function loseOneLife()
  enemies = {}
  enemyBullets = {}
  bullets = {}
  lives = lives - 1
  --playRandomSound(playerDyn.sounds)
  initPlayer()
  if lives == 0 then gameover = true end
end

function love.load(arg)
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  joysticks = love.joystick.getJoysticks()

  love.mouse.setVisible(state)

  initValues()
  initEnemies()
  initPlayer()
  initWeapons()
  initBG()

  lifeImg = love.graphics.newImage(lifeSprite)
  player.img = love.graphics.newImage(playerParams.sprite)

  -- add more sounds
  --[[
  for i = 1,4 do
    table.insert(enemyDyn.sounds,
                 love.audio.newSource(string.format("assets/audio/pow%d.wav", i), "static"))
  end

  for i = 1,4 do
    table.insert(playerDyn.sounds,
                 love.audio.newSource(string.format("assets/audio/boo%d.wav", i), "static"))
  end

  music = love.audio.newSource("assets/audio/sll.wav")
  music:setLooping(true)
  music:play()
  ]]--
end

function move(direction, dt)
  if direction == "left" then
    if player.speed.x > -playerParams.maxSpeed then
      player.speed.x = player.speed.x - (player.accel.x*dt)
    end
  elseif direction == "right" then
    if player.speed.x < playerParams.maxSpeed then
      player.speed.x = player.speed.x + (player.accel.x*dt)
    end
  elseif direction == "up" then
    if player.speed.y > -playerParams.maxSpeed then
      player.speed.y = player.speed.y - (player.accel.y*dt)
    end
  elseif direction == "down" then
    if player.speed.y < playerParams.maxSpeed then
      player.speed.y = player.speed.y + (player.accel.y*dt)
    end
  end
end

function byebye()
  love.event.push("quit")
end

function switchWeapon(back)
  weaponDyn.weaponIdx = (weaponDyn.weaponIdx + (back and -1 or 1)) % #weapons.names
  weaponDyn.currentWeapon = weapons.names[weaponDyn.weaponIdx+1]
  weaponDyn.freq = weapons.params[weaponDyn.currentWeapon].freq
  weaponDyn.canShootTimer = 1/weaponDyn.freq
end

-- edges
function constrainToEdges(dt)
  if player.x > -1 and player.x < love.graphics.getWidth() + 1 then
    player.x = player.x + (player.speed.x*dt)
  else
    player.speed.x = 0
    if player.x < 20 then
      player.x = 0
    else
      player.x = love.graphics.getWidth()
    end
  end

  if player.y > -1 and player.y < love.graphics.getHeight() + 1 then
    player.y = player.y + (player.speed.y*dt)
  else
    player.speed.y = 0
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
  end
end

function love.update(dt)
  -- mute
  --if mute then music:setVolume(0) else music:setVolume(1) end

  -- paused
  if paused or gameover then return end

  -- game gets harder
  nextLevel(dt)

  handleKeyboard(dt)
  handleJoystick(dt)

  -- friction
  player.speed.x = (1 - playerParams.friction)*player.speed.x
  player.speed.y = (1 - playerParams.friction)*player.speed.y

  constrainToEdges(dt)

  -- enable shooting
  weaponDyn.canShootTimer = weaponDyn.canShootTimer - (1 * dt)
  if weaponDyn.canShootTimer < 0 then
    weaponDyn.canShoot = true
  end

  -- generate enemies
  enemiesGenerate(dt)

  -- move bullets around
  for i, bullet in ipairs(bullets) do
    moveBullet(dt, bullets, i)
  end

  enemiesMove(dt)

  -- collisions between enemies and stuff, including you
  enemiesCollide(dt)

  -- stupid shit
  --player.x = math.floor(player.x / 4) * 4
  --player.y = math.floor(player.y / 4) * 4

  moveBG(dt)
end

-- draw stuff
function love.draw(dt)
  drawBG()

  love.graphics.draw(player.img,
                     gridPos(player.x - player.img:getWidth()/2),
                     gridPos(player.y - player.img:getHeight()/2))

  for i, bullet in ipairs(bullets) do
    drawBullet(bullet)
  end

  enemiesDraw(dt)

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
