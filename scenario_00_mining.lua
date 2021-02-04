-- Name: Asteroid mining
-- Description: Lets dig some asteroids. 
--- Modified from Xansta's sandbox mission
-- Type: Basic

require("utils_asteroidMining.lua")

function init()
    asteroidMining_init()
    
    Asteroid():setPosition(1000, 5000):setSize(200)
    Asteroid():setPosition(0, 4000):setSize(100)
    VisualAsteroid():setPosition(0, 6000):setSize(500)
    
    local player = PlayerSpaceship():setPosition(0, 5000):setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(0)
    asteroidMining_enable(player)
    
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
    print("Mission init done")
end

function update(delta)
    for pidx=1,32 do
        local player_ship = getPlayerShip(pidx)
		if player_ship ~= nil and player_ship:isValid() then
            asteroidMining_update(player_ship, delta)
        end
    end
end
