local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local CircleMenuSimpleButtonData = require("CircleMenuSimpleButtonData")
local CircleMenuButtonConfig = require("CircleMenuButtonConfig")

local CityState = require("CityState")

---@class CityStateExplorerTeamOperateMenu:CityState
---@field super CityState
local CityStateExplorerTeamOperateMenu = class("CityStateExplorerTeamOperateMenu", CityState)

function CityStateExplorerTeamOperateMenu:Enter()
    CityStateExplorerTeamOperateMenu.super.Enter(self)
    ---@type CityExplorerTeam
    self.team = self.stateMachine:ReadBlackboard("team")
    self._isOperateUIReady = false
    ---@type CityCircleMenuUISeTroopMediatorParameter
    local param = {}
    param.sceneCamera = self.city:GetCamera():GetUnityCamera()
    param.team = self.team
    local retBtn = CircleMenuSimpleButtonData.new()
    retBtn.buttonIcon = CircleMenuButtonConfig.ButtonIcons.IconTroopBackArraw
    retBtn.buttonBack = CircleMenuButtonConfig.ButtonBacks.BackNormal
    retBtn.buttonEnable = true
    retBtn.onClick = Delegate.GetOrCreate(self,self.OnButtonCallback_BackHome)
    param.btnsData  = {retBtn}
    self._operateUi = g_Game.UIManager:Open(UIMediatorNames.CityCircleMenuUISeTroopMediator, param)
    g_Game.UIManager:AddOnAnyPointDown(Delegate.GetOrCreate(self, self.OnClickAnyUI))
end

function CityStateExplorerTeamOperateMenu:Exit()
    g_Game.UIManager:Close(self._operateUi)
    g_Game.UIManager:RemoveOnAnyPointDown(Delegate.GetOrCreate(self, self.OnClickAnyUI))
    CityStateExplorerTeamOperateMenu.super.Exit(self)
end

function CityStateExplorerTeamOperateMenu:OnClick(gesture)
    self:ExitToIdleState()
end

function CityStateExplorerTeamOperateMenu:OnPressDown(gesture)
    self:ExitToIdleState()
end

function CityStateExplorerTeamOperateMenu:OnClickTrigger(trigger, position)
    self:ExitToIdleState()
end

---@param vector2 CS.UnityEngine.Vector2 @screenPosition
function CityStateExplorerTeamOperateMenu:OnClickAnyUI(screenPos)
    ---@type CityCircleMenuUISeTroopMediator
    local mediator = g_Game.UIManager:FindUIMediator(self._operateUi)
    if not mediator then return end
    if mediator:IsScreenInMyElement(screenPos) then return end
    self:ExitToIdleState()
end

function CityStateExplorerTeamOperateMenu:OnButtonCallback_BackHome()
    self.city.cityExplorerManager:SendDismissTeam(self.team)
    self:ExitToIdleState()
end

return CityStateExplorerTeamOperateMenu