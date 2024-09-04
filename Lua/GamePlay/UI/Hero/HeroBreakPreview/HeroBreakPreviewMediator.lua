local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local ConfigRefer = require('ConfigRefer')
local ItemType = require('ItemType')
local I18N = require("I18N")
local HeroUIUtilities = require('HeroUIUtilities')
local Quality = require('Quality')
---@class HeroBreakPreviewMediator : BaseUIMediator
---@field transSelectCursor CS.UnityEngine.RectTransform
local HeroBreakPreviewMediator = class('HeroBreakPreviewMediator', BaseUIMediator)


function HeroBreakPreviewMediator:ctor()
    self.module = ModuleRefer.HeroModule
    self.Inventory = ModuleRefer.InventoryModule
end

function HeroBreakPreviewMediator:OnCreate()
    self.compChildPopupBaseM = self:LuaBaseComponent('child_popup_base_s')
    self.tableviewproNeedItem = self:TableViewPro('p_need_item')

    self.textTitle1 = self:Text('p_text_title_1', I18N.Get("hero_breakthrough_tips_1"))
    self.textLv = self:Text('p_text_lv', I18N.Get("hero_strengthen_item"))
    self.textNeed = self:Text('p_text_need')


    self.chipsImage = {self.imgMark1, self.imgMark2, self.imgMark3}
    self.chipsNum = {self.textMark1, self.textMark2, self.textMark3}
end

---@param param HeroConfigCache
function HeroBreakPreviewMediator:OnShow(param)
    self.heroData = param
    local titleParam = {}
    titleParam.title = I18N.Get("hero_breakthrough_tips_1")
    self.compChildPopupBaseM:FeedData(titleParam)

    local breakConfig = ConfigRefer.HeroBreakThrough:Find(self.heroData.configCell:BreakThroughCfg())
    self.tableviewproNeedItem:Clear()
    for i = 1, breakConfig:BreakThroughInfoListLength() - 1 do
        local breakInfo = breakConfig:BreakThroughInfoList(i + 1)
        local curBreakInfo = breakConfig:BreakThroughInfoList(i)
        local isBroken = self.heroData.dbData.Level > curBreakInfo:LevelUpperLimit()
        local data = {breakConfig = breakInfo, isBroken = isBroken, lv = curBreakInfo:LevelUpperLimit()}
        self.tableviewproNeedItem:AppendData(data)
    end
end

function HeroBreakPreviewMediator:OnOpened(param)
end

function HeroBreakPreviewMediator:OnClose(param)
end

return HeroBreakPreviewMediator
