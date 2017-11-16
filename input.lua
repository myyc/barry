joystick = nil

function love.joystickadded(j)
    joystick = j
end

function isReasonable(key)
  return key ~= "shift" and key ~= "lshift" and key ~= "rshift" and
    key ~= "up" and key ~= "down" and key ~= "left" and key ~= "right"
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
    switchToMenu()
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
  if gameState == gameStates.level then
    if not gameover then
      if key == "leftshoulder" or key == "rightshoulder" or key == "x" or key == "y" then
        switchWeapon(key == "leftshoulder"  or key == "x")
      elseif key == "start" then
        paused = not paused
      elseif key == "back" then
        switchToMenu()
      end
    else
      if gameoverTimeout < 0 then
        gameover = false
        if key == "back" then
          byebye()
        else
          switchToMenu()
        end
      end
    end
  elseif gameState == "menu" and isMenuIdle() then
    if key == "back" then
      byebye()
    else
      gameState = gameStates.level
      resetLevelState()
    end
  end
end

function love.keyreleased(key)
  if gameState == gameStates.level then
    if not gameover then
       if key == "shift" or key == "lshift" or key == "rshift" then
         switchWeapon()
       elseif key == "p" then
         paused = not paused
       elseif key == "m" then
         mute = not mute
       elseif key == "q" then
         switchToMenu()
       end
    else
      if gameoverTimeout < 0 then
        gameover = false
        if key == "q" or key == "escape" then
          byebye()
        else
          switchToMenu()
        end
      end
    end
  elseif gameState == gameStates.menu and isMenuIdle() then
    if key == "q" or key == "escape" then
      byebye()
    elseif isReasonable(key) then
      gameState = gameStates.level
      resetLevelState()
    end
  end
end
