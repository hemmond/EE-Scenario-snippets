-- Name: utils_scheduler
-- Description: Implementation of job scheduler

--  If you want to use Scheduler functionality, you need to call:
--  * scheduler_init() function in your init() function (to set up this module)
--  * scheduler_update() function in your update() function (to run jobs with expired timer)

-- To add job, use scheduler_add_job(run_in, func, identifier) function. 
-- To add periodic job, use scheduler_add_periodic_job(run_every, func, identifier) function.
-- To remove job, use scheduler_remove_job(identifier). 

-- For more throough documentation, see comments in each function headers. Function parameters and usage are explained there more thoroughly. 

-- Init scheduler library
function scheduler_init()
    scheduler_jobs = {}
end

-- Helper function to iterate over scheduled_jobs queue. 
-- @param identifier: if provided, it runs this function in job removal mode. If nil, it runs in update mode. 
function _scheduler_iterateOn(identifier)
    identifier = identifier or nil --default value
    
    local number_of_jobs = #scheduler_jobs
    
    for i=1,number_of_jobs do
        if identifier == nil then
            -- No identifier provided - running update()
            if scheduler_jobs[i].activation_time < getScenarioTime() then
                scheduler_jobs[i].activate()
                if scheduler_jobs[i].period ~= nil then
                    --reschedule periodic job
                    scheduler_jobs[i].activation_time = getScenarioTime()+scheduler_jobs[i].period
                else
                    --remove one-time job
                    scheduler_jobs[i]=nil
                end
            end
        else
            -- identifier provided, runnung remove_job()
            if scheduler_jobs[i].identifier ~= nil and scheduler_jobs[i].identifier == identifier then
                scheduler_jobs[i]=nil
            end
        end
    end --end for

    local surviving_jobs=0
    for i=1,number_of_jobs do
        if scheduler_jobs[i]~=nil then
            surviving_jobs=surviving_jobs+1
            scheduler_jobs[surviving_jobs]=scheduler_jobs[i]
        end
    end
    
    for i=surviving_jobs+1,number_of_jobs do
        scheduler_jobs[i]=nil
    end
end

-- Helper function, returns job object. 
function _scheduler_job(activation_time, func, period, identifier)
    local identifier = identifier or nil --default value
    
    period = tonumber(period)
    if period and period <= 0 then
        period = nil
    end

    local ScheduledJob = {  activation_time=activation_time,    -- Time when the job should start
                            activate=func,      -- Function to run in specified time
                            identifier=identifier,  -- String identifier of the job
                            period=period      -- Period: nil for jobs ran only once, number of seconds between runs when periodic.
                        }
    
    return ScheduledJob
end

-- Helper function, inserts job into scheduled jobs queue.
function _scheduler_add_job(job)
    if job.activation_time > getScenarioTime() then
        table.insert(scheduler_jobs,job)
    end -- activation time is in future. 
end

-- This function runs check on scheduled jobs and activate which needs to be activated. 
function scheduler_update()
    _scheduler_iterateOn()
end

-- Adds job to scheduler to run in specific time. 
-- @param run_in: time from now when to run the event (in seconds)
-- @param func: function to run when time comes.
-- @param identifier: optional argument to add special name to the job. 
function scheduler_add_job(run_in, func, identifier)
    if run_in ~= nil and func ~= nil then
        local activation_time = getScenarioTime()+run_in
        local job = _scheduler_job(activation_time, func, nil, identifier)
        _scheduler_add_job(job)
    end -- activation_time and func are not nil.
end

-- Adds job to scheduler to run periodicaly every run_every seconds. 
-- @param run_every: Number of seconds between runs (first run is after this time first expires)
-- @param func: function to run when time comes.
-- @param identifier: optional argument to add special name to the event. 
function scheduler_add_periodic_job(run_every, func, identifier)
    if run_every ~= nil and func ~= nil then
        local activation_time = getScenarioTime()+run_every
        local job = _scheduler_job(activation_time, func, run_every, identifier)
        _scheduler_add_job(job)
    end -- activation_time and func are not nil.
end

-- Removes all jobs with valid identifier. 
function scheduler_remove_job(identifier)
    _scheduler_iterateOn(identifier)
end
