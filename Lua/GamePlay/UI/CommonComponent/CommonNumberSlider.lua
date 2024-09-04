local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local TimerUtility = require('TimerUtility')

---@class CommonNumberSliderData
---@field minNum number @integer
---@field maxNum number @integer
---@field limitNum number @integer
---@field ignoreNum number @integer
---@field oneStepNum number @integer
---@field curNum number @integer
---@field maxBtnNum number @integer
---@field limitEnable bool @boolean
---@field callBack fun(curNum:number) @callback
---@field intervalTime number @float
---@field reachBoundCallback fun(targetValue:number) @callback

---@class CommonNumberSlider:BaseUIComponent
local CommonNumberSlider = class('CommonNumberSlider', BaseUIComponent)


local LONG_PRESS_TIME = 100
function CommonNumberSlider:ctor()

end

function CommonNumberSlider:OnCreate()
    self.sliderSetBar = self:Slider('p_set_bar', Delegate.GetOrCreate(self, self.OnSliderValueChanged))
    self.btnCompMinus = self:Button('p_comp_btn_minus', Delegate.GetOrCreate(self, self.OnBtnCompMinusClicked))
    self.btnCompPlus = self:Button('p_comp_btn_plus', Delegate.GetOrCreate(self, self.OnBtnCompPlusClicked))
    self.btnMax = self:Button("p_comp_btn_max", Delegate.GetOrCreate(self, self.OnBtnCompMaxClicked))
    self:PointerDown('p_comp_btn_minus', Delegate.GetOrCreate(self, self.OnBtnCompMinusDown))
    self:PointerDown('p_comp_btn_plus', Delegate.GetOrCreate(self, self.OnBtnCompPlusDown))
    self:PointerUp('p_comp_btn_minus', Delegate.GetOrCreate(self, self.OnBtnCompMinusUp))
    self:PointerUp('p_comp_btn_plus', Delegate.GetOrCreate(self, self.OnBtnCompPlusUp))
    self.p_text_max = self:Text("p_text_max", "MAX")
end

function CommonNumberSlider:OnClose()
    if self.onPressTimer then
        TimerUtility.StopAndRecycle(self.onPressTimer)
        self.onPressTimer = nil
    end
    self.callBack = nil
end

---@param param CommonNumberSliderData
function CommonNumberSlider:OnFeedData(param)
    if not param then
        return
    end
    self.limitNum = param.limitNum
    self.ignoreNum = param.ignoreNum or 1
    self.minNum = param.minNum or 1
    self.maxNum = param.maxNum or 9999
    self.oneStepNum = param.oneStepNum or 1
    self.limitEnable = param.limitEnable
    self.maxBtnNum = param.maxBtnNum
    self:ChangeCurNum(param.curNum or 1)
    self.callBack = param.callBack
    self.reachBoundCallback = param.reachBoundCallback
    self:IgnoreChangeSliderValue()
    if self.onPressTimer then
        TimerUtility.StopAndRecycle(self.onPressTimer)
    end
    self.isLongPress = false
    self.downTime = nil
    self.isMinusDown = false
    self.isPlusDown = false
    self.onPressTimer = TimerUtility.IntervalRepeat(function() self:LongPressTimer() end, param.intervalTime or 0.1, -1)
end

function CommonNumberSlider:OnBtnCompMinusDown()
    if not self.btnCompMinus.interactable then
        return
    end
    self.downTime = g_Game.ServerTime:GetServerTimestampInMilliseconds()
    self.isMinusDown = true
    self.isLongPress = false
end

function CommonNumberSlider:OnBtnCompPlusDown()
    if not self.btnCompPlus.interactable then
        return
    end
    self.downTime = g_Game.ServerTime:GetServerTimestampInMilliseconds()
    self.isPlusDown = true
    self.isLongPress = false
end

function CommonNumberSlider:OnBtnCompMinusUp()
    self.downTime = nil
    self.isMinusDown = false
    if self.isLongPress then
        return
    end
    if not self.btnCompMinus.interactable then
        return
    end
    self:ChangeNum(false)
end

function CommonNumberSlider:OnBtnCompPlusUp()
    self.downTime = nil
    self.isPlusDown = false
    if self.isLongPress then
        return
    end
    if not self.btnCompPlus.interactable then
        return
    end
    self:ChangeNum(true)
