-- 新雷达升级界面
local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local DBEntityPath = require('DBEntityPath')
local UIHelper = require('UIHelper')

---@class RadarPopupUpgradeComp : BaseUIComponent
local RadarPopupUpgradeComp = class('RadarPopupUpgradeComp', BaseUIComponent)

---@class RadarPopupUpgradeCompParam
---@field curlevel number
---@field type number
---@field levelTitleText string

local QUALITY_COLOR = {
    "#87A763",
    "#6D91BC",
    "#AA77C8",
    "#DB8358",
}

function RadarPopupUpgradeComp:OnCreate()
    self.goTitle = self:GameObject('p_item_title')
    self.textTitleLevel = self:Text('p_title_level')
    self.textLv = self:Text('p_text_lv')
    self.goArrowLv = self:GameObject('p_arrow_lv')
    self.textNextLv = self:Text('p_text_lv_next')
    self.goLvMax = self:GameObject('p_group_max')

    self.goItemTaskNum = self:GameObject('p_item_1')
    self.textTaskNumTitle = self:Text('p_text_1', I18N.Get('Radar_intel_limit'))
    self.textTaskNum = self:Text('p_text_num_1')
    self.goArrowTaskNum = self:GameObject('p_arrow_1')
    self.textNextTaskNum = self:Text('p_text_add_1')

    self.goItemTaskQuality = self:GameObject('p_item_2')
    self.textTaskQualityTitle = self:Text('p_text_2', I18N.Get('bw_info_radarsystem_3'))
    self.goQualityCellItem = self:LuaBaseComponent('p_cell_quality')
    self.goQualityCellParent = self:GameObject('grid')

    self.goItemExploreFogNum = self:GameObject('p_item_3')
    self.textExploreFogNumTitle = self:Text('p_text_3', I18N.Get('bw_info_radarsystem_4'))
    self.textExploreFogNum = self:Text('p_text_num_3')
    self.goArrowExploreFogNum = self:GameObject('p_arrow_3')
    self.textNextExploreFogNum = self:Text('p_text_add_3')

    self.goItemCanUnlockFogLevel = self:GameObject('p_item_4')
    self.textCanUnlockFogLevelTitle = self:Text('p_text_4', I18N.Get('bw_info_radarsystem_5'))
    self.textCanUnlockFogLevel = self:Text('p_text_num_4')
    self.goArrowCanUnlockFogLevel = self:GameObject('p_arrow_4')
    self.textNextCanUnlockFogLevel = self:Text('p_text_add_4')

    self.goItemOnceUnlockFogNum = self:GameObject('p_item_5')
    self.textOnceUnlockFogNumTitle = self:Text('p_text_5', I18N.Get('bw_info_radarsystem_6'))
    self.textOnceUnlockFogNum = self:Text('p_text_num_5')
    self.goArrowOnceUnlockFogNum = self:GameObject('p_arrow_5')
    self.textNextOnceUnlockFogNum = self:Text('p_text_add_5')

    self.textDesc = self:Text('p_text_desc', I18N.Get('bw_info_radarsystem_7'))

    self.p_base_num_1 = self:GameObject('p_base_num_1')
    self.imgLighter = self:Image('p_base_num_3')
    self.imgNothing = self:Image('p_base_num_5')
    self.imgNothing:SetVisible(false)
    self.p_base_num_1:SetVisible(false)
end

function RadarPopupUpgradeComp:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MsgPath,Delegate.GetOrCreate(self,self.RefreshLv))
end

function RadarPopupUpgradeComp:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Radar.MsgPath,Delegate.GetOrCreate(self,self.RefreshLv))
end

---@param param RadarPopupUpgradeCompParam
function RadarPopupUpgradeComp:OnFeedData(param)
    self:RefreshLv(param)
    g_Game.SpriteManager:LoadSprite("sp_icon_item_light",self.imgLighter)
end

