-- Name: Drop on destroy
-- Description: Enemy ships drops stuff that can be picked up when they are destroyed. 
--- Implemented both as SupplyDrop and Artifact with pick-up enabled. 
--- Both contains 100 energy and 2 homing torpedoes
-- Type: Basic

require("utils.lua")

-- Callback for when artifact is picked up. 
function pickArtifact(self, picker)
    string.format("")	--necessary to have global reference for Serious Proton engine

    picker:setEnergy(picker:getEnergy()+100)
            
    local currentHoming = picker:getWeaponStorage("Homing")
    local maxHoming = picker:getWeaponStorageMax("Homing")
    if(currentHoming+2 <= maxHoming) then
        picker:setWeaponStorage("Homing", currentHoming+2)
    else
        picker:setWeaponStorage("Homing", maxHoming)
    end        
end

--Main init function
function init()
    -- Create player spaceship
    PlayerSpaceship():setPosition(500, 500):setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(180):setEnergy(500)
    
    -- Create CPU ship that will drop SupplyDrop when destroyed
    ship1 = CpuShip():setPosition(1000, 500):setFaction("Kraylor"):setTemplate("Ktlitan Drone"):orderIdle():setScanned(true)
    ship1:onDestruction( function(ship) 
        local sd = SupplyDrop():setFaction("Human Navy")
        sd:setEnergy(100)
        sd:setWeaponStorage("Homing", 2)
        sd:setPosition( ship:getPosition() )
    end)
    
    -- Create CPU ship that will drop Artifact when destroyed. 
    ship2 = CpuShip():setPosition(0, 500):setFaction("Kraylor"):setTemplate("Ktlitan Drone"):orderIdle():setScanned(true)
    ship2:onDestruction( function(ship) 
        local sd = Artifact():setModel("ammo_box"):allowPickup(true)
        sd:onPickUp(pickArtifact)
        
        sd:setPosition( ship:getPosition() )
    end) --end of ship2:onDestruction
end
