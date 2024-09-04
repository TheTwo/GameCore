--- Shortcut:
---@see BattleEntryMediator
---@see BattleEntryBattleCell
local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local BattleEntryType = require("BattleEntryType")
local ActivityCenterConst = require("ActivityCenterConst")
local NotificationType = require("NotificationType")
---@class BattleEntryModule : BaseModule
local BattleEntryModule = class("BattleEntryModule", BaseModule)

function BattleEntryModule:ctor()
    ---@type table<number, CS.Notification.NotificationDynamicNode>
    self.notifyNodesMap = {}
end

function BattleEntryModule:OnRegister()
    self:InitReddot()
end

function BattleEntryModule:OnRemove()
    table.clear(self.notifyNodesMap)
end

function BattleEntryModule:InitReddot()
    for _, v in ConfigRefer.BattleEntry:ipairs() do
        self:InitReddotByType(v:Type())
    end
end

function BattleEntryModule:InitReddotByType(type)
    if type == BattleEntryType.PvP then
        self:InitPvPReddot()
    elseif type == BattleEntryType.BehemothBattle then
        self:InitBehemothBattleReddot()
    end
    local node = self:GetNotifyNodeByType(type)
    if node then
        local hudNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
            "BattleEntryHud", NotificationType.BATTLE_ENTRY_HUD
        )
        ModuleRefer.NotificationModule:AddToParent(node, hudNode)
    end
end

function BattleEntryModule:InitPvPReddot()
end

function BattleEntryModule:InitBehemothBattleReddot()
    local activityTabId = ActivityCenterConst.BehemothGve
    local tabNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
        ActivityCenterConst.NotificationNodeNames.ActivityCenterTab .. activityTabId, NotificationType.ACTIVITY_CENTER_TAB
    )
    local battleEntryNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
        "BattleEntryCell_" .. BattleEntryType.BehemothBattle, NotificationType.BATTLE_ENTRY_CELL
    )
    ModuleRefer.NotificationModule:AddToParent(tabNode, battleEntryNode)
    self.notifyNodesMap[BattleEntryType.BehemothBattle] = battleEntryNode
end

---@param type number @BattleEntryType
---@return CS.Notification.NotificationDynamicNode
function BattleEntryModule:GetNotifyNodeByType(type)
    return self.notifyNodesMap[type]
end

---@return CS.Notification.NotificationDynamicNode
function BattleEntryModule:GetHUDNotifyNode()
    return ModuleRefer.NotificationModule:GetDynamicNode(
        "BattleEntryHud", NotificationType.BATTLE_ENTRY_HUD
    )
end

return BattleEntryModule