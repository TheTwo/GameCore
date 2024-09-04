--- scene:scene_world_popup_declare_war

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local ConfigTimeUtility = require("ConfigTimeUtility")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceDeclareWarMediatorParameter
---@field village wds.Village
---@field behemothCage wds.BehemothCage
---@field callback fun(lockTrans:CS.UnityEngine.Transform|CS.UnityEngine.Transform[],villageId:number, startTime:number, callback:fun(cmd:BaseParameter, isSuccess:boolean, rsp:any))

---@class AllianceDeclareWarMediator:BaseUIMediator
---@field new fun():AllianceDeclareWarMediator
---@field super BaseUIMediator
local AllianceDeclareWarMediator = class('AllianceDeclareWarMediator', BaseUIMediator)

function AllianceDeclareWarMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type AllianceDeclareWarMediatorParameter
    self._parameter = nil
    ---@type number|nil
    self._allianceId = nil
    self._minSelectedTime = 0
    self._maxSelectedTime = 0
    self._selectedTime = nil
    self._selectMinuteStep = 5

    self._selectedDay = 0
    self._selectedHourOfDay = 0
    self._selectedMinuteOfHour = 0
    
    self._nextRefreshTime = 0
    
    self._costCurrencyId = 0
    self._costCurrencyCount = 0
    self._currencyIcon = string.Empty
    self._enterAutoSelectTimeOffset = 15 * 60
    
    ---@type {startTime:number, endTime:number, minTime:number}[]
    self._declareWarOnCageTimeRange = {}
end

function AllianceDeclareWarMediator:OnCreate(param)
    ---@type CommonSmallBackButtonComponent
    self._child_popup_base_m = self:LuaObject("child_popup_base_m")
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaObject("child_league_logo")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_name_s = self:Text("p_text_name_s")
    
    self._p_text_time = self:Text("p_text_time", "village_info_Set_attack_time")
    self._p_text_detail = self:Text("p_text_detail")
    self._p_text_utc = self:Text("p_text_utc", "UTC")
    self._p_text_hr = self:Text("p_text_hr", "H")
    self._p_text_min = self:Text("p_text_min", "M")
    self._p_text_hint = self:Text("p_text_hint")
    
    self._p_img_enemy = self:Image("p_img_enemy")
    self._p_text_enemy_lv = self:Text("p_text_enemy_lv")
    self._p_text_enemy_lv_name = self:Text("p_text_enemy_lv_name")
    self._p_text_enemy = self:Text("p_text_enemy")
    
    ---@type CommonDropDownSelectScroll
    self._child_dropdown_scroll_day = self:LuaObject("child_dropdown_scroll_day")
    ---@type CommonDropDownSelectScroll
    self._child_dropdown_scroll_h = self:LuaObject("child_dropdown_scroll_h")
    ---@type CommonDropDownSelectScroll
    self._child_dropdown_scroll_m = self:LuaObject("child_dropdown_scroll_m")
    
    self._p_btn_cancle =self:Button("p_btn_cancle", Delegate.GetOrCreate(self, self.OnClickBtnCancel))
    self._p_text = self:Text("p_text", "cancle")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")
    self._p_group_village = self:GameObject("p_group_village")
    
    ---@type CommonDropDownSelectScroll
    self._child_dropdown_scroll_day_1 = self:LuaObject("child_dropdown_scroll_day_1")
    self._p_text_h = self:Text("p_text_h", "H")
    self._child_dropdown_scroll_h_1 = self:LuaObject("child_dropdown_scroll_h_1")
    self._p_text_m = self:Text("p_text_m", "M")
    self._child_dropdown_scroll_m_1 = self:LuaObject("child_dropdown_scroll_m_1")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetail))
    self._p_group_behemoth = self:GameObject("p_group_behemoth")
end

---@param param AllianceDeclareWarMediatorParameter
function AllianceDeclareWarMediator:OnOpened(param)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self._parameter = param
    if param.village then
        self._p_group_village:SetVisible(true)
        self._p_group_behemoth:SetVisible(false)
        self:SetupForVillage()
    elseif param.behemothCage then
        self._p_group_village:SetVisible(false)
        self._p_group_behemoth:SetVisible(true)
        self:SetupForBehemothCage()
    end
end

