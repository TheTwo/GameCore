local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local EventConst = require('EventConst')

---@class FloatingGuideFingerHolder
local FloatingGuideFingerHolder = class("FloatingGuideFingerHolder")

---@param goFinger CS.UnityEngine.GameObject
function FloatingGuideFingerHolder:ctor(goFinger)
    self.goFinger = goFinger
    self.playerIdleCounter = 0
    self.isPlayerIdle = false
    self:Setup()
end

function FloatingGuideFingerHolder:Setup()
    if not self.goFinger then
        return
    end
    self.isLock = false
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
    g_Game.EventManager:AddListener(EventConst.STOP_TASK_AUTO_FINGER, Delegate.GetOrCreate(self, self.SetLock))

end

function FloatingGuideFingerHolder:Release()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
    g_Game.EventManager:RemoveListener(EventConst.STOP_TASK_AUTO_FINGER, Delegate.GetOrCreate(self, self.SetLock))
    self.isLock = false
    self.goFinger = nil
end

function FloatingGuideFingerHolder:OnSecondTick()
    if self.isLock then
        self.goFinger:SetVisible(false)
        return
    end

    local city = ModuleRefer.CityModule.myCity
    if city:IsInSingleSeExplorerMode() then
        self.goFinger:SetVisible(false)
        return
    end

    if self.isPlayerIdle then
        self.playerIdleCounter = self.playerIdleCounter + 1
        if self.playerIdleCounter >= ConfigRefer.ConstMain:GuideChapterClickTime() then
            local taskId = ConfigRefer.ConstMain:DisableGuideFingerTask()
            local isDisableTaskFinish = false
            if taskId and taskId > 0 then
                ---@type TaskItemDataProvider
                local provider = require("TaskItemDataProvider").new(taskId)
                isDisableTaskFinish = provider:IsTaskFinished()
            end
            if not isDisableTaskFinish then
                self.goFinger:SetActive(true)
            end
        end
    else
        self.playerIdleCounter = 0
        self.goFinger:SetActive(false)
    end
end

function FloatingGuideFingerHolder:OnFrameTick()
    if CS.UnityEngine.Input.anyKey then
        self.playerIdleCounter = 0
        self.isPlayerIdle = false
    else
        self.isPlayerIdle = true
    end
end

function FloatingGuideFingerHolder:SetLock(isLock)
    self.isLock = isLock
    if isLock then
        self.goFinger:SetVisible(false)
    end
end

return FloatingGuideFingerHolder