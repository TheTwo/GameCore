local Delegate = require("Delegate")
local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility

---@class SceneManager
---@field new fun():SceneManager
local SceneManager = class("SceneManager", require("BaseManager"))
local EventConst = require("EventConst")

function SceneManager:ctor()
    ---@type Scene[]
    self.scenes = {}
    ---@type Scene
    self.current = nil
    ---@type table<string, number>
    self.preLoadScene = {}
    self.preLoadSceneExpireTime = 5
    self.preLoadSceneCountLimit = 1
end

function SceneManager:Initialize()
    g_Logger.Log("SceneManager Initialize")
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_START, Delegate.GetOrCreate(self, self.OnReloginStart))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_FAILURE, Delegate.GetOrCreate(self, self.OnReloginFailure))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))
end

function SceneManager:Reset()
    g_Logger.Log("SceneManager Release")
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_START, Delegate.GetOrCreate(self, self.OnReloginStart))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_FAILURE, Delegate.GetOrCreate(self, self.OnReloginFailure))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))

    if self.current ~= nil then
        try_catch_traceback_with_vararg(self.current.ExitScene, nil, self.current)
        self.current = nil
    end
    
    for _, v in pairs(self.scenes) do
        ---@type Scene
        local scene = v
        try_catch_traceback_with_vararg(scene.Release, nil, scene)
    end

    self.scenes = {}
    self.current = nil
    SceneLoadUtility.ClearAll()
end

---@param name string
---@param scene Scene
function SceneManager:AddScene(name, scene)
    self.scenes[name] = scene
end

---@param name string
function SceneManager:RemoveScene(name)
    self.scenes[name] = nil
end

---@param name string
function SceneManager:GetScene(name)
    return self.scenes[name]
end

---@param name string
---@param param any
function SceneManager:EnterScene(name, param)
    ---@type Scene
    local scene = self:GetScene(name)
    if scene == nil then
        return
    end
    if self.current ~= nil then
        self.current:ExitScene()
    end
    self.current = scene
    scene:EnterScene(param)
end

---@param name string
---@param param any
function SceneManager:ExitScene(name, param)
    ---@type Scene
    local scene = self.current
    if scene == nil then
        return
    end

    if scene:GetName() ~= name then
        return
    end
    
    scene:ExitScene(param)
    self.current = nil
end

---@param dt number
function SceneManager:OnFrameTick(dt)
    if self.relogin then return end

    ---@type Scene
    local scene = self.current
    if scene then
        scene:Tick(dt)
    end
    self:FilterPreLoadSceneStatus()
    for sceneName, expireLeftTime in pairs(self.preLoadScene) do
        expireLeftTime = expireLeftTime - dt
        self.preLoadScene[sceneName] = expireLeftTime
    end
end

---@return string
function SceneManager:GetCurrentSceneName()
    if self.current then
        return self.current:GetName()
    end
    return nil
end

function SceneManager:OnReloginStart()
    self.relogin = true
    local scene = self.current
    if scene and scene:CanLightRestart() then
        scene:OnLightRestartBegin()
    end
end

function SceneManager:OnReloginSuccess()
    self.relogin = false
    local scene = self.current
    if scene and scene:CanLightRestart() then
        scene:OnLightRestartEnd()
    end
end

function SceneManager:OnReloginFailure()
    self.relogin = false
    local scene = self.current
    if scene and scene:CanLightRestart() then
        scene:OnLightRestartFailed()
    end
end

function SceneManager:FilterPreLoadSceneStatus()
    for sceneName, expireLeftTime in pairs(self.preLoadScene) do
        if not SceneLoadUtility.HasPreLoadScene(sceneName) then
            self.preLoadScene[sceneName] = nil
        elseif expireLeftTime <= 0 then
            SceneLoadUtility.UnloadScene(sceneName)
            self.preLoadScene[sceneName] = nil
        end
    end
end

function SceneManager:AddToPreLoadScene(sceneName)
    if string.IsNullOrEmpty(sceneName) then return end
    if SceneLoadUtility.HasLoadedScene(sceneName) then return end
    local leftTime = self.preLoadScene[sceneName]
    if leftTime and SceneLoadUtility.HasPreLoadScene(sceneName) then
        self.preLoadScene[sceneName] = self.preLoadSceneExpireTime
        return
    end
    self:FilterPreLoadSceneStatus()
    local currentCount = table.nums(self.preLoadScene)
    if currentCount >= self.preLoadSceneCountLimit then
        local lastDuration
        local toRemove
        for preloadSceneName, preloadLeftTime in pairs(self.preLoadScene) do
            if not lastDuration or lastDuration > preloadLeftTime then
                lastDuration = preloadLeftTime
                toRemove = preloadSceneName
            end
        end
        self:RemovePreLoadScene(toRemove)
    end
    self.preLoadScene[sceneName] = self.preLoadSceneExpireTime
    if not SceneLoadUtility.HasPreLoadScene(sceneName) then
        SceneLoadUtility.PreLoadSceneAsync(sceneName)
    end
end

function SceneManager:RemovePreLoadScene(sceneName)
    if string.IsNullOrEmpty(sceneName) then return end
    self.preLoadScene[sceneName] = nil
    if SceneLoadUtility.HasPreLoadScene(sceneName) then
        SceneLoadUtility.UnloadScene(sceneName)
    end
end

return SceneManager