function AllianceDeclareWarMediator:SetupForVillage()
    local stepTime = ConfigRefer.AllianceConsts:AllianceDeclareVillageTimeStepMinute() or 5
    self._selectMinuteStep = math.max(1, stepTime)
    local offsetTime = ConfigRefer.AllianceConsts:AllianceDeclareVillageAutoSelectOffsetSteps() or 3
    self._enterAutoSelectTimeOffset = self._selectMinuteStep * math.max(0, offsetTime) * 60
    self:InitMinMaxTimeForVillage()
    self:UpdateTimeSelectorForVillage()
    self:SetupMyAllianceInfo()
    self:SetupTargetInfo()
    self:UpdateBtnDeclareWar()
    self:SecTick(0)
end

function AllianceDeclareWarMediator:SetupForBehemothCage()
    self._selectMinuteStep = 1
    self:InitMinMaxTimeForCage()
    self:UpdateTimeSelectorForCage()
    self:SetupTargetInfo()
    self:SetupMyAllianceInfo()
    self:UpdateBtnDeclareWar()
    self:SecTick(0)
end

function AllianceDeclareWarMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceCurrency.Currency.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))
end

function AllianceDeclareWarMediator:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceCurrency.Currency.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function AllianceDeclareWarMediator:OnLeaveAlliance(allianceId)
    if self._allianceId and self._allianceId == allianceId then
        self:CloseSelf()
    end
end

function AllianceDeclareWarMediator:SetupMyAllianceInfo()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local allianceBasicInfo = allianceData.AllianceBasicInfo
    self._p_text_name_s.text = allianceBasicInfo.Abbr
    self._p_text_name.text = allianceBasicInfo.Name
    self._child_league_logo:FeedData(allianceBasicInfo.Flag)
end

function AllianceDeclareWarMediator:SetupTargetInfo()
    local village = self._parameter.village
    local cage = self._parameter.behemothCage
    if village then
        local buildingConfig = ConfigRefer.FixedMapBuilding:Find(village.MapBasics.ConfID)
        self._costCurrencyId = buildingConfig:AllianceDeclareCostCurrencyType()
        self._costCurrencyCount = buildingConfig:AllianceDeclareCostCurrencyNum()
        local currencyConfig = ConfigRefer.AllianceCurrency:Find(self._costCurrencyId)
        if currencyConfig then
            self._currencyIcon = currencyConfig:Icon()
        end
        if string.IsNullOrEmpty(self._currencyIcon) then
            self._currencyIcon = "sp_icon_missing"
        end
        g_Game.SpriteManager:LoadSprite(buildingConfig:Image(), self._p_img_enemy)
        self._p_text_enemy_lv.text = tostring(buildingConfig:Level())
        self._p_text_enemy_lv_name.text = I18N.Get(buildingConfig:Name())
        if village.Owner and village.Owner.AllianceID ~= 0 then
            self._p_text_enemy.text = ("[%s]%s"):format(village.Owner.AllianceAbbr.String, village.Owner.AllianceName.String)
        else
            self._p_text_enemy.text = I18N.Get("village_info_No_occupied")
        end
    elseif cage then
        local buildingConfig = ConfigRefer.FixedMapBuilding:Find(cage.BehemothCage.ConfigId)
        self._costCurrencyId = buildingConfig:AllianceDeclareCostCurrencyType()
        self._costCurrencyCount = buildingConfig:AllianceDeclareCostCurrencyNum()
        local currencyConfig = ConfigRefer.AllianceCurrency:Find(self._costCurrencyId)
        if currencyConfig then
            self._currencyIcon = currencyConfig:Icon()
        end
        if string.IsNullOrEmpty(self._currencyIcon) then
            self._currencyIcon = "sp_icon_missing"
        end
        g_Game.SpriteManager:LoadSprite(buildingConfig:Image(), self._p_img_enemy)
        self._p_text_enemy_lv.text = tostring(buildingConfig:Level())
        self._p_text_enemy_lv_name.text = I18N.Get(buildingConfig:Name())
        if cage.Owner and cage.Owner.AllianceID ~= 0 then
            self._p_text_enemy.text = ("[%s]%s"):format(cage.Owner.AllianceAbbr.String, cage.Owner.AllianceName.String)
        else
            self._p_text_enemy.text = I18N.Get("alliance_behemoth_title_cage")
        end
    end
end

