---@class TouchInfoCompDatum
---@field new fun(typ:number, compData):TouchInfoCompDatum
local TouchInfoCompDatum = sealedClass("TouchInfoCompDatum")

---@class TouchInfoButtonCompDatum:TouchInfoCompDatum
---@field compData TouchInfoButtonData

---@class TouchInfoImageCompDatum:TouchInfoCompDatum
---@field compData TouchInfoImageCompData

---@class TouchInfoNameCompDatum:TouchInfoCompDatum
---@field compData TouchInfoNameCompData

---@class TouchInfoPairCompDatum:TouchInfoCompDatum
---@field compData TouchInfoPairComponentData

---@class TouchInfoProgressCompDatum:TouchInfoCompDatum
---@field compData TouchInfoProgressCompData

---@class TouchInfoResidentCompDatum:TouchInfoCompDatum
---@field compData TouchInfoResidentCompData

---@class TouchInfoRewardCompDatum:TouchInfoCompDatum
---@field compData TouchInfoRewardCompData

---@class TouchInfoTextCompDatum:TouchInfoCompDatum
---@field compData TouchInfoTextCompData

---@class TouchInfoPollutionCompDatum:TouchInfoCompDatum
---@field compData TouchInfoPollutionCompData

---@class TouchInfoTaskProgressCompDatum:TouchInfoCompDatum
---@field compData TouchInfoTaskProgressCompData

---@class TouchInfoSingleTaskCompDatum:TouchInfoCompDatum
---@field compData TouchInfoSingleTaskCompData

---@param typ number TouchInfoTemplate下的枚举
function TouchInfoCompDatum:ctor(typ, compData)
    self.typ = typ
    self.compData = compData
end

return TouchInfoCompDatum