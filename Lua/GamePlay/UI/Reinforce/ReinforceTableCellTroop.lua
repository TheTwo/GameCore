local BaseUIComponent = require("BaseUIComponent")
local UIHelper = require("UIHelper")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")

---@class ReinforceTableCellTroop : BaseUIComponent
local ReinforceTableCellTroop = class("ReinforceTableCellTroop", BaseUIComponent)

function ReinforceTableCellTroop:OnCreate()
    self.p_hero_1_template = self:GameObject("p_hero_1")
    self.p_pet_1_template = self:GameObject("p_pet_1")
    self.p_empty = self:GameObject("p_empty")

    self.p_hero_1_template:SetVisible(false)
    self.p_pet_1_template:SetVisible(false)
    self.p_empty:SetVisible(false)

    self.gameObjects = {}
end

function ReinforceTableCellTroop:OnClose()
    self:ClearItems()
end

function ReinforceTableCellTroop:OnFeedData(data)
    if self.data == data.data then
        return
    end

    ---@type ReinforceListData
    self.data = data.data

    self:RefreshUI()
end

function ReinforceTableCellTroop:RefreshUI()
    self:ClearItems()

    local data = self.data
    local heroCount = data.member.HeroTId:Count()
    local petCount = data.member.PetInfo:Count()
    local emptyCount = 6 - (heroCount + petCount)

    --英雄头像
    for i = 1, heroCount do
        local heroId = data.member.HeroTId[i]
        local heroLevel = data.member.HeroLevel[i]
        local HeroStarLevel = data.member.StarLevel[i]
        local heroConfig = ConfigRefer.Heroes:Find(heroId)
        local heroResConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())

        local heroGo = UIHelper.DuplicateUIGameObject(self.p_hero_1_template)
        heroGo:SetVisible(true)

        ---@type HeroInfoItemSmallComponent
        local heroComp = heroGo:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent)).Lua
        local heroData = 
        {
            id = heroId,
            lv = heroLevel,
            starLevel = HeroStarLevel,
            configCell = heroConfig,
            resCell = heroResConfig
        }

        heroComp:FeedData({heroData = heroData})
        table.insert(self.gameObjects, heroGo)
    end

    --宠物头像
    for i = 1, petCount do
        local pet = data.member.PetInfo[i]

        local petGo = UIHelper.DuplicateUIGameObject(self.p_pet_1_template)
        petGo:SetVisible(true)

        ---@type CommonPetIconSmall
        local petComp = petGo:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent)).Lua

        ---@type CommonPetIconBaseData
        local petIconData = {}
        petIconData.cfgId = pet.ConfigId
        petIconData.level = pet.Level
        petIconData.selected = false
        petIconData.showMask = false
        petIconData.skillLevels = ModuleRefer.PetModule:GetSkillLevelQualityList(pet.ConfigId, pet.ClientSkillLevel, pet.ClientLearnableSkillLevel)

        petComp:FeedData(petIconData)
        table.insert(self.gameObjects, petGo)
    end

    --空位
    if emptyCount > 0 then
        for i = 1, emptyCount do
            local emptyGo = UIHelper.DuplicateUIGameObject(self.p_empty)
            emptyGo:SetVisible(true)
            table.insert(self.gameObjects, emptyGo)
        end
    end
end

function ReinforceTableCellTroop:ClearItems()
    for _, go in pairs(self.gameObjects) do
        UIHelper.DeleteUIGameObject(go)
    end
    table.clear(self.gameObjects)
end

return ReinforceTableCellTroop