function AllianceDeclareWarMediator:OnClickBtnCancel()
    self:CloseSelf()
end

function AllianceDeclareWarMediator:OnClickBtnDeclareWar()
    if self._parameter and self._parameter.callback and self._selectedTime then
        local id = self._parameter.village and self._parameter.village.ID or self._parameter.behemothCage.ID
        self._parameter.callback(self._child_comp_btn_b.button.transform ,id, self._selectedTime, function(cmd, isSuccess, rsp)
            if isSuccess then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_Set_time_11"))
            end
        end)
        self:CloseSelf()
    end
end

function AllianceDeclareWarMediator:OnClickDetail()
    ModuleRefer.ToastModule:SimpleShowTextToastTip(I18N.Get("alliance_behemoth_rule_DeclareCage"), self._p_btn_detail.transform)
end

function AllianceDeclareWarMediator:SecTick(dt)
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self._p_text_detail.text = I18N.Get(("UTC %s"):format(TimeFormatter.TimeToDateTimeStringUseFormat(serverTime, "MM.dd HH:mm:ss")))
    if self._selectedTime then
        local passTime = math.max(0, self._selectedTime - serverTime)
        self._p_text_hint.text = I18N.GetWithParams("village_info_Set_time_2", TimeFormatter.SimpleFormatTime(passTime))
    else
        self._p_text_hint.text = string.Empty
    end
    if serverTime <= self._nextRefreshTime then
        return
    end
    if self._parameter.village then
        self:InitMinMaxTimeForVillage()
        self:UpdateTimeSelectorForVillage()
    elseif self._parameter.behemothCage then
        self:InitMinMaxTimeForCage()
        self:UpdateTimeSelectorForCage()
    end
end

---@param entity wds.Alliance
---@param changedData table
function AllianceDeclareWarMediator:OnAllianceCurrencyChanged(entity, changedData)
    if not self._allianceId or self._allianceId ~= entity.ID then
       return
    end
    local add,remove,changed = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    if (add and add[self._costCurrencyId]) or (remove and remove[self._costCurrencyId]) or (changed and changedData[self._costCurrencyId]) then
        self:UpdateBtnDeclareWar()
    end
end

function AllianceDeclareWarMediator:UpdateBtnDeclareWar()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local hasCurrencyCount = allianceData.AllianceCurrency.Currency[self._costCurrencyId] or 0
    ---@type BistateButtonParameter
    local btnParameter = {}
    btnParameter.buttonText = I18N.Get("village_btn_Declare_war")
    btnParameter.onClick = Delegate.GetOrCreate(self, self.OnClickBtnDeclareWar)
    btnParameter.icon = self._currencyIcon
    btnParameter.num1 = self._costCurrencyCount
    btnParameter.num2 = hasCurrencyCount
    self._child_comp_btn_b:FeedData(btnParameter)
    self._child_comp_btn_b:SetEnabled(hasCurrencyCount >= self._costCurrencyCount)
end

---@param originTime number
---@param ceil boolean
---@return CS.System.DateTime
function AllianceDeclareWarMediator:AlignedTimeToStep(originTime, ceil)
    local timeDate = TimeFormatter.ToDateTime(originTime)
    local timeDateMinuteAligned = timeDate.Date:AddHours(timeDate.Hour)
    local timeMinuteAndSecondPart = timeDate.Minute * 60 + timeDate.Second
    local timeMinuteAndSecondPartAlignedWithStep = 0
    timeMinuteAndSecondPartAlignedWithStep = timeMinuteAndSecondPart // (self._selectMinuteStep * 60) * self._selectMinuteStep
    local ret = timeDateMinuteAligned:AddMinutes(timeMinuteAndSecondPartAlignedWithStep)
    if not ceil then
        return ret
    end
    local st = TimeFormatter.DataTimeToTimeStamp(ret)
    if st <= originTime then
        ret = ret:AddMinutes(self._selectMinuteStep)
    end
    return ret
end

