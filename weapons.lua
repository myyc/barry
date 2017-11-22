require "aux"

weapons = {
  names = {},
  params = {
    stars = {
      ttl = 9000,
      v = {x = 0, y = 500},
      sprite = "assets/img/star.png",
      img = nil,
      type = "bullet",
      freq = 10,
      dmg = 200,
      shootFunc = nil,
      sounds = {},
      deviation = 50,
      radius = 20,
    },
    machinegun = {
      ttl = 0.8,
      v = {x = 0, y = 800},
      sprite = "assets/img/bullet.png",
      img = nil,
      type = "bullet",
      freq = 50,
      dmg = 4,
      shootFunc = nil,
      deviation = 100,
      sounds = {},
      radius = 5
    },
    rockets = {
      ttl = 9000,
      v = {x = 0, y = 30},
      accel = 800,
      sprite = "assets/img/missile.png",
      img = nil,
      type = "rocket",
      freq = 6,
      dmg = 500,
      radius = 50,
      shootFunc = nil,
      deviation = 100,
      sounds = {},
    },
    blackholegun = {
      ttl = 0.7,
      v = {x = 0, y = 400},
      sprite = "assets/img/blackholebullet.png",
      type = "bullet",
      freq = 1.5,
      dmg = 0,
      deviation = 30,
      sounds = {}
    }
  }
}

weaponDyn = {
  weaponIdx = 0,
  currentWeapon = "stars",
  canShoot = true,
  freq = weapons.params.stars.freq,
  canShootTimer = 1/weapons.params.stars.freq,
}

blackHoleParams = {
  mass = 400,
  sprite = "assets/img/blackhole2.png",
  gravc = 2000000000,
  radius = 60,
  dmg = 999999
}

function initWeapons()
  weapons.params.machinegun.img = love.graphics.newImage(weapons.params.machinegun.sprite)
  weapons.params.stars.img = love.graphics.newImage(weapons.params.stars.sprite)
  weapons.params.rockets.img = love.graphics.newImage(weapons.params.rockets.sprite)
  weapons.params.blackholegun.img = love.graphics.newImage(weapons.params.blackholegun.sprite)

  blackHoleParams.img = love.graphics.newImage(blackHoleParams.sprite)

  weapons.params.machinegun.shootFunc = shootMachineGun
  weapons.params.stars.shootFunc = shootStar
  weapons.params.rockets.shootFunc = shootRocket
  weapons.params.blackholegun.shootFunc = shootBlackHole

  for type, params in pairs(weapons.params) do
    table.insert(weapons.names, type)
  end

  -- uncomment when sounds are back
  --[[
  for i = 1,5 do
    table.insert(weapons.params.stars.sounds,
                 love.audio.newSource(string.format("assets/audio/pew%d.wav", i), "static"))
  end
  for i = 1,4 do
    table.insert(weapons.params.rockets.sounds,
                 love.audio.newSource(string.format("assets/audio/woosh%d.wav", i), "static"))
  end
  for i = 1,6 do
    table.insert(weapons.params.machinegun.sounds,
                 love.audio.newSource(string.format("assets/audio/tap%d.wav", i), "static"))
  end
  ]]--
end

function getTTL(ttl)
  m = 0.5 + math.random()
  return m*ttl
end

function createBlackHole(x, y)
  blackHole = {x = x, y = y, mass = blackHoleParams.mass,
               img = blackHoleParams.img, v = {x = 0, y = 0},
               weapon = "blackhole", params = blackHoleParams, ttl = 9000,
               gravc = blackHoleParams.gravc, radius = blackHoleParams.radius,
               dmg = blackHoleParams.dmg
              }
  table.insert(bullets, blackHole)
end

function shootStar(bullets)
  params = weapons.params.stars
  bullet = {
    x = player.x,
    y = player.y - 0.7*player.img:getHeight(),
    img = params.img, weapon = "star", ttl = params.ttl,
    params = params, v = {x = params.v.x, y = params.v.y}
  }

  bullet.v.x = params.deviation*(0.5-love.math.random())

  table.insert(bullets, bullet)
