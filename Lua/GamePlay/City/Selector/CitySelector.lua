---@class CitySelector
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field new fun():CitySelector
---@field meshDrawer CS.GridMapBuildingMesh
---@field city City
local CitySelector = class("CitySelector")
local _, yesColor = CS.UnityEngine.ColorUtility.TryParseHtmlString("#3FFF00DD")
local _, noColor = CS.UnityEngine.ColorUtility.TryParseHtmlString("#FF1400FF")

function CitySelector:Awake()
    self.gameObject = self.behaviour.gameObject
    self.transform = self.gameObject.transform
end

---@param city City
function CitySelector:Init(city, x, y, sizeX, sizeY)
    self.city = city
    self.x, self.y = x, y
    self.sizeX, self.sizeY = sizeX, sizeY
    self.transform.position = self.city:GetWorldPositionFromCoord(self.x, self.y)
    self.data = xlua.newtable(sizeX * sizeY)
    for i = 1, sizeX * sizeY do
        self.data[i] = 1
    end
    self:InitMesh(self.sizeX, self.sizeY)
end

function CitySelector:InitMesh(sizeX, sizeY)
    self.meshDrawer:Initialize(sizeX, sizeY, 1, 1, self.data, {noColor, yesColor}, 0)
end

function CitySelector:UpdatePosition(x, y)
    self.x, self.y = x, y
    self.transform.position = self.city:GetWorldPositionFromCoord(x, y)
end

return CitySelector
