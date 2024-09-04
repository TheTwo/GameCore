local ConfigRefer = require("ConfigRefer")

---@class AllianceBehemothDeviceInfo
---@field new fun(mapBuilding:wds.MapBuildingBrief):AllianceBehemothDeviceInfo
local AllianceBehemothDeviceInfo = class('AllianceBehemothDeviceInfo')

---@param mapBuilding wds.MapBuildingBrief
function AllianceBehemothDeviceInfo:ctor(mapBuilding)
    self:UpdateBuilding(mapBuilding)
end

---@param mapBuilding wds.MapBuildingBrief
function AllianceBehemothDeviceInfo:UpdateBuilding(mapBuilding)
    self._building = mapBuilding
    local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(mapBuilding.ConfigId)
    self._deviceConfig = ConfigRefer.BehemothDevice:Find(buildingConfig:BehemothDeviceConfig())
    local deviceExtra = mapBuilding.BehemothDevice
    ---@type number @buildingEntityId
    self._bindBehemoth = deviceExtra.BindBehemoth
    ---@type number @device lv
    self._level = deviceExtra.Level
    self._maxLevel = self._deviceConfig:MaxLevel()
end

return AllianceBehemothDeviceInfo