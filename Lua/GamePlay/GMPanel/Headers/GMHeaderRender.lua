local ShadowDistanceControl = require("ShadowDistanceControl")

local GMHeader = require("GMHeader")

---@class GMHeaderRender:GMHeader
local GMHeaderRender = class('GMHeaderRender', GMHeader)

function GMHeaderRender:ctor()
    GMHeader.ctor(self)

    self._renderTime = 0
    self._shadowDis = 0
    self._shadowNum = 0
    self._shadowSplit = 0
end

function GMHeaderRender:DoText()
    return string.format("Render:%0.3fms, Shadow:Dis:%0.1fm Num:%d Split:%0.2f", self._renderTime * 1000,self._shadowDis, self._shadowNum, self._shadowSplit)
end

function GMHeaderRender:Tick()
    self._renderTime = g_Game.debugSupport.LastFrameRenderingTime
    self._shadowDis,self._shadowNum,self._shadowSplit = ShadowDistanceControl.GetParam()
end

return GMHeaderRender