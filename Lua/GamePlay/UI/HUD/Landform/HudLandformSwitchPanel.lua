local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local ModuleRefer = require('ModuleRefer')
local LandformTaskModule = require('LandformTaskModule')
local NotificationType = require('NotificationType')

---@class HudLandformSwitchPanel : BaseUIComponent
---@field super BaseUIComponent
local HudLandformSwitchPanel = class("HudLandformSwitchPanel", BaseUIComponent)

function HudLandformSwitchPanel:OnCreate(param)
    -- 联盟领地信息
    self.goNoteAlliance = self:GameObject('p_group_note_alliance')
    self.txtAllianceNote1 = self:Text("p_text_alliance_1", 'bw_info_strategic_ally')
    self.txtAllianceNote2 = self:Text("p_text_alliance_2", 'bw_info_strategic_enemy')
    self.txtAllianceNote3 = self:Text("p_text_alliance_3", 'bw_info_strategic_neutral')
    self.txtAllianceNote4 = self:Text("p_text_alliance_4", 'bw_info_strategic_luoling')
    self.buttonLandformEntry = self:Button("child_btn_landform", Delegate.GetOrCreate(self, self.OnEntryClicked))
    ---@type NotificationNode
    self.child_reddot_default = self:LuaObject("child_reddot_default")
end

function HudLandformSwitchPanel:OnShow(param)
    local node = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(LandformTaskModule.NotifyHudRootUniqueName, NotificationType.LANDFORM_TASK_MAIN)
    ModuleRefer.NotificationModule:AttachToGameObject(node, self.child_reddot_default.go, self.child_reddot_default.redDot)
    
    ModuleRefer.LandformTaskModule:RefreshNotifications()
end

function HudLandformSwitchPanel:OnHide(param)
    ModuleRefer.NotificationModule:RemoveFromGameObject(self.child_reddot_default.go, false)
end

function HudLandformSwitchPanel:OnEntryClicked()
    g_Game.UIManager:Open(UIMediatorNames.LandformIntroUIMediator)
end


return HudLandformSwitchPanel