---@class CityCreepBinaryData 解析菌毯二进制配置
---@field new fun():CityCreepBinaryData
---@field data table<number, CityCreepUnpackData>
local CityCreepBinaryData = class("CityCreepBinaryData")
local filenameWithoutExtension = "creepData"

---@class CityCreepUnpackData
---@field id number
---@field maxFieldX number
---@field maxFieldY number
---@field maxFieldSizeX number
---@field maxFieldSizeY number

---@private
function CityCreepBinaryData:Load(fileNameWithoutExt)
    local flag, data = CS.CityCreepBinaryDeserializer.Deserialize(fileNameWithoutExt)
    if not flag then
        error("解析菌毯数据失败")
    end
    self.data = data
end

CityCreepBinaryData.Instance = CityCreepBinaryData.new()
CityCreepBinaryData.Instance:Load(filenameWithoutExtension)

return CityCreepBinaryData