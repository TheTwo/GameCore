local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local TimerUtility = require('TimerUtility')
local Delegate = require('Delegate')
local UIHelper = require("UIHelper")
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local TimeFormatter = require("TimeFormatter")
local CastleMilitiaTrainParameter = require('CastleMilitiaTrainParameter')
local CastleMilitiaTrainingSwitchParameter = require('CastleMilitiaTrainingSwitchParameter')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local I18N = require('I18N')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')

---@class UISoldierArmsMediator : BaseUIMediator
local UISoldierArmsMediator = class('UISoldierArmsMediator', BaseUIMediator)

function UISoldierArmsMediator:OnCreate()
    self.textName = self:Text('p_text_name', I18N.Get('Energy_IntroductionTitle'))
    self.textDetail = self:Text('p_text_detail', I18N.Get('Energy_IntroductionContent'))
    self.textTitleName = self:Text('p_title_name', I18N.Get('Energy_EnergyTitle'))
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.textStatus = self:Text('p_text_status')
    self.goIconStop = self:GameObject('p_icon_stop')
    self.textEnergy = self:Text('p_text_energy', I18N.Get('Energy_EnergyCapacity'))
    self.sliderProgress = self:Slider('p_progress')
    self.imgProgressView = self:Image('p_progress_view')
    self.textCapacityNow = self:Text('p_text_capacity_now')
    self.goNeedCapacity = self:GameObject('p_need_capacity')
    self.textCapacityNeed = self:Text('p_text_capacity_need')
    self.textCapacityLimit = self:Text('p_text_capacity_limit')
    self.textTime = self:Text('p_text_time')
    self.textHint = self:Text('p_text_hint', I18N.Get('Energy_AutoTrainStop'))
    self.goFinish = self:GameObject('finish')
    self.textFinish = self:Text('p_text_finish', I18N.Get('Energy_CompletedAmount'))
    self.textFinishNum = self:Text('p_text_finish_num')
    self.goSpeed = self:GameObject('speed')
    self.textSpeed = self:Text('p_text_speed', I18N.Get('Energy_EnergyProductSpeed'))
    self.textSpeedNum = self:Text('p_text_speed_num')
    self.textSpeedNum1 = self:Text('p_text_speed_num_1', I18N.Get('Energy_EnergyProductUnit'))
    self.goResources = self:GameObject('resources')
    self.textResources = self:Text('p_text_resources')
    self.goItem1 = self:GameObject('p_item_1')
    self.compChildCommonQuantity1 = self:LuaObject('child_common_quantity_1')
    self.goItem2 = self:GameObject('p_item_2')
    self.compChildCommonQuantity2 = self:LuaObject('child_common_quantity_2')
    self.goItem3 = self:GameObject('p_item_3')
    self.compChildCommonQuantity3 = self:LuaObject('child_common_quantity_3')
    self.goQuantity = self:GameObject('quantity')
    self.textNeed = self:Text('p_text_need', I18N.Get('Energy_EnergyNumChoose'))
    self.textInputQuantity = self:Text('p_text_input_quantity')
    self.inputfieldInputBoxClick = self:InputField('p_input_box_click', nil, Delegate.GetOrCreate(self, self.OnEndEdit))
    self.compSetNumBar = self:LuaObject('p_set_num_bar')
    self.textProcess = self:Text('p_text_process', I18N.Get('Energy_AutoTrain'))
    self.btnToggle = self:Button('toggle', Delegate.GetOrCreate(self, self.OnBtnToggleClicked))
    self.goBaseOff = self:GameObject('p_base_off')
    self.goBaseOn = self:GameObject('p_base_on')
    self.goSeletBase = self:GameObject('selet_base')
    self.goBtn = self:GameObject('btn')
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.compChildTime = self:LuaObject('child_time')
    self.goCreate = self:GameObject('btn_create')
    self.btnStop = self:Button('p_btn_stop', Delegate.GetOrCreate(self, self.OnBtnStopClicked))
    self.textText = self:Text('p_text', I18N.Get('Energy_StopButton'))
    self.compReplenish = self:LuaObject('p_btn_replenish')
    self.btnEfficiency = self:Button('p_btn_efficiency', Delegate.GetOrCreate(self, self.OnBtnEfficiencyClicked))
    self.textEfficiency = self:Text('p_text_efficiency')
    self.btnBuff1 = self:Button('p_btn_buff_1', Delegate.GetOrCreate(self, self.OnBtnBuff1Clicked))
    self.textBuff1 = self:Text('p_text_buff_1')
    self.btnBuff2 = self:Button('p_btn_buff_2', Delegate.GetOrCreate(self, self.OnBtnBuff2Clicked))
    self.textBuff2 = self:Text('p_text_buff_2')
    self.btnBuff3 = self:Button('p_btn_buff_3', Delegate.GetOrCreate(self, self.OnBtnBuff3Clicked))
    self.textBuff3 = self:Text('p_text_buff_3')
    self.animtriggerVxTrtigger = self:AnimTrigger('vx_trtigger')
    self.goVxEffectGlow = self:GameObject('vx_effect_glow')
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')
    self.btnBuff2.gameObject:SetActive(false)
    self.btnBuff3.gameObject:SetActive(false)
    self.goBtn:SetActive(true)
    self.costItems = {self.compChildCommonQuantity1, self.compChildCommonQuantity2, self.compChildCommonQuantity3}
