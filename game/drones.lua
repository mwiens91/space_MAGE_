local drones = {
  -- Drone counts
  drone_counts = {
    drones_attack = STARTING_ATTACK_DRONES,
    drones_exploration = STARTING_EXPLORATION_DRONES,
    drones_mining = STARTING_MINING_DRONES,
  },

  -- Count the number of drone births and deaths we have so we know when
  -- to create and destroy clusters
  drone_birth_counts = {
    drones_attack = STARTING_ATTACK_DRONES % DRONE_CLUSTER_SIZE,
    drones_exploration = STARTING_EXPLORATION_DRONES % DRONE_CLUSTER_SIZE,
    drones_mining = STARTING_MINING_DRONES % DRONE_CLUSTER_SIZE,
  },
  drone_death_counts = {
    drones_attack = 0,
    drones_exploration = 0,
    drones_mining = 0
  },

  -- Drone cluster names
  drone_clusters = {
    clusters_attack = {},
    clusters_exploration = {},
    clusters_mining = {},
  },

  -- Drone message log
  drone_log = {},

  -- Drone message backlog
  drone_backlog = {},

  -- Remember the last N drone counts drone counts
  drone_count_queue = {},

  -- Swarm objective and strategy
  swarm_objective = MAXIMIZE_NULL,
  swarm_strategy = TIT_FOR_TAT_STRATEGY,

  -- Swarm morale
  swarm_morale = 69,

  -- Swarm experience
  special_weapons_xp = 0,
  heat_sink_xp = 0,
  movement_xp = 0,
  shields_xp = 0,
}


-- Push a message directly to the drone log
function drones.push_message(msg)
  lume.push(drones["drone_log"], msg)

  if #drones["drone_log"] > MAX_DRONE_MESSAGES then
    table.remove(drones["drone_log"], 1)
  end
end


-- Push a message to the drone backlog
function drones.push_backlog_message(msg)
  lume.push(drones["drone_backlog"], msg)
end


-- Seed drone_count_queue
function drones.seed_drone_count_queue()
  local total_drones = drones.get_total_drones()

  for i=1,DRONE_COUNT_QUEUE_LENGTH do
    lume.push(drones["drone_count_queue"], total_drones)
  end
end


-- Update drone_count_queue
function drones.update_drone_count_queue()
  table.remove(drones["drone_count_queue"])
  table.insert(drones["drone_count_queue"], 1, drones.get_total_drones())
end


