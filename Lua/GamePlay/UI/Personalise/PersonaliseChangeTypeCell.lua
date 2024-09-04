local BaseUIMediator = require ('BaseUIMediator')
local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local NotificationType = require('NotificationType')
local AdornmentType = require('AdornmentType')

---@class PersonaliseChangeTypeCell : BaseTableViewProCell
local PersonaliseChangeTypeCell = class('PersonaliseChangeTypeCell', BaseTableViewProCell)


function PersonaliseChangeTypeCell:OnCreate()
    self.btnItem = self:Button('p_btn_pet', Delegate.GetOrCreate(self, self.OnClickItem))
    self.imgIcon = self:Image('p_icon')
    -- self.textItem = self:Text('p_text_item')
    self.goSelect = self:GameObject('p_img_select')

    self.reddot = self:LuaObject('child_reddot_default')
end

function PersonaliseChangeTypeCell:OnFeedData(configID)
    local configInfo = ConfigRefer.AdornmentTypes:Find(configID)
    if not configInfo then
        return
    end
    self.configInfo = configInfo
    self.type = configInfo:AdornmentType()
    self.mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.PersonaliseChangeMediator)
    if self.mediator then
        local selectType = self.mediator:GetSelectType()
        self.goSelect:SetActive(selectType == self.type)
    end
    -- self.textItem.text = I18N.Get(configInfo:Name())
    if not string.IsNullOrEmpty(configInfo:Icon()) then
        g_Game.SpriteManager:LoadSprite(configInfo:Icon(), self.imgIcon)
    end
    self.reddot:SetVisible(true)
    local redNode = nil
    if self.type == AdornmentType.PortraitFrame then
        redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseTabHeadFrameNode", NotificationType.PERSONALISE_TAB_HEAD_FRAME)
    elseif self.type == AdornmentType.CastleSkin then
        redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseTabCastleSkinNode", NotificationType.PERSONALISE_TAB_CASTLE_SKIN)
    elseif self.type == AdornmentType.Titles then
        redNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseTabTitleNode", NotificationType.PERSONALISE_TAB_TITLE)
    end
    ModuleRefer.NotificationModule:AttachToGameObject(redNode, self.reddot.go, self.reddot.redDot)
    ModuleRefer.PersonaliseModule:RefreshRedPoint()
end

function PersonaliseChangeTypeCell:OnClickItem()
    if not self.mediator then
        self.mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.PersonaliseChangeMediator)
    end
    -- self.mediator.tableproviewType:SetToggleSelect(self.configInfo)
    self.mediator:OnClickChangeType(self.type)
end

function PersonaliseChangeTypeCell:Select()
    self.goSelect:SetActive(true)
end

function PersonaliseChangeTypeCell:UnSelect()
    self.goSelect:SetActive(false)
end


return PersonaliseChangeTypeCell