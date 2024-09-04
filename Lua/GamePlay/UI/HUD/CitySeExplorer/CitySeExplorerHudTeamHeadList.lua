
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")
local EventConst = require("EventConst")
local AudioConsts = require("AudioConsts")
local UIMediatorNames = require("UIMediatorNames")

local BaseUIComponent = require("BaseUIComponent")

---@class CitySeExplorerHudTeamHeadListData
---@field presetIndex number
---@field castleBriefId number

---@class CitySeExplorerHudTeamHeadList:BaseUIComponent
---@field super BaseUIComponent
local CitySeExplorerHudTeamHeadList = class("CitySeExplorerHudTeamHeadList", BaseUIComponent)

function CitySeExplorerHudTeamHeadList:ctor()
    CitySeExplorerHudTeamHeadList.super.ctor(self)
    self._presetIndex = nil
    ---@type number[]
    self._currentTrackHeroes = {}
    ---@type number[]
    self._currentTrackPets = {}
    self._castleBriefId = nil
    self._upgradeCheck = false
    ---@type CitySeExplorerHudTeamHead[]
    self._heroCells = {}
    ---@type CitySeExplorerHudTeamHead[]
    self._petCells = {}
    ---@type CitySeExplorerHudTeamHeadData[]
    self._heroCellsData = {}
    ---@type CitySeExplorerHudTeamHeadData[]
    self._petCellsData = {}
end

function CitySeExplorerHudTeamHeadList:OnCreate(param)
    self._p_hero = self:GameObject("p_hero")
    self._p_pet = self:GameObject("p_pet")
    self._p_btn_upgrade_hero = self:Button("p_btn_upgrade_hero", Delegate.GetOrCreate(self, self.OnHeroUpgradeClick))
    self._p_btn_upgrade_pet = self:Button("p_btn_upgrade_pet", Delegate.GetOrCreate(self, self.OnPetUpgradeClick))
    self._p_text_upgrade_hero = self:Text("p_text_upgrade_hero")
    self._p_text_upgrade_pet = self:Text("p_text_upgrade_pet")
    self._heroCells[1] = self:LuaObject("p_item_hero")
    self._heroCells[2] = self:LuaObject("p_item_hero_1")
    self._heroCells[3] = self:LuaObject("p_item_hero_2")
    self._petCells[1] = self:LuaObject("p_item_pet")
    self._petCells[2] = self:LuaObject("p_item_pet_1")
    self._petCells[3] = self:LuaObject("p_item_pet_2")
    for _, cell in pairs(self._heroCells) do
        cell:SetVisible(false)
    end
    for _, cell in pairs(self._petCells) do
        cell:SetVisible(false)
    end
    self._p_hero:SetVisible(false)
    self._p_pet:SetVisible(false)
end

---@param param CitySeExplorerHudTeamHeadListData
function CitySeExplorerHudTeamHeadList:OnFeedData(param)
    self._presetIndex = param.presetIndex
    self._castleBriefId = param.castleBriefId
    self:Init()
end

function CitySeExplorerHudTeamHeadList:Init()
    if not self._castleBriefId then return end
    table.clear(self._currentTrackHeroes)
    table.clear(self._currentTrackPets)
    self:OnPresetChanged(g_Game.DatabaseManager:GetEntity(self._castleBriefId, DBEntityType.CastleBrief))
    self:OnCheckUpgradeDirty()
end