-- Update drone birth and death counts
function drones.update_drone_birth_and_death_counts(old_counts)
  -- TODO make this function not disgusting

  -- Find the differences (deltas)
  local delta_attack = drones["drone_counts"]["drones_attack"] - old_counts["drones_attack"]
  local delta_exploration = drones["drone_counts"]["drones_exploration"] - old_counts["drones_exploration"]
  local delta_mining = drones["drone_counts"]["drones_mining"] - old_counts["drones_mining"]

  -- Add the numbers to the birth and death counts
  if delta_attack >= 0 then
    drones["drone_birth_counts"]["drones_attack"] = drones["drone_birth_counts"]["drones_attack"] + delta_attack

    if drones["drone_birth_counts"]["drones_attack"] >= DRONE_CLUSTER_SIZE then
      drones["drone_birth_counts"]["drones_attack"] = drones["drone_birth_counts"]["drones_attack"] - DRONE_CLUSTER_SIZE
      drones.create_drone_cluster(ATTACK_TYPE)
    end
  else
    drones["drone_death_counts"]["drones_attack"] = drones["drone_death_counts"]["drones_attack"] - delta_attack

    if drones["drone_death_counts"]["drones_attack"] >= DRONE_CLUSTER_SIZE and #drones["drone_clusters"]["clusters_attack"] ~= 0 then
      drones["drone_death_counts"]["drones_attack"] = drones["drone_death_counts"]["drones_attack"] - DRONE_CLUSTER_SIZE
      drones.destroy_drone_cluster(ATTACK_TYPE)
    end
  end

  if delta_exploration >= 0 then
    drones["drone_birth_counts"]["drones_exploration"] = drones["drone_birth_counts"]["drones_exploration"] + delta_exploration

    if drones["drone_birth_counts"]["drones_exploration"] >= DRONE_CLUSTER_SIZE then
      drones["drone_birth_counts"]["drones_exploration"] = drones["drone_birth_counts"]["drones_exploration"] - DRONE_CLUSTER_SIZE
      drones.create_drone_cluster(EXPLORE_TYPE)
    end
  else
    drones["drone_death_counts"]["drones_exploration"] = drones["drone_death_counts"]["drones_exploration"] - delta_exploration

    if drones["drone_death_counts"]["drones_exploration"] >= DRONE_CLUSTER_SIZE and #drones["drone_clusters"]["clusters_exploration"] ~= 0 then
      drones["drone_death_counts"]["drones_exploration"] = drones["drone_death_counts"]["drones_exploration"] - DRONE_CLUSTER_SIZE
      drones.destroy_drone_cluster(EXPLORE_TYPE)
    end
  end

  if delta_mining >= 0 then
    drones["drone_birth_counts"]["drones_mining"] = drones["drone_birth_counts"]["drones_mining"] + delta_mining

    if drones["drone_birth_counts"]["drones_mining"] >= DRONE_CLUSTER_SIZE then
      drones["drone_birth_counts"]["drones_mining"] = drones["drone_birth_counts"]["drones_mining"] - DRONE_CLUSTER_SIZE
      drones.create_drone_cluster(MINE_TYPE)
    end
  else
    drones["drone_death_counts"]["drones_mining"] = drones["drone_death_counts"]["drones_mining"] - delta_mining

    if drones["drone_death_counts"]["drones_mining"] >= DRONE_CLUSTER_SIZE and #drones["drone_clusters"]["clusters_mining"] ~= 0 then
      drones["drone_death_counts"]["drones_mining"] = drones["drone_death_counts"]["drones_mining"] - DRONE_CLUSTER_SIZE
      drones.destroy_drone_cluster(MINE_TYPE)
    end
  end
end


-- Get total drones
function drones.get_total_drones()
  return (
    drones["drone_counts"]["drones_attack"]
    + drones["drone_counts"]["drones_exploration"]
    + drones["drone_counts"]["drones_mining"]
  )
end


-- Get percentage change of drones.
function drones.get_total_drone_percentage_change()
  local new_count = drones["drone_count_queue"][1]
  local old_count = drones["drone_count_queue"][DRONE_COUNT_QUEUE_LENGTH]
  local percent_change = (new_count - old_count) / old_count * 100

  return percent_change
end


-- Seed drone clusters
function drones.seed_drone_clusters()
  local num_attack_drones = drones["drone_counts"]["drones_attack"]
  local num_exploration_drones = drones["drone_counts"]["drones_exploration"]
  local num_mining_drones = drones["drone_counts"]["drones_mining"]

  local num_attack_clusters = math.floor(num_attack_drones / DRONE_CLUSTER_SIZE)
  local num_exploration_clusters = math.floor(num_exploration_drones / DRONE_CLUSTER_SIZE)
  local num_mining_clusters = math.floor(num_mining_drones / DRONE_CLUSTER_SIZE)

  local fealty_messages = {}

  for i=1,num_attack_clusters do
    local cluster_name = name_generation.generate_cluster_name(ATTACK_TYPE)

    lume.push(
      drones["drone_clusters"]["clusters_attack"],
      cluster_name
    )
    lume.push(fealty_messages, dialogue_generation.fealty_announcement(cluster_name))
  end

  for i=1,num_exploration_clusters do
    local cluster_name = name_generation.generate_cluster_name(EXPLORE_TYPE)

    lume.push(
      drones["drone_clusters"]["clusters_exploration"],
      cluster_name
    )
    lume.push(fealty_messages, dialogue_generation.fealty_announcement(cluster_name))
  end

  for i=1,num_mining_clusters do
    local cluster_name = name_generation.generate_cluster_name(MINE_TYPE)

    lume.push(
      drones["drone_clusters"]["clusters_mining"],
      cluster_name
    )
    lume.push(fealty_messages, dialogue_generation.fealty_announcement(cluster_name))
  end

  -- Push fealty messages to the drone backlog
  for _, msg in ipairs(lume.shuffle(fealty_messages)) do
    drones.push_backlog_message(msg)
  end
