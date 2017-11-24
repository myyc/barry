-- static enemy params
enemyParams = {
  names = {"dumb", "wavy", "brownian", "staticShooter"}, -- filled programmatically
  params = {
    dumb = {
      vAvg = {x = 0, y = 100},
      m = 100,
      speedBand = 0.1,
      sprite = "assets/img/invader1.png",
      life = 100,
      motion = "uniform",
    },
    wavy = {
      k = {x = 5, y = 0},
      m = 100,
      vAvg = {x = 350, y = 80},
      speedBand = 0.1,
      sprite = "assets/img/invader2.png",
      motion = "uniform",
      life = 80,
    },
    brownian = {
      v = {x = 0, y = 30},
      m = 100,
      vAvg = {x = 0, y = 120},
      acc = {x = 0, y = 1000},
      initialTimeout = 0.5,
      sprite = "assets/img/invader3.png",
      motion = "uniform",
      life = 80,
    },
    staticShooter = {
      v = {x = 0, y = 0},
      a = {x = 0, y = 0},
      motion = "still",
      sprite = "assets/img/sshooter.png",
      life = 300,
      freq = 5,
      initialTimeout = 2,
      bullets = 6,
      bulletType = "simple",
    },
    simpleBullet = {
      m = 30,
      avgSpeed = 200,
      life = 1,
      sprite = "assets/img/bullet.png"
    }
  }
}

enemyDyn = {
  dumb = {
    img = nil,
    sounds = {},
  }
}

enemyState = {
  alive = 1,
  dying = 2
}

enemies = {}

function addSSParams(enemy, dt)
  enemy.bullets = enemy.params.bullets
end

function addWavyParams(enemy, dt)
  s = 2*math.random(0,1)-1
  dv = s*math.exp(love.math.randomNormal(0.3, 0))

  enemy.k = {x = enemy.params.k.x, y = enemy.params.k.y}
  enemy.xc = enemy.x

  enemy.v.y = enemy.params.vAvg.y
  enemy.v.x = enemy.params.vAvg.x * dv
end

function addBrownianParams(enemy, dt)
  enemy.acc = {x = enemy.params.acc.x, y = enemy.params.acc.y}
  enemy.braking = false
end

function initEnemies()
  enemyParams.params.wavy.addParams = addWavyParams
  enemyParams.params.brownian.addParams = addBrownianParams
  enemyParams.params.staticShooter.addParams = addSSParams

  for type, params in pairs(enemyParams.params) do
    params.img = love.graphics.newImage(params.sprite)
    if params.bulletParams ~= nil then
      params.bulletParams.img = love.graphics.newImage(params.bulletParams.sprite)
    end
  end
end