end

function shootMachineGun(bullets)
  params = weapons.params.machinegun
  for i = -1, 1, 2 do
    bullet = {
      x = player.x + i*0.33*player.img:getWidth(),
      y = player.y, img = params.img, weapon = "machinegun", ttl = getTTL(params.ttl),
      params = params, v = {x = params.v.x, y = params.v.y},
    }

    bullet.v.x = params.deviation*(0.5-love.math.random())

    table.insert(bullets, bullet)
  end
end

function shootRocket(bullets)
  params = weapons.params.rockets
  bullet = {
    x = player.x,
    y = player.y - 0.7*player.img:getHeight(), img = params.img,
    weapon = "rockets", ttl = params.ttl,
    params = params, v = {x = params.v.x, y = params.v.y}
  }

  bullet.v.x = params.deviation*(0.5-love.math.random())

  table.insert(bullets, bullet)
end

function shootBlackHole(bullets)
  params = weapons.params.blackholegun
  bullet = {
    x = player.x,
    y = player.y - 0.7*player.img:getHeight(),
    img = params.img, weapon = "blackholegun", ttl = params.ttl,
    params = params, v = {x = params.v.x, y = params.v.y}
  }

  bullet.v.x = params.deviation*(0.5-love.math.random())

  table.insert(bullets, bullet)
end

function moveUniform(dt, bullets, i)
  bullet = bullets[i]
  bullet.y = bullet.y - (bullet.v.y * dt)
  bullet.x = bullet.x - (bullet.v.x * dt)

  bullet.ttl = bullet.ttl - dt

  if bullet.y < 0 then
    table.remove(bullets, i)
  end
end

function moveAccel(dt, bullets, i)
  bullet = bullets[i]
  bullet.v.y = bullet.params.accel*dt + bullet.v.y
  bullet.x = bullet.x + (bullet.v.x * dt)
  bullet.y = bullet.y - (bullet.v.y * dt)

  bullet.ttl = bullet.ttl - dt

  if bullet.y < 0 then
    table.remove(bullets, i)
  end
end

function moveBullet(dt, bullets, i)
  bullet = bullets[i]
  bullet.y = bullet.y + bgV*dt

  if bullet.params.type == "bullet" then
    moveUniform(dt, bullets, i)
  elseif bullet.params.type == "rocket" then
    moveAccel(dt, bullets, i)
  end

  if bullet.ttl < 0 or (bullet.mass ~= nil and bullet.mass == 0) then
    if bullet.weapon == "blackholegun" then
      createBlackHole(bullet.x, bullet.y)
    end
    table.remove(bullets, i)
  end
end

function collideBullet(bullet, enemy)
  collided = false
  if bullet.params.type == "bullet" or bullet.params.type == "rocket" then
    collided = simpleCollision(bullet, enemy)
  elseif bullet.weapon == "blackhole" then
    dx = bullet.x - enemy.x
    dy = bullet.y - enemy.y
    collided = dx*dx + dy*dy < bullet.radius*bullet.radius
  end
  if collided then
    enemy.life = enemy.life - bullet.params.dmg
    if bullet.weapon == "blackhole" and enemy.mass ~= nil then
      bullet.mass = bullet.mass - enemy.mass
    end
  end
  return collided
end

function drawBullet(bullet)
  love.graphics.draw(bullet.img, gridPos(bullet.x - bullet.img:getWidth()/2),
                     gridPos(bullet.y - bullet.img:getHeight() / 2))
end

function shoot(bullets)
  if weaponDyn.canShoot then
    weapons.params[weaponDyn.currentWeapon].shootFunc(bullets)
    weaponDyn.canShootTimer = 1/weaponDyn.freq
    weaponDyn.canShoot = false

    --snds = weapons.params[weaponDyn.currentWeapon].sounds
    --playRandomSound(snds)
  end
end
