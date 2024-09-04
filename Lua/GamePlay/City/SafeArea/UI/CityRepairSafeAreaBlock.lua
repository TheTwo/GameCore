local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

---@class CityRepairSafeAreaBlock:CityRepairBlockBase
---@field new fun():CityRepairSafeAreaBlock
---@field GetCity fun(self:CityRepairBlockBase):City|MyCity
---@field Contains fun(self:CityRepairBlockBase,x:number,y:number):boolean
local CityRepairSafeAreaBlock = sealedClass('CityRepairSafeAreaBlock')

---@param city City
---@param wallId number
function CityRepairSafeAreaBlock:Setup(city, wallId)
    self._city = city
    self._wallId = wallId
    self._wallMgr = city.safeAreaWallMgr
end

function CityRepairSafeAreaBlock:GetCity()
    return self._city
end

function CityRepairSafeAreaBlock:Contains(x, y)
    if not self._wallMgr:IsSafeAreaWall(x, y) then
        return false
    end
    local xStart,xEnd = x -1,x +1
    local yStart,yEnd = y -1,y +1
    
    for i = xStart, xEnd do
        for j = yStart, yEnd do
            if self._wallMgr:IsSafeAreaWall(i , j) then
                if self._wallMgr:GetWallId(i , j) == self._wallId then
                    return true
                end
            end
        end
    end
    return false
end

return CityRepairSafeAreaBlock