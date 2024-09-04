local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ManualResourceConst = require("ManualResourceConst")
local UIMediatorNames = require("UIMediatorNames")
local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility

local Scene = require("Scene")

---@class SeJumpSceneParameter
---@field tid number
---@field id number
---@field exitX number
---@field exitY number

--用于se场景间跳转
---@class SeJumpScene:Scene
---@field new fun():SeJumpScene
---@field super Scene
local SeJumpScene = class('SeJumpScene', Scene)

SeJumpScene.Name = "SeJumpScene"

---@param param SeJumpSceneParameter
function SeJumpScene:EnterScene(param)
    ---@type wrpc.PushEnterSceneRequest
    self.capturePushEnterScene = nil
    self.blockLeaveScene = true
    self.origin_tid = param.tid
    self.origin_id = param.id
    self.origin_exitX = param.exitX
    self.origin_exitY = param.exitY
    SceneLoadUtility.LoadSceneAsync(ManualResourceConst.se_jump_scene, nil, Delegate.GetOrCreate(self, self.OnSceneActive))
end

function SeJumpScene:OnSceneActive(success)
    if not success then
        self:BackToOriginScene()
        return
    end
    g_Game.EventManager:AddListener(EventConst.UI_MEDIATOR_CLOSED, Delegate.GetOrCreate(self, self.OnUIMediatorClosed))
    if not ModuleRefer.HuntingModule:OnEnterSeJumpScene(success) then
        self:BackToOriginScene()
    end
end

function SeJumpScene:OnUIMediatorClosed(uiName)
    if uiName ~= UIMediatorNames.HuntingMainMediator then return end
    self:BackToOriginScene()
end

function SeJumpScene:ExitScene(param)
    self.origin_tid = nil
    self.origin_id = nil
    self.origin_exitX = nil
    self.origin_exitY = nil
    self.capturePushEnterScene = nil
    g_Game.EventManager:RemoveListener(EventConst.UI_MEDIATOR_CLOSED, Delegate.GetOrCreate(self, self.OnUIMediatorClosed))
    SceneLoadUtility.UnloadSceneAsync(ManualResourceConst.se_jump_scene)
end

function SeJumpScene:BackToOriginScene()
    self.blockLeaveScene = false
    if self.capturePushEnterScene then
        local data = self.capturePushEnterScene
        self.capturePushEnterScene = nil
        if data.Tid == self.origin_tid and data.Id == self.origin_id then
            local GotoUtils = require('GotoUtils')
            GotoUtils.GotoSceneKingdomWithLoadingUI(self.origin_tid or 0, self.origin_id or 0, self.origin_exitX, self.origin_exitY, nil, true)
        else
            ModuleRefer.EnterSceneModule:OnPushEnterScene(true, data)
        end
    else
        local GotoUtils = require('GotoUtils')
        GotoUtils.GotoSceneKingdomWithLoadingUI(self.origin_tid or 0, self.origin_id or 0, self.origin_exitX, self.origin_exitY)
    end
end

---@return number, number @tid,id
function SeJumpScene:CapturedPushEnterScene()
    return self.captureTid, self.captureId
end

---@param data wrpc.PushEnterSceneRequest
function SeJumpScene:IsPushEnterSceneAllowed(data)
    if not self.blockLeaveScene then
        return true
    end
    self.capturePushEnterScene = data
    return false
end

function SeJumpScene:GetName()
    return SeJumpScene.Name
end

return SeJumpScene