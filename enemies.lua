-- static enemy params
enemyParams = {
  names = {}, -- filled programmatically
  params = {
    dumb = {
      vAvg = {x = 0, y = 100},
      speedBand = 0.1,
      sprite = "assets/img/invader1.png",
      life = 100,
    },
    wavy = {
      k = {x = 40, y = 0},
      vAvg = {x = 250, y = 80},
      dAvg = {x = 100, y = 0},
      speedBand = 0.1,
      sprite = "assets/img/invader2.png",
      life = 80,
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

function addWavyParams(enemy, dt)
  s = 2*math.random(0,1)-1
  dv = s*math.exp(love.math.randomNormal(0.3, 0))

  enemy.d = {x = dv*enemy.params.dAvg.x, y = 0}
  enemy.k = enemy.params.k

  enemy.x = enemy.x + enemy.d.x
  enemy.y = enemy.y + enemy.d.y

  enemy.v.y = enemy.params.vAvg.y
end

function initEnemies()
  enemyParams.params.dumb.addParams = function() end
  enemyParams.params.wavy.addParams = addWavyParams

  for type, params in pairs(enemyParams.params) do
    params.img = love.graphics.newImage(params.sprite)
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
      img = img,
      v = {
        x = 0,
        y = (1 + params.speedBand / 2 - params.speedBand*math.random()) * params.vAvg.y
      },
      life = params.life,
      type = type,
      params = params
    }

    enemy.params.addParams(enemy, dt)

    table.insert(enemies, enemy)
  end
end

function enemiesCollide(dt)
  -- collision between enemies and stuff
  for j, enemy in ipairs(enemies) do
    -- bullets
    for i, bullet in ipairs(bullets) do
      if collideBullet(bullet, enemy) then
         table.remove(bullets, i)
      end
    end

    if enemy.life <= 0 then
      table.remove(enemies, j)
      evolDyn.killed = evolDyn.killed + 1
      evolDyn.stopGettingHarder = false
      --playRandomSound(enemyDyn.sounds)
    end

    -- yourself (to be made a bit more difficult)
    if simpleCollision(player, enemy) then
      enemies = {}
      lives = lives - 1
      --playRandomSound(playerDyn.sounds)
      initPlayer()
      if lives == 0 then gameover = true end
      break
    end
  end
end

function moveStraight(dt, o)
  o.y = o.y + (o.v.y * dt)
  o.x = o.x + (o.v.x * dt)
end

function moveWavy(dt, o)
  o.v.x = -o.k.x*o.d.x*dt + o.v.x
  o.d.x = o.d.x + o.v.x*dt
  o.x = o.x + o.v.x * dt

  o.y = o.y + (o.v.y * dt)
end

function enemiesMove(dt)
  for i, enemy in ipairs(enemies) do
    if enemy.type == "dumb" then
      moveStraight(dt, enemy)
    elseif enemy.type == "wavy" then
      moveWavy(dt, enemy)
    end

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
