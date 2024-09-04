--- scene:scene_child_condition

local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class CommonConditionComponentParameter
---@field title string
---@field condition string
---@field icon string
---@field iconSubscript number @ nil,1,2
---@field context any
---@field onClickGoTo fun(context:any)
---@field isMeetCondition boolean

---@class CommonConditionComponent:BaseUIComponent
---@field new fun():CommonConditionComponent
---@field super BaseUIComponent
local CommonConditionComponent = class('CommonConditionComponent', BaseUIComponent)

function CommonConditionComponent:ctor()
    BaseUIComponent.ctor(self)
    self._context = nil
    ---@type fun(context:any)
    self._onclickGo = nil
end

function CommonConditionComponent:OnCreate(param)
    self._p_icon_condition = self:Image("p_icon_condition")
    self._p_type_b = self:GameObject("p_type_b")
    self._p_type_c = self:GameObject("p_type_c")
    self._p_text_title_condition = self:Text("p_text_title_condition")
    self._p_text_condition = self:Text("p_text_condition")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickBtnGoto))
    self._p_reach = self:GameObject("p_reach")
end

---@param data CommonConditionComponentParameter
function CommonConditionComponent:OnFeedData(data)
    self._context = data.context
    self._onclickGo = data.onClickGoTo
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_condition)
    self._p_type_b:SetVisible(data.iconSubscript == 1)
    self._p_type_c:SetVisible(data.iconSubscript == 2)
    self._p_text_title_condition.text = data.title
    self._p_text_condition.text = data.condition
    if data.isMeetCondition then
        self._p_reach:SetVisible(true)
        self._p_btn_goto:SetVisible(false)
    else
        self._p_reach:SetVisible(false)
        self._p_btn_goto:SetVisible(self._onclickGo ~= nil)
    end
end

function CommonConditionComponent:OnClickBtnGoto()
    if self._onclickGo then
        self._onclickGo(self._context)
    end
end

return CommonConditionComponent