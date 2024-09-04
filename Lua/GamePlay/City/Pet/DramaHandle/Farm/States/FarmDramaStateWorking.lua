local FarmDramaStateBase = require("FarmDramaStateBase")
---@class FarmDramaStateWorking:FarmDramaStateBase
local FarmDramaStateWorking = class("FarmDramaStateWorking", FarmDramaStateBase)

function FarmDramaStateWorking:Enter()
    self.handle.petUnit:PlayLoopState(self.handle:GetWorkCfgAnimName())
    self.handle.petUnit:SyncAnimatorSpeed()
    self.playTime = 3
    self.needCrop = self.handle:IsCurrentFieldFull()
end

function FarmDramaStateWorking:Tick(dt)
    if self.playTime and self.playTime > 0 then
        self.playTime = self.playTime - dt
        if self.playTime <= 0 then
            if self.needCrop then
                self.handle:CountPlus()
            else
                self.handle:DoWater()
            end
            self.handle:MoveToNextActPoint()
        end
    end
end

return FarmDramaStateWorking