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
local PetCollectionEnum = require('PetCollectionEnum')
local PetCollectionPhotoDetailTab = class('PetCollectionPhotoDetailTab', BaseTableViewProCell)
local NotificationType = require('NotificationType')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')

function PetCollectionPhotoDetailTab:OnCreate()
    self._p_status = self:StatusRecordParent("")
    self.child_reddot_default = self:GameObject('child_reddot_default')
    self.btn = self:Button('', Delegate.GetOrCreate(self, self.OnClickTab))
    self.gameObject = self:GameObject('')

    self.p_text_on = self:Text('p_text_on')
    self.p_text_off = self:Text('p_text_off')
    ---@type CS.FpAnimation.FpAnimationCommonTrigger
    self.vxTrigger = self:BindComponent("p_on", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end

function PetCollectionPhotoDetailTab:OnShow()
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_DETAIL_LOCK_TAB, Delegate.GetOrCreate(self, self.LockTab))
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_STORY_RED_POINT, Delegate.GetOrCreate(self, self.RefreshRedPoint))
end

function PetCollectionPhotoDetailTab:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.PET_COLLECTION_DETAIL_LOCK_TAB, Delegate.GetOrCreate(self, self.LockTab))
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_STORY_RED_POINT, Delegate.GetOrCreate(self, self.RefreshRedPoint))
end

function PetCollectionPhotoDetailTab:LockTab(param)
    if param.lock then
        if self.tabIndex ~= PetCollectionEnum.TabType.Details then
            self.gameObject:SetVisible(false)
        else
            self.gameObject:SetVisible(true)
        end
    else
        self.gameObject:SetVisible(true)
    end
end

function PetCollectionPhotoDetailTab:OnFeedData(param)
    self.tabIndex = param.tabIndex
    self.curTabIndex = param.curTabIndex
    self.petIndex = param.petIndex

    if (param.tabIndex == PetCollectionEnum.TabType.Details) then
        self.p_text_on.text = I18N.Get(ConfigRefer.PetConsts:PetHandbookInfoName())
        self.p_text_off.text = I18N.Get(ConfigRefer.PetConsts:PetHandbookInfoName())
    elseif (param.tabIndex == PetCollectionEnum.TabType.Research) then
        self.p_text_on.text = I18N.Get(ConfigRefer.PetConsts:PetHandbookResearchName())
        self.p_text_off.text = I18N.Get(ConfigRefer.PetConsts:PetHandbookResearchName())
    elseif (param.tabIndex == PetCollectionEnum.TabType.Story) then
        self.p_text_on.text = I18N.Get(ConfigRefer.PetConsts:PetHandbookStoryName())
        self.p_text_off.text = I18N.Get(ConfigRefer.PetConsts:PetHandbookStoryName())
    end

    if (self.tabIndex == self.curTabIndex) then
        self._p_status:SetState(0)
        if param.noTabAnim then
            self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom2)
        else
            self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
        end
    else
        self._p_status:SetState(1)
    end

    self:RefreshRedPoint()
end
function PetCollectionPhotoDetailTab:OnClickTab()
    if self.tabIndex == self.curTabIndex then
        return
    end
    self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
    g_Game.EventManager:TriggerEvent(EventConst.PET_COLLECTION_DETAIL_TAB, {detailTabIndex = self.tabIndex})
end

function PetCollectionPhotoDetailTab:RefreshRedPoint()
    local isShow = false

    self.child_reddot_default:SetVisible(isShow)
end

return PetCollectionPhotoDetailTab