function CitySeExplorerHudTeamHeadList:OnShow()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnPresetChanged))
    g_Game.EventManager:AddListener(EventConst.SE_EXPLORER_HERO_CAN_UPGRADE_CHECK, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game.EventManager:AddListener(EventConst.SE_EXPLORER_PET_CAN_UPGRADE_CHECK, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Hero.SystemLevel.SystemLevel.MsgPath, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.Level.MsgPath, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CitySeExplorerHudTeamHeadList:OnHide()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnPresetChanged))
    g_Game.EventManager:RemoveListener(EventConst.SE_EXPLORER_HERO_CAN_UPGRADE_CHECK, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game.EventManager:RemoveListener(EventConst.SE_EXPLORER_PET_CAN_UPGRADE_CHECK, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Hero.SystemLevel.SystemLevel.MsgPath, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.Level.MsgPath, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    for _, value in pairs(self._heroCells) do
        value:SetVisible(false)
    end
    for _, value in pairs(self._petCells) do
        value:SetVisible(false)
    end
    self._p_hero:SetVisible(false)
    self._p_pet:SetVisible(false)
end

function CitySeExplorerHudTeamHeadList:OnClose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnPresetChanged))
    g_Game.EventManager:RemoveListener(EventConst.SE_EXPLORER_HERO_CAN_UPGRADE_CHECK, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game.EventManager:RemoveListener(EventConst.SE_EXPLORER_PET_CAN_UPGRADE_CHECK, Delegate.GetOrCreate(self, self.OnCheckUpgradeDirty))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    for _, value in pairs(self._heroCells) do
        value:SetVisible(false)
    end
    for _, value in pairs(self._petCells) do
        value:SetVisible(false)
    end
    self._p_hero:SetVisible(false)
    self._p_pet:SetVisible(false)
end

function CitySeExplorerHudTeamHeadList:OnCheckUpgradeDirty()
    self._upgradeCheck = true
end

function CitySeExplorerHudTeamHeadList:Tick(dt)
    if not self._upgradeCheck then return end
    self:GenerateHeadList()
end

function CitySeExplorerHudTeamHeadList:GenerateHeadList()
    self._upgradeCheck = false
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local heroCommon = player.Hero.SystemLevelHero
    local syHero = heroCommon and heroCommon[1]
    local heroCommonLevel = player.Hero.SystemLevel.SystemLevel
    local heroModule = ModuleRefer.HeroModule
    local addItems, delta
    if syHero then
        local isMaxLv = heroModule:IsMaxLevel(syHero)
        if isMaxLv then
            goto continue
        end
        if heroModule:IsHeroLevelLimited() then
            goto continue
        end
        -- if heroModule:GetLimitedLevel() < heroCommonLevel then
        --     goto continue
        -- end
        local needBreak = heroModule:NeedBreak(syHero)
        if needBreak then
            goto continue
        end
        addItems, delta = heroModule:GetHeroUpgradeCost(syHero)
        ::continue::
    end
    table.clear(self._heroCellsData)
    ---@type CitySeExplorerHudTeamHeadData[]
    local cellData = self._heroCellsData
    for i = 1, #self._currentTrackHeroes do
        if not addItems or not delta or delta > 0 then
            break
        end
        local heroConfigId = self._currentTrackHeroes[i]
        ---@type CitySeExplorerHudTeamHeadData
        local data = {}
        data.heroConfigId = heroConfigId
        data.heroUpgradeItems = addItems
        table.insert(cellData, data) 
    end
    self._p_hero:SetVisible(#cellData > 0)
    for i = 1, #self._heroCells do
        if i <= #cellData then
            self._heroCells[i]:SetVisible(true)
            self._heroCells[i]:FeedData(cellData[i])
        else
            self._heroCells[i]:SetVisible(false)
        end
    end
    local petModule = ModuleRefer.PetModule
    local inventoryModule = ModuleRefer.InventoryModule
    table.clear(self._petCellsData)
    ---@type CitySeExplorerHudTeamHeadData[]
    cellData = self._petCellsData
    for i = 1, #self._currentTrackPets do
        local petId = self._currentTrackPets[i]
        local canUp, itemId, itemCount = petModule:CanPetOnClickUp(petId, inventoryModule)
        if canUp then
            ---@type CitySeExplorerHudTeamHeadData
            local data = {}
            data.petId = petId
            data.petUpgradeItems = {[itemId] = itemCount}
            table.insert(cellData, data)
        end
    end
    self._p_pet:SetVisible(#cellData > 0)
    for i = 1, #self._petCells do
        if i <= #cellData then
            self._petCells[i]:SetVisible(true)
            self._petCells[i]:FeedData(cellData[i])
        else
            self._petCells[i]:SetVisible(false)
        end
    end
    
    self._p_text_upgrade_hero.text = "Lv." .. tostring(heroCommonLevel)
    self._p_text_upgrade_pet.text = "Lv." .. tostring(petModule:GetPetResonateLevel())
end

---@param entity wds.CastleBrief
function CitySeExplorerHudTeamHeadList:OnPresetChanged(entity, _)
    if not self._castleBriefId or not entity or entity.ID ~= self._castleBriefId then return end
    table.clear(self._currentTrackHeroes)
    table.clear(self._currentTrackPets)
    local preset = entity.TroopPresets.Presets[self._presetIndex + 1]
    if preset then
        for _, presetHero in pairs(preset.Heroes) do
            table.insert(self._currentTrackHeroes, presetHero.HeroCfgID)
            if presetHero.PetCompId ~= 0 then
                table.insert(self._currentTrackPets, presetHero.PetCompId)
            end
        end
    end
    self:OnCheckUpgradeDirty()
end

function CitySeExplorerHudTeamHeadList:OnHeroUpgradeClick()
    local tempSet = {}
    for _, heroConfigId in ipairs(self._currentTrackHeroes) do
        tempSet[heroConfigId] = true
    end
    --if ModuleRefer.HeroModule:HasOtherHero(tempSet) then
    --    g_Game.UIManager:Open(UIMediatorNames.UIHeroMainUIMediator)
    --    return
    --end
    for _, value in pairs(self._heroCellsData) do
        if value.heroUpgradeItems then
            self:SendUpgradeHero(value.heroConfigId, self._p_btn_upgrade_hero.transform ,value.heroUpgradeItems)
            return
        end
    end
end

function CitySeExplorerHudTeamHeadList:OnPetUpgradeClick()
    local tempSet = {}
    for _, heroConfigId in ipairs(self._currentTrackPets) do
        tempSet[heroConfigId] = true
    end
    --if ModuleRefer.PetModule:HasOtherPet(tempSet) then
    --    g_Game.UIManager:Open(UIMediatorNames.UIPetMediator)
    --    return
    --end
    for _, value in pairs(self._petCellsData) do
        if value.petUpgradeItems then
            local itemCount = value.petUpgradeItems[ModuleRefer.PetModule._levelUpExpItemCfgId]
            self:SendUpgradePet(value.petId, self._p_btn_upgrade_pet.transform, itemCount)
            return
        end
    end
end

function CitySeExplorerHudTeamHeadList:SendUpgradeHero(heroId, locktrans, addItems)
    ModuleRefer.HeroModule:AddExp(heroId,locktrans,addItems)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_upgrade)
end

function CitySeExplorerHudTeamHeadList:SendUpgradePet(petID, locktrans, itemCount)
    ModuleRefer.PetModule:PetAddExp(petID, itemCount)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_upgrade)
end

return CitySeExplorerHudTeamHeadList