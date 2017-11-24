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

weaponInv = {}

currentWeapon = nil
secondaryWeapon = weapons.params.blackholegun

blackHoleParams = {
  mass = 400,
  sprite = "assets/img/blackhole2.png",
  gravc = 2000000000,
  radius = 60,
  dmg = 999999
}

function initWeapon(weapon)
  weapon.dyn = {
    canShoot = true,
    freq = weapon.freq,
    canShootTimer = 1/weapon.freq,
  }
end

function selectWeapon(weapon)
  initWeapon(weapon)
  currentWeapon = weapon
end

function reallySwitchWeapon(back)
  idx = (weaponInv[currentWeapon.name] + (back and -1 or 1)) % #weapons.names
  currentWeapon = weapons.params[weapons.names[idx+1]]
  currentWeapon:select()
end

function switchWeapon(back)
  if shootMode == shootModes.rotating then
    reallySwitchWeapon(back)
  elseif shootMode == shootModes.primarySecondary then
    repeat reallySwitchWeapon(back)
    until currentWeapon ~= secondaryWeapon
  end
end

function initWeapons()
  weapons.params.machinegun.img = love.graphics.newImage(weapons.params.machinegun.sprite)
  weapons.params.stars.img = love.graphics.newImage(weapons.params.stars.sprite)
  weapons.params.rockets.img = love.graphics.newImage(weapons.params.rockets.sprite)
  weapons.params.blackholegun.img = love.graphics.newImage(weapons.params.blackholegun.sprite)

  blackHoleParams.img = love.graphics.newImage(blackHoleParams.sprite)

  weapons.params.machinegun.select = selectWeapon
  weapons.params.stars.select = selectWeapon
  weapons.params.rockets.select = selectWeapon
  weapons.params.blackholegun.select = selectWeapon

  weapons.params.machinegun.shoot = shootMachineGun
  weapons.params.stars.shoot = shootStar
  weapons.params.rockets.shoot = shootRocket
  weapons.params.blackholegun.shoot = shootBlackHole

  i = 0
  for name, params in pairs(weapons.params) do
    table.insert(weapons.names, name)
    weaponInv[name] = i
    params.name = name
    i = i + 1
  end

  currentWeapon = weapons.params.stars
  currentWeapon:select()

  if shootMode == shootModes.primarySecondary then
    initWeapon(secondaryWeapon)
  end
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

function shootStar()
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

function shootMachineGun()
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

function shootRocket()
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

function shootBlackHole()
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

function moveUniform(dt, i)
  bullet = bullets[i]
  bullet.y = bullet.y - (bullet.v.y * dt)
  bullet.x = bullet.x - (bullet.v.x * dt)

  bullet.ttl = bullet.ttl - dt

  if bullet.y < 0 then
    table.remove(bullets, i)
  end
end

function moveAccel(dt, i)
  bullet = bullets[i]
  bullet.v.y = bullet.params.accel*dt + bullet.v.y
  bullet.x = bullet.x + (bullet.v.x * dt)
  bullet.y = bullet.y - (bullet.v.y * dt)

  bullet.ttl = bullet.ttl - dt

  if bullet.y < 0 then
    table.remove(bullets, i)
  end
end

function moveBullet(dt, i)
  bullet = bullets[i]
  bullet.y = bullet.y + bgV*dt

  if bullet.params.type == "bullet" then
    moveUniform(dt, i)
  elseif bullet.params.type == "rocket" then
    moveAccel(dt, i)
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

function shootWeaponIfPossible(weapon)
  if weapon.dyn.canShoot then
    weapon:shoot()
    weapon.dyn.canShootTimer = 1/weapon.freq
    weapon.dyn.canShoot = false
  end
end

function shoot(weapon)
  if shootMode == shootModes.rotating then
    shootWeaponIfPossible(currentWeapon)
  elseif shootMode == shootModes.primarySecondary then
    if weapon == nil then
      weapon = currentWeapon
    end
    shootWeaponIfPossible(weapon)
  end
end

function adjustWeaponTimers(dt, weapon)
  weapon.dyn.canShootTimer = weapon.dyn.canShootTimer - (1 * dt)
  if weapon.dyn.canShootTimer < 0 then
    weapon.dyn.canShoot = true
  end
end