function RadarPopupUpgradeComp:RefreshLv(param)
    self.curlevel = param.curlevel
    local isMax = ModuleRefer.RadarModule:CheckIsMax()
    local curLevelCfg = ConfigRefer.RadarLevel:Find(self.curlevel)
    if not curLevelCfg then
        return
    end

    self.textTitleLevel.text = param.levelTitleText
    if param.type == 1 then
        --升级预览
        if isMax then
            self.textLv.gameObject:SetActive(false)
            self.goArrowLv:SetActive(false)
            self.textNextLv.text = I18N.Get("radar_level_num") .. self.curlevel
            self.goLvMax:SetActive(true)
        else
            self.textLv.gameObject:SetActive(true)
            self.goArrowLv:SetActive(true)
            self.textLv.text = I18N.Get("radar_level_num") .. self.curlevel
            self.nextLevel = self.curlevel + 1
            self.textNextLv.text = I18N.Get("radar_level_num") .. self.nextLevel
        end
    elseif param.type == 2 then
        --升级成功
        self.goTitle:SetActive(false)
        self.textLv.gameObject:SetActive(false)
        self.goArrowLv:SetActive(false)
        self.nextLevel = self.curlevel + 1
        self.textNextLv.text = I18N.Get("radar_level_num") .. (self.nextLevel)
        self.goLvMax:SetActive(isMax)
    end

    self:ClearQualityCell()
    if isMax then
        self.goItemTaskNum:SetActive(true)
        self.textTaskNum.gameObject:SetActive(false)
        self.goArrowTaskNum:SetActive(false)
        local totalTask = 0
        for i = 1, curLevelCfg:RadarTaskAnnulusTaskNumLength() do
            totalTask = totalTask + curLevelCfg:RadarTaskAnnulusTaskNum(i)
        end
        self.textNextTaskNum.text = totalTask

        self.goItemTaskQuality:SetActive(true)
        self.goQualityCellItem.gameObject:SetActive(false)
        for i = curLevelCfg:RadarTaskQualityWeightsLength(), 1, -1 do
            if curLevelCfg:RadarTaskQualityWeights(i) == 0 then
                goto continue
            end

            local cellComp = UIHelper.DuplicateUIComponent(self.goQualityCellItem, self.goQualityCellParent.transform)
            ---@type RadarUpgradeQualityCellParam
            local data = {}
            data.nextNum = string.format("%d%%", curLevelCfg:RadarTaskQualityWeights(i))
            data.quality = i
            data.isMax = true
            cellComp.Lua:OnFeedData(data)
            cellComp.gameObject:SetActive(true)
            table.insert(self.qualityCellCache, cellComp)
            ::continue::
        end

        self.goItemExploreFogNum:SetActive(true)
        self.textExploreFogNum.gameObject:SetActive(false)
        self.goArrowExploreFogNum:SetActive(false)
        self.textNextExploreFogNum.text = curLevelCfg:UnlockMistPointRecoverMax()

        self.goItemCanUnlockFogLevel:SetActive(true)
        self.textCanUnlockFogLevel.gameObject:SetActive(false)
        self.goArrowCanUnlockFogLevel:SetActive(false)
        -- self.textNextCanUnlockFogLevel.text = curLevelCfg:UnlockMistPointRecoverMax()

        self.goItemOnceUnlockFogNum:SetActive(true)
        self.textOnceUnlockFogNum.gameObject:SetActive(false)
        self.goArrowOnceUnlockFogNum:SetActive(false)
        local num = curLevelCfg:MistUnlockLevel()
        self.textNextOnceUnlockFogNum.text = num * num

        self.textDesc.gameObject:SetActive(false)
    else
        local nextLevelCfg = ConfigRefer.RadarLevel:Find(self.nextLevel)
        if not nextLevelCfg then
            return
        end

        local curTotalTask = 0
        for i = 1, curLevelCfg:RadarTaskAnnulusTaskNumLength() do
            curTotalTask = curTotalTask + curLevelCfg:RadarTaskAnnulusTaskNum(i)
        end
        local nextTotalTask = 0
        for i = 1, nextLevelCfg:RadarTaskAnnulusTaskNumLength() do
            nextTotalTask = nextTotalTask + nextLevelCfg:RadarTaskAnnulusTaskNum(i)
        end
        if curTotalTask == nextTotalTask then
            self.goItemTaskNum:SetActive(false)
        else
            self.goItemTaskNum:SetActive(true)
            self.textTaskNum.gameObject:SetActive(true)
            self.goArrowTaskNum:SetActive(true)
            self.textTaskNum.text = curTotalTask
            self.textNextTaskNum.text = nextTotalTask
        end

        self.goItemTaskQuality:SetActive(true)
        self.goQualityCellItem.gameObject:SetActive(false)
        for i = curLevelCfg:RadarTaskQualityWeightsLength(), 1, -1 do
            local curNum = curLevelCfg:RadarTaskQualityWeights(i)
            local nextNum = nextLevelCfg:RadarTaskQualityWeights(i)
            if curNum == nextNum then
                goto continue
            end

            local cellComp = UIHelper.DuplicateUIComponent(self.goQualityCellItem, self.goQualityCellParent.transform)
            ---@type RadarUpgradeQualityCellParam
            local data = {}
            data.curNum = string.format("%d%%", curNum)
            data.nextNum = string.format("%d%%", nextNum)
            data.quality = i
            data.isMax = false
            cellComp.Lua:OnFeedData(data)
            cellComp.gameObject:SetActive(true)
            table.insert(self.qualityCellCache, cellComp)
            ::continue::
        end

        local curExploreFogNum = curLevelCfg:UnlockMistPointRecoverMax()
        local nextExploreFogNum = nextLevelCfg:UnlockMistPointRecoverMax()
        if curExploreFogNum == nextExploreFogNum then
            self.goItemExploreFogNum:SetActive(false)
        else
            self.goItemExploreFogNum:SetActive(true)
            self.textExploreFogNum.gameObject:SetActive(true)
            self.goArrowExploreFogNum:SetActive(true)
            self.textExploreFogNum.text = curExploreFogNum
            self.textNextExploreFogNum.text = nextExploreFogNum
        end

        self.goItemCanUnlockFogLevel:SetActive(false)

        local curOnceUnlockFogNum = curLevelCfg:MistUnlockLevel()
        local nextOnceUnlockFogNum = nextLevelCfg:MistUnlockLevel()
        if curOnceUnlockFogNum == nextOnceUnlockFogNum then
            self.goItemOnceUnlockFogNum:SetActive(false)
        else
            self.goItemOnceUnlockFogNum:SetActive(true)
            self.textOnceUnlockFogNum.gameObject:SetActive(true)
            self.goArrowOnceUnlockFogNum:SetActive(true)
            self.textOnceUnlockFogNum.text = curOnceUnlockFogNum * curOnceUnlockFogNum
            self.textNextOnceUnlockFogNum.text = nextOnceUnlockFogNum * nextOnceUnlockFogNum
        end
    end

end

function RadarPopupUpgradeComp:ClearQualityCell()
    if not self.qualityCellCache then
        self.qualityCellCache = {}
    end
    for i = 1, #self.qualityCellCache do
        UIHelper.DeleteUIComponent(self.qualityCellCache[i])
    end
end

return RadarPopupUpgradeComp