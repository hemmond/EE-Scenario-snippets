-- Name: Scheduler test
-- Description: Test scheduler on planet appearing and disappearing every 5 seconds.
-- Type: Basic

require("utils_scheduler.lua")

function init()
    scheduler_init()
    
    planet = nil
    
    scheduler_add_periodic_job(5, function() 
        --string.format("")	--necessary to have global reference for Serious Proton engine
        print("Job fired", getScenarioTime() )
        
        if planet == nil then 
            planet = Planet():setPosition(5000, 5000):setPlanetRadius(3000):setDistanceFromMovementPlane(-2000):setPlanetSurfaceTexture("planets/planet-1.png"):setPlanetCloudTexture("planets/clouds-1.png"):setPlanetAtmosphereTexture("planets/atmosphere.png"):setPlanetAtmosphereColor(0.2, 0.2, 1.0)
        else
            planet:destroy()
            planet = nil
        end
    end, "periodic")
    
    --This job runs once and removes job with identificator "todelete"
    scheduler_add_job(8,   function() 
                                print("One-use job triggered at", getScenarioTime(), "removing job with ID todelete" ) 
                                scheduler_remove_job("todelete")
                            end)
    
    -- This job is added but should be removed in 18-th second by one-time job. 
    scheduler_add_job(12, function() print("This job is not triggered", getScenarioTime() ) end, "todelete")
end

function update()
    scheduler_update()
end