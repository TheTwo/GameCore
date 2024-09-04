local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require('UIMediatorNames')
local FactionPrestigeCell = class('FactionPrestigeCell',BaseTableViewProCell)

function FactionPrestigeCell:OnCreate(param)
    self.goRoot = self:GameObject("")
    self.goSelect = self:GameObject('p_img_select')
    self.btnPrestige = self:Button('p_btn_prestige', Delegate.GetOrCreate(self, self.OnBtnPrestigeClicked))
    self.goIconPrestigeN = self:GameObject('p_icon_prestige_n')
    self.goIconPrestigeLight = self:GameObject('p_icon_prestige_light')
    self.textPrestigeNum = self:Text('p_text_prestige_num')
    self.textPrestige = self:Text('p_text_prestige')
    if self.goSelect then
        self.goSelect:SetActive(false)
    end
end

function FactionPrestigeCell:OnFeedData(data)
    self.forbidClick = data.forbidClick
    self.factionId = data.factionId
    self.index = data.index
    local factionCfg = ConfigRefer.Sovereign:Find(self.factionId)
    local rewards = factionCfg:ReputationReward()
    local rewardCfg = ConfigRefer.SovereignReputation:Find(rewards)
    local stageReward = rewardCfg:StageReward(self.index)
    local curValue = ModuleRefer.FactionModule:GetFactionPrestigeValue(self.factionId)
    local nodeValue = stageReward:Value()
    local maxValue = ModuleRefer.FactionModule:GetMaxPrestigeValue(self.factionId)
    local percent = nodeValue / maxValue
    self.textPrestigeNum.text = nodeValue
    self.textPrestige.text = I18N.Get(stageReward:Relation())
    self.goIconPrestigeLight:SetActive(curValue >= nodeValue)
    self.goRoot.transform.localPosition = CS.UnityEngine.Vector3(percent * data.width + data.offset, self.goRoot.transform.localPosition.y, 0)
end

function FactionPrestigeCell:OnBtnPrestigeClicked(args)
    if self.forbidClick then
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.UIFactionPrestigeMediator, {factionId = self.factionId, index = self.index})
end


function FactionPrestigeCell:Select(param)
    if self.goSelect then
        self.goSelect:SetActive(true)
    end
end

function FactionPrestigeCell:UnSelect(param)
    if self.goSelect then
        self.goSelect:SetActive(false)
    end
end

return FactionPrestigeCell
