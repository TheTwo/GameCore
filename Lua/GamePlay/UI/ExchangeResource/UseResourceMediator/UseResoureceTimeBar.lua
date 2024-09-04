local BaseUIComponent = require ('BaseUIComponent')
local TimeFormatter = require('TimeFormatter')
local Delegate = require('Delegate')

---@class UseResoureceTimeBar:BaseUIComponent
local UseResoureceTimeBar = class('UseResoureceTimeBar', BaseUIComponent)

function UseResoureceTimeBar:OnCreate()
    self._p_progress = self:Slider("p_progress")
    self._p_btn_base = self:Button("p_btn_base", Delegate.GetOrCreate(self, self.OnClick))
    self._p_text_time = self:Text("p_text_time")
end

---@param data {current:number, target:number}
function UseResoureceTimeBar:OnFeedData(data)
    self._p_progress.value = math.clamp01(data.current / data.target)
    self._p_text_time.text = TimeFormatter.SimpleFormatTime(math.max(0, data.target - data.current))
end

return UseResoureceTimeBar