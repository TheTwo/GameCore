local BaseTableViewProCell = require("BaseTableViewProCell")
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

local PetStoryComp = class('PetStoryComp', BaseTableViewProCell)

function PetStoryComp:OnCreate()
    self.p_text_info = self:Text('p_text_info')
    self.p_text_lock = self:Text('p_text_lock')
end

function PetStoryComp:OnShow()
end

function PetStoryComp:OnHide()
end

function PetStoryComp:OnFeedData(param)
    self.param = param
    if self.param.unlock then
        self.p_text_info.text = I18N.Get(ConfigRefer.PetStoryItem:Find(self.param.storyId):Content())
        self.p_text_lock:SetVisible(false)
        self.p_text_info:SetVisible(true)
    else
        self.p_text_lock.text = I18N.GetWithParams("petguide_report_unlock_tip", self.param.level)
        self.p_text_lock:SetVisible(true)
        self.p_text_info:SetVisible(false)
    end
end

return PetStoryComp
