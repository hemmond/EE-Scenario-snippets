-- Name: Asteroid mining
-- Description: Lets dig some asteroids. 
--- Modified from Xansta's sandbox mission
-- Type: Basic
-- Variation[Config]: Provides configuration object to modify values. 
-- Variation[Callbacks]: Provides custom callbacks for asteroid mining.


require("utils_asteroidMining.lua")

function init()
    -- Initialize Asteroid Mining library
    if getScenarioVariation() == "Config" then
        asteroidMining_init({MINING_DISTANCE=1500, MINING_DURATION=10, MINING_BEAM_HEAT=.0020})
    else
        asteroidMining_init()
    end
    
    -- Create targets to mine. 
    a1 = Asteroid():setPosition(1000, 5000):setSize(200); a1.size = 200
    a2 = Asteroid():setPosition(0, 4000):setSize(100); a2.size = 100
    a3 = VisualAsteroid():setPosition(0, 6000):setSize(500); a3.size=500
    a4 = Asteroid():setPosition(1000, 4000):setSize(50); a4.size=50  --Some asteroid in range between 1U and 1.5U
    a5 = Asteroid():setPosition(0, 2800):setSize(50); a5.size=50     --Some asteroid in range away than 2U
    
    -- Set up custom callbacks for "Callbacks" variant
    if getScenarioVariation() == "Callbacks" then
        a1.valuables=true
        a3.valuables=true
        a2.valuables=false
        a4.valuables=false
        a5.valuables=false
    
        asteroidMining_setCanBeMinedCallback(function(object)
            if object ~= nil then
                local object_type = object.typeName
                if object_type ~= nil then
                    if object_type == "Asteroid" or object_type == "VisualAsteroid" then
                        return true
                    end
                end
            end --object not nil
            return false
        end)
        
        asteroidMining_setTargetInfoCallback(function(player_ship) 
            local angle, target_distance = asteroidMining_getHeadingAndDistance(player_ship, player_ship.mining_target)
            local object_type = player_ship.mining_target.typeName
            local line1 = string.format("Sensors report on %s:\nDistance: %.1fU\nBearing: %.1f\nSize: %.1f",object_type, target_distance/1000,angle,player_ship.mining_target.size)
            local line2 = "n/A"
            
            if player_ship.mining_target.valuables then
                line2 = "Valuables available."
            else
                line2 = "Nothing useful here."
            end
            
            return string.format("%s\n%s", line1, line2)
        end)
        
        asteroidMining_setMiningFinishedCallback(function(player_ship) 
            local angle, target_distance = asteroidMining_getHeadingAndDistance(player_ship, player_ship.mining_target)
            local object_type = player_ship.mining_target.typeName
            local line1 = string.format("Mining finished on %s:\nDistance: %.1fU\nBearing: %.1f",object_type, target_distance/1000,angle)
            local line2 = "n/A"
            
            if player_ship.mining_target.valuables then
                line2 = "Valuables acquired."
            else
                line2 = "Nothing useful found."
            end
            
            local ax, ay = player_ship.mining_target:getPosition()
            local size = player_ship.mining_target.size
            
            player_ship.mining_target:destroy()
            ExplosionEffect():setPosition(ax,ay):setSize(size+10):setOnRadar(true)
                        
            local target_description = "mining_finished_message"
            player_ship:addCustomMessage("Weapons",target_description,string.format("%s\n%s", line1, line2))
        end)
    end --end of callbacks scenario set-up.
    
    
    
    -- Create player and initialize Asteroid mining on ship.
    local player = PlayerSpaceship():setPosition(0, 5000):setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(0)
    asteroidMining_enable(player)
    
    -- Add GM functions to enable/disable asteroid mining functionality.
    addGMFunction(
        "Mining ON",
        function()
            local ships = getGMSelection()
            for i=1, #ships do
                if ships[i].typeName == "PlayerSpaceship" then
                    asteroidMining_enable(ships[i])
                end
            end
        end
    )

    addGMFunction(
        "Mining OFF",
        function()
            local ships = getGMSelection()
            for i=1, #ships do
                if ships[i].typeName == "PlayerSpaceship" then
                    asteroidMining_disable(ships[i])
                end
            end
        end
    )
end

function update(delta)
    for pidx=1,32 do
        local player_ship = getPlayerShip(pidx)
		if player_ship ~= nil and player_ship:isValid() then
            asteroidMining_update(player_ship, delta)
        end
    end
end
