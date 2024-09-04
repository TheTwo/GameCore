local BaseUIMediator = require ('BaseUIMediator')
local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local AdornmentType = require('AdornmentType')
local NotificationType = require('NotificationType')
local PersonaliseDefine = require('PersonaliseDefine')

---@class PersonaliseChangeTitleCell : BaseTableViewProCell
local PersonaliseChangeTitleCell = class('PersonaliseChangeTitleCell', BaseTableViewProCell)


function PersonaliseChangeTitleCell:OnCreate()
    self.btnTitle = self:Button('', Delegate.GetOrCreate(self, self.OnIconClick))
    self.imgBase = self:Image('p_base')
    self.luagoTitle = self:LuaObject('p_personalise')
    self.goSelect = self:GameObject('p_select')
    self.goTimeLimited = self:GameObject('p_icon_time')
    self.textCanUnlock = self:Text('p_text_unlock', 'skincollection_canunlock')
    self.goUsing = self:GameObject('p_use')
    self.textUsing = self:Text('p_text_use', 'skincollection_wearing')
    self.goLocked = self:GameObject('p_lock')

    self.reddot = self:LuaObject('child_reddot_default')
end


function PersonaliseChangeTitleCell:OnFeedData(configID)
    self.configID = configID
    local configInfo = ConfigRefer.Adornment:Find(configID)
    if not configInfo then
       return
    end
    self.type = configInfo:AdornmentType()
    self.mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.PersonaliseChangeMediator)
    if not ModuleRefer.PersonaliseModule:IsAdornmentUnlocked(configID) then
        self.goLocked:SetActive(true)
        self:CheckIsCanUnlock(configID)
        self.goTimeLimited:SetActive(false)
    else
        self.goLocked:SetActive(false)
        self.textCanUnlock.gameObject:SetActive(false)
        self.goTimeLimited:SetActive(not ModuleRefer.PersonaliseModule:IsAdornmentPermanent(configID))
    end
    g_Game.SpriteManager:LoadSprite(PersonaliseDefine.TITLE_QUALITY_BASE[configInfo:Quality() + 1], self.imgBase)
    ---@type PlayerTitleParam
    local param = {configID = tonumber(configInfo:Icon()), name = I18N.Get(configInfo:Name())}
    self.luagoTitle:FeedData(param)
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
    -- self.reddot:SetVisible(false)
    self:CheckRedDotState()
end

function PersonaliseChangeTitleCell:OnIconClick()
    if not self.mediator then
        self.mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.PersonaliseChangeMediator)
    end
    -- self.mediator.tableviewproTableList:SetToggleSelect(self.configID)
    self.mediator:OnSelectItem(self.configID)
    local isNew = ModuleRefer.PersonaliseModule:CheckIsNewUnlockItem(self.type, self.configID)
    if isNew then
        ModuleRefer.PersonaliseModule:SyncAdornmentRedDot(self.configID)
        self:UpdateRedDotState(true)
        -- ModuleRefer.PersonaliseModule:RefreshRedPoint()
    end
    self:Select()
end

function PersonaliseChangeTitleCell:IsUsing(type)
    local data = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(type)
    if data then
        return data.ConfigID == self.configID
    end
    return false
end

function PersonaliseChangeTitleCell:CheckIsCanUnlock(configID)
    local isCanUnlock = ModuleRefer.PersonaliseModule:IsCanUnlock(configID)
    self.textCanUnlock.gameObject:SetActive(isCanUnlock)
    -- self.reddot:SetVisible(isCanUnlock)
end

function PersonaliseChangeTitleCell:CheckRedDotState()
    self.redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseItemTitleNode"..self.configID, NotificationType.PERSONALISE_ITEM_TITLE)
    ModuleRefer.NotificationModule:AttachToGameObject(self.redNode, self.reddot.go, self.reddot.redDot)
    self:UpdateRedDotState()
end

function PersonaliseChangeTitleCell:UpdateRedDotState(isClick)
    if not self.redNode then
        self.redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseItemTitleNode"..self.configID, NotificationType.PERSONALISE_ITEM_TITLE)
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

function PersonaliseChangeTitleCell:Select()
    self.goSelect:SetActive(true)
end

function PersonaliseChangeTitleCell:UnSelect()
    self.goSelect:SetActive(false)
end


return PersonaliseChangeTitleCell