end

function UISoldierArmsMediator:OnClose()
    self:StopTimer()
    local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
    for _, costItem in ipairs(costItems) do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(costItem.id, Delegate.GetOrCreate(self, self.RefreshTrainingState))
    end
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleMilitia.MsgPath, Delegate.GetOrCreate(self,self.RefreshTrainingState))
end

function UISoldierArmsMediator:StopTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function UISoldierArmsMediator:OnOpened(param)
    self.furnitureId = param.furnitureId
    self.workId = ModuleRefer.TrainingSoldierModule:GetWorkId(param.configId)
    self.compChildCommonBack:FeedData({title = I18N.Get('Energy_IntroductionTitle')})
    local startBtnData = {}
    startBtnData.onClick = Delegate.GetOrCreate(self, self.OnStartBtnClicked)
    startBtnData.buttonText = I18N.Get("Energy_StartButton")
    startBtnData.disableClick = Delegate.GetOrCreate(self, self.OnDisableBtnClicked)
    self.compChildCompB:OnFeedData(startBtnData)
    local replenishBtnData = {}
    replenishBtnData.onClick = Delegate.GetOrCreate(self, self.OnReplenishBtnClicked)
    replenishBtnData.disableClick = Delegate.GetOrCreate(self, self.OnReplenishDisableBtnClicked)
    replenishBtnData.buttonText = I18N.Get("Energy_UpperLimitButton")
    self.compReplenish:OnFeedData(replenishBtnData)
    self:RefreshTrainingState()
    local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
    for _, costItem in ipairs(costItems) do
        ModuleRefer.InventoryModule:AddCountChangeListener(costItem.id, Delegate.GetOrCreate(self, self.RefreshTrainingState))
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleMilitia.MsgPath, Delegate.GetOrCreate(self,self.RefreshTrainingState))
end