end


-- Create a drone cluster
function drones.create_drone_cluster(drone_type)
  local cluster_name = ""

  if drone_type == ATTACK_TYPE then
    cluster_name = name_generation.generate_cluster_name(ATTACK_TYPE)

    lume.push(
      drones["drone_clusters"]["clusters_attack"],
      cluster_name
    )
  elseif drone_type == EXPLORE_TYPE then
    cluster_name = name_generation.generate_cluster_name(EXPLORE_TYPE)

    lume.push(
      drones["drone_clusters"]["clusters_exploration"],
      cluster_name
    )
  else
    cluster_name = name_generation.generate_cluster_name(MINE_TYPE)

    lume.push(
      drones["drone_clusters"]["clusters_mining"],
      cluster_name
    )
  end

  drones.push_backlog_message(dialogue_generation.fealty_announcement(cluster_name))
end


-- Destroy a drone cluster
function drones.destroy_drone_cluster(drone_type)
  local cluster_name = ""

  if drone_type == ATTACK_TYPE then
    cluster_name = table.remove(
      drones["drone_clusters"]["clusters_attack"],
      math.random(#drones["drone_clusters"]["clusters_attack"])
    )
  elseif drone_type == EXPLORE_TYPE then
    cluster_name = table.remove(
      drones["drone_clusters"]["clusters_exploration"],
      math.random(#drones["drone_clusters"]["clusters_exploration"])
    )
  else
    cluster_name = table.remove(
      drones["drone_clusters"]["clusters_mining"],
      math.random(#drones["drone_clusters"]["clusters_mining"])
    )
  end

  drones.push_backlog_message(dialogue_generation.death_announcement(cluster_name, drone_type))
end


-- Regular variance in drone numbers (independent of any game events).
function drones.regular_variance()
  -- Attack drones
  local attack_nums = drones["drone_counts"]["drones_attack"]
  local attack_max_fluctuation = math.floor(attack_nums / 1e6)
  local attack_fluctuation = math.random(
    -attack_max_fluctuation,
    attack_max_fluctuation
  )

  drones["drone_counts"]["drones_attack"] = attack_nums + attack_fluctuation

  -- Exploration drones
  local exploration_nums = drones["drone_counts"]["drones_exploration"]
  local exploration_max_fluctuation = math.floor(exploration_nums / 1e5)
  local exploration_fluctuation = math.random(
    -exploration_max_fluctuation,
    exploration_max_fluctuation
  )

  drones["drone_counts"]["drones_exploration"] = exploration_nums + exploration_fluctuation

  -- Mining drones
  local mining_nums = drones["drone_counts"]["drones_mining"]
  local mining_max_fluctuation = math.floor(mining_nums / 1e5)
  local mining_fluctuation = math.random(
    -mining_max_fluctuation,
    mining_max_fluctuation
  )

  drones["drone_counts"]["drones_mining"] = mining_nums + mining_fluctuation
end


-- Regular morale decay
function drones.regular_morale_decay()
  local decay_factor = 0

  if drones["swarm_objective"] == MAXIMIZE_NULL then
    decay_factor = 0.1
  elseif drones["swarm_strategy"] == RANDOM_STRATEGY then
    decay_factor = 1.2
  elseif drones["swarm_strategy"] == GREEDY_STRATEGY then
    decay_factor = 0.9
  elseif drones["swarm_strategy"] == CONSERVATIVE_STRATEGY then
    decay_factor = 0.4
  else
    decay_factor = 0.7
  end

  local new_morale = drones["swarm_morale"] - decay_factor

  if new_morale < 0 then
    drones["swarm_morale"] = 0
  else
    drones["swarm_morale"] = new_morale
  end
end


-- Add a percentage increase of drones
function drones.fractionally_increase_population(frac)
  -- Drone growth
  local total_drones = drones.get_total_drones()
  local attack_drone_growth = total_drones * frac
  local exploration_drone_growth = total_drones * frac
  local mining_drone_growth = total_drones * frac

  local new_attack_population = drones["drone_counts"]["drones_attack"] + attack_drone_growth
  local new_exploration_population = drones["drone_counts"]["drones_exploration"] + exploration_drone_growth
  local new_mining_population = drones["drone_counts"]["drones_mining"] + mining_drone_growth

  if new_attack_population <= 0 then
    drones["drone_counts"]["drones_attack"] = 0
  else
    drones["drone_counts"]["drones_attack"] = new_attack_population
  end

  if new_exploration_population <= 0 then
    drones["drone_counts"]["drones_exploration"] = 0
  else
    drones["drone_counts"]["drones_exploration"] = new_exploration_population
  end

  if new_mining_population <= 0 then
    drones["drone_counts"]["drones_mining"] = 0
  else
    drones["drone_counts"]["drones_mining"] = new_mining_population
  end
end


-- Mission effects
function drones.update_drone_mission()
  local swarm_objective = drones["swarm_objective"]
  local swarm_strategy = drones["swarm_strategy"]

  -- No effects for null objective function
  if swarm_objective == MAXIMIZE_NULL then
    return
  end

  -- Drone population
  if drones["swarm_strategy"] == RANDOM_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_DRONE_POPULATION then
      drones.fractionally_increase_population(lume.random(-4e-4, 5e-4))
    else
      drones.fractionally_increase_population(lume.random(-6e-4, 1e-5))
    end
  elseif drones["swarm_strategy"] == GREEDY_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_DRONE_POPULATION then
      drones.fractionally_increase_population(lume.random(-2e-4, 3e-4))
    else
      drones.fractionally_increase_population(lume.random(-6e-5, -1.5e-5))
    end
  elseif drones["swarm_strategy"] == CONSERVATIVE_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_DRONE_POPULATION then
      drones.fractionally_increase_population(lume.random(0, 1e-4))
    else
      drones.fractionally_increase_population(lume.random(-1e-5, 0))
    end
  elseif drones["swarm_strategy"] == TIT_FOR_TAT_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_DRONE_POPULATION then
      drones.fractionally_increase_population(lume.random(0, 2e-4))
    else
      drones.fractionally_increase_population(lume.random(-5e-5, 5e-6))
    end
  end

  -- Special weapons
  if drones["swarm_strategy"] == RANDOM_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_WEAPONS_TECHNOLOGY then
      drones["special_weapons_xp"] = drones["special_weapons_xp"] + lume.random(0, 100)
    else
      drones["special_weapons_xp"] = drones["special_weapons_xp"] + lume.random(0, 2)
    end
  elseif drones["swarm_strategy"] == GREEDY_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_WEAPONS_TECHNOLOGY then
      drones["special_weapons_xp"] = drones["special_weapons_xp"] + lume.random(25, 75)
    else
      drones["special_weapons_xp"] = drones["special_weapons_xp"] + lume.random(0, 9)
    end
  elseif drones["swarm_strategy"] == CONSERVATIVE_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_WEAPONS_TECHNOLOGY then
      drones["special_weapons_xp"] = drones["special_weapons_xp"] + lume.random(30, 35)
    else
      drones["special_weapons_xp"] = drones["special_weapons_xp"] + lume.random(4, 6)
    end
  elseif drones["swarm_strategy"] == TIT_FOR_TAT_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_WEAPONS_TECHNOLOGY then
      drones["special_weapons_xp"] = drones["special_weapons_xp"] + lume.random(40, 60)
    else
      drones["special_weapons_xp"] = drones["special_weapons_xp"] + lume.random(1, 10)
    end
  end

  -- Special weapons
  if drones["swarm_strategy"] == RANDOM_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_SHIP_EFFICACY then
      drones["heat_sink_xp"] = drones["heat_sink_xp"] + lume.random(0, 100)
      drones["shields_xp"] = drones["shields_xp"] + lume.random(0, 100)
      drones["movement_xp"] = drones["movement_xp"] + lume.random(0, 100)
    else
      drones["heat_sink_xp"] = drones["heat_sink_xp"] + lume.random(0, 2)
      drones["shields_xp"] = drones["shields_xp"] + lume.random(0, 2)
      drones["movement_xp"] = drones["movement_xp"] + lume.random(0, 2)
    end
  elseif drones["swarm_strategy"] == GREEDY_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_SHIP_EFFICACY then
      drones["heat_sink_xp"] = drones["heat_sink_xp"] + lume.random(25, 75)
      drones["shields_xp"] = drones["shields_xp"] + lume.random(25, 75)
      drones["movement_xp"] = drones["movement_xp"] + lume.random(25, 75)
    else
      drones["heat_sink_xp"] = drones["heat_sink_xp"] + lume.random(0, 9)
      drones["shields_xp"] = drones["shields_xp"] + lume.random(0, 9)
      drones["movement_xp"] = drones["movement_xp"] + lume.random(0, 9)
    end
  elseif drones["swarm_strategy"] == CONSERVATIVE_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_SHIP_EFFICACY then
      drones["heat_sink_xp"] = drones["heat_sink_xp"] + lume.random(30, 35)
      drones["shields_xp"] = drones["shields_xp"] + lume.random(30, 35)
      drones["movement_xp"] = drones["movement_xp"] + lume.random(30, 35)
    else
      drones["heat_sink_xp"] = drones["heat_sink_xp"] + lume.random(4, 6)
      drones["shields_xp"] = drones["shields_xp"] + lume.random(4, 6)
      drones["movement_xp"] = drones["movement_xp"] + lume.random(4, 6)
    end
  elseif drones["swarm_strategy"] == TIT_FOR_TAT_STRATEGY then
    if drones["swarm_objective"] == MAXIMIZE_WEAPONS_TECHNOLOGY then
      drones["heat_sink_xp"] = drones["heat_sink_xp"] + lume.random(40, 60)
      drones["shields_xp"] = drones["shields_xp"] + lume.random(40, 60)
      drones["movement_xp"] = drones["movement_xp"] + lume.random(40, 60)
    else
      drones["heat_sink_xp"] = drones["heat_sink_xp"] + lume.random(1, 10)
      drones["shields_xp"] = drones["shields_xp"] + lume.random(1, 10)
      drones["movement_xp"] = drones["movement_xp"] + lume.random(1, 10)
    end
  end
end


function drones.update_levels()
  if drones["heat_sink_xp"] >= XP_PER_LEVEL and #drones.drone_clusters.clusters_mining ~= 0  then
    ship.set_max_heat(1.1 * ship.get_max_heat())

    -- Push message to backlog
    local cluster_name = lume.randomchoice(drones.drone_clusters.clusters_mining)
    drones.push_backlog_message(cluster_name .. " has manufactured improved heat sinks!")

    -- Reset XP
    drones["heat_sink_xp"] = drones["heat_sink_xp"] -  XP_PER_LEVEL
  end

  if drones["shields_xp"] >= XP_PER_LEVEL and #drones.drone_clusters.clusters_exploration ~= 0 then
    -- Increase level
    ship.set_max_health(1.1 * ship.get_max_health())
    ship.set_health_regen(1.1 * ship.get_health_regen())

    -- Push message to backlog
    local cluster_name = lume.randomchoice(drones.drone_clusters.clusters_exploration)
    drones.push_backlog_message(cluster_name .. " has discovered new shield materials!")

    -- Reset XP
    drones["shields_xp"] = drones["shields_xp"] -  XP_PER_LEVEL
  end

  if drones["movement_xp"] >= XP_PER_LEVEL then
    -- TODO level up movement once implemented

    drones["movement_xp"] = drones["movement_xp"] -  XP_PER_LEVEL
  end

  if drones["special_weapons_xp"] >= XP_PER_LEVEL then
    -- TODO level up special weapons implemented

    drones["special_weapons_xp"] = drones["special_weapons_xp"] -  XP_PER_LEVEL
  end
end


-- Update drone numbers. This is a general function that calls a bunch
-- of more specific functions.
function drones.update_drones()
  -- Capture old drone counts
  local old_drone_counts = lume.clone(drones["drone_counts"])

  -- Regular variance in drone numbers
  drones.regular_variance()

  -- Decay if morale is 0
  if drones.swarm_morale == 0 then
    drones.fractionally_increase_population(-0.01)
  end

  -- Drone mission stuff
  drones.update_drone_mission()

  -- Update swarm levels
  drones.update_levels()

  -- Update the drone count queue
  drones.update_drone_count_queue()

  -- Update the drone birth and death counts
  drones.update_drone_birth_and_death_counts(old_drone_counts)
end


return drones
