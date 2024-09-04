---@class CitySlgLifeBarUnit
---@field new fun():CitySlgLifeBarUnit
local CitySlgLifeBarUnit = sealedClass("CitySlgLifeBarUnit")

---@param manager CitySlgLifeBarManager
function CitySlgLifeBarUnit:ctor(manager, x, y, cur, max, active)
    self.manager = manager
    self.id = manager:NextId()
    self.x = x
    self.y = y
    self.cur = cur or 0
    self.max = max or 0
    self.active = active or false
end

function CitySlgLifeBarUnit:SetActive(flag)
    self.active = flag
    self.manager:MarkDirty(self)
end

function CitySlgLifeBarUnit:UpdateCur(hp)
    self.cur = hp
    self.manager:MarkDirty(self)
end

return CitySlgLifeBarUnit