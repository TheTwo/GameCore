---scene: scene_se_pvp_tips_player_info
local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local TimerUtility = require("TimerUtility")
local TipsRectTransformUtils = require("TipsRectTransformUtils")
local NumberFormatter = require("NumberFormatter")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")

---@class ReplicaPVPTroopInfoTipsParameter
---@field basicInfo wds.ReplicaPvpPlayerBasicInfo
---@field anchorTrans CS.UnityEngine.Transform

---@class ReplicaPVPTroopInfoTips:BaseUIMediator
---@field new fun():ReplicaPVPTroopInfoTips
---@field super BaseUIMediator
local ReplicaPVPTroopInfoTips = class('ReplicaPVPTroopInfoTips', BaseUIMediator)

function ReplicaPVPTroopInfoTips:OnCreate(param)
    ---@type PlayerInfoComponent
    self.playerIcon = self:LuaObject('child_ui_head_player')
    self.txtPlayerName = self:Text('p_text_player')
    self.imageLvIcon = self:Image('p_icon_level')
    self.imageLvIconNum = self:Image('p_icon_lv_num')
    self.txtPower = self:Text('p_text_power')
    self.txtScore = self:Text('p_text_score')
    self.txtTroop = self:Text('p_text_troop', 'se_pvp_history_battlearray')

    ---@type HeroInfoItemSmallComponent
    self.heroSlot1 = self:LuaObject('p_card_hero_1')
    ---@type HeroInfoItemSmallComponent
    self.heroSlot2 = self:LuaObject('p_card_hero_2')
    ---@type HeroInfoItemSmallComponent
    self.heroSlot3 = self:LuaObject('p_card_hero_3')

    ---@type CommonPetIconSmall
    self.petSlot1 = self:LuaObject('p_card_pet_1')
    ---@type CommonPetIconSmall
    self.petSlot2 = self:LuaObject('p_card_pet_2')
    ---@type CommonPetIconSmall
    self.petSlot3 = self:LuaObject('p_card_pet_3')

    self.heroSlots = {self.heroSlot1, self.heroSlot2, self.heroSlot3}
    self.petSlots = {self.petSlot1, self.petSlot2, self.petSlot3}

    for i, slot in ipairs(self.heroSlots) do
        slot:SetVisible(false)
    end

    for i, slot in ipairs(self.petSlots) do
        slot:SetVisible(false)
    end

    self.content = self:GameObject('content')
end

---@param param ReplicaPVPTroopInfoTipsParameter
function ReplicaPVPTroopInfoTips:OnOpened(param)
    self.anchorTrans = param.anchorTrans

    ---@type wds.ReplicaPvpPlayerBasicInfo
    self.basicInfo = param.basicInfo

    -- 解决打开位置闪烁的bug
    self.content:SetVisible(false)
    TimerUtility.DelayExecute(function()
        self.content:SetVisible(true)
        self.playerIcon:FeedData(self.basicInfo.Portrait)   --RefreshUI里调用时，边框显示不正确。
    end, 0.1)

    self:RefreshUI()
end

function ReplicaPVPTroopInfoTips:OnClose(param)

end

function ReplicaPVPTroopInfoTips:OnShow(param)
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function ReplicaPVPTroopInfoTips:OnHide(param)
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function ReplicaPVPTroopInfoTips:OnTick(delta)
    if self.anchorTrans then
        -- 第一次调用，可能会和第二次的结果不一样
        TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(self.anchorTrans, self.content.transform)
    end
end

function ReplicaPVPTroopInfoTips:RefreshUI()
    self.txtPlayerName.text = self.basicInfo.Name
    local pvpTitleStageConfigCell = ConfigRefer.PvpTitleStage:Find(self.basicInfo.TitleTid)
    self:LoadSprite(pvpTitleStageConfigCell:Icon(), self.imageLvIcon)
    if pvpTitleStageConfigCell:LevelIcon() > 0 then
        self:LoadSprite(pvpTitleStageConfigCell:LevelIcon(), self.imageLvIconNum)
    end
    self.txtPower.text = NumberFormatter.Normal(self.basicInfo.DefPreset.Power)
    self.txtScore.text = NumberFormatter.Normal(self.basicInfo.Score)
    for i, info in ipairs(self.basicInfo.DefPreset.HeroInfos) do
        local heroCfgId = info.CfgId
        local heroCfgCache = {}
        Utils.CopyTable(ModuleRefer.HeroModule:GetHeroByCfgId(heroCfgId), heroCfgCache)
        ---@type HeroInfoData
        local data = {}
        data.heroData = heroCfgCache
        data.heroData.dbData = nil
        data.heroData.heroInitParam = {}
        data.heroData.heroInitParam.Level = info.Level
        data.heroData.heroInitParam.StarLevel = info.StrengthenLevel -- todo 这个似乎不对，和服务器确认一下
        self.heroSlots[i]:SetVisible(true)
        self.heroSlots[i]:FeedData(data)

        if info.Pet.CfgId > 0 then
            ---@type CommonPetIconBaseData
            local petData = {}
            petData.cfgId = info.Pet.CfgId
            petData.level = info.Pet.Level
            petData.rank = info.Pet.RankLevel
            petData.skillLevels = ModuleRefer.PetModule:GetSkillLevelQualityList(info.Pet.CfgId, info.Pet.ClientSkillLevel, info.Pet.ClientLearnableSkillLevel)
            self.petSlots[i]:SetVisible(true)
            self.petSlots[i]:FeedData(petData)
        else
            self.petSlots[i]:SetVisible(false)
        end
    end
end

return ReplicaPVPTroopInfoTips