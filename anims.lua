explosions = {}

genericEnemyExplosion = nil

fps = 18

function newAnimation(anim, x, y)
  return {
    anim = anim,
    x = x,
    y = y,
    time = 0,
    maxTime = anim.frames / fps
  }
end

function initAnimations()
  simpleBulletExplosion = loadAnimation(love.graphics.newImage("assets/img/bulletexpl.png"), 15, 15)
  rocketExplosion = loadAnimation(love.graphics.newImage("assets/img/missileexpl.png"), 39, 39)
  stargunExplosion = loadAnimation(love.graphics.newImage("assets/img/starexpl.png"), 27, 27)
  blackHoleImplosion = loadAnimation(love.graphics.newImage("assets/img/blackholeexpl.png"), 33, 39)

  genericEnemyExplosion = loadAnimation(love.graphics.newImage("assets/img/genericenemyexpl.png"), 54, 54)

  weapons.params.machinegun.explosion = simpleBulletExplosion
  enemyParams.params.simpleBullet.explosion = simpleBulletExplosion
  weapons.params.rockets.explosion = rocketExplosion
  weapons.params.stars.explosion = stargunExplosion
  blackHoleParams.explosion = blackHoleImplosion
end

function loadAnimation(image, width, height)
  anim = {}
  anim.img = image
  anim.quads = {}
  anim.frames = 0
  anim.width = width
  anim.height = height

  for y = 0, image:getHeight() - height, height do
    for x = 0, image:getWidth() - width, width do
      table.insert(anim.quads, love.graphics.newQuad(x, 0, width, height, image:getDimensions()))
      anim.frames = anim.frames + 1
    end
  end

  return anim
end

function explosionsProcess(dt)
  for i, anim in ipairs(explosions) do
    anim.time = anim.time + dt
    anim.y = anim.y + bgV*dt
    if anim.time >= anim.maxTime then
      table.remove(explosions, i)
    end
  end
end

function explosionsDraw(dt)
  for i, anim in ipairs(explosions) do
    frame = math.floor(anim.time*fps)+1
    love.graphics.draw(anim.anim.img, anim.anim.quads[frame], gridPos(anim.x - anim.anim.width/2),
                       gridPos(anim.y - anim.anim.height/2))
  end
end
