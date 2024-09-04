--- Lua端 Unity引擎计时器的缓存，在每帧开始时更新
local CSTime = CS.UnityEngine.Time
local UnityTimeWrapper = sealedClass('UnityTimeWrapper')

function UnityTimeWrapper:ctor()    
    self:Update(0)
end

function UnityTimeWrapper:Update(delta)
    self.time = CSTime.time
    self.deltaTime = delta
    self.timeScale = CSTime.timeScale
    self.frameCount = CSTime.frameCount
    self.realtimeSinceStartup = CSTime.realtimeSinceStartup    
end

return UnityTimeWrapper;