---@param originTime number
---@return CS.System.DateTime
function AllianceDeclareWarMediator:AlignedTimeToStepEqualOrCeil(originTime)
    local timeDate = TimeFormatter.ToDateTime(originTime)
    local timeDateMinuteAligned = timeDate.Date:AddHours(timeDate.Hour)
    local timeMinuteAndSecondPart = timeDate.Minute * 60 + timeDate.Second
    local timeMinuteAndSecondPartAlignedWithStep = 0
    timeMinuteAndSecondPartAlignedWithStep = timeMinuteAndSecondPart // (self._selectMinuteStep * 60) * self._selectMinuteStep
    local ret = timeDateMinuteAligned:AddMinutes(timeMinuteAndSecondPartAlignedWithStep)
    local st = TimeFormatter.DataTimeToTimeStamp(ret)
    if st < originTime then
        ret = ret:AddMinutes(self._selectMinuteStep)
    end
    return ret
end

function AllianceDeclareWarMediator:InitMinMaxTimeForVillage()
    local village = self._parameter.village
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local nowTimeDateMinuteAligned = self:AlignedTimeToStep(nowTime, false)
    self._nextRefreshTime = TimeFormatter.DataTimeToTimeStamp(nowTimeDateMinuteAligned) + self._selectMinuteStep * 60
    local minTime = math.max(ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:AllianceDeclareVillageMinInternal()), 0)
    if village.Owner.AllianceID ~= 0 then
        minTime = math.max(minTime, ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:AllianceDeclareOwnedVillageMinInternal()))
    end
    local maxTime =  math.max(ConfigTimeUtility.NsToSeconds(ConfigRefer.AllianceConsts:AllianceDeclareVillageMaxInternal()), minTime + self._selectMinuteStep * 60)
    self._minSelectedTime = TimeFormatter.DataTimeToTimeStamp(self:AlignedTimeToStep(nowTime + minTime, true))
    self._maxSelectedTime = TimeFormatter.DataTimeToTimeStamp(self:AlignedTimeToStep(nowTime + maxTime, false))
    self._maxSelectedTime = math.max(self._maxSelectedTime, self._minSelectedTime)
    if not self._selectedTime then
        local adviceTime = TimeFormatter.DataTimeToTimeStamp(self:AlignedTimeToStep(nowTime + self._enterAutoSelectTimeOffset, true))
        self._selectedTime = math.clamp(adviceTime, self._minSelectedTime, self._maxSelectedTime)
    else
        self._selectedTime = math.clamp(self._selectedTime, self._minSelectedTime, self._maxSelectedTime)
    end
end

