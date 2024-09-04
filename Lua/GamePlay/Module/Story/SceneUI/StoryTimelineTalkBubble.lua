local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

--- prefab:ui3d_bubble_timeline_npc_talk
---@class StoryTimelineTalkBubble
---@field root CS.UnityEngine.GameObject
---@field StyleWithName CS.DragonReborn.LuaBehaviour
---@field StyleWithoutName CS.DragonReborn.LuaBehaviour
---@field facingCamera CS.U2DFacingCamera
---@field ExtraStyles table @List<CS.DragonReborn.LuaBehaviour>
local StoryTimelineTalkBubble = class('StoryTimelineTalkBubble')

function StoryTimelineTalkBubble:Awake()
    self._colliderDirty = 0
    ---@type StoryTimelineTalkBubbleStylePart
    self._withName = self.StyleWithName.Instance
    ---@type StoryTimelineTalkBubbleStylePart
    self._withoutName = self.StyleWithoutName.Instance
    ---@type StoryTimelineTalkBubbleStylePart[]
    self._extraStyles = {}
    for i = 0, self.ExtraStyles.Count - 1 do
        self._extraStyles[i + 1] = self.ExtraStyles[i].Instance
    end
    ---@type StoryTimelineTalkBubbleStylePart
    self._currentPart = nil
end

function StoryTimelineTalkBubble:SetContent(bubbleId, camera)
    self._currentPart = nil
    local bubble = ConfigRefer.Bubble:Find(bubbleId)
    local name = bubble.SrcName and I18N.Get(bubble:SrcName()) or ''
    local style = bubble:TimelineBubbleStyle()
    if style == 0 then
        if string.IsNullOrEmpty(name) then
            self._withName:SetVisible(false)
            self._withoutName:SetVisible(true)
            for _, v in ipairs(self._extraStyles) do
                v:SetVisible(false)
            end
            self._currentPart = self._withoutName
        else
            self._withName:SetVisible(true)
            self._withoutName:SetVisible(false)
            for _, v in ipairs(self._extraStyles) do
                v:SetVisible(false)
            end
            self._currentPart = self._withName
        end
    else
        self._withName:SetVisible(false)
        self._withoutName:SetVisible(false)
        for i, v in ipairs(self._extraStyles) do
            if i == style then
                v:SetVisible(true)
                self._currentPart = v
            else
                v:SetVisible(false)
            end
        end
    end
    if self._currentPart then
        self._currentPart:SetNameAndContent(name, I18N.Get(bubble:Content()))
    end
    self._colliderDirty = 2
    self.facingCamera.FacingCamera = camera
end

function StoryTimelineTalkBubble:Update()
    if self._colliderDirty <= 0 then
        return
    end
    if not self._currentPart then
        return
    end
    self._colliderDirty = self._colliderDirty - 1
    self._currentPart:UpdateLayout()
end

return StoryTimelineTalkBubble