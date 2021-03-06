local prep_menu = {
  music_playing = false,
}


-- Menu state constants
local NULL_STATE = "null"
local COMMAND_STATE = "command"
local CONNECT_STATE = "connect"


-- Useful module-level variables
local menu_state = NULL_STATE
local timer = 0
local propane_mike_time = 6.9
local propane_mike_msg = lume.once(
  drones.push_backlog_message,
  PROPANE_MIKE .. ": MAGE, call me :)"
)
local propane_mike_call = false
local propane_mike_call_timer = 0


-- Particle system to make menu more interesting
local particle_img = love.graphics.newImage("/media/img/ship.png")
psystem = love.graphics.newParticleSystem(particle_img, 70)
psystem:setParticleLifetime(2, 20) -- Particles live at least 2s and at most 5s.
psystem:setLinearAcceleration(-100, -100, 100, 100)
psystem:setRotation(0, math.pi*2)
psystem:setSpin(-0.5, 0.5)
psystem:setColors(0.3, 0.3, 0.3, 1, 0, 0, 0, 1) -- Fade to black.


-- Clean up this state and move to the next
local function exit_state()
  -- Stop the music
  music["menu"]:stop()

  -- Set the next state
  current_state = "space_combat"
  if ship.start_new_level then
    ship.start_level()
  end
end


function prep_menu:update(dt)
  -- Start the music
  if not prep_menu["music_playing"] then
    music["menu"]:setLooping(true)
    music["menu"]:play()

    prep_menu["music_playing"] = true
  end

  timer = timer + dt

  if timer > propane_mike_time and not propane_mike_call then
    propane_mike_msg()
  end

  if propane_mike_call then
    propane_mike_call_timer = propane_mike_call_timer + dt

    dialogue.update(propane_mike_call_timer)
  end

  if ship.start_main_menu then
    ship.start_menu()
  end

  psystem:update(dt)
  psystem:emit(2)
  ship.update(dt)
end


function prep_menu:draw()
  -- Draw particles
  love.graphics.draw(psystem, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5)

  -- Draw ship
  ship.draw()

  -- Draw the title screen menu
  love.graphics.setFont(font_menu)

  love.graphics.printf(
    "COMMAND [o]",
    0,
    GAME_HEIGHT - 100,
    GAME_WIDTH - 20,
    "right"
  )
  love.graphics.printf(
    "CONNECT [n]",
    0,
    GAME_HEIGHT - 70,
    GAME_WIDTH - 20,
    "right"
  )
  love.graphics.printf(
    "COMMENCE [m]",
    0,
    GAME_HEIGHT - 40,
    GAME_WIDTH - 20,
    "right"
  )

  -- Show the command menu
  if menu_state == COMMAND_STATE then
    -- Draw the menu box
    love.graphics.setColor(1, 1, 1, 0.4)

    love.graphics.rectangle(
      "fill",
      GAME_WIDTH - 500,
      10,
      490,
      340
    )

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.printf(
      "OBJECTIVE FUNCTION",
      GAME_WIDTH - 490,
      20,
      GAME_WIDTH,
      "left"
    )
    love.graphics.printf(
      "[1] " .. MAXIMIZE_NULL,
      GAME_WIDTH - 490,
      50,
      GAME_WIDTH,
      "left"
    )
    love.graphics.printf(
      "[2] " .. MAXIMIZE_DRONE_POPULATION,
      GAME_WIDTH - 490,
      80,
      GAME_WIDTH,
      "left"
    )
    love.graphics.printf(
      "[3] " .. MAXIMIZE_WEAPONS_TECHNOLOGY,
      GAME_WIDTH - 490,
      110,
      GAME_WIDTH,
      "left"
    )
    love.graphics.printf(
      "[4] " .. MAXIMIZE_SHIP_EFFICACY,
      GAME_WIDTH - 490,
      140,
      GAME_WIDTH,
      "left"
    )

    love.graphics.printf(
      "STRATEGY",
      GAME_WIDTH - 490,
      190,
      GAME_WIDTH,
      "left"
    )
    love.graphics.printf(
      "[7] " .. RANDOM_STRATEGY,
      GAME_WIDTH - 490,
      220,
      GAME_WIDTH,
      "left"
    )
    love.graphics.printf(
      "[8] " .. GREEDY_STRATEGY,
      GAME_WIDTH - 490,
      250,
      GAME_WIDTH,
      "left"
    )
    love.graphics.printf(
      "[9] " .. CONSERVATIVE_STRATEGY,
      GAME_WIDTH - 490,
      280,
      GAME_WIDTH,
      "left"
    )
    love.graphics.printf(
      "[0] " .. TIT_FOR_TAT_STRATEGY,
      GAME_WIDTH - 490,
      310,
      GAME_WIDTH,
      "left"
    )
  elseif menu_state == CONNECT_STATE then
    -- Draw the menu box
    love.graphics.setColor(1, 1, 1, 0.4)

    love.graphics.rectangle(
      "fill",
      GAME_WIDTH - 500,
      10,
      490,
      140
    )

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.printf(
      "CONNECT",
      GAME_WIDTH - 490,
      20,
      GAME_WIDTH,
      "left"
    )
    love.graphics.printf(
      "[1] " .. PROPANE_MIKE,
      GAME_WIDTH - 490,
      50,
      GAME_WIDTH,
      "left"
    )
  end

  love.graphics.setFont(font_default)
