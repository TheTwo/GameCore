local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local ModuleRefer = require('ModuleRefer')
local NotificationType = require('NotificationType')
local NoviceConst = require('NoviceConst')
local ConfigRefer = require('ConfigRefer')

---@class HUDSeClimbTower : BaseUIComponent
local HUDSeClimbTower = class('HUDSeClimbTower', BaseUIComponent)

function HUDSeClimbTower:OnCreate()
    self.btnClimbTowerTask = self:Button('p_btn_climbtower', Delegate.GetOrCreate(self, self.OnBtnSeClimbTowerClicked))
    self.textClimbTowerTask = self:Text('p_text_climbtower')
    self.notifyNode = self:LuaObject('child_reddot_default')
end

function HUDSeClimbTower:OnShow()
    -- local notifyNode = ModuleRefer.NotificationModule:GetDynamicNode(
    --     NoviceConst.NoviceNotificationNodeNames.NoviceEntry, NotificationType.NOVICE_HUD)
    -- ModuleRefer.NotificationModule:AttachToGameObject(notifyNode, self.notifyNode.go, self.notifyNode.redDot)

    local systemEntryId = ConfigRefer.ClimbTowerConst:ClimbTowerSystemID()
    ---@type SystemEntryConfigCell
    local systemEntryCell = ConfigRefer.SystemEntry:Find(systemEntryId)
    self.textClimbTowerTask.text = I18N.Get(systemEntryCell:Name())
end

function HUDSeClimbTower:OnBtnSeClimbTowerClicked()
    g_Game.UIManager:Open(UIMediatorNames.SEClimbTowerMainMediator)
end


return HUDSeClimbTower
