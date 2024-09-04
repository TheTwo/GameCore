local Delegate = require("Delegate")
local BaseUIMediator = require("BaseUIMediator")
local I18N = require("I18N")

---@class StoryDialogSkipPopupUIMediator:BaseUIMediator
---@field new fun():StoryDialogSkipPopupUIMediator
---@field super BaseUIMediator
local StoryDialogSkipPopupUIMediator = class('StoryDialogSkipPopupUIMediator', BaseUIMediator)

---@class StoryDialogSkipPopupUIMediatorParameter
---@field new fun():StoryDialogSkipPopupUIMediator
---@field content string[]
---@field callback fun(isSkip:boolean)

function StoryDialogSkipPopupUIMediator:OnCreate(param)
    self:PointerClick("p_base_mask", Delegate.GetOrCreate(self, self.OnCancel))
    self._lb_title = self:Text("p_text_title")
    self._lb_content = self:Text("p_text_content")
    self._btn_skip = self:Button("p_btn_skip", Delegate.GetOrCreate(self, self.OnSkip))
    self._lb_skip = self:Text("p_text_skip", "Story_SkipUI_Disc")
    self._p_text_continue = self:Text("p_text_continue", "bw_tips_newcircle_2")
end

-----@param param StoryDialogSkipPopupUIMediatorParameter
function StoryDialogSkipPopupUIMediator:OnOpened(param)
    self._param = param
    local str = ""
    if param.content then
        for _, v in ipairs(param.content) do
            str = str .. I18N.Get(v)
        end
    end
    self._lb_content.text = str
end

function StoryDialogSkipPopupUIMediator:OnSkip()
    self:CloseSelf()
    if self._param and self._param.callback then
        self._param.callback(true)
    end
end

function StoryDialogSkipPopupUIMediator:OnCancel()
    self:CloseSelf()
    if self._param and self._param.callback then
        self._param.callback(false)
    end
end

return StoryDialogSkipPopupUIMediator