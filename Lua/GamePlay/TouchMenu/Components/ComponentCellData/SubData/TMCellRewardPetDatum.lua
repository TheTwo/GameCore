local TMCellRewardBase = require("TMCellRewardBase")

---@class TMCellRewardPetDatum:TMCellRewardBase
---@field super TMCellRewardBase
---@field new fun(content:string, petConfigIds:number[]):TMCellRewardPetDatum
local TMCellRewardPetDatum = class('TMCellRewardPetDatum', TMCellRewardBase)

---@param content string
---@param petConfigIds number[]
function TMCellRewardPetDatum:ctor(content, petConfigIds)
    self.content = content
    self.petConfigIds = petConfigIds
end

function TMCellRewardPetDatum:GetPrefabIndex()
    return 3
end

return TMCellRewardPetDatum