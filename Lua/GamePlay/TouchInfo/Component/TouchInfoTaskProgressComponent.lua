local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require("Delegate")

---@class TouchInfoTaskProgressComponent:BaseUIComponent
local TouchInfoTaskProgressComponent = class('TouchInfoTaskProgressComponent', BaseUIComponent)

---@class TouchInfoTaskProgressCompData
---@field title string
---@field progress number|fun():number
---@field progressText string|fun():string
---@field needTick boolean|nil

function TouchInfoTaskProgressComponent:OnCreate()
    self._p_text_title_area = self:Text("p_text_title_area")
    self._p_progress_area = self:Slider("p_progress_area")
    self._p_text_progress = self:Text("p_text_progress")
end

---@param data TouchInfoTaskProgressCompData
function TouchInfoTaskProgressComponent:OnFeedData(data)
    self._p_text_title_area.text = data.title
    if type(data.progress) == "number" then
        self._p_progress_area.value = math.clamp01(data.progress)
    elseif type(data.progress) == "function" then
        self._p_progress_area.value = math.clamp01(data.progress())
    end

    if type(data.progressText) == "string" then
        self._p_text_progress.text = data.progressText
    elseif type(data.progressText) == "function" then
        self._p_text_progress.text = data.progressText()
    end

    if data.needTick then
        self.valueFunc = data.progress
        self.textFunc = data.progressText
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
    end
end

function TouchInfoTaskProgressComponent:OnClose()
    if self.valueFunc or self.textFunc then
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
        self.valueFunc = nil
        self.textFunc = nil
    end
end

function TouchInfoTaskProgressComponent:OnTick()
    if type(self.valueFunc) == "function" then
        self._p_progress_area.value = math.clamp01(self.valueFunc())
    end
    if type(self.textFunc) == "function" then
        self._p_text_progress.text = self.textFunc()
    end
end

return TouchInfoTaskProgressComponent