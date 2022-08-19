-- Name: utils_ehnancedWarpJammer.lua
-- Description: Enhanced warp jammers are warp jammers with a twist.
--- This utils library aspires to have more as the time progresses.
--- Currently it provides only VariableRange warp jammer.

-- Module API description
--- * enhancedWarpJammer:enableDebugPrints() = calling this will enable debugging output of this module (when not called, this module should not write to logfile).
--- * enhancedWarpJammer:VariableRange() = creates Variable Range warp jammer. This jammer will reduce its range every time it has been hit.

-- VariableRange warp jammer API (additional methods in addition to WarpJammer LUA api methods)
--- * WarpJammer:setRangeStep(num) = Every time the jammer is hit, it will substract this amount for every 1 point of damage (default 50).
--- * WarpJammer:setMinimalRange(num) = When range gets under this value after it was hit, warp jammer will be destroyed (default 500 = 0,5U).
--- * WarpJammer.jammerType = here is string containing "VariableRange", for testing if this jammer have methods above.

enhancedWarpJammer = {
    debug_prints = false,
    
    variable_range_step = 50,    -- Substract this value from range for every point of damage received.
    variable_range_minimum_range = 500  -- When range drops below this value, jammer is destroyed.
}

--- Debugging method that enables debugging output from this library.
function enhancedWarpJammer:enableDebugPrints()
    enhancedWarpJammer.debug_prints = true

end

--- Internal auxiliary method used throughout this code to print text only if enabled.
--- @param text: Text that should be printed to logfile (if debug output is enabled).
function enhancedWarpJammer:_debug_print(text)
    if enhancedWarpJammer.debug_prints then
        print(text)
    end
end

--- Creates VariableRange warp jammer
--- This jammer will decrease its range for every hit it receives. When range drops to zero, jammer is destroyed.
function enhancedWarpJammer:VariableRange()
    enhancedWarpJammer:_debug_print("creating VariableRange warp jammer")
    local jammer = WarpJammer()

    jammer.jammerType = "VariableRange"
    jammer.rangeStep = enhancedWarpJammer.variable_range_step
    jammer.rangeMinimum = enhancedWarpJammer.variable_range_minimum_range
    jammer:setHull(250)

    jammer:onTakingDamage(function(jammer, attacker)
        local damage_taken_ = 250 - jammer:getHull()
        local new_range_ = jammer:getRange()-damage_taken_*jammer.rangeStep

        enhancedWarpJammer:_debug_print("VariableRange jammer has taken ".. damage_taken_ .." damage, range delta: ".. new_range_)

        if new_range_ > jammer.rangeMinimum then
            jammer:setRange(new_range_)
            enhancedWarpJammer:_debug_print("VariableRange jammer HP: "..jammer:getHull().." | new range: " .. jammer:getRange())
            jammer:setHull(250)
        else
            --range is down, kill the jammer.
            enhancedWarpJammer:_debug_print("VariableRange jammer range dropped below "..jammer.rangeMinimum.." - destroying")
            jammer:setHull(1)
            jammer:takeDamage(20)
        end
    end)

    function jammer:setRangeStep(step)
        jammer.rangeStep = step
        enhancedWarpJammer:_debug_print("VariableRange jammer range step set to: " .. jammer.rangeStep)
    end

    function jammer:setMinimalRange(range)
        jammer.rangeMinimum = range
        enhancedWarpJammer:_debug_print("VariableRange jammer minimal range set to: " .. jammer.rangeMinimum)
    end

    enhancedWarpJammer:_debug_print("VariableRange warp jammer created")
    return jammer
end
