local BaseUIMediator = require ('BaseUIMediator')
local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local AdornmentType = require('AdornmentType')
local AdornmentQuality = require('AdornmentQuality')
local UIMediatorNames = require('UIMediatorNames')
local NotificationType = require('NotificationType')

---@class PersonaliseChangeItemCellParam
---@field iconData BaseItemIcon
---@field name string
---@field icon string
---@field clickCallBack fun()

---@class PersonaliseChangeItemCell : BaseTableViewProCell
local PersonaliseChangeItemCell = class('PersonaliseChangeItemCell', BaseTableViewProCell)


function PersonaliseChangeItemCell:OnCreate()
    self.child_item_standard_s = self:LuaObject('child_item_standard_s')

    self.goTimeLimited = self:GameObject('p_icon_time')
    self.textCanUnlock = self:Text('p_text_unlock', 'skincollection_canunlock')
    self.goUsing = self:GameObject('p_use')
    self.textUsing = self:Text('p_text_use', 'skincollection_wearing')

    self.reddot = self:LuaObject('child_reddot_default')
end

function PersonaliseChangeItemCell:OnFeedData(configID)
    self.configID = configID
    local configInfo = ConfigRefer.Adornment:Find(configID)
    if not configInfo then
       return
    end
    self.type = configInfo:AdornmentType()
    self.mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.PersonaliseChangeMediator)
    local iconData = {}
    if not string.IsNullOrEmpty(configInfo:Icon()) then
        iconData.customImage = configInfo:Icon()
    else
        iconData.customImage = "sp_icon_missing_2"
    end
    iconData.customQuality = configInfo:Quality() + 2
    iconData.showCount = false
    iconData.locked = not ModuleRefer.PersonaliseModule:IsAdornmentUnlocked(configID)
    iconData.onClick = Delegate.GetOrCreate(self, self.OnIconClick)
    self.child_item_standard_s:FeedData(iconData)
    -- self.child_item_standard_s:ChangeQuality(configInfo:Quality() + 2)
    if iconData.locked then
        self:CheckIsCanUnlock(configID)
        self.goTimeLimited:SetActive(false)
    else
        self.goTimeLimited:SetActive(not ModuleRefer.PersonaliseModule:IsAdornmentPermanent(configID))
        self.textCanUnlock.gameObject:SetActive(false)
        -- self.reddot:SetVisible(false)
    end
    self.textUsing:SetVisible(false)
    if self:IsUsing(self.type) then
        self.goUsing:SetActive(true)
    else
        self.goUsing:SetActive(false)
    end
    if self.mediator then
        if self.configID == self.mediator:GetCurSelectItemID() or 
        self.configID == self.mediator:GetDefaultChoosonItemID() then
            self:Select()
        else
            self:UnSelect()
        end
    end
    self:CheckRedDotState()
end

function PersonaliseChangeItemCell:OnIconClick()
    if not self.mediator then
        self.mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.PersonaliseChangeMediator)
    end
    -- self.mediator.tableproviewItem:SetToggleSelect(self.configID)
    local isNew = ModuleRefer.PersonaliseModule:CheckIsNewUnlockItem(self.type, self.configID)
    if isNew then
        ModuleRefer.PersonaliseModule:SyncAdornmentRedDot(self.configID)
        self:UpdateRedDotState(true)
        -- ModuleRefer.PersonaliseModule:RefreshRedPoint()
    end
    self.mediator:OnSelectItem(self.configID)
end

function PersonaliseChangeItemCell:IsUsing(type)
    local data = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(type)
    if data then
        return data.ConfigID == self.configID
    end
    return false
end

function PersonaliseChangeItemCell:CheckIsCanUnlock(configID)
    local isCanUnlock = ModuleRefer.PersonaliseModule:IsCanUnlock(configID)
    self.textCanUnlock.gameObject:SetActive(isCanUnlock)
    -- self.reddot:SetVisible(isCanUnlock)
end

function PersonaliseChangeItemCell:CheckRedDotState()
    self.redNode = nil
    if self.type == AdornmentType.PortraitFrame then
        self.redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseItemHeadFrameNode"..self.configID, NotificationType.PERSONALISE_ITEM_HEAD_FRAME)
    elseif self.type == AdornmentType.CastleSkin then
        self.redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseItemCastleSkinNode"..self.configID, NotificationType.PERSONALISE_ITEM_CASTLE_SKIN)
    end
    ModuleRefer.NotificationModule:AttachToGameObject(self.redNode, self.reddot.go, self.reddot.redDot)
    self:UpdateRedDotState()
end

function PersonaliseChangeItemCell:UpdateRedDotState(isClick)
    if not self.redNode then
        if self.type == AdornmentType.PortraitFrame then
            self.redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseItemHeadFrameNode"..self.configID, NotificationType.PERSONALISE_ITEM_HEAD_FRAME)
        elseif self.type == AdornmentType.CastleSkin then
            self.redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseItemCastleSkinNode"..self.configID, NotificationType.PERSONALISE_ITEM_CASTLE_SKIN)
        end
    end
    isClick = isClick or false
    local isNew = false
    if not isClick then
        isNew = ModuleRefer.PersonaliseModule:CheckIsNewUnlockItem(self.type, self.configID)
    end
    local isCanUnlock = ModuleRefer.PersonaliseModule:IsCanUnlock(self.configID)
    if isNew then
        self.redNode.uiNode:ChangeToggleObject(self.reddot.redNew)
    else
        self.redNode.uiNode:ChangeToggleObject(self.reddot.redDot)
    end
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.redNode, (isNew or isCanUnlock) and 1 or 0)
end

function PersonaliseChangeItemCell:Select()
    self.child_item_standard_s:ChangeSelectStatus(true)
end

function PersonaliseChangeItemCell:UnSelect()
    self.child_item_standard_s:ChangeSelectStatus(false)
end




return PersonaliseChangeItemCell