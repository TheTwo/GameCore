local BaseTableViewProCell = require("BaseTableViewProCell")
local TimerUtility = require('TimerUtility')
local I18N = require("I18N")

local ChapterQuestNullItem = class("ChapterQuestNullItem", BaseTableViewProCell)

function ChapterQuestNullItem:OnCreate()
    self.textTaskNull = self:Text('p_text_task_null')
    self.animation = self:BindComponent("p_cell_group", typeof(CS.UnityEngine.Animation))
end

function ChapterQuestNullItem:OnFeedData(data)
	self.textTaskNull.text = data.isMain and I18N.Get("chapter_main_none") or I18N.Get("chapter_sub_none")
end

function ChapterQuestNullItem:PlayShowAnim()
    self.animation:Play("anim_vx_ui_mission_item_slot_null_in")
end

function ChapterQuestNullItem:PlayInitAnim()
    self.animation:Play("anim_vx_ui_mission_item_slot_null_null")
end


return ChapterQuestNullItem