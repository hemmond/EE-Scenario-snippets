-- Name: utils_asteroidMining
-- Description: Functions to enhance player ships with asteroid mining functionality.
--- Code is extracted from Xansta's sandbox scenario. 

--  If you want to use asteroid mining functionality, you need to call:
--  * asteroidMining_init() function in your init() function (to set up this module)
--  * asteroidMining_update(player_ship) function for each of your player ships in update() function

--  To set up asteroid mining functionality, you need to call asteroidMining_enable(player_ship) on required ship. 
--  To remove asteroid mining functionality, you need to call asteroidMining_disable(player_ship) on required ship.

--  For usage in callbacks, the convenienence function asteroidMining_getHeadingAndDistance(player_ship, object) retunrs heading and distance of the object relative from the player ship. 

--  To replace default callbacks with mission-defined ones, use:
--  * asteroidMining_setCanBeMinedCallback(func)
--  * asteroidMining_setMiningFinishedCallback(func)
--  * asteroidMining_setTargetInfoCallback(func)


require("utils.lua")

-------------------------------------------------------------------------------
--	Public API functions 
-------------------------------------------------------------------------------

-- Init asteroid mining library
function asteroidMining_init(config)
    asteroidMining_MAXIMUM_VELOCITY = 10        -- Mining is not available above this speed. 
    asteroidMining_MINING_DISTANCE = 1000       -- Distance on which object can be targetted and mining beam started. 
    asteroidMining_MINING_DURATION = 5          -- Number of seconds till mining is finished
    asteroidMining_MINING_DRAIN = .00025        -- Coeficient of power consumption. 
    asteroidMining_MINING_BEAM_HEAT = .0025     -- Heat generated to beam weapons while mining. 
    
    if config ~= nil then
        if config.MAXIMUM_VELOCITY ~= nil and tonumber(config.MAXIMUM_VELOCITY) ~= nil then
            asteroidMining_MAXIMUM_VELOCITY = tonumber(config.MAXIMUM_VELOCITY)
        end
        
        if config.MINING_DISTANCE ~= nil and tonumber(config.MINING_DISTANCE) ~= nil then
            asteroidMining_MINING_DISTANCE = tonumber(config.MINING_DISTANCE)
        end
        
        if config.MINING_DURATION ~= nil and tonumber(config.MINING_DURATION) ~= nil then
            asteroidMining_MINING_DURATION = tonumber(config.MINING_DURATION)
        end
        
        if config.MINING_DRAIN ~= nil and tonumber(config.MINING_DRAIN) ~= nil then
            asteroidMining_MINING_DRAIN = tonumber(config.MINING_DRAIN)
        end
        
        if config.MINING_BEAM_HEAT ~= nil and tonumber(config.MINING_BEAM_HEAT) ~= nil then
            asteroidMining_MINING_BEAM_HEAT = tonumber(config.MINING_BEAM_HEAT)
        end
    end
    
    asteroidMining_MINING_BEAM_STRING = {
		"beam_orange.png",
		"beam_yellow.png",
		"fire_sphere_texture.png"
	}
    
    -- Callback called after mining finishes before clearing player_ship.mining_target variable
    -- @param player_ship: ship that just finished mining. 
    asteroidMining_MINING_FINISHED_CALLBACK = function(player_ship) 
            local angle, target_distance = asteroidMining_getHeadingAndDistance(player_ship, player_ship.mining_target)
            print(string.format("Mining finished on asteroid:\tDistance: %.1fU\tBearing: %.1f",target_distance/1000,angle))
        end
    
    -- Callback called when testing if specified object in range can be mined. 
    -- @param object: object which is being tested for mineability.
    -- @returns: true if object can be mined, false otherwise.
    asteroidMining_CAN_BE_MINED_CALLBACK = function(object)
            local ENABLE_VISUAL_ASTEROID = true
            local retval = false
            
            if object ~= nil then
                local object_type = object.typeName
                if object_type ~= nil then
                    if object_type == "Asteroid" or (object_type == "VisualAsteroid" and ENABLE_VISUAL_ASTEROID == true) then
                        retval = true
                    end
                end
            end --object not nil
            
            return retval
        end --end of asteroidMining_CAN_BE_MINED_CALLBACK
    
    -- Callback called when retrieving info about currently targeted object.
    -- @param player_ship: ship which is requiring info about targeted object
    -- @returns: string to be shown in CustomInfo on Science screen.
    asteroidMining_TARGET_INFO_CALLBACK = function(player_ship)
            local angle, target_distance = asteroidMining_getHeadingAndDistance(player_ship, player_ship.mining_target)
            return string.format("Distance: %.1fU\nBearing: %.1f\n",target_distance/1000,angle)
        end  -- end of asteroidMining_TARGET_INFO_CALLBACK
