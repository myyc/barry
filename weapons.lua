require "aux"

weapons = {
  names = {"stars", "machinegun", "rockets"},
  params = {
    stars = {
      ttl = 9000,
      speed = 500,
      sprite = "assets/img/star.png",
      img = nil,
      type = "bullet",
      freq = 10,
      dmg = 200,
      shootFunc = nil,
      sounds = {},
    },
    machinegun = {
      ttl = 0.8,
      speed = 800,
      sprite = "assets/img/bullet.png",
      img = nil,
      type = "bullet",
      freq = 50,
      dmg = 30,
      shootFunc = nil,
      sounds = {}
    },
    rockets = {
      ttl = 9000,
      speed = {x = 0, y = 30},
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
    }
  }
}

collisions = {"bullet", "ray", "rocket"}

weaponDyn = {
  weaponIdx = 0,
  currentWeapon = "stars",
  canShoot = true,
  freq = weapons.params.stars.freq,
  canShootTimer = weapons.params.stars.freq,
}

function initWeapons()
  weapons.params.machinegun.img = love.graphics.newImage(weapons.params.machinegun.sprite)
  weapons.params.stars.img = love.graphics.newImage(weapons.params.stars.sprite)
  weapons.params.rockets.img = love.graphics.newImage(weapons.params.rockets.sprite)

  weapons.params.machinegun.shootFunc = shootMachineGun
  weapons.params.stars.shootFunc = shootStar
  weapons.params.rockets.shootFunc = shootRocket

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

function shootStar(bullets)
  params = weapons.params.stars
  bullet = {
    x = player.x,
    y = player.y - 0.7*player.img:getHeight(), img = params.img, weapon = "star", ttl = params.ttl,
    params = params,
  }
  table.insert(bullets, bullet)
end

function shootMachineGun(bullets)
  params = weapons.params.machinegun
  for i = -1, 1, 2 do
    bullet = {
      x = player.x + i*0.33*player.img:getWidth(),
      y = player.y, img = params.img, weapon = "machinegun", ttl = params.ttl,
      params = params,
    }
    table.insert(bullets, bullet)
  end
end

function shootRocket(bullets)
  params = weapons.params.rockets
  bullet = {
    x = player.x,
    y = player.y - 0.7*player.img:getHeight(), img = params.img,
    weapon = "rockets", ttl = params.ttl,
    params = params, speed = {}
  }

  bullet.speed.y = params.speed.y
  bullet.speed.x = params.deviation*(0.5-love.math.random())

  table.insert(bullets, bullet)
end

function moveUniform(dt, bullets, i)
  bullet = bullets[i]
  bullet.y = bullet.y - (bullet.params.speed * dt)

  bullet.ttl = bullet.ttl - dt

  if bullet.y < 0 or bullet.ttl < 0 then
    table.remove(bullets, i)
  end
end

function moveAccel(dt, bullets, i)
  bullet = bullets[i]
  bullet.speed.y = bullet.params.accel*dt + bullet.speed.y
  bullet.x = bullet.x + (bullet.speed.x * dt)
  bullet.y = bullet.y - (bullet.speed.y * dt)

  bullet.ttl = bullet.ttl - dt

  if bullet.y < 0 or bullet.ttl < 0 then
    table.remove(bullets, i)
  end
end

function moveBullet(dt, bullets, i)
  if bullets[i].params.type == "bullet" then
    moveUniform(dt, bullets, i)
  elseif bullets[i].params.type == "rocket" then
    moveAccel(dt, bullets, i)
  end
end

function collideBullet(bullet, enemy)
  collided = false
  if bullet.params.type == "bullet" or bullet.params.type == "rocket" then
    collided = simpleCollision(bullet, enemy)
  end
  if collided then
    enemy.life = enemy.life - bullet.params.dmg
  end
  return collided
end

function drawBullet(bullet)
  if bullet.params.type == "bullet" or bullet.params.type == "rocket" then
    love.graphics.draw(bullet.img, gridPos(bullet.x - bullet.img:getWidth()/2),
                       gridPos(bullet.y - bullet.img:getHeight() / 2))
  end
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
