local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local UIHelper = require("UIHelper")
local Utils = require("Utils")

local BaseUIComponent = require("BaseUIComponent")

---@class CitySeExplorerHudTeamHeadData
---@field heroConfigId number|nil
---@field heroUpgradeItems table<number, table<number, number>>|nil
---@field petId number|nil
---@field petUpgradeItems table<number, number>|nil

---@class CitySeExplorerHudTeamHead:BaseUIComponent
---@field super BaseUIComponent
local CitySeExplorerHudTeamHead = class("CitySeExplorerHudTeamHead", BaseUIComponent)

function CitySeExplorerHudTeamHead:ctor()
    CitySeExplorerHudTeamHead.super.ctor(self)
    ---@see HeroInfoItemSmallComponent
    self._p_head_hero = nil
    ---@see CommonPetIconSmall
    self._p_head_pet = nil
    ---@type CS.DragonReborn.UI.UIHelper.CallbackHolder
    self._heroHeadCreateHolder = nil
    ---@type CS.DragonReborn.UI.UIHelper.CallbackHolder
    self._petHeadCreateHolder = nil
end

function CitySeExplorerHudTeamHead:OnCreate(param)
    self._selfGoName = self:GameObject("").name
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
end

---@param param CitySeExplorerHudTeamHeadData
function CitySeExplorerHudTeamHead:OnFeedData(param)
    self._param = param
    if not param then return end
    if param.heroConfigId then
        if not self._heroHeadCreateHolder then
            self._heroHeadCreateHolder =  CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self:GetParentBaseUIMediator().CSComponent, "child_card_hero_s_ex", self._selfGoName, Delegate.GetOrCreate(self, self.OnHeroHeadCreated), false)
        else
            self:FeedHeroHead()
        end
    elseif param.petId then
        if not self._petHeadCreateHolder then
            self._petHeadCreateHolder =  CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self:GetParentBaseUIMediator().CSComponent, "child_card_pet_circle", self._selfGoName, Delegate.GetOrCreate(self, self.OnPetHeadCreated), false)
        else
            self:FeedPetHead()
        end
    end
end

---@param go CS.UnityEngine.GameObject
function CitySeExplorerHudTeamHead:OnHeroHeadCreated(go, success)
    if Utils.IsNotNull(go) then
        self._p_head_hero = go:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent))
        self:FeedHeroHead()
    end
end

function CitySeExplorerHudTeamHead:OnPetHeadCreated(go, success)
    if Utils.IsNotNull(go) then
        self._p_head_pet = go:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent))
        self:FeedPetHead()
    end
end

function CitySeExplorerHudTeamHead:FeedHeroHead()
    if self._p_head_hero and self._param and self._param.heroConfigId then
        local heroConfigCache = ModuleRefer.HeroModule:GetHeroByCfgId(self._param.heroConfigId)
        ---@type HeroInfoData
        local data = {}
        data.onClick = Delegate.GetOrCreate(self, self.OnClickSelf)
        data.heroData = heroConfigCache
        self._p_head_hero:FeedData(data)
    end
end

function CitySeExplorerHudTeamHead:FeedPetHead()
    if self._p_head_pet and self._param and self._param.petId then
        local petData = ModuleRefer.PetModule:GetPetByID(self._param.petId)
        ---@type CommonPetIconBaseData
        local data = {}
        data.id = self._param.petId
        data.cfgId = petData.ConfigId
        data.onClick = Delegate.GetOrCreate(self, self.OnClickSelf)
        data.level = petData.Level
        self._p_head_pet:FeedData(data)
    end
end

function CitySeExplorerHudTeamHead:OnClose()
    if self._heroHeadCreateHolder then
        self._heroHeadCreateHolder:AbortAndCleanup()
        self._heroHeadCreateHolder = nil
    end
    if self._petHeadCreateHolder then
        self._petHeadCreateHolder:AbortAndCleanup()
        self._petHeadCreateHolder = nil
    end
    if self._p_head_hero and Utils.IsNotNull(self._p_head_hero) then
        UIHelper.DeleteUIComponent(self._p_head_hero)
        self._p_head_hero = nil
    end
    if self._p_head_pet and Utils.IsNotNull(self._p_head_pet) then
        UIHelper.DeleteUIComponent(self._p_head_pet)
        self._p_head_pet = nil
    end
end

return CitySeExplorerHudTeamHead