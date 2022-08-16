-- Name: utils_durableWarpJammer
-- Description: Durable warp jammer is warp jammer that has hit points and needs more than one shot to kill it. 
--- 

durableWarpJammer = {
    default_hitpoins = 250
}

function durableWarpJammer:warpJammer()
    local jammer = WarpJammer()
    
    function jammer:setHitpoins(hitpoins)
        jammer.durableWarpJammerHitpoins = hitpoins
    end

    function jammer:getHitpoints()
        if jammer.durableWarpJammerHitpoins ~= nil then
            return jammer.durableWarpJammerHitpoins
        else
            return 0
        end
    end

    jammer.setHitpoins(default_hitpoins)
end
