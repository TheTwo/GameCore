local FurOverviewProcessState = require("FurOverviewProcessState")
---@class FurOverviewProcessStateDoing:FurOverviewProcessState
---@field new fun():FurOverviewProcessStateDoing
local FurOverviewProcessStateDoing = class("FurOverviewProcessStateDoing", FurOverviewProcessState)
local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
local TimeFormatter = require("TimeFormatter")
local Delegate = require("Delegate")

function FurOverviewProcessStateDoing:Enter()
    self.data.cell._statusRecord:ApplyStatusRecord(1)

    local castleFurniture = self.data.city.furnitureManager:GetCastleFurniture(self.data.furnitureId)
    local progress = CityWorkProcessWdsHelper.GetCityWorkProcessProgress(self.data.city, castleFurniture)
    local remainTime = CityWorkProcessWdsHelper.GetCityWorkProcessRemainTime(self.data.city, castleFurniture.ProcessInfo)

    self.data.cell._p_progress_process.value = progress
    self.data.cell._p_text_time_process.text = TimeFormatter.SimpleFormatTime(remainTime)

    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function FurOverviewProcessStateDoing:Exit()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function FurOverviewProcessStateDoing:OnFrameTick()
    local castleFurniture = self.data.city.furnitureManager:GetCastleFurniture(self.data.furnitureId)
    if not castleFurniture then return end
    
    local progress = CityWorkProcessWdsHelper.GetCityWorkProcessProgress(self.data.city,castleFurniture, castleFurniture.ProcessInfo)
    local remainTime = CityWorkProcessWdsHelper.GetCityWorkProcessRemainTime(self.data.city, castleFurniture.ProcessInfo)

    self.data.cell._p_progress_process.value = progress
    self.data.cell._p_text_time_process.text = TimeFormatter.SimpleFormatTime(remainTime)

    if remainTime <= 0 then
        local FurOverviewProcessStateFinished = require("FurOverviewProcessStateFinished")
        self.stateMachine:ChangeState(FurOverviewProcessStateFinished:GetName())
    end
end

return FurOverviewProcessStateDoing