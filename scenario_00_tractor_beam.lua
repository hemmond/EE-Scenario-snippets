-- Name: Tractor beam
-- Description: Lock a tractor beam on another ship and pull it behind you. 
--- Modified from Xansta's sandbox mission
-- Type: Basic

require("utils_tractorBeam.lua")
--require("utils_tractorBeam_wrap.lua")

function GM_buttons_init()
    addGMFunction(
        "Tractor ON",
        function()
            local ships = getGMSelection()
            for i=1, #ships do
                if ships[i].typeName == "PlayerSpaceship" then
                    tractorBeam:enable(ships[i])
                end
            end
        end
    )

    addGMFunction(
        "Tractor OFF",
        function()
            local ships = getGMSelection()
            for i=1, #ships do
                if ships[i].typeName == "PlayerSpaceship" then
                    tractorBeam:disable(ships[i])
                end
            end
        end
    )
    
    tractorBeam:GMButtons(GM_buttons_init)
end 

function init()
    --tractorBeam_init()
    
    SpaceStation():setPosition(1000, 1000):setTemplate('Small Station'):setFaction("Human Navy"):setCallSign("Small station"):setRotation(random(0, 360))
    Artifact():setPosition(1000, 5000):setModel("small_frigate_1"):setDescription("Artifact")
    Asteroid():setPosition(2000, 5000):setSize(random(100, 500))
    VisualAsteroid():setPosition(3000, 5000):setSize(random(100, 500))
    
    local player = PlayerSpaceship():setPosition(500, 5000):setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(200)
    tractorBeam:enable(player)
    
    GM_buttons_init()
    player:setEnergy(100)
end

function update(delta)
    tractorBeam:update(delta)
end
