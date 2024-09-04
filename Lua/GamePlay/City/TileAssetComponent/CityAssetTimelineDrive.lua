local CityAssetTimelineDriveHost = require("CityAssetTimelineDriveHost")
local Utils = require("Utils")

---@class CityAssetTimelineDrive
---@field playableDirector CS.UnityEngine.Playables.PlayableDirector
local CityAssetTimelineDrive = sealedClass("CityAssetTimelineDrive")

function CityAssetTimelineDrive:OnEnable()
    CityAssetTimelineDriveHost.GetInstance():AddTickStart(self)
end

function CityAssetTimelineDrive:OnDisable()
    CityAssetTimelineDriveHost.GetInstance():RemoveTickStart(self)
end

function CityAssetTimelineDrive:InQueuePlayStart()
    if Utils.IsNotNull(self.playableDirector) then
        self.playableDirector:Play()
    end
end

return CityAssetTimelineDrive