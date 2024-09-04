local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local GrowthFundConst = require('GrowthFundConst')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local PlayerGetAutoRewardParameter = require('PlayerGetAutoRewardParameter')
local Utils = require('Utils')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local TimerUtility = require('TimerUtility')
local EventConst = require('EventConst')

---@class PersonalReward : BaseTableViewProCell
local PersonalReward = class('PersonalReward', BaseTableViewProCell)

function PersonalReward:OnCreate()
    self.p_icon_reward_n = self:Button('p_icon_reward_n', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_icon_reward_open = self:GameObject('p_icon_reward_open')

    self.imgClose = self:Image('p_icon_reward_n')
    self.imgOpen = self:Image('p_icon_reward_open')

    self.p_line = self:GameObject('p_line')
    self.line_n = self:Image('line_n')
    self.p_line_open = self:Image('p_line_open')

end

function PersonalReward:OnShow()

end

function PersonalReward:OnHide()

end

function PersonalReward:OnFeedData(param)
    self.param = param

    if param.index == 1 then
        g_Game.SpriteManager:LoadSprite("sp_task_icon_box_1_open", self.imgOpen)
        g_Game.SpriteManager:LoadSprite("sp_task_icon_box_1", self.imgClose)
    elseif param.index == 2 then
        g_Game.SpriteManager:LoadSprite("sp_task_icon_box_4_open", self.imgOpen)
        g_Game.SpriteManager:LoadSprite("sp_task_icon_box_4", self.imgClose)
    elseif param.index == 3 then
        g_Game.SpriteManager:LoadSprite("sp_task_icon_box_5_open", self.imgOpen)
        g_Game.SpriteManager:LoadSprite("sp_task_icon_box_5", self.imgClose)
    end
    g_Game.SpriteManager:LoadSprite("sp_white_solid_gap", self.line_n)
    g_Game.SpriteManager:LoadSprite("sp_white_solid_gap", self.p_line_open)

    self:Refresh()

end

function PersonalReward:Refresh()
    local isClaimed = self.param.isClaimed
    local num = self.param.num
    local curValue = self.param.curValue
    local isClaimable = curValue >= num
    self.isClaimable = isClaimable

    if self.param.index == 1 then
        self.p_line:SetVisible(false)
    else
        self.p_line:SetVisible(true)
    end

    if isClaimed then
        self.imgClose:SetVisible(false)
        self.imgOpen:SetVisible(true)
        self.line_n:SetVisible(false)
        self.p_line_open:SetVisible(true)
    elseif not isClaimable then
        self.imgClose:SetVisible(true)
        self.imgOpen:SetVisible(false)
        self.line_n:SetVisible(true)
        self.p_line_open:SetVisible(false)
    elseif isClaimable then
        self.imgClose:SetVisible(true)
        self.imgOpen:SetVisible(false)
        self.line_n:SetVisible(false)
        self.p_line_open:SetVisible(true)
    end
end

function PersonalReward:OnBtnClick()
    local itemPram = {}
    local items = {}
    local count = self.param.itemGroupConfig:ItemGroupInfoListLength()
    for i = 1, count do
        local itemGroup = self.param.itemGroupConfig:ItemGroupInfoList(i)
        table.insert(items, {itemId = itemGroup:Items(), itemCount = itemGroup:Nums()})
    end
    itemPram.listInfo = items
    itemPram.clickTrans = self.p_icon_reward_n.gameObject.transform
    g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, itemPram)

end

return PersonalReward
