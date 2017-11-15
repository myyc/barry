function simpleCollision(a, b)
  if a.params then ra = a.params.radius end
  if b.params then rb = b.params.radius end

  r = math.max(ra or (a.img:getWidth() + a.img:getHeight())/4,
               rb or (b.img:getWidth() + b.img:getHeight())/4)

  return math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2) < r*r
end

function playRandomSound(snds)
  if not mute then
    if snds ~= nil then
      n = math.random(#snds)
      if snds[n]:isPlaying() then
        snds[n]:stop()
      end
      snds[n]:play()
    end
  end
end

-- only move in steps of 3 cos this is very pretentious
function gridPos(u)
  return 3*math.floor(u/3)
end
