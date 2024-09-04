local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local HeroConfigCache = require("HeroConfigCache")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local AttackDistanceType = require("AttackDistanceType")
local UIHelper = require("UIHelper")
local DBEntityPath = require("DBEntityPath")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceWarPlayerCellData
---@field memberInfo wds.AllianceBattleMemberInfo
---@field owner AllianceWarCellData

---@class AllianceWarPlayerCell:BaseTableViewProCell
---@field new fun():AllianceWarPlayerCell
---@field super BaseTableViewProCell
local AllianceWarPlayerCell = class('AllianceWarPlayerCell', BaseTableViewProCell)

function AllianceWarPlayerCell:OnCreate(param)
    self._p_base_b = self:GameObject("p_base_b")
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject('child_ui_head_player')
    self._p_icon_Initiator = self:GameObject("p_icon_Initiator")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_state = self:Text("p_text_state")
    
    ---@type CS.UnityEngine.GameObject[]
    self._hero = {}
    ---@type HeroInfoItemComponent[]
    self._heroCard = {}
    ---@type CS.UnityEngine.GameObject[]
    self._heroEmpty = {}
    ---@type CS.UnityEngine.UI.Slider[]
    self._heroHp = {}
    ---@type CS.UnityEngine.GameObject[]
    self._pet = {}
    ---@type CommonPetIcon[]
    self._petCard = {}
    ---@type CS.UnityEngine.UI.Slider[]
    self._petHp = {}

    for i = 1, 3 do
        self._hero[i] = self:GameObject(string.format("head_%d", i))
        self._heroCard[i] = self:LuaObject(string.format("child_card_hero_s_%d", i))
        self._heroEmpty[i] = self:GameObject(string.format("p_empty_%d", i))
        self._heroHp[i] = self:Slider(string.format("p_troop_hp_%d", i))
        self._pet[i] = self:GameObject(string.format("pet_%d", i))
        self._petCard[i] = self:LuaObject(string.format("child_pet_%d", i))
        self._petHp[i] = self:Slider(string.format("p_troop_hp_%d", i+3))
    end

    self._p_icon_arms = self:Image("p_icon_arms")
    self._p_text_arms = self:Text("p_text_arms")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_btn_back = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.OnClickBack))
    self._p_icon_Initiator = self:GameObject("p_icon_Initiator")
end

function AllianceWarPlayerCell:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceTeamInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnTeamInfoChange))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.Tick))
end

function AllianceWarPlayerCell:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTeamInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnTeamInfoChange))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.Tick))
end

function AllianceWarPlayerCell:Tick()
    self:UpdateTime()
end

function AllianceWarPlayerCell:OnTeamInfoChange()
    self:UpdateTime()
end

function AllianceWarPlayerCell:UpdateTime()
    if self.data == nil then
        return
    end

    local player = self.data.memberInfo
    if player == nil then
        return
    end

    local endTime = player.MoveStopTime
    if endTime > 0 then
        local now = g_Game.ServerTime:GetServerTimestampInMilliseconds()
        local duration = endTime - now
        local remaining = math.max(duration / 1000, 0)
        self._p_text_state.text = TimeFormatter.SimpleFormatTime(remaining)
    else
        self._p_text_state.text = I18N.Get("alliance_war_toast4")
    end
end