function UISoldierArmsMediator:RefreshTrainingState()
    local castleMilitia = ModuleRefer.TrainingSoldierModule:GetCastleMilitia()
    self.lackResource = false
    self.isCustomTraining = castleMilitia.TrainPlan and castleMilitia.TrainPlan > 0
    self.isAutoTraining = not (castleMilitia.SwitchOff or self.isCustomTraining)
    self.isTraining = self.isAutoTraining or self.isCustomTraining
    self.isMax = castleMilitia.Capacity <= castleMilitia.Count
    self.textStatus.gameObject:SetActive(self.isMax or self.isTraining)
    self.goIconStop:SetActive(self.isMax)
    self.sliderProgress.value = math.clamp01(castleMilitia.Count / castleMilitia.Capacity)
    self.maxNum = castleMilitia.Capacity - castleMilitia.Count
    self.textInputQuantity.text = self.maxNum
    self.traingSpeed = ModuleRefer.TrainingSoldierModule:GetTraingSpeed(self.workId, nil, self.furnitureId, nil)
    self.textEfficiency.text = ModuleRefer.TrainingSoldierModule:GetWorkPower(self.workId, nil, self.furnitureId, nil)
    self.textBuff1.text = ModuleRefer.TrainingSoldierModule:GetCostDecrease(self.workId, nil, self.furnitureId, nil)
    local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
    local maxBtnNum = math.maxinteger
    for i = 1, #costItems do
        local hasNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItems[i].id)
        local costNum = costItems[i].count
        local num = math.floor(hasNum / costNum)
        if maxBtnNum > num then
            maxBtnNum = num
        end
    end
    local defaultNum = 1
    if not self.isMax then
        local setBarData = {}
        setBarData.minNum = 1
        setBarData.maxNum = self.maxNum
        setBarData.maxBtnNum = maxBtnNum
        setBarData.oneStepNum = 1
        setBarData.curNum = 1
        setBarData.intervalTime = 0.1
        setBarData.callBack = function(value)
            self:OnEndEdit(value)
        end
        self.compSetNumBar:FeedData(setBarData)
        self.inputfieldInputBoxClick.text = defaultNum
    end
    self:ChangeCostResourcesNum(defaultNum)
    self.textCapacityNow.text = self.isMax and UIHelper.GetColoredText(castleMilitia.Count, CommonItemDetailsDefine.TEXT_COLOR.RED) or castleMilitia.Count
    self.goNeedCapacity:SetActive(not self.isMax)
    if self.isMax then
        self.textStatus.text = I18N.Get('Energy_EnergyFull')
    elseif self.lackResource then
        self.textStatus.text = I18N.Get('Energy_ResourceNotEnough')
    elseif self.isAutoTraining then
        self.textStatus.text = I18N.Get('Energy_AutoProducting')
    elseif self.isCustomTraining then
        self.textStatus.text = I18N.Get('Energy_ManualProducting')
    end
    self.targetNum = nil
    if self.isAutoTraining then
        self.targetNum = castleMilitia.Capacity
        self.textCapacityNeed.text = castleMilitia.Capacity
        self.imgProgressView.fillAmount = 1
    elseif self.isCustomTraining then
        self.targetNum = castleMilitia.Count + castleMilitia.TrainPlan - castleMilitia.TrainProgress
        self.textCapacityNeed.text = self.targetNum
        self.imgProgressView.fillAmount = math.clamp01(self.targetNum / castleMilitia.Capacity)
        self.compReplenish:SetEnabled(self.targetNum < castleMilitia.Capacity)
    else
        self.textCapacityNeed.text = castleMilitia.Count + defaultNum
        self.imgProgressView.fillAmount = math.clamp01((castleMilitia.Count + defaultNum) / castleMilitia.Capacity)
    end
    self.textCapacityLimit.text = "/" .. castleMilitia.Capacity
    self.compChildCompB:SetVisible(not self.isTraining)
    self.compChildTime:SetVisible(not (self.isMax or self.isTraining))
    self.btnStop.gameObject:SetActive(self.isCustomTraining and not self.isMax)
    self.compReplenish:SetVisible(self.isCustomTraining and not self.isMax)
    local isOpenAuto = not castleMilitia.SwitchOff
    self.goBaseOn:SetActive(isOpenAuto)
    self.goSeletBase.transform.localPosition = CS.UnityEngine.Vector3(isOpenAuto and 31 or -31, -4, 0)
    self.textHint.gameObject:SetActive(self.isAutoTraining and self.lackResource)
    self.textTime.gameObject:SetVisible(self.isTraining and not self.lackResource and not self.isMax)
    if not self.lackResource and not self.isMax then
        if self.isCustomTraining then
            if not self.timer then
                local endTime = ModuleRefer.TrainingSoldierModule:GetCustomTraingTime()
                if not endTime or endTime <= 0 then
                    local needTime = ((self.targetNum - castleMilitia.Count) / self.traingSpeed) * 60
                    ModuleRefer.TrainingSoldierModule:RecordCustomTraingTime(needTime + g_Game.ServerTime:GetServerTimestampInSeconds())
                end
                self:RefreshCustomLastTime()
                self:StopTimer()
                self.timer = TimerUtility.IntervalRepeat(function()
                    self:RefreshCustomLastTime()
                end, 0.5, -1)
            end
            ModuleRefer.TrainingSoldierModule:ClearAutoTraingTime()
        elseif self.isAutoTraining then
            if not self.timer then
                local endTime = ModuleRefer.TrainingSoldierModule:GetAutoTraingTime()
                if not endTime or endTime <= 0 then
                    local needTime = ((self.targetNum - castleMilitia.Count) / self.traingSpeed) * 60
                    ModuleRefer.TrainingSoldierModule:RecordAutoTraingTime(needTime + g_Game.ServerTime:GetServerTimestampInSeconds())
                end
                self:RefreshAutoLastTime()
                self:StopTimer()
                self.timer = TimerUtility.IntervalRepeat(function()
                    self:RefreshAutoLastTime()
                end, 0.5, -1)
            end
            ModuleRefer.TrainingSoldierModule:ClearCustomTraingTime()
        else
            self.textTime.text = ""
            self:StopTimer()
            ModuleRefer.TrainingSoldierModule:ClearCustomTraingTime()
        end
    else
        self.textTime.text = ""
        self:StopTimer()
        ModuleRefer.TrainingSoldierModule:ClearCustomTraingTime()
    end
    if self.isAutoTraining and self.lackResource and not self.isMax then
        self.textTime.text = I18N.Get("Energy_AutoTrainStop")
    end
    if not (self.isMax or self.isTraining) then
        local needTime = (defaultNum / self.traingSpeed) * 60
        self.compChildTime:FeedData({endTime = needTime + g_Game.ServerTime:GetServerTimestampInSeconds()})
    end
    self.goFinish:SetActive(self.isCustomTraining)
    if self.isCustomTraining then
        self.textFinishNum.text =  "+" .. castleMilitia.TrainProgress
    end
    self.textSpeedNum.text = self.traingSpeed
    if isOpenAuto then
        self.animtriggerVxTrtigger:PlayAll(FpAnimTriggerEvent.Custom1)
    else
        self.animtriggerVxTrtigger:ResetAll(FpAnimTriggerEvent.Custom1)
    end
    self.goVxEffectGlow:SetActive(self.isTraining and not self.lackResource and not self.isMax)
    self.goVxEffectGlow.transform.localPosition = CS.UnityEngine.Vector3(math.clamp01(castleMilitia.Count / castleMilitia.Capacity) * 952 - 44, 249, 0)
    if not self.isCustomTraining then
        g_Game.UIManager:CloseByName(UIMediatorNames.CommonConfirmPopupMediator)
    end
