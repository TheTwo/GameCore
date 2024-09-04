local ConfigRefer = require("ConfigRefer")
local BubbleUsage = require("BubbleUsage")
local CityCitizenBubbleHandle = require("CityCitizenBubbleHandle")
local Utils = require("Utils")

---@class CityCitizenBubbleManager
---@field new fun():CityCitizenBubbleManager
local CityCitizenBubbleManager = sealedClass('CityCitizenBubbleManager')

function CityCitizenBubbleManager:ctor()
    self._eventsAdd = false
    self._bubbleCount = 0
    ---@type City|MyCity
    self._city = nil
    ---@type table<CityCitizenBubbleHandle, CityCitizenBubbleHandle>
    self._idleBubbles = {}
    ---@type table<CityCitizenBubbleHandle, CityCitizenBubbleHandle>
    self._inScreenIdleBubbles = {}
    ---@type table<CityCitizenBubbleHandle, CityCitizenBubbleHandle>
    self._notInScreenIdleBubbles = {}
    ---@type table<CityCitizenBubbleHandle, CityCitizenBubbleHandle>
    self._gotoBubbles = {}
    ---@type BubbleConfigCell[]
    self._idleBubbleGroup = {}
    ---@type BubbleConfigCell
    self._gotoBubbleGroup = {}
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self._goCreator = nil
    self._inScreenIdleLimitCount = nil
    self._bubbleInScreenDirty = false
end

---@param city City|MyCity
function CityCitizenBubbleManager:Init(city)
    self._city = city
    self._goCreator = city.createHelper
    table.clear(self._idleBubbleGroup)
    table.clear(self._gotoBubbleGroup)
    for _, v in ConfigRefer.Bubble:pairs() do
        if v:Usage() == BubbleUsage.CitizenIdle then
            table.insert(self._idleBubbleGroup, v)
        elseif v:Usage() == BubbleUsage.CitizenGoTo then
            table.insert(self._gotoBubbleGroup, v)
        end
    end
    local limit = ConfigRefer.CityConfig:CitizenMaxIdleBubbleCountInScreen()
    self._inScreenIdleLimitCount = limit >= 0 and limit or nil
end

function CityCitizenBubbleManager:Release()
    self._city = nil
    self._goCreator = nil
    table.clear(self._idleBubbleGroup)
    table.clear(self._gotoBubbleGroup)
end

function CityCitizenBubbleManager:Initialized()
    return self._city ~= nil
end

---@param type number @0-idle,1-goto,2-other
---@return CityCitizenBubbleHandle|nil,BubbleConfigCell|nil
function CityCitizenBubbleManager:QueryBubble(type)
    if not self._city:IsMyCity() then
        return nil
    end
    ---@type CityCitizenBubbleHandle
    local ret
    local config
    local group
    local outScreen
    if type == 0 then
        local count = #self._idleBubbleGroup
        if count <= 0 then
            return nil
        end
        config = self._idleBubbleGroup[math.random(1, count)]
        group = self._idleBubbles
        outScreen = self._notInScreenIdleBubbles
    elseif type == 1 then
        local count = #self._gotoBubbleGroup
        if count <= 0 then
            return nil
        end
        config = self._gotoBubbleGroup[math.random(1, count)]
        group = self._gotoBubbles
    end
    ret = CityCitizenBubbleHandle.new()
    if group then
        group[ret] = ret
        if outScreen then
            self._bubbleInScreenDirty = true
            outScreen[ret] = ret
        end
    end
    ret:Init(self)
    return ret,config
end

---@param bubble CityCitizenBubbleHandle
function CityCitizenBubbleManager:ReleaseBubble(bubble)
    if not bubble then return end
    bubble:SetActive(false)
    self._gotoBubbles[bubble] = nil
    self._idleBubbles[bubble] = nil
    self._notInScreenIdleBubbles[bubble] = nil
    self._inScreenIdleBubbles[bubble] = nil
    bubble:Release()
end

function CityCitizenBubbleManager:Tick(dt)
    if not self._bubbleInScreenDirty then
        return
    end
    self._bubbleInScreenDirty = false
    self:UpdateCamera(self._city.camera)
end

---@param basicCamera BasicCamera
function CityCitizenBubbleManager:UpdateCamera(basicCamera)
    self._bubbleInScreenDirty = false
    if not self._city:IsMyCity() then
        return nil
    end
    local camera = basicCamera.mainCamera
    local projection = CS.Grid.CameraUtils.CalculateFrustumProjectionOnPlane(camera, camera.nearClipPlane,
            camera.farClipPlane, basicCamera:GetBasePlane());
    local cameraBox = CS.Grid.CameraUtils.CalculateFrustumProjectionAABB(projection);
    local min, max = cameraBox.min, cameraBox.max
    local needRemove = {}
    local inScreenCounter = 0
    for i, v in pairs(self._inScreenIdleBubbles) do
        if Utils.IsNotNull(v._attachTrans) then
            local p = v._attachTrans.position
            if (p.x > max.x or p.z > max.z or p.x < min.x or p.z < min.z) or (self._inScreenIdleLimitCount and inScreenCounter >= self._inScreenIdleLimitCount) then
                self._inScreenIdleBubbles[i] = nil
                needRemove[i] = v
                v:SetActive(false)
            else
                inScreenCounter = inScreenCounter + 1
            end
        else
            self._inScreenIdleBubbles[i] = nil
            needRemove[i] = v
            v:SetActive(false)
        end
    end
    for i, v in pairs(self._notInScreenIdleBubbles) do
        if Utils.IsNotNull(v._attachTrans) then
            local p = v._attachTrans.position
            if p.x <= max.x and p.z <= max.z and p.x >= min.x and p.z >= min.z and (not self._inScreenIdleLimitCount or inScreenCounter < self._inScreenIdleLimitCount) then
                self._notInScreenIdleBubbles[i] = nil
                self._inScreenIdleBubbles[i] = v
                v:SetActive(true)
            end
        end
    end
    for i, v in pairs(needRemove) do
        self._notInScreenIdleBubbles[i] = v
    end
end

return CityCitizenBubbleManager