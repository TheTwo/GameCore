local DBEntityType = require("DBEntityType")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@class HUDTroopCondition

local HUDTroopCondition = {}

---@param source wds.Troop
---@param target wds.Troop | wds.MapMob
---@return boolean
function HUDTroopCondition.CheckBehemothCage(source, target)
    if target.TypeHash == DBEntityType.MapMob and target.MobInfo and target.MobInfo.BehemothCageId > 0 then
        local isInCage = source and source.MapStates.StateWrapper2.InBehemothCage
        if not isInCage then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_tips_enterCage"))
            return false
        end    
    end

    return true
end

return HUDTroopCondition