end

function UISoldierArmsMediator:RefreshAutoLastTime()
    local endTime = ModuleRefer.TrainingSoldierModule:GetAutoTraingTime()
    if endTime and endTime > 0 then
        local lastTime = endTime - g_Game.ServerTime:GetServerTimestampInSeconds()
        self.textTime.text = TimeFormatter.SimpleFormatTime(lastTime)
        if lastTime <= 0 then
            self:StopTimer()
            self.textTime.text = ""
        end
    end
end

function UISoldierArmsMediator:RefreshCustomLastTime()
    local endTime = ModuleRefer.TrainingSoldierModule:GetCustomTraingTime()
    if endTime and endTime > 0 then
        local lastTime = endTime - g_Game.ServerTime:GetServerTimestampInSeconds()
        self.textTime.text = TimeFormatter.SimpleFormatTime(lastTime)
        if lastTime <= 0 then
            self:StopTimer()
            self.textTime.text = ""
        end
    end
end

function UISoldierArmsMediator:OnEndEdit(inputText)
    if not self.isMax then
        local inputNum = tonumber(inputText)
        if not inputNum or inputNum < 1 then
            inputNum = 1
        end
        if inputNum > self.maxNum then
            inputNum = self.maxNum
        end
        self.inputfieldInputBoxClick.text = inputNum
        local castleMilitia = ModuleRefer.TrainingSoldierModule:GetCastleMilitia()
        self.textCapacityNeed.text = castleMilitia.Count + inputNum
        self.imgProgressView.fillAmount = math.clamp01((castleMilitia.Count + inputNum) / castleMilitia.Capacity)
        self.compSetNumBar:OutInputChangeSliderValue(inputNum)
        local needTime = (inputNum / self.traingSpeed) * 60
        self.compChildTime:FeedData({endTime = needTime + g_Game.ServerTime:GetServerTimestampInSeconds()})
        self:ChangeCostResourcesNum(inputNum)
    end
