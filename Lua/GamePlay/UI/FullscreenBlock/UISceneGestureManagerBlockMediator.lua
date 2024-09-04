--- scene:scene_scene_gesture_block

local BaseUIMediator = require("BaseUIMediator")

---@class UISceneGestureManagerBlockMediator:BaseUIMediator
---@field new fun():UISceneGestureManagerBlockMediator
---@field super BaseUIMediator
local UISceneGestureManagerBlockMediator = class('UISceneGestureManagerBlockMediator', BaseUIMediator)

return UISceneGestureManagerBlockMediator