function AllianceDeclareWarMediator:UpdateTimeSelectorForVillage()
    if not self._selectedTime then
        self:SetNoneSelector()
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local nowTimeDay = TimeFormatter.ToDateTime(nowTime)
    local nowTimeDate = nowTimeDay.Date
    local maxTimeDay = TimeFormatter.ToDateTime(self._maxSelectedTime)
    local maxTimeDate = maxTimeDay.Date
    local maxTimeDateHour = TimeFormatter.DataTimeToTimeStamp(maxTimeDate:AddHours(maxTimeDay.Hour))
    local maxTimeDateMinute = TimeFormatter.DataTimeToTimeStamp(maxTimeDate:AddHours(maxTimeDay.Hour):AddMinutes(maxTimeDay.Minute))
    local minTimeDay = TimeFormatter.ToDateTime(self._minSelectedTime)
    local minTimeDate = minTimeDay.Date
    local minTimeDateHour = TimeFormatter.DataTimeToTimeStamp(minTimeDate:AddHours(minTimeDay.Hour))
    local minTimeDateMinute = TimeFormatter.DataTimeToTimeStamp(minTimeDate:AddHours(minTimeDay.Hour):AddMinutes(minTimeDay.Minute))
    
    local selectedTimeDate = TimeFormatter.ToDateTime(self._selectedTime)
    local selectedTimeDateDay = selectedTimeDate.Date
    local selectedDayStartTimestamp = TimeFormatter.DataTimeToTimeStamp(selectedTimeDateDay)

    -- Day Selector
    ---@type CommonDropDownSelectScrollParameter
    local daySelectorParameter = {}
    daySelectorParameter.onSelected = Delegate.GetOrCreate(self, self.OnTimeSelectorDayChanged)
    daySelectorParameter.dataSource = {}
    local addDay = math.floor((minTimeDate - nowTimeDate).TotalDays + 0.5)
    local maxAddDay = math.floor((maxTimeDate - nowTimeDate).TotalDays + 0.5)
    for i = addDay, maxAddDay do
        local currentDay = TimeFormatter.DataTimeToTimeStamp(nowTimeDate:AddDays(i))
        if i == 0 then
            table.insert(daySelectorParameter.dataSource, {show = I18N.Get("village_info_Today"), context = currentDay})
        elseif i == 1 then
            table.insert(daySelectorParameter.dataSource, {show = I18N.Get("village_info_Tomorrow"), context = currentDay})
        else
            table.insert(daySelectorParameter.dataSource, {show = ("+%sD"):format(i), context = currentDay})
        end
        if currentDay == selectedDayStartTimestamp then
            daySelectorParameter.defaultIndex = #daySelectorParameter.dataSource
        end
    end
    self._child_dropdown_scroll_day:FeedData(daySelectorParameter)

    -- Hour Selector
    ---@type CommonDropDownSelectScrollParameter
    local hourSelectorParameter = {}
    hourSelectorParameter.onSelected = Delegate.GetOrCreate(self, self.OnTimeSelectorHourChanged)
    hourSelectorParameter.dataSource = {}
    hourSelectorParameter.defaultIndex = 1
    for i = 0, 23 do
        local currentTime = selectedDayStartTimestamp + i * 3600
        if currentTime >= minTimeDateHour and currentTime <= maxTimeDateHour then
            table.insert(hourSelectorParameter.dataSource, {show = string.format("%d", i), context = i})
        else
            table.insert(hourSelectorParameter.dataSource, {show = string.format("%d", i), context = i, isDisable = true})
        end
        if i == selectedTimeDate.Hour then
            hourSelectorParameter.defaultIndex = #hourSelectorParameter.dataSource
        end
    end
    self._child_dropdown_scroll_h:FeedData(hourSelectorParameter)
    
    -- Minute Selector
    ---@type CommonDropDownSelectScrollParameter
    local minuteSelectorParameter = {}
    minuteSelectorParameter.onSelected = Delegate.GetOrCreate(self, self.OnTimeSelectorMinuteChanged)
    minuteSelectorParameter.dataSource = {}
    minuteSelectorParameter.defaultIndex = 1
    for i = 0, 59, self._selectMinuteStep do
        local currentTime = selectedDayStartTimestamp + selectedTimeDate.Hour * 3600 + i * 60
        if currentTime >= minTimeDateMinute and currentTime <= maxTimeDateMinute then
            table.insert(minuteSelectorParameter.dataSource, {show = string.format("%d", i), context = i})
        else
            table.insert(minuteSelectorParameter.dataSource, {show = string.format("%d", i), context = i, isDisable = true})
        end
        if i == selectedTimeDate.Minute then
            minuteSelectorParameter.defaultIndex = #minuteSelectorParameter.dataSource
        end
    end
    self._child_dropdown_scroll_m:FeedData(minuteSelectorParameter)
end

function AllianceDeclareWarMediator:InitMinMaxTimeForCage()
    local cage = self._parameter.behemothCage
    local fixedBuildingConfig = ConfigRefer.FixedMapBuilding:Find(cage.BehemothCage.ConfigId)
    local cageConfig = ConfigRefer.BehemothCage:Find(fixedBuildingConfig:BehemothCageConfig())
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local nowTimeDateMinuteAligned = self:AlignedTimeToStep(nowTime, false)
    local nowTimeDateMinuteAlignedCeil = TimeFormatter.DataTimeToTimeStamp(self:AlignedTimeToStep(nowTime, true))
    self._nextRefreshTime = TimeFormatter.DataTimeToTimeStamp(nowTimeDateMinuteAligned) + self._selectMinuteStep * 60
    table.clear(self._declareWarOnCageTimeRange)
    local minTime = nil
    local maxTime = nil
    for i = 1, cageConfig:AttackActivityLength() do
        local templateId = cageConfig:AttackActivity(i)
        local startTime, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(templateId)
        if startTime and endTime and endTime.ServerSecond > nowTime and (endTime.ServerSecond - startTime.ServerSecond) > (self._selectMinuteStep * 60) then
            local used = false
            for _, value in pairs(cage.VillageWar.AllianceWar) do
                if value.StartTime >= startTime.ServerSecond and value.StartTime <= endTime.ServerSecond then
                    used = true
                    break
                end
                if value.EndTime >= startTime.ServerSecond and value.EndTime <= endTime.ServerSecond then
                    used = true
                    break
                end
            end
            if not used then
                ---@type {startTime:number, endTime:number, minTime:number}
                local timePair = {}
                timePair.startTime = TimeFormatter.DataTimeToTimeStamp(self:AlignedTimeToStepEqualOrCeil(startTime.ServerSecond))
                timePair.minTime = math.max(nowTimeDateMinuteAlignedCeil, timePair.startTime)
                local endTimeA = TimeFormatter.DataTimeToTimeStamp(self:AlignedTimeToStep(endTime.ServerSecond, false))
                if endTime.ServerSecond - endTimeA <= 0 then
                    timePair.endTime = endTimeA - (self._selectMinuteStep * 60)
                else
                    timePair.endTime = endTimeA
                end
                if not minTime or minTime > timePair.minTime then
                    minTime = timePair.minTime
                end
                if not maxTime or maxTime < timePair.endTime then
                    maxTime = timePair.endTime
                end
                table.insert(self._declareWarOnCageTimeRange,1 ,timePair)
            end
        end
    end
    self._minSelectedTime = minTime
    self._maxSelectedTime = maxTime
    if not self._minSelectedTime or not self._maxSelectedTime then
        self._selectedTime = nil
        return
    end
    if not self._selectedTime then
        self._selectedTime = self._minSelectedTime + self._selectMinuteStep * 60
    end
    self._selectedTime = math.clamp(self._selectedTime, self._minSelectedTime, self._maxSelectedTime)
