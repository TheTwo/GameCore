local BaseTableViewProCell = require("BaseTableViewProCell")
local I18N = require("I18N")
local ChapterQuestTypeItem = class("ChapterQuestTypeItem", BaseTableViewProCell)

---@class ChapterQuestTypeItemData
---@field isMain boolean

function ChapterQuestTypeItem:OnCreate()
    self.animation = self:BindComponent("p_cell_group", typeof(CS.UnityEngine.Animation))
    self.goIconMain = self:GameObject('p_icon_main')
    self.goIconBranch = self:GameObject('p_icon_branch')
    self.textType = self:Text('p_text_type')
end

---@param data ChapterQuestTypeItemData
function ChapterQuestTypeItem:OnFeedData(data)
	self.goIconMain:SetActive(data.isMain)
	self.goIconBranch:SetActive(not data.isMain)
	self.textType.text = data.isMain and I18N.Get("task_info_main") or I18N.Get("task_info_side")
end

function ChapterQuestTypeItem:PlayShowAnim()
    self.animation:Play("anim_vx_ui_mission_item_slot_type_in")
end

function ChapterQuestTypeItem:PlayInitAnim()
    self.animation:Play("anim_vx_ui_mission_item_slot_type_null")
end

return ChapterQuestTypeItem