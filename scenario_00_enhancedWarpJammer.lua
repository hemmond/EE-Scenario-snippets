-- Name: Enhanced Warp Jammer
-- Description: Enhanced Warp Jammer module testing scenario
-- Type: Development

--- Scenario
-- @script enhancedWarpJammer

require("utils_enhancedWarpJammer.lua")
require("utils_customElements.lua")

function jammer_info(tgt_)
    if tgt_ ~= nil then
        local text_ = "Target: " .. tgt_:getCallSign() .. " (" .. tgt_.typeName .. ")\n"
        
        if tgt_.typeName == "WarpJammer" then
            text_ = text_ .. "Jammer hull: " .. tgt_:getHull() .. "\n"
            text_ = text_ .. "Jammer range: " .. tgt_:getRange() .. "\n"
        end

        customElements:addCustomMessage(player_ship, "Helms", "debugInfo", text_)
    end
end

function init()
    --set up libraries
    enhancedWarpJammer:enableDebugPrints()
    customElements:modifyOperatorPositions("Helms", {"Helms", "Weapons", "Tactical", "Single"})
    
    --create player ship
    player_ship = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis"):setHeading(0):setPosition(1000, 1000):commandTargetRotation(270):setAutoCoolant(true)
    customElements:addCustomButton(player_ship, "Helms", "restart", "Restart", function() setScenario("scenario_00_enhancedWarpJammer.lua", "None") end)
    
    --create jammers
    enhancedWarpJammer.VariableRange():setFaction("Kraylor"):setCallSign("VaRng")
    WarpJammer():setFaction("Kraylor"):setPosition(2000, 0):setCallSign("Normal")
    
    unpauseGame()   --for faster testing
end

function update(delta)
    -- Show range and hull of selected WarpJammer on stations.
    local tgt_ = player_ship:getTarget()
    if tgt_ ~= nil and tgt_.typeName == "WarpJammer" then
        customElements:addCustomInfo(player_ship, "Helms", "info_rng", "Range: "..tgt_:getRange())
        customElements:addCustomInfo(player_ship, "Helms", "info_hull", "Hull: "..tgt_:getHull())
    else
        customElements:removeCustom(player_ship, "info_rng")
        customElements:removeCustom(player_ship, "info_hull")
    end
end