end

---@param range {startTime:number, endTime:number, minTime:number}
---@return string
function AllianceDeclareWarMediator.BuildTimeRangeOption(range)
    local startTime = TimeFormatter.ToDateTime(range.startTime)
    local endTime = TimeFormatter.ToDateTime(range.endTime)
    if TimeFormatter.InSameDay(startTime, endTime) then
        local dateTime = startTime.Date
        local currentCultureInfo = g_Game.LocalizationManager:GetCultureInfo()
        return dateTime:ToString("yyyy/MM/dd", currentCultureInfo) .. (" %s-%s"):format(startTime.Hour, endTime.Hour)
    else
        local currentCultureInfo = g_Game.LocalizationManager:GetCultureInfo()
        local dateTime1 = startTime.Date
        local dateTime2 = endTime.Date
        return ("%s %s-%s %s"):format(dateTime1:ToString("yyyy/MM/dd", currentCultureInfo), startTime.Hour, dateTime2:ToString("yyyy/MM/dd", currentCultureInfo), endTime.Hour)
    end
end

function AllianceDeclareWarMediator:SetNoneSelector()
    -- Day Selector
    ---@type CommonDropDownSelectScrollParameter
    local daySelectorParameter = {}
    daySelectorParameter.onSelected = Delegate.GetOrCreate(self, self.OnOnTimeSelectorRangeStart_Cage_Changed)
    daySelectorParameter.dataSource = {}
    daySelectorParameter.dataSource[1] = {show = "--"}
    daySelectorParameter.defaultIndex = 1
    self._child_dropdown_scroll_day_1:FeedData(daySelectorParameter)

    -- Hour Selector
    ---@type CommonDropDownSelectScrollParameter
    local hourSelectorParameter = {}
    hourSelectorParameter.onSelected = Delegate.GetOrCreate(self, self.OnTimeSelectorHour_Cage_Changed)
    hourSelectorParameter.dataSource = {}
    hourSelectorParameter.dataSource[1] = {show = "--"}
    hourSelectorParameter.defaultIndex = 1
    self._child_dropdown_scroll_h_1:FeedData(hourSelectorParameter)

    -- Minute Selector
    ---@type CommonDropDownSelectScrollParameter
    local minuteSelectorParameter = {}
    minuteSelectorParameter.onSelected = Delegate.GetOrCreate(self, self.OnTimeSelectorMinute_Cage_Changed)
    minuteSelectorParameter.dataSource = {}
    minuteSelectorParameter.dataSource[1] = {show = "--"}
    minuteSelectorParameter.defaultIndex = 1
    self._child_dropdown_scroll_m_1:FeedData(minuteSelectorParameter)
end

