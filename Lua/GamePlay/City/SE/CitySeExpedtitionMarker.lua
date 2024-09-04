
---@class CitySeExpedtitionMarker:IMarker
---@field new fun(mgr:CitySeManager):CitySeExpedtitionMarker
local CitySeExpedtitionMarker = class("CitySeExpedtitionMarker")

---@param mgr CitySeManager
function CitySeExpedtitionMarker:ctor(mgr)
    self.mgr = mgr
    self.needShow = false
    self.needShowImpl = false
    self.img = "sp_hud_icon_hint_explore"
    self.worldPosition = nil
    self.camera = nil
    self.targetViewPos = nil
    ---@type number[]
    self.elementIdStack = {}
    self.zoneId = 0
end

function CitySeExpedtitionMarker:Setup(zoneId)
    self.camera = self.mgr.city:GetCamera()
    self.zoneId = zoneId
end

function CitySeExpedtitionMarker:FilterCurrentStack(requireZoneId)
    self.zoneId = requireZoneId
    if #self.elementIdStack <= 0 then return end
    local tempStack = {}
    table.addrange(tempStack, self.elementIdStack)
    self.worldPosition = nil
    self.targetViewPos = nil
    self.distance = 0
    table.clear(self.elementIdStack)
    for i = 1, #tempStack do
        self:PushElementId(tempStack[i])
    end
end

function CitySeExpedtitionMarker:SetNeedShow(value)
    self.needShow = value
end

function CitySeExpedtitionMarker:PushElementId(elementId)
    for i = #self.elementIdStack, 1, -1 do
        if self.elementIdStack[i] == elementId then
            return false
        end
    end
    local eleMgr = self.mgr.city.elementManager
    ---@type CityElementSpawner|CityElementNpc
    local ele = eleMgr:GetElementById(elementId)
    if not ele then
        return false
    end
    local zone = self.mgr.city.zoneManager:GetZone(ele.x, ele.y)
    if not zone or zone.id ~= self.zoneId then return false end
    if ele:IsNpc() then
        self.targetViewPos = nil
        self.distance = 0
        table.insert(self.elementIdStack, 1, elementId)
        self.worldPosition = ele:GetWorldPosition()
    elseif ele:IsSpawner() then
        table.insert(self.elementIdStack, elementId)
        if #self.elementIdStack == 1 then
            self.targetViewPos = nil
            self.distance = 0
            self.worldPosition = ele:GetWorldPosition()
        end
    else
        return false
    end
    return true
end

function CitySeExpedtitionMarker:PopElementId(elementId)
    local autoPop = false
    local count = #self.elementIdStack
    for i = count, 1, -1 do
        if self.elementIdStack[i] == elementId then
            table.remove(self.elementIdStack, i)
            if i == 1 then
                autoPop = true
            end
            break
        end
    end
    if not autoPop then return end
    self.worldPosition = nil
    self.targetViewPos = nil
    self.distance = 0
    if #self.elementIdStack <= 0 then
        return
    end
    local tmp = {}
    table.addrange(tmp, self.elementIdStack)
    table.clear(self.elementIdStack)
    while #tmp > 0 do
        local eleId = table.remove(tmp, 1)
        self:PushElementId(eleId)
    end
end

function CitySeExpedtitionMarker:ClearStack()
    self.worldPosition = nil
    self.targetViewPos = nil
    self.distance = 0
    table.clear(self.elementIdStack)
end

function CitySeExpedtitionMarker:IsTroop()
    return false
end

function CitySeExpedtitionMarker:GetHeroInfoData()
    return nil
end

function CitySeExpedtitionMarker:GetImage()
    return self.img
end

function CitySeExpedtitionMarker:DoUpdate()
    self.targetViewPos = self:GetViewportPositionImpl()
    self.needShowImpl = self:NeedShowImp()
    self.distance = 0
    if not self.needShowImpl then return end
    local lookAt = self.camera:GetLookAtPlanePosition()
    local lookAtX, lookAtZ = lookAt.x, lookAt.z
    local x, z = self.worldPosition.x, self.worldPosition.z
    self.distance = math.sqrt((lookAtX - x) ^ 2 + (lookAtZ - z) ^ 2)
end

function CitySeExpedtitionMarker:GetViewportPositionImpl()
    if not self.worldPosition then return nil end
    return self.camera.mainCamera:WorldToViewportPoint(self.worldPosition)
end

function CitySeExpedtitionMarker:GetViewportPosition()
    return self.targetViewPos or CS.UnityEngine.Vector3(0.5, 0.5, 0)
end

function CitySeExpedtitionMarker:NeedShowImp()
    if self.targetViewPos then
        local x, y = self.targetViewPos.x, self.targetViewPos.y
        return x < 0 or x > 1 or y < 0 or y > 1
    end
    return false
end

function CitySeExpedtitionMarker:NeedShow()
    if not self.needShowImpl then 
        return false
    end
    if not self.targetViewPos then
        return false
    end
    return self.needShow
end

function CitySeExpedtitionMarker:GetCamera()
    return self.camera
end

function CitySeExpedtitionMarker:GetDistance()
    return self.distance
end

function CitySeExpedtitionMarker:OnClick()
end

return CitySeExpedtitionMarker