end

function CommonNumberSlider:LongPressTimer()
    if not (self.isMinusDown or self.isPlusDown) then
        return
    end
    if not self.downTime then
        return
    end
    local curServerTime = g_Game.ServerTime:GetServerTimestampInMilliseconds()
    if curServerTime - self.downTime < LONG_PRESS_TIME then
        return
    end
    self.isLongPress = true
    if self.isMinusDown then
        self:ChangeNum(false)
    elseif self.isPlusDown then
        self:ChangeNum(true)
    end
end

function CommonNumberSlider:OnBtnCompMaxClicked()
    local targetValue = self.maxNum
    if self.reachBoundCallback and (targetValue > self.maxNum or (self.limitNum and targetValue > self.limitNum)) then
        self.reachBoundCallback(targetValue)
    end
    if self.maxBtnNum then
        targetValue = self.maxBtnNum
        if targetValue < self.minNum then
            targetValue = self.minNum
        end
        self:ChangeCurNum(math.clamp(targetValue, self.minNum, self.maxBtnNum))
    else
        self:ChangeCurNum(math.clamp(targetValue, self.minNum, self.maxNum))
    end
    self:IgnoreChangeSliderValue()
    if self.callBack then
        self.callBack(self.curNum)
    end
end

function CommonNumberSlider:ChangeNum(isAdd)
   local changeNum = isAdd and self.oneStepNum or -1 * self.oneStepNum
    local targetValue = self.curNum + changeNum
   if self.reachBoundCallback and (targetValue > self.maxNum or (self.limitNum and targetValue > self.limitNum)) then
       self.reachBoundCallback(targetValue)
   end
   self:ChangeCurNum(math.clamp(targetValue, self.minNum, self.maxNum))
   --self:IgnoreChangeSliderValue()
   if self.callBack then
        self.callBack(self.curNum)
   end
end

function CommonNumberSlider:ChangeCurNum(value)
    if self.limitNum and value > self.limitNum then
        value = self.limitNum
        if self.reachBoundCallback and not self.hintOnce then
            self.reachBoundCallback(value)
            self.hintOnce = true
        end
    else
        self.hintOnce = false
    end
    self.curNum = value
    local enableMinus = not (self.curNum == self.minNum)
    self.btnCompMinus.interactable = enableMinus
    local enablePlus = not (self.curNum == self.maxNum)
    if self.limitEnable then
        self.btnCompPlus.interactable = true
    else
        self.btnCompPlus.interactable = enablePlus
    end
    if not enableMinus then
        if self.isMinusDown then
            self.isMinusDown = false
            self.downTime = nil
        end
        if self.isPlusDown then
            self.isPlusDown = false
            self.downTime = nil
        end
    end
	self:IgnoreChangeSliderValue()
end

function CommonNumberSlider:OutInputChangeSliderValue(inputNum)
    self:ChangeCurNum(inputNum)
    self:IgnoreChangeSliderValue()
end

function CommonNumberSlider:IgnoreChangeSliderValue()
    self.ignoreValueListener = true
	if self.maxNum == self.ignoreNum then
		self.sliderSetBar.value = 1
	else
		self.sliderSetBar.value = math.clamp01((self.curNum - self.ignoreNum) / (self.maxNum - self.ignoreNum))
	end
    self.ignoreValueListener = false
end

function CommonNumberSlider:OnSliderValueChanged(sliderValue)
    if self.ignoreValueListener then
        return
    end
    local minNum = self.minNum == 0 and self.minNum or self.minNum - 1
    self:ChangeCurNum(math.clamp(math.ceil(sliderValue * (self.maxNum - minNum)), self.minNum, self.maxNum))
    if self.callBack then
        self.callBack(self.curNum)
   end
end

function CommonNumberSlider:SetInteractable(interactable)
    self.btnCompMinus.interactable = interactable
    self.btnCompPlus.interactable = interactable
    self.sliderSetBar.interactable = interactable
    if interactable then
        self:ChangeCurNum(self.curNum)
    end
end

function CommonNumberSlider:SetPlusInteractable(interactable)
    self.btnCompPlus.interactable = interactable
end

return CommonNumberSlider
