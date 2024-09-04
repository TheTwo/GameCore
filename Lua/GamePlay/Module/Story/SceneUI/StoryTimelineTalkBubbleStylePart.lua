local Utils = require("Utils")

---@class StoryTimelineTalkBubbleStylePart
---@field root CS.UnityEngine.GameObject
---@field text CS.U2DTextMesh
---@field name CS.U2DTextMesh
---@field bg CS.U2DSpriteMesh
---@field clickCollider CS.UnityEngine.BoxCollider
---@field trigger CS.DragonReborn.LuaBehaviour
local StoryTimelineTalkBubbleStylePart = class('StoryTimelineTalkBubbleStylePart')

function StoryTimelineTalkBubbleStylePart:SetVisible(visible)
    self.root:SetVisible(visible)
end

function StoryTimelineTalkBubbleStylePart:SetNameAndContent(name, content)
    if Utils.IsNotNull(self.name) then
        self.name.text = name
    end
    if Utils.IsNotNull(self.text) then
        self.text.text = content
    end
end

function StoryTimelineTalkBubbleStylePart:UpdateLayout()
    if Utils.IsNull(self.bg) or Utils.IsNull(self.clickCollider) then
        return
    end
    if self.root.activeInHierarchy then
        local w = self.bg.width
        local h = self.bg.height
        self.clickCollider.center = CS.UnityEngine.Vector3(0, 0.5 * h, 0)
        self.clickCollider.size = CS.UnityEngine.Vector3(w, h, 0)
    end
end

return StoryTimelineTalkBubbleStylePart