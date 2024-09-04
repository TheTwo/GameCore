local ConfigRefer = require("ConfigRefer")
local AllianceBehemothDefine = require("AllianceBehemothDefine")
local ModuleRefer = require("ModuleRefer")

---@class AllianceBehemoth
---@field new fun():AllianceBehemoth
local AllianceBehemoth = class('AllianceBehemoth')

function AllianceBehemoth:ctor()
    ---@type wds.MapBuildingBrief
    self._cageBuilding = nil
    ---@type BehemothCageConfigCell
    self._cageConfig = nil
    ---@type FixedMapBuildingConfigCell
    self._cageBuildingConfig = nil
    ---@type wds.MapBuildingBrief
    self._deviceBuilding = nil
    ---@type BehemothDeviceConfigCell
    self._deviceConfig = nil
    ---@type FlexibleMapBuildingConfigCell
    self._deviceBuildingConfig = nil
    ---@type KmonsterDataConfigCell[]
    self._monstersByLv = {}
    ---@type KmonsterDataConfigCell[]
    self._summonMonstersByLv = {}
    ---@type AllianceBehemothDefine.SrcType
    self._srcType = AllianceBehemothDefine.SrcType.Dummy
end

---@param a KmonsterDataConfigCell
---@param b KmonsterDataConfigCell
function AllianceBehemoth.SortMonsterByLvThenId(a, b)
    local lvOffset = a:Level() - b:Level()
    if lvOffset < 0 then
        return true
    end
    if lvOffset > 0 then
        return false
    end
    return a:Id() < b:Id()
end

---@param kMonsterDataConfig KmonsterDataConfigCell
---@param summonMonsterConfig KmonsterDataConfigCell
function AllianceBehemoth.FromKMonsterData(kMonsterDataConfig, summonMonsterConfig)
    local ret = AllianceBehemoth.new()
    ret._monstersByLv[1] = kMonsterDataConfig
    ret._summonMonstersByLv[1] = summonMonsterConfig
    return ret
end

---@param cageConfig BehemothCageConfigCell
---@param cageBuildingConfig FixedMapBuildingConfigCell
function AllianceBehemoth.FromCageBuildingConfig(cageConfig, cageBuildingConfig)
	local ret = AllianceBehemoth.new()
	ret._cageConfig = cageConfig
	ret._cageBuildingConfig = cageBuildingConfig
	table.clear(ret._monstersByLv)
	for i = 1, ret._cageConfig:InstanceMonsterLength() do
		ret._monstersByLv[i] = ConfigRefer.KmonsterData:Find(ret._cageConfig:InstanceMonster(i))
	end
	table.sort(ret._monstersByLv, AllianceBehemoth.SortMonsterByLvThenId)
	table.clear(ret._summonMonstersByLv)
	for i = 1, ret._cageConfig:BehemothTroopMonsterLength() do
		ret._summonMonstersByLv[i] = ConfigRefer.KmonsterData:Find(ret._cageConfig:BehemothTroopMonster(i))
	end
	table.sort(ret._summonMonstersByLv, AllianceBehemoth.SortMonsterByLvThenId)
	return ret
end

---@param building wds.MapBuildingBrief
function AllianceBehemoth.FromDeviceDefault(building)
    local ret = AllianceBehemoth.new()
    ret._srcType = AllianceBehemothDefine.SrcType.DeviceDefault
    ret:UpdateBuildingEntity(building)
    return ret
end

---@param building wds.MapBuildingBrief
function AllianceBehemoth.FromCageBuilding(building)
    local ret = AllianceBehemoth.new()
    ret._srcType = AllianceBehemothDefine.SrcType.Cage
    ret:UpdateBuildingEntity(building)
    return ret
end

