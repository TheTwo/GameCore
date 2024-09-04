---@class CityLegoFloor
---@field new fun():CityLegoFloor
local CityLegoFloor = sealedClass("CityLegoFloor")
local CityLegoDefine = require("CityLegoDefine")
local CityLegoAttachedDecoration = require("CityLegoAttachedDecoration")
local ConfigRefer = require("ConfigRefer")

---@param legoBuilding CityLegoBuilding
---@param payload LegoBlockInstanceConfigCell
function CityLegoFloor:ctor(legoBuilding, payload)
    self.legoBuilding = legoBuilding
    self.city = self.legoBuilding.manager.city
    self:UpdatePayload(payload)
end

---@param payload LegoBlockInstanceConfigCell
function CityLegoFloor:UpdatePayload(payload)
    local coord = payload:RelPos()
    self.x = coord:X() + self.legoBuilding.x
    self.y = coord:Y()
    self.z = coord:Z() + self.legoBuilding.z

    if (self.x % 1 ~= 0) or (self.z % 1 ~= 0) then
        g_Logger.ErrorChannel("CityLegoFloor", "[BlockInstance:%d] 配置偏移非整数", payload:Id())
    end

    self.payload = payload
    self.hashCode = CityLegoDefine.GetCoordHashCode(self.x, self.y, self.z)
    self.filter = nil
    self.indoorDecorations = nil
    self.outsideDecorations = nil
end

function CityLegoFloor:UpdatePosition()
    if not self.payload then return end

    local coord = self.payload:RelPos()
    self.x = coord:X() + self.legoBuilding.x
    self.y = coord:Y()
    self.z = coord:Z() + self.legoBuilding.z

    if (self.x % 1 ~= 0) or (self.z % 1 ~= 0) then
        g_Logger.ErrorChannel("CityLegoFloor", "[BlockInstance:%d] 配置偏移非整数", self.payload:Id())
    end

    self.hashCode = CityLegoDefine.GetCoordHashCode(self.x, self.y, self.z)
end

---@return number
function CityLegoFloor:GetCfgId()
    return self.payload:Type()
end

function CityLegoFloor:GetStyle(indoor)
    if indoor then
        return self.payload:StyleIndoor()
    else
        return self.payload:StyleOutside()
    end
end

function CityLegoFloor:GetWorldPosition()
    return self.city:GetCenterWorldPositionFromCoord(self.x, self.z, CityLegoDefine.BlockSize, CityLegoDefine.BlockSize)
end

function CityLegoFloor:GetDecorations(indoor)
    local filter = self:GetAttachPointFilter()
    if indoor then
        return self:GetIndoorDecorations(filter)
    else
        return self:GetOutsideDecorations(filter)
    end
end

function CityLegoFloor:HasIndoorPart()
    return self.payload:StyleIndoor() > 0
end

function CityLegoFloor:HasOutsidePart()
    return self.payload:StyleOutside() > 0
end

---@private
function CityLegoFloor:GetAttachPointFilter()
    if self.filter == nil then
        local blockCfg = ConfigRefer.LegoBlock:Find(self:GetCfgId())
        self.filter = {}
        for i = 1, blockCfg:AttachPointLength() do
            local attachPointCfgId = blockCfg:AttachPoint(i)
            local attachPointCfg = ConfigRefer.LegoBlockAttachPoint:Find(attachPointCfgId)
            if attachPointCfg then
                self.filter[attachPointCfg:Name()] = attachPointCfg:Outside()
            end
        end
    end
    return self.filter
end

---@private
function CityLegoFloor:GetIndoorDecorations(filter)
    if self.indoorDecorations == nil then
        ---@type CityLegoAttachedDecoration[]
        self.indoorDecorations = {}
        for i = 1, self.payload:DecorationsLength() do
            local decorationCfg = self.payload:Decorations(i)
            local name = decorationCfg:AttachPoint()
            if not string.IsNullOrEmpty(name) and filter[name] == false then
                local decoration = CityLegoAttachedDecoration.new(self.legoBuilding, decorationCfg, self:GetCfgId())
                table.insert(self.indoorDecorations, decoration)
            end
        end
    end
    return self.indoorDecorations
end

---@private
function CityLegoFloor:GetOutsideDecorations(filter)
    if self.outsideDecorations == nil then
        ---@type CityLegoAttachedDecoration[]
        self.outsideDecorations = {}
        for i = 1, self.payload:DecorationsLength() do
            local decorationCfg = self.payload:Decorations(i)
            local name = decorationCfg:AttachPoint()
            if not string.IsNullOrEmpty(name) and filter[name] == true then
                local decoration = CityLegoAttachedDecoration.new(self.legoBuilding, decorationCfg, self:GetCfgId())
                table.insert(self.outsideDecorations, decoration)
            end
        end
    end
    return self.outsideDecorations
end

return CityLegoFloor