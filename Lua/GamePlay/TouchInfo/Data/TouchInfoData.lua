---@class TouchInfoData
---@field new fun(btns:TouchInfoCompDatum[],position:CS.UnityEngine.Vector3,...:TouchInfoWindowData):TouchInfoData
local TouchInfoData = class('TouchInfoData')

---@param btns TouchInfoButtonCompDatum[]
---@param position CS.UnityEngine.Vector3
---@param closeCallback fun()
---@param onCityGestureClose boolean
---@param windowToggleData TouchInfoWindowToggleData
---@vararg TouchInfoWindowData
function TouchInfoData:ctor(btns, position, closeCallback, onCityGestureClose, windowToggleData, ...)
    self.btns = btns
    self.position = position
    self.closeCallback = closeCallback
    self.onCityGestureClose = onCityGestureClose
    self.windowToggleData = windowToggleData
    self.windowData = {...}
end

return TouchInfoData