---@class CityFurnitureSelector
---@field new fun():CityFurnitureSelector
---@field arrowL CS.UnityEngine.Transform
---@field arrowR CS.UnityEngine.Transform
---@field arrowT CS.UnityEngine.Transform
---@field arrowB CS.UnityEngine.Transform
---@field meshDrawer CS.GridMapBuildingMesh
local CityFurnitureSelector = class("CityFurnitureSelector")
local Vector3 = CS.UnityEngine.Vector3
local CityGridLayerMask = require("CityGridLayerMask")
local _, yesColor = CS.UnityEngine.ColorUtility.TryParseHtmlString("#3FFF00DD")
local _, noColor = CS.UnityEngine.ColorUtility.TryParseHtmlString("#FF1400FF")

function CityFurnitureSelector:Awake()
    self.gameObject = self.behaviour.gameObject
    self.transform = self.gameObject.transform
end

---@param city City
---@param dataWrap SelectorDataWrap
---@param showArrow boolean
function CityFurnitureSelector:Init(city, dataWrap, showArrow)
    self.city = city
    self.dataWrap = dataWrap
    self.showArrow = showArrow
    self.dataWrap:AttachSelector(self)
    self:SwitchArrowShowed(showArrow)
    if showArrow then
        self:InitArrowPos(dataWrap.sizeX, dataWrap.sizeY)
    end
    self.transform.position = self.city:GetWorldPositionFromCoord(dataWrap.x, dataWrap.y)
    self:InitData()
    self:InitMesh()
end

function CityFurnitureSelector:SwitchArrowShowed(flag)
    self.arrowL.gameObject:SetActive(flag == true)
    self.arrowR.gameObject:SetActive(flag == true)
    self.arrowB.gameObject:SetActive(flag == true)
    self.arrowT.gameObject:SetActive(flag == true)
end

function CityFurnitureSelector:InitArrowPos(xLength, yLength)
    self.arrowL.localPosition = Vector3(-1, 0, yLength / 2)
    self.arrowR.localPosition = Vector3(xLength + 1, 0, yLength / 2)
    self.arrowB.localPosition = Vector3(xLength / 2, 0, -1)
    self.arrowT.localPosition = Vector3(xLength / 2, 0, yLength + 1)
end

function CityFurnitureSelector:InitData()
    local sizeX, sizeY = self.dataWrap:GetSize()
    self.data = xlua.newtable(sizeX * sizeY)
    self:UpdateData()
end

function CityFurnitureSelector:UpdateData()
    self.dataWrap:UpdateData(self.data)
end

function CityFurnitureSelector:InitMesh()
    local sizeX, sizeY = self.dataWrap:GetSize()
    self.meshDrawer:Initialize(sizeX, sizeY, 1, 1, self.data, {noColor, yesColor}, 0)
end

return CityFurnitureSelector