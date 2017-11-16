-- static enemy params
enemyParams = {
  names = {}, -- filled programmatically
  params = {
    dumb = {
      a = {x = 0, y = 0},
      v = {x = 0, y = 0},
      vAvg = {x = 0, y = 100},
      speedBand = 0.1,
      sprite = "assets/img/invader1.png",
      life = 100,
      motion = "uniform",
    },
    wavy = {
      a = {x = 0, y = 0},
      v = {x = 0, y = 0},
      k = {x = 20, y = 0},
      vAvg = {x = 350, y = 80},
      dAvg = {x = 100, y = 0},
      speedBand = 0.1,
      sprite = "assets/img/invader2.png",
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
      bulletParams = {
        avgSpeed = 200,
        sprite = "assets/img/bullet.png"
      }
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

enemyBullets = {}

function addSSParams(enemy, dt)
  enemy.bulletParams = enemy.params.bulletParams
  enemy.bullets = enemy.params.bullets
end

function addWavyParams(enemy, dt)
  s = 2*math.random(0,1)-1
  dv = s*math.exp(love.math.randomNormal(0.3, 0))

  enemy.k = enemy.params.k
  enemy.xc = enemy.x

  enemy.v.y = enemy.params.vAvg.y
  enemy.v.x = enemy.params.vAvg.x*dv
end

function initEnemies()
  enemyParams.params.dumb.addParams = function() end
  enemyParams.params.wavy.addParams = addWavyParams
  enemyParams.params.staticShooter.addParams = addSSParams

  for type, params in pairs(enemyParams.params) do
    params.img = love.graphics.newImage(params.sprite)
    if params.bulletParams ~= nil then
      params.bulletParams.img = love.graphics.newImage(params.bulletParams.sprite)
    end
    table.insert(enemyParams.names, type)
    --enemyDyn[type].vAvg = params.vAvg
  end
end

function enemiesGenerate(dt)
  if love.math.random() < evolParams.thrsh * evolDyn.thrshm then
    type = enemyParams.names[math.random(1, #(enemyParams.names))]
    params = enemyParams.params[type]
    img = params.img
    enemy = {
      x = love.math.random()*(love.graphics.getWidth() - img:getWidth()),
      y = - img:getHeight() - 5,
      v = {x = params.v.x, y = params.v.y},
      a = {x = params.a.x, y = params.a.y},
      img = img,
      life = params.life,
      type = type,
      params = params
    }

    if params.motion == "uniform" then
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

    enemy.params.addParams(enemy, dt)

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
      table.remove(bullets, i)
    end
  end

  for i, bullet in ipairs(enemyBullets) do
    if simpleCollision(player, bullet) then
      loseOneLife()
      break
    end
  end

  for j, enemy in ipairs(enemies) do
    -- bullets
    if enemy.life <= 0 then
      table.remove(enemies, j)
      evolDyn.killed = evolDyn.killed + 1
      evolDyn.stopGettingHarder = false
      --playRandomSound(enemyDyn.sounds)
    end

    -- yourself (to be made a bit more difficult)
    if simpleCollision(player, enemy) then
      loseOneLife()
      break
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
  o.a.x = o.a.x - o.k.x*(o.x - o.xc)
end

function enemyActivate(dt, enemy)
  if enemy.type == "staticShooter" then
    params = enemy.bulletParams
    bullet = {
      x = enemy.x,
      y = enemy.y, img = params.img,
      params = params,
    }

    dx = player.x - enemy.x
    dy = player.y - enemy.y
    d = math.sqrt(dx*dx + dy*dy)

    bullet.v = {x = params.avgSpeed*dx/d,
                y = params.avgSpeed*dy/d}

    bullet.a = {x = 0, y = 0}

    table.insert(enemyBullets, bullet)
    enemy.bullets = enemy.bullets - 1
    if enemy.bullets == 0 then
      enemy.bullets = enemy.params.bullets
      enemy.timeout = enemy.params.initialTimeout
    else
      enemy.timeout = 1/enemy.params.freq
    end
  end
end

function enemiesMove(dt)
  for i, enemy in ipairs(enemies) do
    enemy.a = {x = enemy.params.a.x, y = enemy.params.a.y}
    for i, bullet in ipairs(bullets) do
      if bullet.weapon == "blackhole" then
        if enemy.params.motion ~= "still" then
          dx = enemy.x - bullet.x
          dy = enemy.y - bullet.y
          d = math.sqrt(dx*dx + dy*dy)

          fc = bullet.gravc * 1000 / (d*d*d)
          enemy.a.x = -dx*fc
          enemy.a.y = -dy*fc
        end
      end
    end

    if enemy.type == "wavy" then
      moveWavy(dt, enemy)
    end

    inertia(dt, enemy)

    -- move with the background
    enemy.y = enemy.y + bgV*dt

    if enemy.timeout ~= nil then
      enemy.timeout = enemy.timeout - dt
      if enemy.timeout < 0 then
        enemyActivate(dt, enemy)
      end
    end

    if enemy.y + enemy.img:getHeight() > love.graphics.getHeight() then
      table.remove(enemies, i)
    end
  end

  for i, bullet in ipairs(enemyBullets) do
    inertia(dt, bullet)
    bullet.y = bullet.y + bgV*dt
    if bullet.x < 10 or bullet.x > love.graphics.getWidth() + 10
    or bullet.y < 10 or bullet.y > love.graphics.getWidth() + 10 then
      table.remove(enemyBullets, i)
    end
  end
end

function enemiesDraw(dt)
  for i, enemy in ipairs(enemies) do
    love.graphics.draw(enemy.img, gridPos(enemy.x - enemy.img:getWidth()/2),
                       gridPos(enemy.y - enemy.img:getHeight()/2))
  end

  for i, bullet in ipairs(enemyBullets) do
    love.graphics.draw(bullet.img, gridPos(bullet.x - bullet.img:getWidth()/2),
                       gridPos(bullet.y - bullet.img:getHeight()/2))
  end
end