function enemiesGenerate(dt)
  if love.math.random() < evolParams.thrsh * evolDyn.thrshm then
    type = enemyParams.names[math.random(1, #(enemyParams.names))]
    --type = "brownian"

    params = enemyParams.params[type]
    img = params.img
    if params.a ~= nil then
      a = {x = params.a.x, y = params.a.y}
    else
      a = {x = 0, y = 0}
    end

    enemy = {
      x = love.math.random()*(love.graphics.getWidth() - img:getWidth()),
      y = - img:getHeight() - 5,
      a = a,
      m = params.m,
      img = img,
      life = params.life,
      type = type,
      params = params
    }

    if params.motion == "uniform" and params.v == nil then
      enemy.v = {
        x = 0,
        y = (1 + params.speedBand / 2 - params.speedBand*math.random()) * params.vAvg.y
      }
    else -- still
      enemy.v = {x = 0, y = 0}
    end

    if params.initialTimeout ~= nil then
      enemy.timeout = params.initialTimeout
    end

    if enemy.params.addParams ~= nil then
      enemy.params.addParams(enemy, dt)
    end

    table.insert(enemies, enemy)
  end
end

function enemiesCollide(dt)
  -- collision between enemies and stuff
  for i, bullet in ipairs(bullets) do
    collided = false
    for j, enemy in ipairs(enemies) do
      if collideBullet(bullet, enemy) then
        collided = true
      end
    end
    if collided then
      if bullet.params.explosion ~= nil then
        anim = newAnimation(bullet.params.explosion, bullet.x, bullet.y)
        table.insert(explosions, anim)
      end
      table.remove(bullets, i)
    end
  end

  for j, enemy in ipairs(enemies) do
    -- bullets
    if enemy.life <= 0 then
      if enemy.params.explosion ~= nil then
        expl = enemy.params.explosion
      else
        expl = genericEnemyExplosion
      end
      anim = newAnimation(expl, enemy.x, enemy.y)
      table.insert(explosions, anim)
      table.remove(enemies, j)
      evolDyn.killed = evolDyn.killed + 1
      evolDyn.stopGettingHarder = false
      --playRandomSound(enemyDyn.sounds)
    end

    -- yourself
    if enemy.params.motion ~= "still" then
      if simpleCollision(player, enemy) then
        expl = genericEnemyExplosion
        anim = newAnimation(expl, player.x, player.y)
        table.insert(explosions, anim)
        loseOneLife()
        break
      end
    end
  end
end

function inertia(dt, o)
  o.v.x = o.v.x + o.a.x*dt
  o.v.y = o.v.y + o.a.y*dt

  o.y = o.y + (o.v.y * dt)
  o.x = o.x + (o.v.x * dt)
end

function moveWavy(dt, o)
  sgn = 1
  if o.x < o.xc then sgn = -1 end

  o.a.x = o.a.x - sgn * o.k.x*math.pow(o.x - o.xc, 2)/o.m
end

function moveBrownian(dt, o)
  if o.timeout < o.params.initialTimeout / 2 and o.timeout > 0 then
    if not o.braking then
      o.acc.x = -o.acc.x
      o.acc.y = -o.acc.y
      o.braking = true
    end
  elseif o.timeout < 0 then
    o.braking = false
    t = math.random(0, math.pi)
    o.acc.x = o.params.acc.y*math.cos(t)
    o.acc.y = o.params.acc.y*math.sin(t)

    o.timeout = o.params.initialTimeout
  end

  o.a.x = o.a.x + o.acc.x
  o.a.y = o.a.y + o.acc.y

  o.timeout = o.timeout - dt
end

function shootAimingBullet(dt, enemy, params)
  bullet = {
    x = enemy.x,
    y = enemy.y, img = params.img,
    m = params.m,
    life = params.life,
    params = params,
  }

  dx = player.x - enemy.x
  dy = player.y - enemy.y
  d = math.sqrt(dx*dx + dy*dy)

  bullet.v = {x = params.avgSpeed*dx/d,
              y = params.avgSpeed*dy/d}

  bullet.a = {x = 0, y = 0}

  table.insert(enemies, bullet)
end

function enemyActivate(dt, enemy)
  if enemy.type == "staticShooter" then
    if enemy.timeout ~= nil then
      enemy.timeout = enemy.timeout - dt
      if enemy.timeout < 0 then
        shootAimingBullet(dt, enemy, enemyParams.params.simpleBullet)

        enemy.bullets = enemy.bullets - 1
        if enemy.bullets == 0 then
          enemy.bullets = enemy.params.bullets
          enemy.timeout = enemy.params.initialTimeout
        else
          enemy.timeout = 1/enemy.params.freq
        end
      end
    end
  elseif enemy.type == "brownian" then
    if math.random() < 0.01 then
      shootAimingBullet(dt, enemy, enemyParams.params.simpleBullet)
    end
  end
end

function addGravity(dt, enemy)
  for i, bullet in ipairs(bullets) do
    if bullet.weapon == "blackhole" then
      if enemy.m ~= nil then
        dx = enemy.x - bullet.x
        dy = enemy.y - bullet.y
        d = math.sqrt(dx*dx + dy*dy)

        fc = bullet.gravc / (d*d*d)
        enemy.a.x = enemy.a.x - dx*fc/enemy.m
        enemy.a.y = enemy.a.y - dy*fc/enemy.m
      end
    end
  end
end

function enemiesMove(dt)
  for i, enemy in ipairs(enemies) do
    enemy.a = {x = 0, y = 0}
    addGravity(dt, enemy)

    if enemy.type == "wavy" then
      moveWavy(dt, enemy)
    elseif enemy.type == "brownian" then
      moveBrownian(dt, enemy)
    end

    inertia(dt, enemy)

    -- move with the background
    enemy.y = enemy.y + bgV*dt

    enemyActivate(dt, enemy)

    if enemy.y + enemy.img:getHeight() > love.graphics.getHeight() then
      table.remove(enemies, i)
    end
  end
end

function enemiesDraw(dt)
  for i, enemy in ipairs(enemies) do
    love.graphics.draw(enemy.img, gridPos(enemy.x - enemy.img:getWidth()/2),
                       gridPos(enemy.y - enemy.img:getHeight()/2))
  end
end