function AllianceDeclareWarMediator:UpdateTimeSelectorForCage()
    if not self._declareWarOnCageTimeRange or #self._declareWarOnCageTimeRange <= 0 or not self._selectedTime then
        self:SetNoneSelector()
        return
    end
    local selectedTimeDate = TimeFormatter.ToDateTime(self._selectedTime)
    local selectedTimeDateDay = selectedTimeDate.Date
    local selectedDayStartTimestamp = TimeFormatter.DataTimeToTimeStamp(selectedTimeDateDay)
    
    -- Day Selector
    ---@type CommonDropDownSelectScrollParameter
    local daySelectorParameter = {}
    daySelectorParameter.onSelected = Delegate.GetOrCreate(self, self.OnOnTimeSelectorRangeStart_Cage_Changed)
    daySelectorParameter.dataSource = {}
    for i = 1, #self._declareWarOnCageTimeRange do
        local range = self._declareWarOnCageTimeRange[i]
        table.insert(daySelectorParameter.dataSource, {show = AllianceDeclareWarMediator.BuildTimeRangeOption(range), context = range})
        if self._selectedTime >= range.minTime and self._selectedTime <= range.endTime and not daySelectorParameter.defaultIndex then
            daySelectorParameter.defaultIndex = i
        end
    end
    self._child_dropdown_scroll_day_1:FeedData(daySelectorParameter)
    local currentRange = self._declareWarOnCageTimeRange[daySelectorParameter.defaultIndex]
    local rangeStartDate = TimeFormatter.ToDateTime(currentRange.minTime)
    local rangeEndDate = TimeFormatter.ToDateTime(currentRange.endTime)
    local rangeStartHour = TimeFormatter.DataTimeToTimeStamp(rangeStartDate.Date:AddHours(rangeStartDate.Hour))
    local rangeEndHour = TimeFormatter.DataTimeToTimeStamp(rangeEndDate.Date:AddHours(rangeEndDate.Hour))
    
    -- Hour Selector
    ---@type CommonDropDownSelectScrollParameter
    local hourSelectorParameter = {}
    hourSelectorParameter.onSelected = Delegate.GetOrCreate(self, self.OnTimeSelectorHour_Cage_Changed)
    hourSelectorParameter.dataSource = {}
    hourSelectorParameter.defaultIndex = 1
    for i = 0, 23 do
        local currentTime = selectedDayStartTimestamp + i * 3600
        if currentTime >= rangeStartHour and currentTime <= rangeEndHour then
            table.insert(hourSelectorParameter.dataSource, {show = string.format("%d", i), context = i})
        else
            table.insert(hourSelectorParameter.dataSource, {show = string.format("%d", i), context = i, isDisable = true})
        end
        if i == selectedTimeDate.Hour then
            hourSelectorParameter.defaultIndex = #hourSelectorParameter.dataSource
        end
    end
    self._child_dropdown_scroll_h_1:FeedData(hourSelectorParameter)

    -- Minute Selector
    ---@type CommonDropDownSelectScrollParameter
    local minuteSelectorParameter = {}
    minuteSelectorParameter.onSelected = Delegate.GetOrCreate(self, self.OnTimeSelectorMinute_Cage_Changed)
    minuteSelectorParameter.dataSource = {}
    minuteSelectorParameter.defaultIndex = 1
    for i = 0, 59, self._selectMinuteStep do
        local currentTime = selectedDayStartTimestamp + selectedTimeDate.Hour * 3600 + i * 60
        if currentTime >= currentRange.minTime and currentTime <= currentRange.endTime then
            table.insert(minuteSelectorParameter.dataSource, {show = string.format("%d", i), context = i})
        else
            table.insert(minuteSelectorParameter.dataSource, {show = string.format("%d", i), context = i, isDisable = true})
        end
        if i == selectedTimeDate.Minute then
            minuteSelectorParameter.defaultIndex = #minuteSelectorParameter.dataSource
        end
    end
    self._child_dropdown_scroll_m_1:FeedData(minuteSelectorParameter)
end

---@param selected {index:number, data:{show:string, context:any}}
function AllianceDeclareWarMediator:OnTimeSelectorDayChanged(selected)
    if not self._selectedTime then return end
    if not selected.data.context then return end
    local selectedTimeDate = TimeFormatter.ToDateTime(self._selectedTime)
    local selectedDays = TimeFormatter.DataTimeToTimeStamp(selectedTimeDate.Date)
    if selectedDays == selected.data.context then
        return
    end
    self._selectedTime = selected.data.context + selectedTimeDate.Hour * 3600 + selectedTimeDate.Minute * 60
    self._selectedTime = math.clamp(self._selectedTime, self._minSelectedTime, self._maxSelectedTime)
    self:UpdateTimeSelectorForVillage()
    self:SecTick(0)
