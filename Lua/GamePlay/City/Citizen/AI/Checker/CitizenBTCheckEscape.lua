local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTNode = require("CitizenBTNode")

---@class CitizenBTCheckEscape:CitizenBTNode
---@field new fun():CitizenBTCheckEscape
---@field super CitizenBTNode
local CitizenBTCheckEscape = class('CitizenBTCheckEscape', CitizenBTNode)

function CitizenBTCheckEscape:Run(context, gContext)
    local current = context:Read(CitizenBTDefine.ContextKey.CurrentKey)
    if current ~= "CitizenBTActionEscape" then
        local mgr = context:GetMgr()
        return mgr:CheckIsEnemyEffectRange(context:GetCitizen())
    end
    return false
end

return CitizenBTCheckEscape