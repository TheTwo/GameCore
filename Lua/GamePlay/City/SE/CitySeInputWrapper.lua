
---@class CitySeInputWrapper:SEInputManagerInputWrapper
---@param new fun(city:City):CitySeInputWrapper
---@field mousePosition CS.UnityEngine.Vector3
---@field GetMouseButton fun(button:number):boolean
---@field GetMouseButtonDown fun(button:number):boolean
---@field GetMouseButtonUp fun(button:number):boolean
local CitySeInputWrapper = sealedClass("CitySeInputWrapper")

---@param city City
function CitySeInputWrapper:ctor(city)
    ---@type City
    self.city = city
    self.mousePosition = nil
    self.GetMouseButton = function(button)
        if not self.city.seMediator.gestureEnable then return end
        if g_Game.GestureManager:IsFingerOverUI(button) then
            return
        end
        return CS.UnityEngine.Input.GetMouseButton(button)
    end
    self.GetMouseButtonDown = function(button)
        if not self.city.seMediator.gestureEnable then return end
        if g_Game.GestureManager:IsFingerOverUI(button) then
            return
        end
        return CS.UnityEngine.Input.GetMouseButtonDown(button)
    end
    self.GetMouseButtonUp = function(button)
        if not self.city.seMediator.gestureEnable then return end
        if g_Game.GestureManager:IsFingerOverUI(button) then
            return
        end
        return CS.UnityEngine.Input.GetMouseButtonUp(button)
    end
end

function CitySeInputWrapper:Tick(dt)
    self.mousePosition = CS.UnityEngine.Input.mousePosition
end

return CitySeInputWrapper