end

function UISoldierArmsMediator:ChangeCostResourcesNum(inputNum)
    if self.isCustomTraining then
        self.goQuantity:SetActive(false)
        self.goResources:SetActive(false)
        return
    end
    self.goResources:SetActive(true)
    self.lackResource = false
    if self.isAutoTraining then
        self.goQuantity:SetActive(false)
        self.textResources.text = I18N.Get('Energy_ResourceConsume')
        local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
        for i = 1, #self.costItems do
            local isShow = costItems[i] ~= nil
            self.costItems[i]:SetVisible(isShow)
            if isShow then
                local hasNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItems[i].id)
                local costNum = costItems[i].count
                if hasNum < costNum  then
                    self.lackResource = true
                end
                local data = {}
                data.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
                data.itemId = costItems[i].id
                data.num1 = hasNum
                data.num2 = costNum
                data.useColor1 = true
                self.costItems[i]:FeedData(data)
            end
        end
    else
        self.goQuantity:SetActive(not self.isMax)
        self.textResources.text = I18N.Get('Energy_ResourceConsume')
        local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
        for i = 1, #self.costItems do
            local isShow = costItems[i] ~= nil
            self.costItems[i]:SetVisible(isShow)
            if isShow then
                local hasNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItems[i].id)
                local costNum = costItems[i].count * inputNum
                if hasNum < costNum  then
                    self.lackResource = true
                end
                local data = {}
                data.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
                data.itemId = costItems[i].id
                data.num1 = hasNum
                data.num2 = costNum
                data.useColor1 = true
                self.costItems[i]:FeedData(data)
                if self.isMax then
                    self.costItems[i]:ChangeText("--")
                end
            end
        end
        self.compChildCompB:SetEnabled(not (self.lackResource or self.isMax))
    end
end

function UISoldierArmsMediator:OnBtnDetailClicked(args)
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnDetail.transform, content = I18N.Get("Energy_IntroductionContent")})
end

function UISoldierArmsMediator:OnReplenishBtnClicked()
    local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
    local items = {}
    local maxNum = math.maxinteger
    for i = 1, #costItems do
        local hasNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItems[i].id)
        local costNum = costItems[i].count
        local num = math.floor(hasNum / costNum)
        if maxNum > num then
            maxNum = num
        end
    end
    if maxNum == 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Energy_ResourceNotEnough"))
        return
    end
    for i = 1, #costItems do
        local hasNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItems[i].id)
        local single = {}
        single.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
        single.itemId = costItems[i].id
        single.num1 = hasNum
        single.num2 = costItems[i].count * maxNum
        single.useColor1 = true
        items[#items + 1] = single
    end
    local confirmPopupData = {}
    confirmPopupData.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.WithItems
    confirmPopupData.title = I18N.Get("Energy_DoubleCheckTitle")
    confirmPopupData.content = I18N.Get("Energy_DoubleCheckContent02")
    local needTime = (maxNum / self.traingSpeed) * 60
    confirmPopupData.contentDescribe = I18N.Get("Energy_DoubleCheckContent03") .. TimeFormatter.SimpleFormatTime(needTime)
    confirmPopupData.confirmLabel = I18N.Get("confirm")
    confirmPopupData.cancelLabel = I18N.Get("cancle")
    confirmPopupData.items = items
    confirmPopupData.onConfirm = function(context)
        self:StopTimer()
        ModuleRefer.TrainingSoldierModule:ClearCustomTraingTime()
        ModuleRefer.TrainingSoldierModule:ClearAutoTraingTime()
        local param = CastleMilitiaTrainParameter.new()
        param.args.FurnitureId = self.furnitureId
        param.args.WorkCfgId = self.workId
        --param.args.CitizenId = 0
        param.args.Count = self.targetNum + maxNum
        param:Send()
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmPopupData)
end

