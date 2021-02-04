-- Name: utils_asteroidMining
-- Description: Functions to enhance player ships with asteroid mining functionality.
--- Code is extracted from Xansta's sandbox scenario. 

--  If you want to use asteroid mining functionality, you need to call:
--  * asteroidMining_init() function in your init() function (to set up this module)
--  * asteroidMining_update(player_ship) function for each of your player ships in update() function

-- To set up asteroid mining functionality, you need to call asteroidMining_enable(player_ship) on required ship. 
-- To remove asteroid mining functionality, you need to call asteroidMining_disable(player_ship) on required ship.


--[[   TODO
Create callback after (successful?) mining. 
Create function to check if the asteroid is mining-able (and contains something)
Create "toggle" function to set all asteroid mining/only selected asteroid mining.
Create "toggle" function to enable/disable mining of visual asteroids.
Enable altering mining distance (remove magical constants)
]]--

require("utils.lua")

-------------------------------------------------------------------------------
--	Public API functions 
-------------------------------------------------------------------------------

-- Init asteroid mining library
function asteroidMining_init()
    asteroidMining_MAXIMUM_VELOCITY = 10        -- Mining is not available above this speed. 
    asteroidMining_DETECTION_RADIUS = 1000      -- Radius in which we search for mining targets (1000 = 1U)
    asteroidMining_ENABLE_VISUAL_ASTEROID = true    -- Allow also mining Visual asteroids.
    asteroidMining_MINING_DISTANCE = 1000       -- Distance on which mining beam can be started. 
    asteroidMining_MINING_DURATION = 5          -- Number of seconds till mining is finished
    asteroidMining_MINING_DRAIN = .00025        -- Coeficient of power consumption. 
    asteroidMining_MINING_BEAM_HEAT = .0025     -- Heat generated to beam weapons while mining. 
    
    asteroidMining_MINING_BEAM_STRING = {
		"beam_orange.png",
		"beam_yellow.png",
		"fire_sphere_texture.png"
	}
end

