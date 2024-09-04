---@class BaseModule
---@field new fun():BaseModule
local BaseModule = class("BaseModule")

function BaseModule:ctor()
    
end

function BaseModule:OnRegister()
    -- 重载此函数
end

function BaseModule:OnRemove()
    -- 重载此函数
end

return BaseModule