function UISoldierArmsMediator:OnReplenishDisableBtnClicked()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Energy_ReachedUpperLimit"))
end

function UISoldierArmsMediator:OnStartBtnClicked()
    local param = CastleMilitiaTrainParameter.new()
    param.args.FurnitureId = self.furnitureId
    param.args.WorkCfgId = self.workId
    --param.args.CitizenId = 0
    param.args.Count = tonumber(self.inputfieldInputBoxClick.text)
    param:Send()
end

function UISoldierArmsMediator:OnDisableBtnClicked()
    if self.lackResource then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Energy_ResourceNotEnough"))
    elseif self.isMax then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Energy_ReachedUpperLimit"))
    end
end

function UISoldierArmsMediator:OnBtnToggleClicked(args)
    local castleMilitia = ModuleRefer.TrainingSoldierModule:GetCastleMilitia()
    local param = CastleMilitiaTrainingSwitchParameter.new()
    param.args.Fid = self.furnitureId
    param.args.WorkCfgId = self.workId
    --param.args.CitizenId = 0
    param.args.On = castleMilitia.SwitchOff
    param:Send(self.btnToggle.transform)
    if castleMilitia.SwitchOff and self.isCustomTraining then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Energy_ProductTransferAlert"))
    end
end

function UISoldierArmsMediator:OnBtnStopClicked(args)
    local castleMilitia = ModuleRefer.TrainingSoldierModule:GetCastleMilitia()
    local returnNum = castleMilitia.TrainPlan - castleMilitia.TrainProgress
    local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
    local items = {}
    for i = 1, #costItems do
        local single = {}
        single.itemId = costItems[i].id
        single.num1 = tostring(costItems[i].count * returnNum)
        items[#items + 1] = single
    end
    local confirmPopupData = {}
    confirmPopupData.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.WithItems
    confirmPopupData.title = I18N.Get("Energy_DoubleCheckTitle")
    confirmPopupData.content = I18N.Get("Energy_DoubleCheckContent01")
    confirmPopupData.confirmLabel = I18N.Get("confirm")
    confirmPopupData.cancelLabel = I18N.Get("cancle")
    confirmPopupData.items = items
    confirmPopupData.onConfirm = function(context)
        self:StopTimer()
        ModuleRefer.TrainingSoldierModule:ClearCustomTraingTime()
        ModuleRefer.TrainingSoldierModule:ClearAutoTraingTime()
        local param = CastleMilitiaTrainParameter.new()
        param.args.FurnitureId = self.furnitureId
        param.args.WorkCfgId = self.workId
        --param.args.CitizenId = 0
        param.args.Count = 0
        param:Send()
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmPopupData)
end

function UISoldierArmsMediator:OnBtnEfficiencyClicked(args)
    -- body
end

function UISoldierArmsMediator:OnBtnBuff1Clicked(args)
    -- body
end

-- function UISoldierArmsMediator:OnBtnBuff2Clicked(args)
--     -- body
-- end

-- function UISoldierArmsMediator:OnBtnBuff3Clicked(args)
--     -- body
-- end

return UISoldierArmsMediator
