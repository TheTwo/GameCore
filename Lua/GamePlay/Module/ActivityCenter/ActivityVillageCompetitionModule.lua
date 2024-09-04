local BaseModule = require("BaseModule")
local ConfigRefer = require("ConfigRefer")
local VillageType = require("VillageType")
local ModuleRefer = require("ModuleRefer")
local AllianceModuleDefine = require("AllianceModuleDefine")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local I18N = require("I18N")
local KingdomMapUtils = require("KingdomMapUtils")

---@class ActivityVillageCompetitionModule : BaseModule
local ActivityVillageCompetitionModule = class("ActivityVillageCompetitionModule", BaseModule)

function ActivityVillageCompetitionModule:ctor()
    ---@type table<number, TerritoryConfigCell[]>
    self.villageCfgCache = {}
end

function ActivityVillageCompetitionModule:OnRegister()
end

function ActivityVillageCompetitionModule:OnRemove()
    self:ReleaseVillageCfgCache()
end

function ActivityVillageCompetitionModule:InitVillageCfgCache()
    ---@type number, TerritoryConfigCell
    for _, cfg in ConfigRefer.Territory:ipairs() do
        if cfg:VillageType() == VillageType.Village then
            local vCfg = ConfigRefer.FixedMapBuilding:Find(cfg:VillageId())
            local lvl = vCfg:Level()
            if not self.villageCfgCache[lvl] then
                self.villageCfgCache[lvl] = {}
            end
            table.insert(self.villageCfgCache[lvl], cfg)
        end
    end
end

function ActivityVillageCompetitionModule:ReleaseVillageCfgCache()
    table.clear(self.villageCfgCache)
end

function ActivityVillageCompetitionModule:GotoNeareastVillageByLevel(lvl)
    if table.isNilOrZeroNums(self.villageCfgCache) then
        self:InitVillageCfgCache()
    end
    local cfgs = self.villageCfgCache[lvl]
    if not cfgs then
        return
    end
    local basePos = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    local myAllianceMemberDic = ModuleRefer.AllianceModule:GetMyAllianceMemberDic()
    for _, member in pairs(myAllianceMemberDic) do
        if member.Rank == AllianceModuleDefine.LeaderRank then
            basePos = member.BigWorldPosition
            break
        end
    end
    local allianceCenterVillage = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
    if allianceCenterVillage then
        basePos = allianceCenterVillage.Pos
    end
    local baseX, baseZ = KingdomMapUtils.ParseBuildingPos(basePos)
    local coord = CS.DragonReborn.Vector2Short(baseX, baseZ)
    local gotoCallback = function()
        local filter = function(vx,vy,level,territoryConfig,villageConfig)
            return villageConfig:SubType() == require("MapBuildingSubType").City and level == lvl
            and ModuleRefer.TerritoryModule:GetDistrictAt(vx, vy) == ModuleRefer.TerritoryModule:GetDistrictAt(baseX, baseZ)
        end
        local _, _, tileX, tileZ = ModuleRefer.TerritoryModule:GetNearestTerritoryPosition(coord, lvl, filter)
        if not tileX or not tileZ then
            g_Logger.ErrorChannel("ActivityVillageCompetitionModule", "省内未找到符合条件的目标，尝试在省外寻找")
            local filterWithoutDistrict = function(vx,vy,level,territoryConfig,villageConfig)
                return villageConfig:SubType() == require("MapBuildingSubType").City and level == lvl
            end
            _, _, tileX, tileZ = ModuleRefer.TerritoryModule:GetNearestTerritoryPosition(coord, lvl, filterWithoutDistrict)
            if not tileX or not tileZ then
                return false
            end
        end
        AllianceWarTabHelper.GoToCoord(tileX, tileZ, true, nil, nil, nil)
        return true
    end

    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene then
        return false
    end
    if scene:IsInCity() then
        scene:LeaveCity(gotoCallback)
        return true
    else
        return gotoCallback()
    end
end

return ActivityVillageCompetitionModule