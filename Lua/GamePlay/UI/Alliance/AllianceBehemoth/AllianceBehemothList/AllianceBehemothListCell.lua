local Delegate = require("Delegate")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local ModuleRefer = require("ModuleRefer")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBehemothListCellData
---@field ownedData AllianceBehemoth
---@field monsterConfig KmonsterDataConfigCell
---@field isInUsing boolean
---@field host AllianceBehemothListMediator

---@class AllianceBehemothListCell:BaseTableViewProCell
---@field new fun():AllianceBehemothListCell
---@field super BaseTableViewProCell
local AllianceBehemothListCell = class('AllianceBehemothListCell', BaseTableViewProCell)

function AllianceBehemothListCell:OnCreate(param)
    ---@type AllianceBehemothHeadCell
    self._child_behemoth_head = self:LuaObject("child_behemoth_head")
end

---@param data AllianceBehemothListCellData
function AllianceBehemothListCell:OnFeedData(data)
    self._data = data
    local _,icon,lv = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(data.monsterConfig)
    ---@type AllianceBehemothHeadCellData
    self._headData = {}
    self._headData.inUsing = data.isInUsing
    self._headData.icon = icon
    if data.isInUsing then
        self._headData.lv = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel()
    else
        self._headData.lv = nil
    end
    self._headData.setGrey = data.ownedData:IsFake()
    self._headData.onclick = Delegate.GetOrCreate(self, self.OnClickSelf)
    self._headData.setNotifyNode = Delegate.GetOrCreate(self, self.SetNotifyNode)
    self._child_behemoth_head:FeedData(self._headData)
end

function AllianceBehemothListCell:OnClickSelf()
    self:GetTableViewPro():SetToggleSelect(self._data)
end

function AllianceBehemothListCell:Select()
    self._headData.isSelected = true
    self._child_behemoth_head:SetSelected(true)
end

function AllianceBehemothListCell:UnSelect()
    self._child_behemoth_head:SetSelected(false)
    self._headData.isSelected = false
end

---@param node NotificationNode
function AllianceBehemothListCell:SetNotifyNode(node)
    if self._data.ownedData:IsFake() then
        node.go:SetVisible(false)
        return 
    end
    local key = AllianceModuleDefine.GetNotifyKeyForBehemoth(self._data.ownedData)
    local notify = ModuleRefer.NotificationModule:GetDynamicNode(key, NotificationType.ALLIANCE_BEHEMOTH_NEW)
    if not notify then return end
    ModuleRefer.NotificationModule:AttachToGameObject(notify, node.go, node.redDot)
    self._data.host:DelayRemoveNotifyMarkBehemoth(self._data.ownedData)
end

return AllianceBehemothListCell