end

-- Set Can Be Mined callback to user defined function
-- @param func: function to use as Can Be Mined callback.
function asteroidMining_setCanBeMinedCallback(func)
    asteroidMining_CAN_BE_MINED_CALLBACK = func
end 

-- Set Target Info callback to user defined function
-- @param func: function to use as Target Info callback.
function asteroidMining_setTargetInfoCallback(func)
    asteroidMining_TARGET_INFO_CALLBACK = func
end

-- Set Mining Finished callback to user defined function
-- @param func: function to use as Mining Finished callback.
function asteroidMining_setMiningFinishedCallback(func)
    asteroidMining_MINING_FINISHED_CALLBACK = func
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
                            asteroidMining_MINING_FINISHED_CALLBACK(player_ship)
                            player_ship.mining_target_lock = false
                            player_ship.mining_timer = nil
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
    end  -- end if player ship has mining enabled.
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
        asteroidMining_removeMiningButtons(player_ship)
        
        player_ship.mining_target_lock = false
        player_ship.mining_in_progress = false
        player_ship.mining_timer = nil
        player_ship.mining_target = nil
        
        if player_ship.trigger_mine_beam_button ~= nil then
            player_ship:removeCustom(player_ship.trigger_mine_beam_button)
            player_ship.trigger_mine_beam_button = nil
        end
        
        if player_ship.mining_timer_info ~= nil then
            player_ship:removeCustom(player_ship.mining_timer_info)
            player_ship.mining_timer_info = nil
        end
    end
end

-- Retunrs heading, distance pair of the object heading and distance relative from the player ship. 
function asteroidMining_getHeadingAndDistance(player_ship, object)
    string.format("")	--necessary to have global reference for Serious Proton engine
    local cpx, cpy = player_ship:getPosition()
    local tpx, tpy = object:getPosition()
    local target_distance = distance(cpx, cpy, tpx, tpy)
    
    local theta = math.atan(tpy - cpy,tpx - cpx)
    if theta < 0 then
        theta = theta + 6.2831853071795865
    end
    
    local angle = theta * 57.2957795130823209
    angle = angle + 90
    if angle >= 360 then
        angle = angle - 360
    end
    return angle, target_distance
end

-------------------------------------------------------------------------------
--	Internal helper functions
-------------------------------------------------------------------------------

-- Returns true/false if object is valid object for mining. 
-- It is simply a wrapper around asteroidMining_CAN_BE_MINED_CALLBACK(object)
function _asteroidMining_isValidMiningObject(object)
    local retval = false
    
    if asteroidMining_CAN_BE_MINED_CALLBACK(object) then
        retval = true
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
    local nearby_objects = player_ship:getObjectsInRange(asteroidMining_MINING_DISTANCE)
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
    local angle, asteroid_distance = asteroidMining_getHeadingAndDistance(player_ship, player_ship.mining_target)
    if asteroid_distance <= asteroidMining_MINING_DISTANCE then
        player_ship.mining_target_lock = true
        local mining_locked_message = "mining_locked_message"
        player_ship:addCustomMessage("Science",mining_locked_message,"Mining target locked\nWeapons may trigger the mining beam")
    else
        --TODO should this pop on Engineering or Science? 
        local mining_lock_fail_message = "mining_lock_fail_message"
        player_ship:addCustomMessage("Science",mining_lock_fail_message,string.format("Mining target lock failed\nAsteroid distance is %.4fU\nMaximum range for mining is 1U",asteroid_distance/1000))
        player_ship.mining_target = nil
    end
    asteroidMining_removeMiningButtons(player_ship)
end     -- end aseroidMining_lockForMiningAction

-- This function (triggered by "Target Asteroid" button) shows information about currently selected target. 
function asteroidMining_targetAsteroidAction(player_ship)
    local target_description = "target_description"
    player_ship:addCustomMessage("Science",target_description,asteroidMining_TARGET_INFO_CALLBACK(player_ship))
end -- asteroidMining_targetAsteroidAction

-- This function (triggered by "Other Mining Target" button) switches target to next available target. 
function asteroidMining_otherMiningTargetAction(player_ship)
    local mining_objects = asteroidMining_getMiningObjects(player_ship)
        if mining_objects ~= nil and #mining_objects > 0 then
        --print(string.format("%i tractorable objects under 1 unit away",#tractor_objects))
        if _asteroidMining_isValid(player_ship.mining_target) then 
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
    else	--no nearby mineable objects
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
