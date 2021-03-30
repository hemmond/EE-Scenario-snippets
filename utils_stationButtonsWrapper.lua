-- Name: utils_stationButtonsWrapper
-- Description: Wrapper upon different stations, so mission author can add button/information to station Operator, 
--- abstracting the position through which the operator fulfills his duties. 
--- This module should remove multiple boilerplate to accomodate 6/5 and 4/3 station categories. 
--- Operator in context of this module means player fulfilling specific duties aboard the ship
--- (for example Engineer can use "Engineering" or "Engineering+"). 

--- Module API description: 
--- * utils_ButtonWrapper:modifyOperatorPositions(operator_key, position_list) = Modify ECrewPositions for specified station
--- * utils_ButtonWrapper:addCustomButton(player_ship, operator, name, caption, callback)
--- * utils_ButtonWrapper:addCustomInfo(player_ship, operator, name, caption)
--- * utils_ButtonWrapper:addCustomMessage(player_ship, operator, name, caption)
--- * utils_ButtonWrapper:addCustomMessageWithCallback(player_ship, operator, name, caption, callback)
--- * utils_ButtonWrapper:removeCustom(player_ship, name)

--- Functions that might be interesting in specific use-cases:
--- * utils_ButtonWrapper:operatorPositions(operator_key)
--- * utils_ButtonWrapper:printOperatorPositions(operator_key)

-- TODO list:
--- * When addCustomMessage is called, it is shown on all positions. Think about adding as addCustomMessageWithCallback where callback will close all messages of the same name.

-- Create Button Wrapper module with default Operator positions
utils_ButtonWrapper = {
    -- Not assinged ECrewPositions: "DamageControl", "PowerManagement", "Database", "CommsOnly", "ShipLog"
    operators = {
        ["Helms"]={"Helms", "Tactical", "Single"}, 
        ["Weapons"]={"Weapons", "Tactical", "Single"}, 
        ["Engineering"]={"Engineering", "Engineering+"}, 
        ["Science"]={"Science", "Operations"},
        ["Relay"]={"Relay", "Operations", "AltRelay"}
    }
}

-- -------------------------------------------------------------
-- Public API for the whole module
-- -------------------------------------------------------------

-- Modify Operator position list
-- @param operator_key: String identification of operator (new or existing)
-- @param position_list: Table (list) of ECrewPositions strings to be assigned to this operator
function utils_ButtonWrapper:modifyOperatorPositions(operator_key, position_list)
    self.operators[operator_key] = position_list
end

-- Get Operator position list
-- @param operator_key: String identification of existing operator
-- @returns: Table (list) of ECrewPositions strings for this operator (or empty table if operator does not exists)
function utils_ButtonWrapper:operatorPositions(operator_key)
    if self.operators[operator_key] ~= nil then
        return self.operators[operator_key]
    end
    return {}
end

-- -------------------------------------------------------------
-- Wrapped functions for work with Custom elements
-- -------------------------------------------------------------

-- Add custom button to all stations for specified operator.
-- @param player_ship: Player ship to which you want to add a custom button
-- @param operator: String identification of operator. 
-- @param name: String identifier of the button (parameter of PlayerShip:addCustomButton)
-- @param caption: Label of the button (parameter of PlayerShip:addCustomButton)
-- @param callback: Callback function to be run when button is pressed (parameter of PlayerShip:addCustomButton)
function utils_ButtonWrapper:addCustomButton(player_ship, operator, name, caption, callback)
    for _, station in ipairs(self:operatorPositions(operator)) do
        player_ship:addCustomButton(station, name..station, caption, callback)
    end
end

-- Add custom info to all stations for specified operator:
-- @param player_ship: Player ship to which you want to add a custom information field.
-- @param operator: String identification of operator. 
-- @param name: String identifier of the message (parameter of PlayerShip:addCustomInfo)
-- @param caption: Text content of the info field (parameter of PlayerShip:addCustomInfo)
function utils_ButtonWrapper:addCustomInfo(player_ship, operator, name, caption)
    for _, station in ipairs(self:operatorPositions(operator)) do
        player_ship:addCustomInfo(station, name..station, caption)
    end
end

-- Add custom message to all stations for specified operator.
-- @param player_ship: Player ship to which you want to add a custom message
-- @param operator: String identification of operator. 
-- @param name: String identifier of the message (parameter of PlayerShip:addCustomMessage)
-- @param caption: Text of the message (parameter of PlayerShip:addCustomMessage)
function utils_ButtonWrapper:addCustomMessage(player_ship, operator, name, caption)
    for _, station in ipairs(self:operatorPositions(operator)) do
        player_ship:addCustomMessage(station, name..station, caption)
    end
end

-- Add custom message with callback to all stations for specified operator.
-- @param player_ship: Player ship to which you want to add a custom message
-- @param operator: String identification of operator. 
-- @param name: String identifier of the message (parameter of PlayerShip:addCustomMessageWithCallback)
-- @param caption: Text of the message (parameter of PlayerShip:addCustomMessageWithCallback)
-- @param callback: Callback function to be run when message is closed (parameter of PlayerShip:addCustomMessageWithCallback)
function utils_ButtonWrapper:addCustomMessageWithCallback(player_ship, operator, name, caption, callback)
    for _, station in ipairs(self:operatorPositions(operator)) do
        player_ship:addCustomMessageWithCallback(station, name..station, caption, callback)
    end
end

-- Remove custom element from all stations
-- @param player_ship: Player ship to which you want to add a custom message
-- @param name: String identifier of the element to be removed.
function utils_ButtonWrapper:removeCustom(player_ship, name)
    local crew_positions = {"Helms", "Weapons", "Engineering", "Science", "Relay", "Tactical", 
                            "Engineering+", "Operations", "Single", "DamageControl", "PowerManagement", 
                            "Database", "AltRelay", "CommsOnly", "ShipLog"}
    for _, station in ipairs(crew_positions) do
        print("Removing ", name, " from ", station)
        player_ship:removeCustom(name..station)
    end
end

-- Debugging function which prints ECrewPositions strings for selected operator
-- @param operator_key: String identification of existing operator
function utils_ButtonWrapper:printOperatorPositions(operator_key)
    print("Stations for "..operator_key..": ")
    for _, station in ipairs(self:operatorPositions(operator_key)) do
        print (station)
    end
    print("=====")
end

--[[
This code can be used to test modification of Operator positions list:

utils_ButtonWrapper:modifyOperatorPositions("Test", {"Helms", "Tactical", "Single", "Weapons",  "Engineering"})
utils_ButtonWrapper:printOperatorPositions("Helms")
utils_ButtonWrapper:printOperatorPositions("Test")
--]]