---@param building wds.MapBuildingBrief
function AllianceBehemoth:UpdateBuildingEntity(building)
    if self._srcType == AllianceBehemothDefine.SrcType.Cage then
        self._cageBuilding = building
        self._cageBuildingConfig = ConfigRefer.FixedMapBuilding:Find(building.ConfigId)
        self._cageConfig = ConfigRefer.BehemothCage:Find(self._cageBuildingConfig:BehemothCageConfig())
        table.clear(self._monstersByLv)
        for i = 1, self._cageConfig:InstanceMonsterLength() do
            self._monstersByLv[i] = ConfigRefer.KmonsterData:Find(self._cageConfig:InstanceMonster(i))
        end
        table.sort(self._monstersByLv, AllianceBehemoth.SortMonsterByLvThenId)
        table.clear(self._summonMonstersByLv)
        for i = 1, self._cageConfig:BehemothTroopMonsterLength() do
            self._summonMonstersByLv[i] = ConfigRefer.KmonsterData:Find(self._cageConfig:BehemothTroopMonster(i))
        end
        table.sort(self._summonMonstersByLv, AllianceBehemoth.SortMonsterByLvThenId)
    elseif self._srcType == AllianceBehemothDefine.SrcType.DeviceDefault then
        self._deviceBuilding = building
        self._deviceBuildingConfig = ConfigRefer.FlexibleMapBuilding:Find(building.ConfigId)
        self._deviceConfig = ConfigRefer.BehemothDevice:Find(self._deviceBuildingConfig:BehemothDeviceConfig())
        table.clear(self._monstersByLv)
        for i = 1, self._deviceConfig:InstanceMonsterLength() do
            self._monstersByLv[i] = ConfigRefer.KmonsterData:Find(self._deviceConfig:InstanceMonster(i))
        end
        table.sort(self._monstersByLv, AllianceBehemoth.SortMonsterByLvThenId)
        table.clear(self._summonMonstersByLv)
        for i = 1, self._deviceConfig:BehemothTroopMonsterLength() do
            self._summonMonstersByLv[i] = ConfigRefer.KmonsterData:Find(self._deviceConfig:BehemothTroopMonster(i))
        end
        table.sort(self._summonMonstersByLv, AllianceBehemoth.SortMonsterByLvThenId)
    end
end

function AllianceBehemoth:GetBuildingEntityId()
    if self._srcType == AllianceBehemothDefine.SrcType.DeviceDefault then
        return self._deviceBuilding.EntityID
    end
    if self._srcType == AllianceBehemothDefine.SrcType.Cage then
        return self._cageBuilding.EntityID
    end
    return nil
end

function AllianceBehemoth:GetBehemothGroupId()
    return ModuleRefer.AllianceModule.Behemoth:GetBehemothGroupId(self._monstersByLv[1]:Id())
end

---@return KmonsterDataConfigCell|nil 
function AllianceBehemoth:GetCageSlgInstanceMonsterConfig()
	if self._srcType ~= AllianceBehemothDefine.SrcType.Cage then return end
	return ConfigRefer.KmonsterData:Find(self._cageConfig:Monster())
end

---@return KmonsterDataConfigCell|nil
function AllianceBehemoth:GetRefKMonsterDataConfig(level)
    level = math.clamp(level, 1, #self._monstersByLv)
    return self._monstersByLv[level]
end

---@return KmonsterDataConfigCell|nil
function AllianceBehemoth:GetSummonRefKMonsterDataConfig(level)
    level = math.clamp(level, 1, #self._summonMonstersByLv)
    return self._summonMonstersByLv[level]
end

function AllianceBehemoth:IsFake()
    return self._srcType == AllianceBehemothDefine.SrcType.Dummy
end

function AllianceBehemoth:IsDeviceDefault()
    return self._srcType == AllianceBehemothDefine.SrcType.DeviceDefault
end

function AllianceBehemoth:IsFromCage()
    return self._srcType == AllianceBehemothDefine.SrcType.Cage
end

function AllianceBehemoth:GetBuilding()
    if self._srcType == AllianceBehemothDefine.SrcType.DeviceDefault then
        return self._deviceBuilding
    end
    if self._srcType == AllianceBehemothDefine.SrcType.Cage then
        return self._cageBuilding
    end
    return nil
end

---@return number, number
function AllianceBehemoth:GetMapLocation()
    local building = self:GetBuilding()
    if building then
        return building.Pos.X, building.Pos.Y
    end
    return nil
end

return AllianceBehemoth
