-- Name: tractor_beam_utils
-- Description: Functions to enhance player ships with tractor beam functionality. 
--- Code is extracted from Xansta's sandbox scenario. 

--  If you want to use Tractor Beam functionality, you need to call:
--  * tractorBeam:update(delta) function in scenario update() function

-- To set up tractor beam functionality, you need to call tractorBeam:enable(player_ship) on required ship. 
-- To remove tractor beam functionality, you need to call tractorBeam:disable(player_ship) on required ship. 
-- To check if tractor beam functionality is enabled, you need to call tractorBeam:isEnabled(player_ship) on required ship.

-- TODO:
-- * Tractor Beam power consumption is dependent on number of update() calls, not on time elapsed. 
-- * implement function setVisualAsteroidsTractorable(true|false)

require("utils.lua")

tractorBeam = {
    DISTANCE = 1000,    -- aka 1U - Tractor beam range. Object beyond this range will not be shown in tractor beam controls.
    LOCK_ON_VELOCITY = 1,    -- If ship speed is above this value, tractor beam cannot be initiated.
    TEAROFF_VELOCITY =  50,     -- If ship speed is above this value, tractor beam cannot continue. (roughly equals 3U/min)

    -- Textures for Tractor Beam visual effect. 
    textures_string = {
        "beam_blue.png",
        "shield_hit_effect.png",
        "electric_sphere_texture.png"
    },
    
    energy_drain = 0.5,   -- Tractor beam energy drain per second.
    equipped_ships = {}
}

-- Enable tractor beam function on specified player ship
function tractorBeam:enable(player_ship)
    if player_ship._tractorBeamData == nil then
        player_ship._tractorBeamData = {
            enabled = true,
            target_lock = false,
            
            -- Copy default values: 
            energy_drain = tractorBeam.energy_drain,
            LOCK_ON_VELOCITY = tractorBeam.LOCK_ON_VELOCITY, 
            TEAROFF_VELOCITY = tractorBeam.TEAROFF_VELOCITY
        }
        table.insert(tractorBeam.equipped_ships, player_ship)
    elseif player_ship._tractorBeamData.enabled == false then
        player_ship._tractorBeamData.enabled = true
        tractorBeam:_disengageTractorBeam(player_ship)
        table.insert(tractorBeam.equipped_ships, player_ship)
    end
end

-- Remove tractor beam function on specified player ship
function tractorBeam:disable(player_ship)
    if player_ship._tractorBeamData ~= nil and player_ship._tractorBeamData.enabled == true then
        player_ship._tractorBeamData.enabled = false
        tractorBeam:removeTractorObjectButtons(player_ship)
        tractorBeam:_disengageTractorBeam(player_ship)
        for index, ship in ipairs(tractorBeam.equipped_ships) do
            if ship == player_ship then
                table.remove(tractorBeam.equipped_ships, index)
            end
        end
    end
end

-- get energy drain of player ship
function tractorBeam:getEnergyDrain(player_ship)
    return player_ship._tractorBeamData.energy_drain
end

-- set energy drain of player_ship
function tractorBeam:setEnergyDrain(player_ship, value)
    if value < 0 then
        player_ship._tractorBeamData.energy_drain = 0
    else
        player_ship._tractorBeamData.energy_drain = value
    end
end

-- get lock on velocity of player ship
function tractorBeam:getLockOnVelocity(player_ship)
    return player_ship._tractorBeamData.LOCK_ON_VELOCITY
end

-- set lock on velocity of player_ship
function tractorBeam:setLockOnVelocity(player_ship, value)
    if value < 0 then
        player_ship._tractorBeamData.LOCK_ON_VELOCITY = 0
    else
        player_ship._tractorBeamData.LOCK_ON_VELOCITY = value
    end
end

-- get tearoff velocity of player ship
function tractorBeam:getTearoffVelocity(player_ship)
    return player_ship._tractorBeamData.TEAROFF_VELOCITY
end

-- set tearoff velocity of player_ship
function tractorBeam:setTearoffVelocity(player_ship, value)
    if value < 0 then
        player_ship._tractorBeamData.TEAROFF_VELOCITY = 0
    else
        player_ship._tractorBeamData.TEAROFF_VELOCITY = value
    end
