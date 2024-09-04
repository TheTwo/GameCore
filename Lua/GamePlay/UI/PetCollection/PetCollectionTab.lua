local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local GuideUtils = require("GuideUtils")
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local UIMediatorNames = require('UIMediatorNames')
local PetCollectionTab = class('PetCollectionTab', BaseTableViewProCell)

function PetCollectionTab:OnCreate()
    -- self._p_status = self:StatusRecordParent("")
    self.btn = self:Button('', Delegate.GetOrCreate(self, self.OnClickTab))
    self.child_reddot_default = self:GameObject('child_reddot_default')
    self.p_text_on = self:Text('p_text_on', I18N.Get('ALL'))
    self.p_text_off = self:Text('p_text_off', I18N.Get('ALL'))
    self.p_icon_on = self:Image('p_icon_on')
    self.p_icon_off = self:Image('p_icon_off')
    self.p_on = self:GameObject('p_on')
    self.p_off = self:GameObject('p_off')
end

function PetCollectionTab:OnShow()
    self:RegisterEvent()
    self:RefreshRedPoint()
end

function PetCollectionTab:OnHide()
    self:UnregisterEvent()
end

function PetCollectionTab:RegisterEvent()
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_TAB, Delegate.GetOrCreate(self, self.RefreshTab))
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_STORY_RED_POINT, Delegate.GetOrCreate(self, self.RefreshRedPoint))
end

function PetCollectionTab:UnregisterEvent()
    g_Game.EventManager:RemoveListener(EventConst.PET_COLLECTION_TAB, Delegate.GetOrCreate(self, self.RefreshTab))
    g_Game.EventManager:RemoveListener(EventConst.PET_COLLECTION_STORY_RED_POINT, Delegate.GetOrCreate(self, self.RefreshRedPoint))
end

function PetCollectionTab:OnFeedData(param)
    self.areaIndex = param.areaIndex
    self.curIndex = param.curIndex
    self:RefreshTab(param)
    self:RefreshRedPoint()

    local sprite = param:Icon()
    g_Game.SpriteManager:LoadSprite(sprite, self.p_icon_on)
    g_Game.SpriteManager:LoadSprite(sprite, self.p_icon_off)
end

function PetCollectionTab:RefreshTab(param)
    self.curIndex = param.curIndex
    if self.areaIndex == 1 then
        self.p_text_on:SetVisible(true)
        self.p_text_off:SetVisible(true)
        self.p_icon_on:SetVisible(false)
        self.p_icon_off:SetVisible(false)
    else
        self.p_text_on:SetVisible(false)
        self.p_text_off:SetVisible(false)
        self.p_icon_on:SetVisible(true)
        self.p_icon_off:SetVisible(true)
    end

    local isSelect = param.curIndex == self.areaIndex
    self.p_on:SetVisible(isSelect)
    self.p_off:SetVisible(not isSelect)
end

function PetCollectionTab:RefreshRedPoint()

end

function PetCollectionTab:OnClickTab()
    if self.areaIndex == self.curIndex then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.PET_COLLECTION_TAB, {areaIndex = self.areaIndex, curIndex = self.areaIndex})
end

return PetCollectionTab
