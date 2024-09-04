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

local PetCollectionPhotoDetailStoryComp = class('PetCollectionPhotoDetailStoryComp', BaseTableViewProCell)

function PetCollectionPhotoDetailStoryComp:OnCreate()
    self.p_text_info = self:Text('p_text_unlock_story')
    self.p_text_unlock_desc = self:Text('p_text_unlock_desc')
    self.p_icon_lock = self:GameObject('p_icon_lock')
    self.p_icon_complete = self:GameObject('p_icon_complete')
    -- 优化
    self.p_text_lock = self:Text('p_text_unlock_complete', I18N.Get("hero_equip_enhance_convert_tips_unlock"))
    self.base_1 = self:GameObject('base_1')
    self.child_item_standard_s = self:LuaObject('child_item_standard_s')
    self.obj_child_item_standard_s = self:GameObject('child_item_standard_s')
end

function PetCollectionPhotoDetailStoryComp:OnShow()
end

function PetCollectionPhotoDetailStoryComp:OnHide()
end

function PetCollectionPhotoDetailStoryComp:OnFeedData(param)
    self.param = param
    self:Refresh()
end
function PetCollectionPhotoDetailStoryComp:Refresh()

    if self.param.unlock then
        self.p_text_unlock_desc:SetVisible(true)
        self.p_text_info:SetVisible(false)
        self.p_text_unlock_desc.text = I18N.Get(ConfigRefer.PetStoryItem:Find(self.param.storyId):Content())
        self.obj_child_item_standard_s:SetVisible(false)
        self.base_1:SetVisible(false)
        self.p_icon_lock:SetVisible(false)
        self.p_text_lock:SetVisible(false)
        self.p_icon_complete:SetVisible(false)
    else
        self.base_1:SetVisible(true)
        self.p_text_unlock_desc:SetVisible(false)

        local iconData = {}
        local itemGroupConfig = ConfigRefer.ItemGroup:Find(self.param.reward)
        local itemGroup = itemGroupConfig:ItemGroupInfoList(1)
        iconData.configCell = ConfigRefer.Item:Find(itemGroup:Items())
        iconData.count = itemGroup:Nums()
        iconData.showCount = true
        self.rewards = {{id = iconData.configCell:Id(), count = iconData.count}}
        self.obj_child_item_standard_s:SetVisible(true)
        iconData.received = false

        if self.param.curResearchLevel >= self.param.level then
            iconData.claimable = true
            iconData.onClick = Delegate.GetOrCreate(self, self.OnClickNormal)
            self.p_text_lock:SetVisible(true)
            self.p_text_info:SetVisible(false)
            self.p_icon_complete:SetVisible(true)
            self.p_icon_lock:SetVisible(false)
        else
            iconData.claimable = false
            iconData.showTips = true
            self.p_text_info.text = I18N.GetWithParams(ConfigRefer.PetConsts:PetHandbookStoryUnlockDesc(), self.param.level)
            self.p_text_lock:SetVisible(false)
            self.p_text_info:SetVisible(true)
            self.p_icon_complete:SetVisible(false)
            self.p_icon_lock:SetVisible(true)

        end
        self.child_item_standard_s:FeedData(iconData)
    end
end

function PetCollectionPhotoDetailStoryComp:OnClickNormal()
    ModuleRefer.PetCollectionModule:ResetStoryRedPoint(self.param.areaIndex, self.param.petIndex, self.param.petIndex)
    ModuleRefer.PetCollectionModule:UnlockStory(self.param.petIndex, self.param.index, function()
        self.param.unlock = true
        self:Refresh()
        g_Game.UIManager:Open(UIMediatorNames.UIRewardMediator, {itemInfo = self.rewards})
    end)
end

return PetCollectionPhotoDetailStoryComp