end

-- This function returns if tractor beam is enabled or not. 
function tractorBeam:isEnabled(player_ship)
    if player_ship._tractorBeamData == nil then
        return false
    end
    return player_ship._tractorBeamData.enabled
end

--	Tractor functions (called from update loop)
function tractorBeam:removeTractorObjectButtons(player_ship)
    --print("TB tractorBeam:removeTractorObjectButtons: ", player_ship:getCallSign())
	if player_ship._tractorBeamData.tractor_next_target_button ~= nil then
		player_ship:removeCustom(player_ship._tractorBeamData.tractor_next_target_button)
		player_ship._tractorBeamData.tractor_next_target_button = nil
	end
	if player_ship._tractorBeamData.tractor_target_button ~= nil then
		player_ship:removeCustom(player_ship._tractorBeamData.tractor_target_button)
		player_ship._tractorBeamData.tractor_target_button = nil
	end
	if player_ship._tractorBeamData.tractor_lock_button ~= nil then
		player_ship:removeCustom(player_ship._tractorBeamData.tractor_lock_button)
		player_ship._tractorBeamData.tractor_lock_button = nil
	end
end

-- p = player ship, tractor_objects = table of tractor-able objects in range
function tractorBeam:addTractorObjectButtons(player_ship, tractor_objects)
    --print("TB tractorBeam:addTractorObjectButtons: ", player_ship:getCallSign())

    local cpx, cpy = player_ship:getPosition()
	local tpx, tpy = player_ship._tractorBeamData.tractor_target:getPosition()
    
	if player_ship._tractorBeamData.tractor_lock_button == nil then
		if player_ship:hasPlayerAtPosition("Engineering") then
			player_ship._tractorBeamData.tractor_lock_button = "tractor_lock_button"
			player_ship:addCustomButton("Engineering",player_ship._tractorBeamData.tractor_lock_button,"Lock on Tractor",
                                        function() tractorBeam:_lockOnTractor(player_ship) end)
		end
	end -- end of tractor_lock_button IF
    
	if player_ship._tractorBeamData.tractor_target_button == nil then
		if player_ship:hasPlayerAtPosition("Engineering") then
			player_ship._tractorBeamData.tractor_target_button = "tractor_target_button"
            -- Create target label
			local tractor_label = player_ship._tractorBeamData.tractor_target.typeName
			if tractor_label == "CpuShip" or tractor_label == "PlayerSpaceship" then
				tractor_label = player_ship._tractorBeamData.tractor_target:getCallSign()
			elseif tractor_label == "VisualAsteroid" then
				tractor_label = "Asteroid"
			end
            
			player_ship:addCustomButton("Engineering",player_ship._tractorBeamData.tractor_target_button,string.format("Target %s",tractor_label),
                                function() tractorBeam:_targetDescription(player_ship) end)
		end
	end -- end of tractor_target_button IF
    
	if #tractor_objects > 1 then
		if player_ship._tractorBeamData.tractor_next_target_button == nil then
			if player_ship:hasPlayerAtPosition("Engineering") then
				player_ship._tractorBeamData.tractor_next_target_button = "tractor_next_target_button"
				player_ship:addCustomButton("Engineering",player_ship._tractorBeamData.tractor_next_target_button,"Other tractor target", function() tractorBeam:_nextTarget(player_ship) end)
			end -- end if player_ship:hasPlayerAtPosition("Engineering")
		end -- end if player_ship.player_ship._tractorBeamData.tractor_next_target_button == nil
	else -- only one tractor target in range
		if player_ship._tractorBeamData.tractor_next_target_button ~= nil then
                        -- Remove previously available button. 
			player_ship:removeCustom(player_ship._tractorBeamData.tractor_next_target_button)
			player_ship._tractorBeamData.tractor_next_target_button = nil
		end
	end -- end of more than 1 tractor_objects
end

