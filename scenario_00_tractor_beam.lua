-- Name: Tractor beam
-- Description: Lock a tractor beam on another ship and pull it behind you. 
--- Modified from Xansta's sandbox mission
-- Type: Basic

require("tractor_beam_utils.lua")

function init()
    tractorBeam_init()
    
    SpaceStation():setPosition(1000, 1000):setTemplate('Small Station'):setFaction("Human Navy"):setCallSign("Small station"):setRotation(random(0, 360))
    Artifact():setPosition(1000, 5000):setModel("small_frigate_1"):setDescription("Artifact")
    Asteroid():setPosition(2000, 5000):setSize(random(100, 500))
    VisualAsteroid():setPosition(3000, 5000):setSize(random(100, 500))
    
    local player = PlayerSpaceship():setPosition(500, 5000):setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(200)
    tractorBeam_initShip(player)
end

function update(delta)
    for pidx=1,32 do
        local player_ship = getPlayerShip(pidx)
		if player_ship ~= nil and player_ship:isValid() then
            tractorBeam_update(player_ship)
        end
    end
end