-- Update state of player ship's mining functions
function asteroidMining_update(player_ship, delta)
    if player_ship.mining then
        local vx, vy = player_ship:getVelocity()
        local dx=math.abs(vx)
        local dy=math.abs(vy)
        local player_velocity = math.sqrt((dx*dx)+(dy*dy))

        if player_velocity < asteroidMining_MAXIMUM_VELOCITY then
            if player_ship.mining_target_lock then
                if _asteroidMining_isValid(player_ship.mining_target) then
                    if player_ship.mining_in_progress then
                        player_ship.mining_timer = player_ship.mining_timer - delta
                        if player_ship.mining_timer < 0 then
                            player_ship.mining_in_progress = false
                            if player_ship.mining_timer_info ~= nil then
                                player_ship:removeCustom(player_ship.mining_timer_info)
                                player_ship.mining_timer_info = nil
                            end
                            
                            player_ship.mining_target_lock = false
                            player_ship.mining_timer = nil
                            
                            print("Mining finished")
                        else	--still mining, update timer display, energy and heat
                            player_ship:setEnergy(player_ship:getEnergy() - player_ship:getMaxEnergy()*asteroidMining_MINING_DRAIN)
                            player_ship:setSystemHeat("beamweapons",player_ship:getSystemHeat("beamweapons") + asteroidMining_MINING_BEAM_HEAT)
                            local mining_seconds = math.floor(player_ship.mining_timer % 60)
                            if random(1,100) < 38 then
                                BeamEffect():setSource(player_ship,0,0,0):setTarget(player_ship.mining_target,0,0):setRing(false):setDuration(1):setTexture(asteroidMining_MINING_BEAM_STRING[math.random(1,#asteroidMining_MINING_BEAM_STRING)])
                            end
                            if player_ship:hasPlayerAtPosition("Weapons") then
                                player_ship.mining_timer_info = "mining_timer_info"
                                player_ship:addCustomInfo("Weapons",player_ship.mining_timer_info,string.format("Mining %i",mining_seconds))
                            end
                        end
                    else	--mining not in progress
                        if player_ship.trigger_mine_beam_button == nil then
                            if player_ship:hasPlayerAtPosition("Weapons") then
                                player_ship.trigger_mine_beam_button = "trigger_mine_beam_button"
                                player_ship:addCustomButton("Weapons",player_ship.trigger_mine_beam_button,"Start Mining",function()
                                    player_ship.mining_in_progress = true
                                    player_ship.mining_timer = delta + asteroidMining_MINING_DURATION
                                    player_ship:removeCustom(player_ship.trigger_mine_beam_button)
                                    player_ship.trigger_mine_beam_button = nil
                                end)
                            end
                        end
                    end --end of mining in progress
                else	--no mining target or mining target invalid
                    player_ship.mining_target_lock = false
                    if player_ship.mining_timer_info ~= nil then
                        player_ship:removeCustom(player_ship.mining_timer_info)
                        player_ship.mining_timer_info = nil
                    end
                end
            else	--not locked
                local mining_objects = asteroidMining_getMiningObjects(player_ship)
                
                if mining_objects ~= nil and #mining_objects > 0 then
                    if _asteroidMining_isValid(player_ship.mining_target) then
                        -- Search currently selected mining target in mining_objects. 
                        local target_in_list = false
                        for i=1,#mining_objects do
                            if mining_objects[i] == player_ship.mining_target then
                                target_in_list = true   -- Current target found
                                break
                            end
                        end		--end of check for the current target in list loop
                        
                        if not target_in_list then
                            -- Current target not found, set first from mining_objects. 
                            player_ship.mining_target = mining_objects[1]
                            asteroidMining_removeMiningButtons(player_ship)
                        end
                    else
                        -- No target was selected, set first from mining_objects
                        player_ship.mining_target = mining_objects[1]
                    end
                    asteroidMining_addMiningButtons(player_ship,mining_objects)
                else	--no mining objects
                    if player_ship.mining_target ~= nil then
                        asteroidMining_removeMiningButtons(player_ship)
                        player_ship.mining_target = nil
                    end
                end
            end  -- end if mining_target_lock
        else	--not moving slowly enough to mine
            asteroidMining_removeMiningButtons(player_ship)
            if player_ship.mining_timer_info ~= nil then
                player_ship:removeCustom(player_ship.mining_timer_info)
                player_ship.mining_timer_info = nil
            end
            if player_ship.trigger_mine_beam_button then
                player_ship:removeCustom(player_ship.trigger_mine_beam_button)
                player_ship.trigger_mine_beam_button = nil
            end
            player_ship.mining_target_lock = false
            player_ship.mining_in_progress = false
            player_ship.mining_timer = nil
        end
    end  -- if player ship has mining enabled.
end

-- Enable mining functionality on player ship
function asteroidMining_enable(player_ship)
    if player_ship.mining == false or player_ship.mining == nil then
        player_ship.mining = true
    end
end

-- Disable mining functionality on player ship
function asteroidMining_disable(player_ship)
    if player_ship.mining == true then
        player_ship.mining = false
    end
end

-------------------------------------------------------------------------------
--	Internal helper functions
-------------------------------------------------------------------------------

-- Returns true/false if object is valid object for mining. 
-- Any altering logic should be put here (excluding VisualAsteroids, check player callback if object is valid, etc...)
function _asteroidMining_isValidMiningObject(object)
    local retval = false
    
    local object_type = object.typeName
    if object_type ~= nil then
        if object_type == "Asteroid" or (object_type == "VisualAsteroid" and asteroidMining_ENABLE_VISUAL_ASTEROID == true) then
            retval = true
        end
    end
    
    return retval
end --_asteroidMining_isValidMiningObject

-- Retruns true if object is valid. 
function _asteroidMining_isValid(obj)
    local retval = false
    if obj ~= nil and obj:isValid() then
        retval = true
    end
    return retval
end

-- Returns a list of available asteroids which can be targeted by mining. 
function asteroidMining_getMiningObjects(player_ship)
    local nearby_objects = player_ship:getObjectsInRange(asteroidMining_DETECTION_RADIUS)
    local mining_objects = {}
    if nearby_objects ~= nil and #nearby_objects > 1 then
        for _, obj in ipairs(nearby_objects) do
            if player_ship ~= obj then
                if _asteroidMining_isValidMiningObject(obj) then
                    table.insert(mining_objects,obj)
                end
            end     -- end of check that object is not player ship. 
        end		--end of nearby object list loop
    end
    return mining_objects
end

-- This function (triggered by "Lock For Mining" button) transfers mining controls from SCIENCE to WEAPONS. 
function asteroidMining_lockForMiningAction(player_ship)
    local cpx, cpy = player_ship:getPosition()
    local tpx, tpy = player_ship.mining_target:getPosition()
    local asteroid_distance = distance(cpx,cpy,tpx,tpy)
    if asteroid_distance < asteroidMining_MINING_DISTANCE then
        player_ship.mining_target_lock = true
        local mining_locked_message = "mining_locked_message"
        player_ship:addCustomMessage("Science",mining_locked_message,"Mining target locked\nWeapons may trigger the mining beam")
    else
        local mining_lock_fail_message = "mining_lock_fail_message"
        player_ship:addCustomMessage("Engineering",mining_lock_fail_message,string.format("Mining target lock failed\nAsteroid distance is %.4fU\nMaximum range for mining is 1U",asteroid_distance/1000))
        player_ship.mining_target = nil
    end
    asteroidMining_removeMiningButtons(player_ship)
end     -- end aseroidMining_lockForMiningAction

-- This function (triggered by "Target Asteroid" button) shows information about currently selected target. 
function asteroidMining_targetAsteroidAction(player_ship)
    string.format("")	--necessary to have global reference for Serious Proton engine
    local cpx, cpy = player_ship:getPosition()
    local tpx, tpy = player_ship.mining_target:getPosition()
    local theta = math.atan(tpy - cpy,tpx - cpx)
    if theta < 0 then
        theta = theta + 6.2831853071795865
    end

    local target_description = "target_description"
    
    local target_distance = distance(cpx, cpy, tpx, tpy)/1000
    local angle = theta * 57.2957795130823209
    angle = angle + 90
    if angle >= 360 then
        angle = angle - 360
    end
    player_ship:addCustomMessage("Science",target_description,string.format("Distance: %.1fU\nBearing: %.1f\n",target_distance,angle))
end -- asteroidMining_targetAsteroidAction

-- This function (triggered by "Other Mining Target" button) switches target to next available target. 
function asteroidMining_otherMiningTargetAction(player_ship)
    local mining_objects = asteroidMining_getMiningObjects(player_ship)
        if mining_objects ~= nil and #mining_objects > 0 then
        --print(string.format("%i tractorable objects under 1 unit away",#tractor_objects))
        if player_ship.mining_target ~= nil and player_ship.mining_target:isValid() then
            local target_in_list = false
            local matching_index = 0
            for i=1,#mining_objects do
                if mining_objects[i] == player_ship.mining_target then
                    target_in_list = true
                    matching_index = i
                    break
                end
            end		--end of check for the current target in list loop
            if target_in_list then
                if #mining_objects > 1 then
                    if #mining_objects > 2 then
                        local new_index = matching_index
                        repeat
                            new_index = math.random(1,#mining_objects)
                        until(new_index ~= matching_index)
                        player_ship.mining_target = mining_objects[new_index]
                    else
                        if matching_index == 1 then
                            player_ship.mining_target = mining_objects[2]
                        else
                            player_ship.mining_target = mining_objects[1]
                        end
                    end
                    asteroidMining_removeMiningButtons(player_ship)
                    asteroidMining_addMiningButtons(player_ship,mining_objects)
                end
            else
                player_ship.mining_target = mining_objects[1]
                asteroidMining_removeMiningButtons(player_ship)
                asteroidMining_addMiningButtons(player_ship,mining_objects)
            end
        else
            player_ship.mining_target = mining_objects[1]
            asteroidMining_addMiningButtons(player_ship,mining_objects)
        end
    else	--no nearby tractorable objects
        if player_ship.mining_target ~= nil then
            asteroidMining_removeMiningButtons(player_ship)
            player_ship.mining_target = nil
        end
    end
end -- asteroidMining_otherMiningTargetAction

-- Removes SCIENCE mining buttons. 
function asteroidMining_removeMiningButtons(player_ship)
	if player_ship.mining_next_target_button ~= nil then
		player_ship:removeCustom(player_ship.mining_next_target_button)
		player_ship.mining_next_target_button = nil
	end
	if player_ship.mining_target_button ~= nil then
		player_ship:removeCustom(player_ship.mining_target_button)
		player_ship.mining_target_button = nil
	end
	if player_ship.mining_lock_button ~= nil then
		player_ship:removeCustom(player_ship.mining_lock_button)
		player_ship.mining_lock_button = nil
	end
end

-- Add SCIENCE mining buttons to player_ship, depenidng on number of mining targets. 
function asteroidMining_addMiningButtons(player_ship,mining_objects)
	local cpx, cpy = player_ship:getPosition()
	local tpx, tpy = player_ship.mining_target:getPosition()
	
    if player_ship.mining_lock_button == nil then
		if player_ship:hasPlayerAtPosition("Science") then
			player_ship.mining_lock_button = "mining_lock_button"
			player_ship:addCustomButton("Science", player_ship.mining_lock_button, "Lock for Mining",
                                        function() asteroidMining_lockForMiningAction(player_ship) end)
		end
	end
    
	if player_ship.mining_target_button == nil then
		if player_ship:hasPlayerAtPosition("Science") then
			player_ship.mining_target_button = "mining_target_button"
			player_ship:addCustomButton("Science",player_ship.mining_target_button,"Target Asteroid",
                                        function() asteroidMining_targetAsteroidAction(player_ship) end)
		end
	end
    
	if #mining_objects > 1 then
		if player_ship.mining_next_target_button == nil then
			if player_ship:hasPlayerAtPosition("Science") then
				player_ship.mining_next_target_button = "mining_next_target_button"
				player_ship:addCustomButton("Science",player_ship.mining_next_target_button,"Other mining target",
                                    function() asteroidMining_otherMiningTargetAction(player_ship) end)
			end
		end
	else -- Just 1 mining object available
		if player_ship.mining_next_target_button ~= nil then
			player_ship:removeCustom(player_ship.mining_next_target_button)
			player_ship.mining_next_target_button = nil
		end
	end
end     -- end asteroidMining_addMiningButtons
