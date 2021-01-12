-- Name: Deploy artifact
-- Description: Deploy artifact from player ship using custom
--- button on either Operations or Relay officer screen. 
-- Type: Basic


-- vectorFromAngle function is used fro utils.lua
require("utils.lua")

-- This function creates satelite behind the player ship 
-- @argument player: player ship which spawns the artifact.
function spawn_satelite(player)
    -- Distance from the ship for the artifact to be spawn. 
    DISTANCE = 100

    -- Get where the ship is and where it aims to.
    x,y = player:getPosition()
    ship_rotation = player:getRotation()

    -- Calculate where to put the artifact.
    deploy_angle = (ship_rotation+180)%360
    dx, dy = vectorFromAngle(deploy_angle, 100)

    -- Create artifact and put it on coordinates right behind the ship.
    Artifact():setPosition(x+dx, y+dy):setModel("shield_generator"):setDescription("shield_generator")
end --spawn_satelite

-- This function creates player ship on coordinates x, y
function spawn_player_ship(x, y)
    --Create player ship and put it on coordinates. 
    player = PlayerSpaceship():setPosition(x, y):setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(0)
    
    -- Add custom buttons to Relay and Operations. 
    player:addCustomButton("Relay", "deploy", "Deploy satelite", function () spawn_satelite(player) end)
    player:addCustomButton("Operations", "deployOp", "Deploy satelite", function () spawn_satelite(player) end)
    -- NOTE: Button on Operations is not visible until you change from "SCANNING" to "OTHER" in selector above target information. 
end --spawn_player_ship

function init()
    spawn_player_ship(1000, 1000)
end
