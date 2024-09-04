local FurOverviewProcessState = require("FurOverviewProcessState")
---@class FurOverviewProcessStateAutoPaused:FurOverviewProcessState
---@field new fun():FurOverviewProcessStateAutoPaused
local FurOverviewProcessStateAutoPaused = class("FurOverviewProcessStateAutoPaused", FurOverviewProcessState)
local ConfigRefer = require("ConfigRefer")
local CityWorkType = require("CityWorkType")
local CityWorkFormula = require("CityWorkFormula")
local I18N = require("I18N")
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")

function FurOverviewProcessStateAutoPaused:Enter()
    self.data.cell._statusRecord:ApplyStatusRecord(2)
    local castleFurniture = self.data.city.furnitureManager:GetCastleFurniture(self.data.furnitureId)
    local info = castleFurniture.ProcessInfo[1]

    local cur = info.FinishNum
    local thisWorkCfg = ConfigRefer.CityWork:Find(info.WorkCfgId)
    local citizenId = nil
    local max = CityWorkFormula.GetAutoProcessMaxCount(thisWorkCfg, nil, self.data.furnitureId, citizenId)
    self.data.cell._p_progress_process.value = math.clamp01(cur / max)
    self.data.cell._p_text_time_process.text = ("%d/%d"):format(cur, max) --I18N.GetWithParams(FurnitureOverview_I18N.UIHint_FurnitureOverview_ProcessAutoProgress, cur, max)
    self.data.cell._p_text_process.text = I18N.Get("FAILURE_REASON_POLLUTED")
end

function FurOverviewProcessStateAutoPaused:Exit()
    
end

return FurOverviewProcessStateAutoPaused