end

---@param selected {index:number, data:{show:string, context:any}}
function AllianceDeclareWarMediator:OnTimeSelectorHourChanged(selected)
    if not self._selectedTime then return end
    if not selected.data.context then return end
    local selectedTimeDate = TimeFormatter.ToDateTime(self._selectedTime)
    if selectedTimeDate.Hour == selected.data.context then
        return
    end
    local selectedDays = TimeFormatter.DataTimeToTimeStamp(selectedTimeDate.Date)
    self._selectedTime = selectedDays + selected.data.context * 3600 + selectedTimeDate.Minute * 60
    self._selectedTime = math.clamp(self._selectedTime, self._minSelectedTime, self._maxSelectedTime)
    self:UpdateTimeSelectorForVillage()
    self:SecTick(0)
end

---@param selected {index:number, data:{show:string, context:any}}
function AllianceDeclareWarMediator:OnTimeSelectorMinuteChanged(selected)
    if not self._selectedTime then return end
    if not selected.data.context then return end
    local selectedTimeDate = TimeFormatter.ToDateTime(self._selectedTime)
    if selectedTimeDate.Minute == selected.data.context then
        return
    end
    local selectedDays = TimeFormatter.DataTimeToTimeStamp(selectedTimeDate.Date)
    self._selectedTime = selectedDays + selectedTimeDate.Hour * 3600 + selected.data.context * 60
    self._selectedTime = math.clamp(self._selectedTime, self._minSelectedTime, self._maxSelectedTime)
    self:UpdateTimeSelectorForVillage()
    self:SecTick(0)
end

---@param selected {index:number, data:{show:string, context:any}}
function AllianceDeclareWarMediator:OnOnTimeSelectorRangeStart_Cage_Changed(selected)
    if not self._selectedTime then return end
    if not selected.data.context then return end
    local selectedTimeDate = TimeFormatter.ToDateTime(self._selectedTime)
    ---@type {startTime:number, endTime:number, minTime:number}
    local range = selected.data.context
    if self._selectedTime >= range.minTime and self._selectedTime <= range.endTime then
        return
    end
    local rangeStartDate = TimeFormatter.ToDateTime(range.minTime)
    local t = TimeFormatter.DataTimeToTimeStamp(rangeStartDate.Date)
    self._selectedTime = t + selectedTimeDate.Hour * 3600 + selectedTimeDate.Minute * 60
    self._selectedTime = math.clamp(self._selectedTime, range.minTime, range.endTime)
    self:UpdateTimeSelectorForCage()
    self:SecTick(0)
end

---@param selected {index:number, data:{show:string, context:any}}
function AllianceDeclareWarMediator:OnTimeSelectorHour_Cage_Changed(selected)
    if not self._selectedTime then return end
    if not selected.data.context then return end
    local selectedTimeDate = TimeFormatter.ToDateTime(self._selectedTime)
    if selectedTimeDate.Hour == selected.data.context then
        return
    end
    local selectedDays = TimeFormatter.DataTimeToTimeStamp(selectedTimeDate.Date)
    self._selectedTime = selectedDays + selected.data.context * 3600 + selectedTimeDate.Minute * 60
    self._selectedTime = math.clamp(self._selectedTime, self._minSelectedTime, self._maxSelectedTime)
    self:UpdateTimeSelectorForCage()
    self:SecTick(0)
end

---@param selected {index:number, data:{show:string, context:any}}
function AllianceDeclareWarMediator:OnTimeSelectorMinute_Cage_Changed(selected)
    if not self._selectedTime then return end
    if not selected.data.context then return end
    local selectedTimeDate = TimeFormatter.ToDateTime(self._selectedTime)
    if selectedTimeDate.Minute == selected.data.context then
        return
    end
    local selectedDays = TimeFormatter.DataTimeToTimeStamp(selectedTimeDate.Date)
    self._selectedTime = selectedDays + selectedTimeDate.Hour * 3600 + selected.data.context * 60
    self._selectedTime = math.clamp(self._selectedTime, self._minSelectedTime, self._maxSelectedTime)
    self:UpdateTimeSelectorForCage()
    self:SecTick(0)
end

return AllianceDeclareWarMediator