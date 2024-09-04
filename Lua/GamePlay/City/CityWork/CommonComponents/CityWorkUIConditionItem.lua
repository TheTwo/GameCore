local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIHelper = require("UIHelper")
local ColorConsts = require("ColorConsts")
local ColorUtil = require("ColorUtil")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")

local I18N = require("I18N")

---@class CityWorkUIConditionItem:BaseUIComponent
local CityWorkUIConditionItem = class('CityWorkUIConditionItem', BaseUIComponent)

function CityWorkUIConditionItem:OnCreate()
    self._p_base_1 = self:Image("p_base_1")
    self._p_icon_n = self:Image("p_icon_n")
    self._p_text_conditions = self:Text("p_text_conditions")
    self._p_icon_finish = self:GameObject("p_icon_finish")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoto))
    self._p_text = self:Text("p_text", "goto")
end

---@param data {cfg:TaskConfigCell}
function CityWorkUIConditionItem:OnFeedData(data)
    self.data = data
    self.taskCfg = data.cfg
    local status = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.taskCfg:Id())
    self.finished = status == wds.TaskState.TaskStateFinished or status == wds.TaskState.TaskStateCanFinish
    if self._p_base_1 ~= nil then
        if self.finished then
            self._p_base_1.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey .. "26")
        else
            self._p_base_1.color = UIHelper.TryParseHtmlString(ColorConsts.army_red .. "3A")
        end
    end

    self.gotoId = self.taskCfg:Property():Goto()
    self._p_icon_finish:SetActive(self.finished)
    self._p_btn_goto:SetVisible(not self.finished and self.gotoId > 0)
    local taskNameKey,taskNameParam = ModuleRefer.QuestModule:GetTaskName(self.taskCfg)
	local content = I18N.GetWithParamList(taskNameKey,taskNameParam)
    if string.IsNullOrEmpty(content) and (UNITY_EDITOR or UNITY_DEBUG) then
        content = "#[DebugOnly]看到这说明产品没有配条件的任务名"
    end
    if self.finished then
        self._p_text_conditions.text = content
    else
        self._p_text_conditions.text = ("<color=%s><b>%s</b></color>"):format(ColorUtil.FromGammaStrToLinearStr(ColorConsts.warning), content)
    end
end

function CityWorkUIConditionItem:OnClickGoto()
    if self.gotoId > 0 then
        ModuleRefer.GuideModule:CallGuide(self.gotoId)
    end
end

return CityWorkUIConditionItem