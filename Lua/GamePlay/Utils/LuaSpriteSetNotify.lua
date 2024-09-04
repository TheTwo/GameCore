---@class LuaSpriteSetNotify
local LuaSpriteSetNotify = sealedClass('LuaSpriteSetNotify')

function LuaSpriteSetNotify:ctor()
    ---@type fun(isSuccess:boolean,spriteName:string)
    self._callback = nil
end

---@param isSuccess boolean
---@param spriteName string
function LuaSpriteSetNotify:OnSpriteManagerSetSprite(isSuccess,spriteName)
    if self._callback then
        self._callback(isSuccess, spriteName)
    end
end

return LuaSpriteSetNotify