---@param data AllianceWarPlayerCellData
function AllianceWarPlayerCell:OnFeedData(data)
    self.data = data
    local player = data.memberInfo
    local allianceMember = ModuleRefer.AllianceModule:QueryMyAllianceMemberData(player.FacebookId)
    local myPlayerId= ModuleRefer.PlayerModule:GetPlayerId()
    local isMyCell = myPlayerId == player.PlayerId
    local selfIsCaptain = myPlayerId  == data.owner._serverData.CaptainId
    local isCaptain = player.PlayerId == data.owner._serverData.CaptainId
    
    self:UpdateTime()

    if allianceMember then
        self._child_ui_head_player:SetVisible(true)
        self._child_ui_head_player:FeedData(allianceMember.PortraitInfo)
        self._p_text_name.text = allianceMember.Name
    else
        g_Logger.Error("player.FacebookId:%s is not in MyAllianceMemberData", player.FacebookId)
        self._child_ui_head_player:SetVisible(false)
        self._p_text_name.text = player.PlayerName
    end

    if isMyCell then
        self._p_text_name.text = ModuleRefer.PlayerModule:GetPlayer().Owner.PlayerName.String
    end
    
    local troopData = data.memberInfo.Troops[1]
    local heroData = troopData and troopData.Heroes or {}
    for i = 1, 3 do
        local hero = heroData[i - 1]
        if not hero or hero.ConfigId <= 0 then
            self._hero[i]:SetActive(false)
            self._heroEmpty[i]:SetVisible(true)
            self._heroCard[i]:SetVisible(false)
            self._heroHp[i]:SetVisible(false)
            self._pet[i]:SetVisible(false)
        else
            self._hero[i]:SetActive(true)
            self._heroEmpty[i]:SetVisible(false)
            self._heroCard[i]:SetVisible(true)
            self._heroHp[i]:SetVisible(true)

            ---@type HeroInfoData
            local cellInfo = {}
            local heroConfig = ConfigRefer.Heroes:Find(hero.ConfigId)
            cellInfo.heroData = HeroConfigCache.FromHeroInitParam(hero, heroConfig)
            self._heroCard[i]:FeedData(cellInfo)
            self._heroHp[i].value = hero.MaxHp > 0 and math.clamp01(hero.Hp / hero.MaxHp) or 0
            local petInfo = hero.PetInfos
            ---@type wds.PetDataView
            local pet
            if petInfo then
                for _, value in pairs(petInfo) do
                    pet = value
                    break
                end
            end
            if pet then
                self._pet[i]:SetVisible(true)
                self._petHp[i].value = pet.HpMax > 0 and math.clamp01(pet.Hp / pet.HpMax) or 0

                ---@type CommonPetIconBaseData
                local petIconData = {}
                petIconData.cfgId = pet.ConfigId
                petIconData.level = pet.Level
                petIconData.selected = false
                petIconData.showMask = false
                petIconData.skillLevels = self:GetSkillLevelQualityList(pet.ConfigId, pet.ClientSkillLevel, pet.ClientLearnableSkillLevel)

                self._petCard[i]:FeedData(petIconData)
            else
                self._pet[i]:SetVisible(false)
            end
        end
    end
    self._p_btn_back:SetVisible(isMyCell and (not selfIsCaptain))
    self._p_icon_Initiator:SetVisible(isCaptain)
    self._p_text_quantity.text = tostring(data.memberInfo.Power)
    g_Game.SpriteManager:LoadSprite(self:GetTroopIcon(heroData), self._p_icon_arms)
end

function AllianceWarPlayerCell:GetSkillLevelQualityList(petCfgId, fixedSkillLevels, learnableSkillLevels)
    return ModuleRefer.PetModule:GetSkillLevelQualityList(petCfgId, fixedSkillLevels, learnableSkillLevels)
end

function AllianceWarPlayerCell:OnClickBack()
    ModuleRefer.SlgModule:LeaveAllianceTeam(self.data.memberInfo.Troops[1].PresetQueue + 1)
end

AllianceWarPlayerCell.SP_HERO_ATTACK_RANGE = {
    [AttackDistanceType.Short] = "sp_icon_survivor_type_1",
    [AttackDistanceType.Long] = "sp_icon_survivor_type_2",
}

---@param heroList table<number, wds.HeroInitParam>
function AllianceWarPlayerCell:GetTroopIcon(heroList)
    local typeValue = AttackDistanceType.Short
    for _, v in pairs(heroList) do
        local heroConfig = ConfigRefer.Heroes:Find(v.ConfigId)
        if heroConfig then
            typeValue = math.max(typeValue, heroConfig:AttackDistance())
        end
    end
    local ret = AllianceWarPlayerCell.SP_HERO_ATTACK_RANGE[typeValue]
    return UIHelper.IconOrMissing(ret)
end

return AllianceWarPlayerCell