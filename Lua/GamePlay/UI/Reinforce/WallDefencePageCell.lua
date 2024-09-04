local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local SetPresetDefendOrderParameter = require("SetPresetDefendOrderParameter")
local DBEntityPath = require("DBEntityPath")
local NumberFormatter = require("NumberFormatter")
local HeroUIUtilities = require("HeroUIUtilities")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local I18N = require("I18N")
local HUDTroopUtils = require("HUDTroopUtils")
local FormationUtility = require('FormationUtility')

---@class WallDefencePageCell : BaseTableViewProCell
local WallDefencePageCell = class("WallDefencePageCell", BaseTableViewProCell)

---@class WallDefencePageCellData
---@field preset wds.TroopPreset
---@field index number
---@field presetIndex number
---@field power number

---@param presetIndex number
---@param defendOrder number[] | RepeatedField
local function IsChecked(presetIndex, defendOrder)
    for _, index in pairs(defendOrder) do
        if index == presetIndex then
            return true
        end
    end
    return false
end

function WallDefencePageCell:OnCreate()
    self.p_text_troop = self:Text("p_text_troop")
    self.p_troop_status = self:Image("p_troop_status")
    self.p_icon_status = self:Image("p_icon_status")
    self.p_text_power = self:Text("p_text_power")
    self.p_text_defense = self:Text("p_text_defense", "base_defence_troopindefense")
    self.p_troop_status_btn = self:Button("p_troop_status", Delegate.GetOrCreate(self, self.OnTips))
    self.p_troop_status_transform = self:RectTransform("p_troop_status")

    self.child_toggle_set = self:Button('child_toggle_set',Delegate.GetOrCreate(self, self.OnCheck))
    self.child_toggle_set_status = self:BindComponent('child_toggle_set',typeof(CS.StatusRecordParent))
    self.checkState = false

    self.p_hero_1_template = self:GameObject("p_hero_1")
    self.p_pet_1_template = self:GameObject("p_pet_1")
    self.p_empty_template = self:GameObject("p_empty")

    self.p_hero_1_template:SetVisible(false)
    self.p_pet_1_template:SetVisible(false)
    self.p_empty_template:SetVisible(false)

    self.gameObjects = {}
end

function WallDefencePageCell:OnOpened()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.DefendOrder.MsgPath, Delegate.GetOrCreate(self, self.OnDefendOrderChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Troop.MsgPath, Delegate.GetOrCreate(self, self.OnTroopChanged))
end

function WallDefencePageCell:OnClose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.DefendOrder.MsgPath, Delegate.GetOrCreate(self, self.OnDefendOrderChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Troop.MsgPath, Delegate.GetOrCreate(self, self.OnTroopChanged))
    self:ClearItems()
end

---@param data WallDefencePageCellData
function WallDefencePageCell:OnFeedData(data)
    self.castle = ModuleRefer.PlayerModule:GetCastle()
    self.data = data

    self.p_text_troop.text = tostring(self.data.index)
    self.p_text_power.text = NumberFormatter.Normal(self.data.power)
    self:UpdateSateIcon()

    self.checkState = IsChecked(self.data.presetIndex, self.castle.TroopPresets.DefendOrder)
    self:UpdateCheck()

    self:UpdateHerosAndPets()
end

function WallDefencePageCell:UpdateCheck()
    self.child_toggle_set_status:Play(self.checkState and 1 or 0)
end

function WallDefencePageCell:UpdateSateIcon()
    local icon, base, show = HUDTroopUtils.GetPresetStateIcon(self.data.presetIndex + 1)
    g_Game.SpriteManager:LoadSprite(icon, self.p_icon_status)
    g_Game.SpriteManager:LoadSprite(base, self.p_troop_status)
    self.p_icon_status:SetVisible(show)
    self.p_troop_status:SetVisible(show)
end

