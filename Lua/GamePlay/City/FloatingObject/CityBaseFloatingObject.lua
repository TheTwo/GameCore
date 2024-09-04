---@class CityBaseFloatingObject
local CityBaseFloatingObject = class("CityBaseFloatingObject")

function CityBaseFloatingObject:ctor()
end

function CityBaseFloatingObject:OnCreate()
end

function CityBaseFloatingObject:OnDestroy()
end

function CityBaseFloatingObject:OnMoveStart()
end

function CityBaseFloatingObject:OnMoveEnd()
end

function CityBaseFloatingObject:OnClick()
end

---@param dest CS.UnityEngine.Vector3
function CityBaseFloatingObject:MoveTo(dest)
end

function CityBaseFloatingObject:Pause()
end

function CityBaseFloatingObject:Update()
end

return CityBaseFloatingObject