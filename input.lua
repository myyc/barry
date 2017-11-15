joystick = nil

function love.joystickadded(j)
    joystick = j
end

function handleJoystick(dt)
  if joystick ~= nil then
    if joystick:isGamepadDown("back") then
      byebye()
    end

    if joystick:isGamepadDown("dpleft") then
      move("left", dt)
    end
    if joystick:isGamepadDown("dpright") then
      move("right", dt)
    end
    if joystick:isGamepadDown("dpup") then
      move("up", dt)
    end
    if joystick:isGamepadDown("dpdown") then
      move("down", dt)
    end

    -- shooting
    if joystick:isGamepadDown("a", "b") then
      shoot(bullets)
    end
  end
end

function handleKeyboard(dt)
  if love.keyboard.isDown("escape") then
    byebye()
  end

  if love.keyboard.isDown("left", "a") then
    move("left", dt)
  end
  if love.keyboard.isDown("right", "d") then
    move("right", dt)
  end
  if love.keyboard.isDown("up", "w") then
    move("up", dt)
  end
  if love.keyboard.isDown("down", "s") then
    move("down", dt)
  end

  -- shooting
  if love.keyboard.isDown("space") then
    shoot(bullets)
  end
end

function love.gamepadreleased(joystick, key)
  if key == "triggerleft" or key == "triggerright" then
    mute = not nute
  end
  if not gameover then
    if key == "leftshoulder" or key == "rightshoulder" or key == "x" or key == "y" then
      switchWeapon(key == "leftshoulder"  or key == "x")
    elseif key == "start" then
      paused = not paused
    elseif key == "back" then
      byebye()
    end
  end
end

function love.keyreleased(key)
  if not gameover then
     if key == "shift" or key == "lshift" or key == "rshift" then
       switchWeapon()
     elseif key == "p" then
       paused = not paused
     elseif key == "m" then
       mute = not mute
     elseif key == "q" then
       byebye()
     end
  end
end
