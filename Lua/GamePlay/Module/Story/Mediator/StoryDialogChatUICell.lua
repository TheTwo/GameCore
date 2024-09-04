local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class StoryDialogChatUICellParameter
---@field heroImage string
---@field heroName string
---@field content string

---@class StoryDialogChatUICell:BaseUIComponent
---@field new fun():StoryDialogChatUICell
---@field super BaseUIComponent
local StoryDialogChatUICell = class('StoryDialogChatUICell', BaseUIComponent)

function StoryDialogChatUICell:OnCreate(param)
    self._p_img_hero_1 = self:Image("p_img_hero_1")
    self._p_text_name_1 = self:Text("p_text_name_1")
    self._p_text_content_1 = self:Text("p_text_content_1")
    ---@type CS.Empty4Raycast
    self._p_self_click = self:BindComponent("", typeof(CS.Empty4Raycast))
    self:PointerClick("", Delegate.GetOrCreate(self, self.OnClickCell))
end

function StoryDialogChatUICell:SetOnClick(callback)
    self._onClickCallback = callback
end

function StoryDialogChatUICell:OnClickCell()
    if self._onClickCallback then
        self._onClickCallback()
    end
end

return StoryDialogChatUICell

