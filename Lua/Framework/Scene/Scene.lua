---@class Scene
local Scene = class('Scene')

---@return string
function Scene:GetName()
    if self.__class ~= nil then
        return self.__class.__cname
    end

    if self.__cname ~= nil then
        return self.__cname;
    end
    
    return ""
end

---@param param any
function Scene:EnterScene(param)

end

---@param param any
function Scene:ExitScene(param)

end

function Scene:Tick(dt)
    
end

function Scene:Release()
    
end

---@return boolean
function Scene:GetVisible()
    return false
end

---@param value boolean
function Scene:SetVisible(value)

end

function Scene:IsLoaded()
    return false
end

function Scene:CanLightRestart()
    return false
end

function Scene:OnLightRestartBegin()
    ---override this
end

function Scene:OnLightRestartEnd()
    ---override this
end

function Scene:OnLightRestartFailed()
    ---override this
end

return Scene