-- Name: utils_jumpCallbackChecker
-- Description: Script-side implemented custom callback launcher on jump initiated (Jump button pressed) and jump finished (ship appeared on new position)

--- Module API description: 
--- * jumpCallbackChecker:init_ship(ship, jump_initiated_callback, jump_finished_callback) = Initialize checker for specified ship. 
--- * jumpCallbackChecker:update() = Check all ships for jumps (should be called from scenario update() function.


require("utils.lua")

jumpCallbackChecker = {
    checked_ships = {},     -- list of ships that have this functionality enabled
    MIN_DISTANCE = 3000     -- minimum of 3U to trigger jump_finished_callback
}


-- -------------------------------------------------------------
-- Public API for the whole module
-- -------------------------------------------------------------

-- Initialize checker for specified ship
-- @param ship: PlayerSpaceship object
-- @param jump_initiated_callback: function that should be called when jump is initiated (countdown started), optional. 
-- @param jump_finished_callback: function that should be called when jump is finished (ship moved), optional, but if set, requires jump_initiated_callback to be set.
function jumpCallbackChecker:init_ship(ship, jump_initiated_callback, jump_finished_callback)
    local pos_x, pos_y = ship:getPosition()
    local charge = ship:getJumpDriveCharge()
    
    if jump_initiated_callback == nil then
        jump_initiated_callback = function() end
    end
    
    if jump_finished_callback == nil then
        jump_finished_callback = function() end
    end
    
    ship._jumpCallbackCheckerData = {
        JUMP_CHARGE = charge,
        LAST_POS_X = pos_x,
        LAST_POS_Y = pos_y,
        
        jump_initiated = jump_initiated_callback,
        jump_finished = jump_finished_callback, 
        jump_in_progress = false
    }
    
    table.insert(jumpCallbackChecker.checked_ships, ship)
end


-- Check all ships if jump occured and update last values. 
-- This function should be called in scenario update() function.
function jumpCallbackChecker:update()
    for i, ship in ipairs(jumpCallbackChecker.checked_ships) do
        jumpCallbackChecker:_update_ship(ship)
    end
end


-- -------------------------------------------------------------
-- Private methods
-- -------------------------------------------------------------

-- Checks for jump callbacks trigger events and updates stored values on specified ship. 
-- @param ship: Ship that should be checked if any of jump events occured on it.
function jumpCallbackChecker:_update_ship(ship)
    if ship._jumpCallbackCheckerData ~= nil then
        local charge = ship:getJumpDriveCharge()
        
        if ship._jumpCallbackCheckerData.jump_in_progress then
            dist = distance(ship._jumpCallbackCheckerData.LAST_POS_X, ship._jumpCallbackCheckerData.LAST_POS_Y, ship)
            if dist > jumpCallbackChecker.MIN_DISTANCE then
                ship._jumpCallbackCheckerData.jump_finished()
                ship._jumpCallbackCheckerData.jump_in_progress = false
            end
        end
        
        if charge < ship._jumpCallbackCheckerData.JUMP_CHARGE then
            ship._jumpCallbackCheckerData.jump_initiated()
            ship._jumpCallbackCheckerData.jump_in_progress = true
        end
        
        local pos_x, pos_y = ship:getPosition()
        ship._jumpCallbackCheckerData.JUMP_CHARGE = ship:getJumpDriveCharge()
        ship._jumpCallbackCheckerData.LAST_POS_X = pos_x
        ship._jumpCallbackCheckerData.LAST_POS_Y = pos_y
    end
end
