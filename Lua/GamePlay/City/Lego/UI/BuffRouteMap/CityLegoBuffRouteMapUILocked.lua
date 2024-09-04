local BaseUIComponent = require ('BaseUIComponent')

---@class CityLegoBuffRouteMapUILocked:BaseUIComponent
local CityLegoBuffRouteMapUILocked = class('CityLegoBuffRouteMapUILocked', BaseUIComponent)

function CityLegoBuffRouteMapUILocked:OnCreate()
    self._p_text_lvl_lock = self:Text("p_text_lvl_lock")
    self._p_text_hint_lock = self:Text("p_text_hint_lock", "roombuff_unlock")
end

---@param data {roomLvCfg:RoomLevelInfoConfigCell}
function CityLegoBuffRouteMapUILocked:OnFeedData(data)
    self._p_text_lvl_lock.text = data.roomLvCfg:Level()
end

return CityLegoBuffRouteMapUILocked