end


function prep_menu:keypressed(key)
  if key == "m" then
    local prep_menu_sound1 = sfx["menu_long_01"]:clone()
    prep_menu_sound1:play()

    exit_state()
  end

  local prep_menu_sound2 = sfx["menu_short_01"]:clone()
  local prep_menu_sound3 = sfx["menu_short_02"]:clone()

  if menu_state == NULL_STATE then
    if key == "o" then
      menu_state = COMMAND_STATE
      prep_menu_sound2:play()
    end
    if key == "n" then
      menu_state = CONNECT_STATE
      prep_menu_sound2:play()
    end
  elseif menu_state == COMMAND_STATE then
    if key == "o" then
      menu_state = NULL_STATE
      prep_menu_sound2:play()
    elseif key == "n" then
      menu_state = CONNECT_STATE
      prep_menu_sound2:play()
    elseif key == "1" then
      drones["swarm_objective"] = MAXIMIZE_NULL
      prep_menu_sound3:play()
    elseif key == "2" then
      drones["swarm_objective"] = MAXIMIZE_DRONE_POPULATION
      prep_menu_sound3:play()
    elseif key == "3" then
      drones["swarm_objective"] = MAXIMIZE_WEAPONS_TECHNOLOGY
      prep_menu_sound3:play()
    elseif key == "4" then
      drones["swarm_objective"] = MAXIMIZE_SHIP_EFFICACY
      prep_menu_sound3:play()
    elseif key == "7" then
      drones["swarm_strategy"] = RANDOM_STRATEGY
      prep_menu_sound3:play()
    elseif key == "8" then
      drones["swarm_strategy"] = GREEDY_STRATEGY
      prep_menu_sound3:play()
    elseif key == "9" then
      drones["swarm_strategy"] = CONSERVATIVE_STRATEGY
      prep_menu_sound3:play()
    elseif key == "0" then
      drones["swarm_strategy"] = TIT_FOR_TAT_STRATEGY
      prep_menu_sound3:play()
    end
  else
    if key == "o" then
      menu_state = COMMAND_STATE
      prep_menu_sound2:play()
    elseif key == "n" then
      menu_state = NULL_STATE
      prep_menu_sound2:play()
    elseif key == "1" then
      prep_menu_sound3:play()
      propane_mike_call = true
    end
  end
end

return prep_menu
