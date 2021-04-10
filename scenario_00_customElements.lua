-- Name: Custom Elements wrapper
-- Description: Demo mission for Custom Elements wrapper module
-- Type: Basic

--- Scenario
-- @script scenario_10_empty

require("utils.lua")
require("utils_customElements.lua")

function init()
    player = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis"):setRotation(200)
    print("before")
    
    customElements:closeAllMessagesUponClose(true)
    
    customElements:addCustomButton(player, "Engineering", "add", "Add", 
                                    function() 
                                        customElements:addCustomButton(player, "Engineering", "test", "test", 
                                                                       function() print("test clicked") end)
                                    end)
    customElements:addCustomButton(player, "Engineering", "del", "Del", function() customElements:removeCustom(player, "test") end)
    
    
    customElements:addCustomButton(player, "Engineering", "msg", "Msg", 
                                    function()
                                        customElements:addCustomMessageWithCallback(player, "Engineering", "testmsg", "Lorem Ipsum", 
                                                                                    function() 
                                                                                        print("message fired") 
                                                                                        customElements:removeCustom(player, "testmsg")
                                                                                    end)
                                    end)
    print("after")
end

function update(delta)
    customElements:addCustomInfo(player, "Engineering", "eng_info", string.format("Shields active: %s", tostring(player:getShieldsActive())))
    -- No victory condition
end