-- This function returns table of tractorable objects in range of player_ship.
function tractorBeam:getTractorObjects(player_ship)
    local nearby_objects = player_ship:getObjectsInRange(tractorBeam.DISTANCE)
    local tractor_objects = {}
    if nearby_objects ~= nil and #nearby_objects > 0 then
        for _, obj in ipairs(nearby_objects) do
            if player_ship ~= obj then
                local object_type = obj.typeName
                if object_type ~= nil then
                    if object_type == "Asteroid" or object_type == "CpuShip" or object_type == "Artifact" or object_type == "PlayerSpaceship" or object_type == "WarpJammer" or object_type == "Mine" or object_type == "ScanProbe" or object_type == "VisualAsteroid" then
                        table.insert(tractor_objects,obj)
                    end
                end
            end -- filter out player ship
        end		--end of nearby object list loop
    end
    return tractor_objects
end

-- This function is called when operator pushes tractor_lock_button.
function tractorBeam:_lockOnTractor(player_ship)
    local cpx, cpy = player_ship:getPosition()
    local tpx, tpy = player_ship._tractorBeamData.tractor_target:getPosition()
    local tractor_object_distance = distance(cpx,cpy,tpx,tpy)
    -- TODO distance allows two objects as input - will get the positions by itself)
    
    if tractor_object_distance < tractorBeam.DISTANCE then
        -- Tractor beam lock can be estabilished
        player_ship._tractorBeamData.target_lock = true
        player_ship._tractorBeamData.tractor_vector_x = tpx - cpx
        player_ship._tractorBeamData.tractor_vector_y = tpy - cpy
        local locked_message = "locked_message"
        player_ship:addCustomMessage("Engineering",locked_message,"Tractor locked on target")
    else
        -- Tractor beam lock cannot be estabilished
        local lock_fail_message = "lock_fail_message"
        player_ship:addCustomMessage("Engineering",lock_fail_message,string.format("Tractor lock failed\nObject distance is %.4fU\nMaximum range of tractor is %.4fU",
                                                                                   tractor_object_distance/tractorBeam.DISTANCE, tractorBeam.DISTANCE/1000))
        player_ship._tractorBeamData.tractor_target = nil
    end
    tractorBeam:removeTractorObjectButtons(player_ship)
end

-- This function is called when operator pushes tractor_target_button (button with target label)
function tractorBeam:_targetDescription(player_ship)
    string.format("")	--necessary to have global reference for Serious Proton engine
    local cpx, cpy = player_ship:getPosition()
    local tpx, tpy = player_ship._tractorBeamData.tractor_target:getPosition()
    local target_distance = distance(cpx, cpy, tpx, tpy)/1000
    local theta = math.atan(tpy - cpy,tpx - cpx)
    if theta < 0 then
        theta = theta + 6.2831853071795865
    end
    local angle = theta * 57.2957795130823209
    angle = angle + 90 -- TODO replace with modulo
    if angle > 360 then
        angle = angle - 360
    end
    local target_description = "target_description"
    player_ship:addCustomMessage("Engineering",target_description,string.format("Distance: %.1fU\nBearing: %.1f",target_distance,angle))
end