function WallDefencePageCell:UpdateHerosAndPets()
    self:ClearItems()

    local data = self.data
    local maxIndex = FormationUtility.GetMaxIndex(data.preset.Heroes)
    local heroCount = 0
    local pets = {}

    --英雄头像
    for i = 1, maxIndex do
        local hero = data.preset.Heroes[i]
        if hero and hero.HeroCfgID > 0 then
            local heroCfgCache = ModuleRefer.HeroModule:GetHeroByCfgId(hero.HeroCfgID)
    
            local heroLevel = heroCfgCache.dbData.Level
            local HeroStarLevel = heroCfgCache.dbData.StarLevel
            local heroConfig = ConfigRefer.Heroes:Find(hero.HeroCfgID)
            local heroResConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
    
            local heroGo = UIHelper.DuplicateUIGameObject(self.p_hero_1_template)
            heroGo:SetVisible(true)
    
            ---@type HeroInfoItemSmallComponent
            local heroComp = heroGo:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent)).Lua
            local heroData = 
            {
                id = hero.HeroCfgID,
                lv = heroLevel,
                starLevel = HeroStarLevel,
                configCell = heroConfig,
                resCell = heroResConfig
            }
    
            heroComp:FeedData({heroData = heroData})
            table.insert(self.gameObjects, heroGo)
    
            if heroCfgCache.dbData.BindPetId > 0 then
                table.insert(pets, heroCfgCache.dbData.BindPetId)
            end

            heroCount = heroCount + 1
        end
    end

    --宠物头像
    local petCount = #pets
    for i = 1, petCount do
        local petGo = UIHelper.DuplicateUIGameObject(self.p_pet_1_template)
        petGo:SetVisible(true)

        ---@type CommonPetIconSmall
        local petComp = petGo:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent)).Lua

        ---@type CommonPetIconBaseData
        local petIconData = {}
        petIconData.id = pets[i]

        petComp:FeedData(petIconData)
        table.insert(self.gameObjects, petGo)
    end

    --空位
    local emptyCount = 6 - (heroCount + petCount)
    if emptyCount > 0 then
        for i = 1, emptyCount do
            local emptyGo = UIHelper.DuplicateUIGameObject(self.p_empty_template)
            emptyGo:SetVisible(true)
            table.insert(self.gameObjects, emptyGo)
        end
    end
end

function WallDefencePageCell:ClearItems()
    for _, go in pairs(self.gameObjects) do
        UIHelper.DeleteUIGameObject(go)
    end
    table.clear(self.gameObjects)
end

---@param data wds.CastleBrief
function WallDefencePageCell:OnDefendOrderChanged(data)
    if data.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then
        return
    end
    
    self.checkState = IsChecked(self.data.presetIndex, self.castle.TroopPresets.DefendOrder)
    self:UpdateCheck()
end

---@param data wds.Troop
function WallDefencePageCell:OnTroopChanged(data)
    if data.Owner.PlayerID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    self:UpdateSateIcon()
end

function WallDefencePageCell:OnCheck()
    self.checkState = not self.checkState

    local param = SetPresetDefendOrderParameter.new()
    if self.checkState then
        for _, index in pairs(self.castle.TroopPresets.DefendOrder) do
            param.args.Orders:Add(index)
        end
        param.args.Orders:Add(self.data.presetIndex)
    else
        for _, index in pairs(self.castle.TroopPresets.DefendOrder) do
            if index ~= self.data.presetIndex then
                param.args.Orders:Add(index)
            end
        end
    end

    param:Send()

    self:UpdateCheck()
end

function WallDefencePageCell:OnTips()
    local troopInfo = ModuleRefer.SlgModule.troopManager:GetTroopInfoByPresetIndex(self.data.presetIndex + 1)
    local _, _, desc = HeroUIUtilities.MyTroopStateIconAndDesc(troopInfo.entityData, troopInfo.preset)

    if troopInfo.preset.BasicInfo.Moving then
        ---@type TextToastMediatorParameter
        local param = {}
        param.timeText = "{1}"
        param.timeStamp = HeroUIUtilities.GetTroopsStateEndTime(troopInfo.preset)
        param.tailContent = ""
        param.content = I18N.Get(desc)
        param.clickTransform = self.p_troop_status_transform
        ModuleRefer.ToastModule:ShowTextToast(param)
    else
        ModuleRefer.ToastModule:SimpleShowTextToastTip(I18N.Get(desc), self.p_troop_status_transform)
    end
end

return WallDefencePageCell