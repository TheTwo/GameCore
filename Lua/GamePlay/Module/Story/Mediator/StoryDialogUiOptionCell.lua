local Delegate = require("Delegate")
local StoryDialogUiOptionCellType = require("StoryDialogUiOptionCellType")
local Utils = require("Utils")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class StoryDialogUiOptionCellData
---@field index number
---@field type StoryDialogUiOptionCellType.enum
---@field requireNum number
---@field nowNum number
---@field showNumberPair boolean
---@field content string
---@field showIsOnGoing boolean
---@field onClick fun(index:number, lockable:CS.UnityEngine.Transform)
---@field showCreep boolean

---@class StoryDialogUiOptionCell:BaseTableViewProCell
---@field new fun():StoryDialogUiOptionCell
---@field super BaseTableViewProCell
local StoryDialogUiOptionCell = class('StoryDialogUiOptionCell', BaseTableViewProCell)

function StoryDialogUiOptionCell:OnCreate(param)
    self._selfBtn = self:Button("p_btn_op", Delegate.GetOrCreate(self, self.OnClickSelfBtn))
    self._p_text_task = self:Text("p_text_task")
    -- self._p_icon_type = self:Image("p_icon_type")
    self._p_icon_finish = self:GameObject("p_icon_finish")
    self._p_icon_finish:SetVisible(false)
    self._p_icon_creep = self:Image("p_icon_creep")
    self._p_vote_effect = self:GameObject("vfx_effect_zan")
    if Utils.IsNotNull(self._p_icon_creep) then
        self._p_icon_creep:SetVisible(false)
    end
end

---@param data StoryDialogUiOptionCellData
function StoryDialogUiOptionCell:OnFeedData(data)
    self._data = data
    if data.showNumberPair then
        self._p_text_task.text = data.content .. string.format("(%d/%d)", data.nowNum, data.requireNum)
    else
        self._p_text_task.text = data.content
    end
    if Utils.IsNotNull(self._p_icon_creep) then
        self._p_icon_creep:SetVisible(data.showCreep)
    end
    -- local icon = StoryDialogUiOptionCellType.typeIcon[data.type]
    -- if string.IsNullOrEmpty(icon) then
    --     self._p_icon_type:SetVisible(false)
    -- else
    --     self._p_icon_type:SetVisible(true)
    --     g_Game.SpriteManager:LoadSprite(icon, self._p_icon_type)
    -- end
end

function StoryDialogUiOptionCell:OnClickSelfBtn()
    if self._data.type == StoryDialogUiOptionCellType.enum.Vote then
        self._p_vote_effect:SetVisible(true)
    end
    if self._data.onClick then
        self._data.onClick(self._data.index, self._selfBtn.transform)
    end
end

return StoryDialogUiOptionCell

