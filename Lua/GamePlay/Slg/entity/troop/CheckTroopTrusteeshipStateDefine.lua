
---@class CheckTroopTrusteeshipStateDefine
local CheckTroopTrusteeshipStateDefine = {}

---@class CheckTroopTrusteeshipStateDefine.State
CheckTroopTrusteeshipStateDefine.State = {}
CheckTroopTrusteeshipStateDefine.State.None = false

CheckTroopTrusteeshipStateDefine.State.OldValue_Allow_Cancel = 1
CheckTroopTrusteeshipStateDefine.State.OldValue_Not_Allow_Cancel = 2

CheckTroopTrusteeshipStateDefine.State.InEscrowPreparing = 3
CheckTroopTrusteeshipStateDefine.State.InEscrowRunning = 4

CheckTroopTrusteeshipStateDefine.State.InAssemblePreparing = 5
CheckTroopTrusteeshipStateDefine.State.InAssembleLaunched = 6

---@param state CheckTroopTrusteeshipStateDefine.State
function CheckTroopTrusteeshipStateDefine.IsStateCanCancel(state)
    if state == CheckTroopTrusteeshipStateDefine.State.InEscrowPreparing
            or state == CheckTroopTrusteeshipStateDefine.State.InEscrowRunning
            or state == CheckTroopTrusteeshipStateDefine.State.InAssemblePreparing then
        return true
    end
    return false
end

return CheckTroopTrusteeshipStateDefine