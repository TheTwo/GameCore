--- scene:scene_league_popup_new_leader

local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceNewLeaderMediator:BaseUIMediator
---@field new fun():AllianceNewLeaderMediator
---@field super BaseUIMediator
local AllianceNewLeaderMediator = class('AllianceNewLeaderMediator', BaseUIMediator)

function AllianceNewLeaderMediator:OnCreate(param)
    self._p_text = self:Text("p_text")
    self._p_text_hint = self:Text("p_text_hint")
end

---@param param wds.AllianceLeaderChangeInfo
function AllianceNewLeaderMediator:OnOpened(param)
    ModuleRefer.AllianceModule:ReadAllianceLeaderChange()
    self._p_text.text = I18N.GetWithParams("alliance_retire_leaderchange_popup_title", param.NewName)
    if param.Reason == wds.AllianceLeaderChangeReason.AllianceLeaderChangeReason_ActiveSwitchLeader then
        self._p_text_hint.text = I18N.GetWithParams("alliance_retire_leaderchange_popup_desc1", param.OldName)
    elseif param.Reason == wds.AllianceLeaderChangeReason.AllianceLeaderChangeReason_Impeach then
        local total = (param.Params[1] or 0) + (param.Params[2] or 0) -- 同意+反对
        self._p_text_hint.text = I18N.GetWithParams("alliance_retire_leaderchange_popup_desc3", param.OldName, total, param.Params[1] or 0)
    else
        self._p_text_hint.text = I18N.GetWithParams("alliance_retire_leaderchange_popup_desc2", param.OldName)
    end
end

return AllianceNewLeaderMediator