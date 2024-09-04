local ArtResourceUtils = require("ArtResourceUtils")
local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class CityCitizenResidentFeedbackLeftPortrait:BaseUIComponent
---@field new fun():CityCitizenResidentFeedbackLeftPortrait
---@field super BaseUIComponent
local CityCitizenResidentFeedbackLeftPortrait = class('CityCitizenResidentFeedbackLeftPortrait', BaseUIComponent)

function CityCitizenResidentFeedbackLeftPortrait:ctor()
    BaseUIComponent.ctor(self)
    self._isPlaying = false
    ---@type CitizenConfigCell[]
    self._inQueue = {}
    self._inShowingCount = 0
    self._inShowPosLimit = 4
end

function CityCitizenResidentFeedbackLeftPortrait:OnCreate(param)
    ---@type CS.UnityEngine.Animation
    self._p_animation = self:BindComponent("p_animation", typeof(CS.UnityEngine.Animation))
    ---@type LuaBehaviourAnimationEventReceiver
    self._p_animation_event = self:BindComponent("p_animation", typeof(CS.DragonReborn.LuaBehaviourAnimationEventReceiver)).Instance
    self._p_animation_event:SetEventCallback(Delegate.GetOrCreate(self, self.OnPlayEnd))
    ---@type CS.UnityEngine.UI.Image[]
    self._heroPosArray = {}
    self._iniPosArray = {}
    for i = 1, self._inShowPosLimit do
        local key = string.format("p_hero_%d", i)
        local img = self:Image(key)
        local imgTrans = img.transform
        self._heroPosArray[i] = img
        self._iniPosArray[i] = {
            pos =  imgTrans.localPosition,
            scale = imgTrans.localScale,
            alpha = img.color.a
        }
    end
end

---@param data CitizenConfigCell[]
function CityCitizenResidentFeedbackLeftPortrait:OnFeedData(data)
    table.addrange(self._inQueue, data)
    self:Dequeue()
end

---@param data CitizenConfigCell
function CityCitizenResidentFeedbackLeftPortrait:AppendData(data)
    table.insert(self._inQueue, data)
    if not self._isPlaying then
        self:Dequeue()
    end
end

function CityCitizenResidentFeedbackLeftPortrait:PlayMoving() 
    self._isPlaying = true
    self._p_animation:Play()
end

function CityCitizenResidentFeedbackLeftPortrait:OnPlayEnd()
    self._p_animation:Stop()
    self:RebuildPos()
    self:Dequeue()
    self._isPlaying = false
end

function CityCitizenResidentFeedbackLeftPortrait:ForwardEnd()
    self._p_animation:Stop()
    local clip = self._p_animation.clip
    self._p_animation:SetAnimationTime(clip.name, clip.length)
    self._p_animation:Sample()
    self:OnPlayEnd()
end

function CityCitizenResidentFeedbackLeftPortrait:RebuildPos()
    self._p_animation:SetVisible(false)
    local first = self._heroPosArray[1]
    first:SetVisible(false)
    first.transform:SetAsFirstSibling()
    local count = #self._heroPosArray
    local lastName = self._heroPosArray[count].name
    for i = 1, count do
        local n = self._heroPosArray[i].name
        self._heroPosArray[i].name = lastName
        lastName = n
    end
    table.insert(self._heroPosArray, table.remove(self._heroPosArray, 1))
    self._inShowingCount = self._inShowingCount - 1
    for i = 1, count do
        local status = self._iniPosArray[i]
        local img = self._heroPosArray[i]
        local imgTrans = img.transform
        imgTrans.localPosition = status.pos
        imgTrans.localScale = status.scale
        local c = img.color
        c.a = status.alpha
        img.color = c
    end
    self._p_animation:SetVisible(true)
    local clip = self._p_animation.clip
    self._p_animation:SetAnimationTime(clip.name, 0)
    self._p_animation:Sample()
end

function CityCitizenResidentFeedbackLeftPortrait:Dequeue()
    while self._inShowingCount < self._inShowPosLimit do
        if #self._inQueue <= 0 then
            break
        end
        self._inShowingCount = self._inShowingCount + 1
        ---@type CitizenConfigCell
        local data = table.remove(self._inQueue, 1)
        local cell = self._heroPosArray[self._inShowingCount]
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(data:CharacterImage()), cell)
        cell:SetVisible(true)
    end
    for i = self._inShowingCount + 1, self._inShowPosLimit do
        self._heroPosArray[i]:SetVisible(false)
    end
end

function CityCitizenResidentFeedbackLeftPortrait:IsPlaying()
    return self._isPlaying
end

return CityCitizenResidentFeedbackLeftPortrait