-- This function is called when operator pushes tractor_next_target_button (next ship button)
function tractorBeam:_nextTarget(player_ship)
    tractor_objects = tractorBeam:getTractorObjects(player_ship)
    
    if #tractor_objects > 0 then
        --print(string.format("%i tractorable objects under 1 unit away",#tractor_objects))
        if player_ship._tractorBeamData.tractor_target ~= nil and player_ship._tractorBeamData.tractor_target:isValid() then
            local target_in_list = false
            local matching_index = 0
            for i=1,#tractor_objects do
                if tractor_objects[i] == player_ship._tractorBeamData.tractor_target then
                    target_in_list = true
                    matching_index = i
                    break
                end
            end		--end of check for the current target in list loop
            if target_in_list then
                if #tractor_objects > 1 then
                    if #tractor_objects > 2 then
                        local new_index = matching_index
                        repeat
                            new_index = math.random(1,#tractor_objects)
                        until(new_index ~= matching_index)
                        player_ship._tractorBeamData.tractor_target = tractor_objects[new_index]
                    else
                        if matching_index == 1 then
                            player_ship._tractorBeamData.tractor_target = tractor_objects[2]
                        else
                            player_ship._tractorBeamData.tractor_target = tractor_objects[1]
                        end
                    end
                    tractorBeam:removeTractorObjectButtons(player_ship)
                    tractorBeam:addTractorObjectButtons(player_ship,tractor_objects)
                end
            else
                player_ship.tractor_target = tractor_objects[1]
                tractorBeam:removeTractorObjectButtons(player_ship)
                tractorBeam:addTractorObjectButtons(player_ship,tractor_objects)
            end
        else
            player_ship.tractor_target = tractor_objects[1]
            tractorBeam:addTractorObjectButtons(player_ship,tractor_objects)
        end
    else	--no nearby tractorable objects
        if player_ship.tractor_target ~= nil then
            tractorBeam:removeTractorObjectButtons(player_ship)
            player_ship.tractor_target = nil
        end
    end
end

function tractorBeam:_disengageTractorBeam(player_ship)
    player_ship._tractorBeamData.target_lock = false
    if player_ship._tractorBeamData.disengage_tractor_button ~= nil then
        player_ship:removeCustom(player_ship._tractorBeamData.disengage_tractor_button)
        player_ship._tractorBeamData.disengage_tractor_button = nil
    end
end

function tractorBeam:_processTractor(player_ship, delta)
    local cpx, cpy = player_ship:getPosition()
    
    if player_ship._tractorBeamData.tractor_target ~= nil and player_ship._tractorBeamData.tractor_target:isValid() then -- Valid and locked tractor beam target
        player_ship._tractorBeamData.tractor_target:setPosition(cpx+player_ship._tractorBeamData.tractor_vector_x,cpy+player_ship._tractorBeamData.tractor_vector_y)
        player_ship:setEnergy(player_ship:getEnergy() - player_ship._tractorBeamData.energy_drain*delta)
        
        if random(1,100) < 27 then
            BeamEffect():setSource(player_ship,0,0,0):setTarget(player_ship._tractorBeamData.tractor_target,0,0):setDuration(1):setRing(false):setTexture(tractorBeam.textures_string[math.random(1,#tractorBeam.textures_string)])
        end
        
        if player_ship._tractorBeamData.disengage_tractor_button == nil then
            player_ship._tractorBeamData.disengage_tractor_button = "disengage_tractor_button"
            player_ship:addCustomButton("Engineering",player_ship._tractorBeamData.disengage_tractor_button,"Disengage Tractor",function()
                tractorBeam:_disengageTractorBeam(player_ship)
            end)
        end
        
        if player_ship:getEnergy() < 2 then
            player_ship:addCustomMessage("Engineering", "no_energy_msg", "No energy left for sustaining tractor beam. Tractor beam disengaged.")
            tractorBeam:_disengageTractorBeam(player_ship)
        end
    else	-- tractor target no longer invalid
        tractorBeam:_disengageTractorBeam(player_ship)
    end
end

-- Updates all tractor-beam equipped ships and locked targets.
-- This function needs to be called inside update() function with delta specified.
function tractorBeam:update(delta)
    for _, player_ship in ipairs(tractorBeam.equipped_ships) do
        tractorBeam:updateShip(player_ship, delta)
    end
end

-- This function updates tractor beam equipped Player Ship.
-- It shows buttons, calculates new target positions, etc.
-- @param player_ship: instance of PlayerShip class
-- @param delta: time difference between last call and this call.
function tractorBeam:updateShip(player_ship, delta)
    if tractorBeam:isEnabled(player_ship) == true then       --Process this only if the ship has Tractor beam enabled. 
        
        -- Count velocity of player ship, tractor beam works on low velocities only.
        local vx, vy = player_ship:getVelocity()
        local dx=math.abs(vx)
        local dy=math.abs(vy)
        local player_velocity = math.sqrt((dx*dx)+(dy*dy))

        if player_velocity < player_ship._tractorBeamData.LOCK_ON_VELOCITY then   -- Slow enough to establish tractor
            if player_ship._tractorBeamData.target_lock then
                tractorBeam:_processTractor(player_ship, delta)
            else	--tractor not locked on target
                local tractor_objects = tractorBeam:getTractorObjects(player_ship)
                if tractor_objects ~= nil and #tractor_objects > 0 then
                    if player_ship._tractorBeamData.tractor_target ~= nil and player_ship._tractorBeamData.tractor_target:isValid() then
                        local target_in_list = false
                        for i=1,#tractor_objects do
                            if tractor_objects[i] == player_ship._tractorBeamData.tractor_target then
                                target_in_list = true
                                break
                            end
                        end		--end of check for the current target in list loop
                        if not target_in_list then
                            player_ship._tractorBeamData.tractor_target = tractor_objects[1]
                            tractorBeam:removeTractorObjectButtons(player_ship)
                        end
                    else 
                        player_ship._tractorBeamData.tractor_target = tractor_objects[1]
                    end --end of IF tractor_target is set and valid
                    tractorBeam:addTractorObjectButtons(player_ship,tractor_objects)
                else	--no nearby tractorable objects
                    if player_ship._tractorBeamData.tractor_target ~= nil then
                        tractorBeam:removeTractorObjectButtons(player_ship)
                        player_ship._tractorBeamData.tractor_target = nil
                    end
                end --end of check that tractor_object exists and is not empty
            end
        else	--not moving slowly enough to establish tractor
            tractorBeam:removeTractorObjectButtons(player_ship)
            if player_velocity > player_ship._tractorBeamData.TEAROFF_VELOCITY then
                player_ship._tractorBeamData.target_lock = false
                if player_ship._tractorBeamData.disengage_tractor_button ~= nil then
                    player_ship:removeCustom(player_ship._tractorBeamData.disengage_tractor_button)
                    player_ship._tractorBeamData.disengage_tractor_button = nil
                end
            else
                if player_ship._tractorBeamData.target_lock then
                    tractorBeam:_processTractor(player_ship, delta)
                end		--end of tractor lock processing				
            end		--end of player moving slow enough to tractor branch
        end		--end of speed checks for tractoring
    end		--end of tractor enabled check
end

-- -------------------------------------------------------------------------
-- GM Configuration menu and sub-menus
-- -------------------------------------------------------------------------

--- Generate GM button as entrypoint to configurating Player Ship. 
function tractorBeam:GMFunctions(back_callback)
    addGMFunction(
        "+Config Tractor",
        function()
            local ships = getGMSelection()
            local shipFound = false
            for i=1, #ships do
                if ships[i].typeName == "PlayerSpaceship" then
                shipFound = true
                    tractorBeam:_GMConfigureShip(ships[i], back_callback)
                end
            end
            
            if shipFound ==false then
                addGMMessage("Select exactly one player ship to configure Tractor Beam.")
            end
        end
    )
end --end of GM Config Menu

-- Generate sub-menu for configuring selected player ship. 
function tractorBeam:_GMConfigureShip(player_ship, back_callback)
    clearGMFunctions()
    
    addGMFunction("-From Tractor Beam", function()
        clearGMFunctions()
        if back_callback ~= nil then 
            back_callback()
        else
            tractorBeam:GMButtons(back_callback)
        end
    end)
    
    
    addGMFunction("CFG: "..player_ship:getCallSign(), function()
        string.format("")
        msg = "Tractor beam configuration:\n"
        msg = msg.."Callsign: "..player_ship:getCallSign().."\n"
        msg = msg.."Tractor beam: "
        if tractorBeam:isEnabled(player_ship) then
            msg = msg.."Enabled"
        else
            msg = msg.."Disabled"
        end
        msg = msg.."\n"
        
        msg = msg.."Power consumption: "..tractorBeam:getEnergyDrain(player_ship).."/second\n"
        msg = msg.."Lock on velocity: "..tractorBeam:getLockOnVelocity(player_ship).."\n"
        msg = msg.."Tearoff velocity: "..tractorBeam:getTearoffVelocity(player_ship).."\n"
        msg = msg.."\n"
        if player_ship._tractorBeamData.target_lock and player_ship._tractorBeamData.tractor_target ~= nil and player_ship._tractorBeamData.tractor_target:isValid() then
            msg = msg.."Currently tractoring "..player_ship._tractorBeamData.tractor_target.typeName..": "..player_ship._tractorBeamData.tractor_target:getCallSign()
        end
        addGMMessage(msg)
    end)
    
    if tractorBeam:isEnabled(player_ship) then 
        addGMFunction("TB disable", function()
            tractorBeam:disable(player_ship)
            tractorBeam:_GMConfigureShip(player_ship, back_callback)
        end)
    else
        addGMFunction("TB enable", function()
            tractorBeam:enable(player_ship)
            tractorBeam:_GMConfigureShip(player_ship, back_callback)
        end)
    end
    
    addGMFunction("+Energy drain", function()
        tractorBeam:_GMSetEnergyDrain(player_ship, back_callback)
    end)
    
    addGMFunction("+Lock on velocity", function()
        tractorBeam:_GMSetLockOnVelocity(player_ship, back_callback)
    end)
    
    addGMFunction("+Tearoff velocity", function()
        tractorBeam:_GMSetTearoffVelocity(player_ship, back_callback)
    end)
    
end --end of GM Config Menu

-- Helper function that generates buttons to set specified numeric value. 
-- @param getter: function that returns current numeric value.
-- @param setter: function that takes 1 argument = new numeric value to set. 
-- @param reload: function that gets called every time GM makes a change (and should re-draw this GM sub-menu, thus call this function again).
-- @param values: Numeric values that ends up buttons to add/subsrtract from value retrieved with getter. Maximum of 4 elements is recommended. 
function numericChangeDialogue(getter, setter, reload, values)
    table.sort(values)  -- get values from low to high
    
    -- Increasing buttons
    for i=1, #values do
        local value = values[#values + 1 - i]
        addGMFunction("+"..value, function()
            string.format("")
            setter(getter()+value)
            reload()
        end)
    end
    
    -- Show value
    addGMFunction("="..getter(), function() string.format("") end)
    
    -- Decreasing buttons
    for i=1, #values do
        local value = values[i]
        addGMFunction("-"..value, function()
            string.format("")
            setter(getter()-value)
            reload()
        end)
    end
end

-- Dialog to set energy drain.
function tractorBeam:_GMSetEnergyDrain(player_ship, back_callback)
    clearGMFunctions()
    addGMFunction("-From Energy drain", function()
        clearGMFunctions()
        tractorBeam:_GMConfigureShip(player_ship, back_callback)
    end)
    
    numericChangeDialogue(
        function() --getter
            return tractorBeam:getEnergyDrain(player_ship)
        end, 
        function(x) --setter
            tractorBeam:setEnergyDrain(player_ship, x)
        end, 
        function() --reload
            tractorBeam:_GMSetEnergyDrain(player_ship, back_callback)
        end, 
        {10, 1, 0.1, 0.001}
    )
end

-- Dialog to set lock on velocity.
function tractorBeam:_GMSetLockOnVelocity(player_ship, back_callback)
    clearGMFunctions()
    addGMFunction("-From Lock on velocity", function()
        clearGMFunctions()
        tractorBeam:_GMConfigureShip(player_ship, back_callback)
    end)
    
    numericChangeDialogue(
        function() --getter
            return tractorBeam:getLockOnVelocity(player_ship)
        end, 
        function(x) --setter
            tractorBeam:setLockOnVelocity(player_ship, x)
        end, 
        function() --reload
            tractorBeam:_GMSetLockOnVelocity(player_ship, back_callback)
        end, 
        {10, 5, 1}
    )
end

-- Dialog to set tearoff velocity.
function tractorBeam:_GMSetTearoffVelocity(player_ship, back_callback)
    clearGMFunctions()
    addGMFunction("-From Tearoff velocity", function()
        clearGMFunctions()
        tractorBeam:_GMConfigureShip(player_ship, back_callback)
    end)
    
    numericChangeDialogue(
        function() --getter
            return tractorBeam:getTearoffVelocity(player_ship)
        end, 
        function(x) --setter
            tractorBeam:setTearoffVelocity(player_ship, x)
        end, 
        function() --reload
            tractorBeam:_GMSetTearoffVelocity(player_ship, back_callback)
        end, 
        {50, 10, 5, 1}
    )
end
