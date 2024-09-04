local create = coroutine.create
local running = coroutine.running
local resume = coroutine.resume
local yield = coroutine.yield
local error = error
local unpack = table.unpack
local debug = debug
local Timer = require("Timer")
local FrameTimer = Timer.FrameTimer
local CoTimer = Timer.Timer;

local comap = {}
local pool = {}
setmetatable(comap, {__mode = "kv"})

function coroutine.start(f, ...)
	local co = create(f)

	if running() == nil then
		local flag, msg = resume(co, ...)

		if not flag then					
			error(debug.traceback(co, msg))
		end
	else
		local args = {...}
		local timer = nil

		local action = function()
			comap[co] = nil
			timer.func = nil
			local flag, msg = resume(co, unpack(args, 1, #args))
			table.insert(pool, timer)

			if not flag then	
				timer:Stop()														
				error(debug.traceback(co, msg))
			end
		end

		if #pool > 0 then
			timer = table.remove(pool)
			timer:Reset(action, 0, 1)
		else
			timer = FrameTimer.new(action, 0, 1)
		end

		comap[co] = timer
		timer:Start()		
	end

	return co
end

function coroutine.wait(t, co, ...)
	if t == nil or t <= 0 then
		return
	end

	local args = {...}
	co = co or running()
	local timer = nil

	local action = function()
		comap[co] = nil
		timer.func = nil
		local flag, msg = resume(co, unpack(args, 1, #args))

		if not flag then
			timer:Stop()
			error(debug.traceback(co, msg))
			return
		end
	end

	timer = CoTimer.new(action, t, 1)
	comap[co] = timer	
	timer:Start()
	return yield()
end

function coroutine.step(t, co, ...)
	if t == nil or t <= 0 then
		return
	end

	local args = {...}
	co = co or running()
	local timer = nil

	local action = function()
		comap[co] = nil
		timer.func = nil
		local flag, msg = resume(co, unpack(args, 1, #args))
		table.insert(pool, timer)

		if not flag then	
			timer:Stop()																			
			error(debug.traceback(co, msg))
			return
		end
	end
	
	if #pool > 0 then
		timer = table.remove(pool)
		timer:Reset(action, t or 1, 1)
	else
		timer = FrameTimer.new(action, t, 1)
	end

	comap[co] = timer
	timer:Start()
	return yield()
end

function coroutine.stop(co)
	if type(co) ~= "thread" then
		return;
	end

 	local timer = comap[co]

 	if timer ~= nil then
 		comap[co] = nil
 		timer:Stop()
 		timer.func = nil
 	end
end

function coroutine.kill_all_suspended()
	for k, v in pairs(comap) do
		coroutine.stop(k);
	end
end