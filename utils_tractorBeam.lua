-- Name: tractor_beam_utils
-- Description: Functions to enhance player ships with tractor beam functionality. 
--- Code is extracted from Xansta's sandbox scenario. 

--  If you want to use Tractor Beam functionality, you need to call:
--  * tractorBeam:update(player_ship) function for each of your player ships in update() function

-- To set up tractor beam functionality, you need to call tractorBeam:enable(player_ship) on required ship. 
-- To remove tractor beam functionality, you need to call tractorBeam:disable(player_ship) on required ship. 
-- Ro check if tractor beam functionality is enabled, you need to call tractorBeam:isEnabled(player_ship) on required ship.

-- TODO:
-- * Tractor Beam power consumption is dependent on number of update() calls, not on time elapsed. 
-- * implement function setVisualAsteroidsTractorable(true|false)

require("utils.lua")

tractorBeam = {
    DISTANCE = 1000,    -- aka 1U
    TEAROFF_VELOCITY = 1,   -- If speed is above this value (roughly equals 3U/min)

    textures_string = {
        "beam_blue.png",
        "shield_hit_effect.png",
        "electric_sphere_texture.png"
    },
    energy_drain = .000005
}

-- This enables tractor beam function on specified player ship
function tractorBeam:enable(player_ship)
    if player_ship._tractorBeamData == nil then
        player_ship._tractorBeamData = {
            enabled = true,
            target_lock = false
        }
    elseif player_ship._tractorBeamData.enabled == false then
        player_ship._tractorBeamData.enabled = true
        player_ship._tractorBeamData.target_lock = false
    end
end

-- This removes tractor beam function on specified player ship
function tractorBeam:disable(player_ship)
    if player_ship._tractorBeamData ~= nil and player_ship._tractorBeamData.enabled == true then
        --print("TB disable", player_ship:getCallSign())
        player_ship._tractorBeamData.enabled = false
        player_ship._tractorBeamData.target_lock = false
        tractorBeam:removeTractorObjectButtons(player_ship)
        if player_ship._tractorBeamData.disengage_tractor_button ~= nil then
            player_ship._tractorBeamData.target_lock = false
            player_ship:removeCustom(player_ship._tractorBeamData.disengage_tractor_button)
            player_ship._tractorBeamData.disengage_tractor_button = nil
        end
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

function tractorBeam:processTractor(player_ship)
    local cpx, cpy = player_ship:getPosition()
    
    if player_ship._tractorBeamData.tractor_target ~= nil and player_ship._tractorBeamData.tractor_target:isValid() then -- Valid tractor beam target ready to lock
        player_ship._tractorBeamData.tractor_target:setPosition(cpx+player_ship._tractorBeamData.tractor_vector_x,cpy+player_ship._tractorBeamData.tractor_vector_y)
        player_ship:setEnergy(player_ship:getEnergy() - player_ship:getMaxEnergy()*tractorBeam.energy_drain)
        if random(1,100) < 27 then
            BeamEffect():setSource(player_ship,0,0,0):setTarget(player_ship._tractorBeamData.tractor_target,0,0):setDuration(1):setRing(false):setTexture(tractorBeam.textures_string[math.random(1,#tractorBeam.textures_string)])
        end
        if player_ship._tractorBeamData.disengage_tractor_button == nil then
            player_ship._tractorBeamData.disengage_tractor_button = "disengage_tractor_button"
            player_ship:addCustomButton("Engineering",player_ship._tractorBeamData.disengage_tractor_button,"Disengage Tractor",function()
                player_ship._tractorBeamData.target_lock = false
                player_ship:removeCustom(player_ship._tractorBeamData.disengage_tractor_button)
                player_ship._tractorBeamData.disengage_tractor_button = nil
            end)
        end
    else	--invalid tractor target
        player_ship._tractorBeamData.target_lock = false
        player_ship:removeCustom(player_ship._tractorBeamData.disengage_tractor_button)
        player_ship._tractorBeamData.disengage_tractor_button = nil
    end
end

-- This function needs to be called inside update() function. 
function tractorBeam:update(player_ship)
    player_name = player_ship:getCallSign()
    --print("TB update: ", player_ship:getCallSign())
    -- Count velocity of player ship, tractor beam works on low velocities only. 
    local vx, vy = player_ship:getVelocity()
    local dx=math.abs(vx)
    local dy=math.abs(vy)
    local player_velocity = math.sqrt((dx*dx)+(dy*dy))
        
    if tractorBeam:isEnabled(player_ship) == true then       --Process this only if the ship has Tractor beam enabled. 
        if player_velocity < tractorBeam.TEAROFF_VELOCITY then
            --print(string.format("%s velocity: %.1f slow enough to establish tractor",player_name,player_velocity))
            if player_ship._tractorBeamData.target_lock then
                tractorBeam:processTractor(player_ship)
            else	--tractor not locked on target
                local tractor_objects = tractorBeam:getTractorObjects(player_ship)
                if tractor_objects ~= nil and #tractor_objects > 0 then
                    --print(string.format("%i tractorable objects under 1 unit away",#tractor_objects))
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
                    --print("TB no nearby tractorable objects", player_name)
                    if player_ship._tractorBeamData.tractor_target ~= nil then
                        tractorBeam:removeTractorObjectButtons(player_ship)
                        player_ship._tractorBeamData.tractor_target = nil
                    end
                end --end of check that tractor_object exists and is not empty
            end
        else	--not moving slowly enough to establish tractor
            tractorBeam:removeTractorObjectButtons(player_ship)
            --print(string.format("%s velocity: %.1f too fast to establish tractor",player_name,player_velocity))
            if player_velocity > 50 then
                --print(string.format("%s velocity: %.1f too fast to continue tractor",player_name,player_velocity))
                player_ship._tractorBeamData.target_lock = false
                if player_ship._tractorBeamData.disengage_tractor_button ~= nil then
                    player_ship:removeCustom(player_ship._tractorBeamData.disengage_tractor_button)
                    player_ship._tractorBeamData.disengage_tractor_button = nil
                end
            else
                if player_ship._tractorBeamData.target_lock then
                    tractorBeam:processTractor(player_ship)
                end		--end of tractor lock processing				
            end		--end of player moving slow enough to tractor branch
        end		--end of speed checks for tractoring
    end		--end of tractor checks
end
