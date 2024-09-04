local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
local ConfigRefer = require("ConfigRefer")
local HUDTroopUtils = require("HUDTroopUtils")
local TimeFormatter = require("TimeFormatter")
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local BaseUIComponent = require("BaseUIComponent")
local BistateButton = require("BistateButton")
local SlgUtils = require("SlgUtils")

---@alias TimeSelectCell {go:CS.UnityEngine.GameObject,btn:CS.UnityEngine.UI.Button, normalRoot:CS.UnityEngine.GameObject, selectedRoot:CS.UnityEngine.GameObject, normalText:CS.UnityEngine.UI.Text, selectedText:CS.UnityEngine.UI.Text, time:number}

---@class HUDSelectTroopBattleAssemblyTipComponentParameter
---@field listParam HUDSelectTroopListData
---@field onGotoButtonClicked fun(index)

---@class HUDSelectTroopBattleAssemblyTipComponent:BaseUIComponent
---@field new fun():HUDSelectTroopBattleAssemblyTipComponent
---@field super BaseUIComponent
local HUDSelectTroopBattleAssemblyTipComponent = class('HUDSelectTroopBattleAssemblyTipComponent', BaseUIComponent)

function HUDSelectTroopBattleAssemblyTipComponent:ctor()
    BaseUIComponent.ctor(self)
    ---@type TimeSelectCell[]
    self._timeCellBts = {}
    self._selectedIndex = 1
    self._checkPreFetchKey = string.Empty
    self._preFetchTimeInfo = nil
    self._preFetchTimeInfoError = false
    self._troopOk = false
    self._ppOk = false
    self._itemOk = false
    self._timeOk = false
    self._leftTimeOk = false
end

function HUDSelectTroopBattleAssemblyTipComponent:OnCreate(param)
    self._selfRect = self:RectTransform("")
    self._p_text_league = self:Text("p_text_league", "alliance_team_jingong")
    self._p_text_info = self:Text("p_text_info", "alliance_team_tips01")
    self._p_choose_time = self:Transform("p_choose_time")
    self._p_btn_time_template = self:GameObject("p_btn_time")
    self._p_text_my_power_lable = self:Text("p_text_my_power_lable", "alliance_team_zhanli")
    self._p_text_my_power_value = self:Text("p_text_my_power_value")
    self._p_btn_time_template:SetVisible(false)

    self._p_text_march_time_title = self:Text("p_text_march_time_title", "alliance_team_xingjunshijian")
    self._p_text_march_time_value = self:Text("p_text_march_time_value")

    self._p_arrow_2 = self:GameObject("p_arrow_2")

    ---@type CommonPairsQuantity
    self._child_common_quantity = self:LuaObject("child_common_quantity")
    self._child_common_quantity:SetVisible(false)
    ---@type CommonPairsQuantity
    self._child_common_quantity_1 = self:LuaObject("child_common_quantity_1")
    self._child_common_quantity_1:SetVisible(false)
    ---@type BistateButton
    self._p_btn_goto = self:LuaObject("p_btn_goto")

    self.compAssembleAnim = self:AnimTrigger('vx_trigger')

    -- 编队信息
    self._p_heroes = {
        self:LuaObject("p_card_hero_1"),
        self:LuaObject("p_card_hero_2"),
        self:LuaObject("p_card_hero_3"),
    }

    self._p_pets = {
        self:LuaObject("p_card_pet_1"),
        self:LuaObject("p_card_pet_2"),
        self:LuaObject("p_card_pet_3"),
    }
end

function HUDSelectTroopBattleAssemblyTipComponent:OnShow(param)
    self:SetupEvents(true)
    self.compAssembleAnim:PlayAll(FpAnimTriggerEvent.OnShow)
end

function HUDSelectTroopBattleAssemblyTipComponent:OnHide(param)
    self._checkPreFetchKey = string.Empty
    self:SetupEvents(false)
end

function HUDSelectTroopBattleAssemblyTipComponent:OnClose(param)
    self:SetupEvents(false)

    for i, v in pairs(self._timeCellBts) do
        UIHelper.DeleteUIGameObject(v.go)
    end
end

function HUDSelectTroopBattleAssemblyTipComponent:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.EventManager:AddListener(EventConst.HUD_SELECT_TROOP_ASSEMBLE_TIME_PREFETCH_UPDATE, Delegate.GetOrCreate(self, self.OnTimePreFetch))
        g_Game.EventManager:AddListener(EventConst.HUD_SELECT_TROOP_ASSEMBLE_TIME_PREFETCH_UPDATE_FAILED, Delegate.GetOrCreate(self, self.OnTimePreFetchFailed))
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateKeepInRange))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.EventManager:RemoveListener(EventConst.HUD_SELECT_TROOP_ASSEMBLE_TIME_PREFETCH_UPDATE, Delegate.GetOrCreate(self, self.OnTimePreFetch))
        g_Game.EventManager:RemoveListener(EventConst.HUD_SELECT_TROOP_ASSEMBLE_TIME_PREFETCH_UPDATE_FAILED, Delegate.GetOrCreate(self, self.OnTimePreFetchFailed))
        g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateKeepInRange))
    end
end


---@class HUDAssembleTipComponentParam
---@field listParam HUDSelectTroopListData
---@field listItem HUDSelectTroopListItemData
---@field troopPower number
---@field preset wds.TroopPreset
---@field arrowPosY number
---@field onGotoButtonClicked fun(time:number)

---@param data HUDAssembleTipComponentParam
function HUDSelectTroopBattleAssemblyTipComponent:OnFeedData(data)
    self._parameter = data
    self.preset = data.preset
    self.troopInfo = data.listItem.troopInfo

    self:SetUpTimeCell()

    self._p_text_my_power_value.text = tostring(data.troopPower or 0)
    ---@type BistateButtonParameter
    local btnData = {}
    btnData.onClick = Delegate.GetOrCreate(self, self.OnClickBtnGo)
    btnData.disableClick = Delegate.GetOrCreate(self,self.OnBtnDisableGotoClicked)
    if data.listParam.joinAssembleTeam then
        btnData.buttonText = I18N.Get("alliance_team_jiaru")
    else
        btnData.buttonText = I18N.Get("alliance_team")
    end
    
    btnData.buttonState = BistateButton.BUTTON_TYPE.RED

    local player = ModuleRefer.PlayerModule:GetPlayer()
    self.curPPP = player and player.PlayerWrapper2.Radar.PPPCur or 0
    self.costPPP = ModuleRefer.SlgModule:GetAssembleStaminaCost(data.listParam.trusteeshipRule, data.listItem.joinAssembleTeam)
    self.curItem = 0
    self.costItem = 0

    local captainId
    local targetId
    local troopIndex
    if data.listParam.joinAssembleTeam then
        local team = ModuleRefer.AllianceModule:GetMyAllianceAllianceTeamInfoByTeamId(data.listParam.joinAssembleTeam)
        captainId = team.CaptainId
        targetId = team.TargetInfo.Id
    else
        captainId = ModuleRefer.PlayerModule:GetPlayerId()
        targetId = data.listParam.entity.ID
    end
    troopIndex = self._parameter.listItem.index
    self._checkPreFetchKey = self._parameter.listItem.preFetchCache:MakeKey(captainId, targetId, troopIndex)
    self._preFetchTimeInfo = self._parameter.listItem.preFetchCache:FetchOrGetCache(captainId, targetId, troopIndex)
    self._preFetchTimeInfoError = false
    self._ppOk = true
    self._itemOk = true
    self._troopOk = HUDTroopUtils.CanCreateOrJoinAssemble(self.troopInfo)

    if self.costPPP and self.costPPP > 0 then
        btnData.icon = "sp_comp_icon_shape"
        btnData.num1 = self.costPPP
        btnData.num2 = self.curPPP
        self._ppOk = self.curPPP >= self.costPPP
    end

    local itemId, itemCount = ModuleRefer.SlgModule:GetAssembleItemCost(self._parameter.listParam.trusteeshipRule, self._parameter.listItem.joinAssembleTeam)
    if itemId > 0 and itemCount > 0 then
        self.curItem = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
        self.costItem = itemCount

        local item = ModuleRefer.InventoryModule:GetConfigByConfigId(itemId)
        btnData.icon = item and item:Icon() or ""
        btnData.num1 = self.costItem
        btnData.num2 = self.curItem
        self._itemOk = self.curItem >= self.costItem
    end

    self._p_btn_goto:FeedData(btnData)

    self:OnSelectTimeCell(self._selectedIndex)

    if self.preset then
        for i = 1, #self._p_heroes do
            if self.preset.Heroes[i] then
                local heroCfg = ModuleRefer.HeroModule:GetHeroByCfgId(self.preset.Heroes[i].HeroCfgID)
                if heroCfg then
                    ---@type HeroInfoData
                    local data = {}
                    data.heroData = heroCfg
                    self._p_heroes[i]:FeedData(data)
                else
                    self._p_heroes[i]:SetVisible(false)
                end
            else
                self._p_heroes[i]:SetVisible(false)
            end
        end

        for i = 1, #self._p_pets do
            local hero = self.preset.Heroes[i]
            if hero and hero.PetCompId and hero.PetCompId > 0 then
                local pet = ModuleRefer.PetModule:GetPetByID(hero.PetCompId)
                self._p_pets[i]:FeedData({id = hero.PetCompId, cfgId = pet.ConfigId, level = pet.Level})
            else
                self._p_pets[i]:SetVisible(false)
            end
        end
    end

    self._p_choose_time:SetVisible(nil == data.listParam.joinAssembleTeam)
    self._noHeavyInjured = not SlgUtils.PresetAllHeroInjured(self.preset, ModuleRefer.SlgModule.battleMinHpPct)

    self:RefreshTime()
    self:RefreshBtn()
end

function HUDSelectTroopBattleAssemblyTipComponent:RefreshBtn()
    self._p_btn_goto:SetEnabled(self._itemOk and self._ppOk and self._troopOk and self._timeOk and self._leftTimeOk and self._noHeavyInjured)
end

function HUDSelectTroopBattleAssemblyTipComponent:SetUpTimeCell()
    for i, v in pairs(self._timeCellBts) do
        UIHelper.DeleteUIGameObject(v.go)
    end

    table.clear(self._timeCellBts)
    self._p_btn_time_template:SetVisible(true)
    local logicRoot = self
    local assembleWaitTimes = ModuleRefer.SlgModule:GetCustomAssembleWaitTimes(self._parameter.listParam.trusteeshipRule)
    for i, time in ipairs(assembleWaitTimes) do
        local go = UIHelper.DuplicateUIGameObject(self._p_btn_time_template, self._p_choose_time)
        ---@type TimeSelectCell
        local cellInfo = {}
        cellInfo.time = time
        cellInfo.go = go
        cellInfo.btn = self:ButtonImp(go:GetComponent(typeof(CS.UnityEngine.UI.Button)), function()
            logicRoot:OnSelectTimeCell(i)
        end)
        cellInfo.normalRoot = go.transform:Find("p_status_n").gameObject
        cellInfo.selectedRoot = go.transform:Find("p_status_selected").gameObject
        local timeText_N = cellInfo.normalRoot.transform:Find("p_text_time_n"):GetComponent(typeof(CS.UnityEngine.UI.Text))
        local timerStr = TimeFormatter.TimerStringFormat(cellInfo.time)
        if timeText_N then
            timeText_N.text = timerStr
        end
        local timeText_S = cellInfo.selectedRoot.transform:Find("p_text_time_selected"):GetComponent(typeof(CS.UnityEngine.UI.Text))
        if timeText_S then
            timeText_S.text = timerStr
        end
        table.insert(self._timeCellBts, cellInfo)
    end

    self._p_btn_time_template:SetVisible(false)

    ---@type CS.UnityEngine.UI.MaskableGraphic[]
    local graphics = self:GameObject(""):GetComponentsInChildren(typeof(CS.UnityEngine.UI.MaskableGraphic), true)
    for i = 0, graphics.Length - 1 do
        -- 2024.03.29 之前部队做了滑动，tips需要跟着滑动但不能被裁切掉，现在部队不会滑动，ue要求下面这行注释掉
        -- graphics[i].maskable = false
    end
end

function HUDSelectTroopBattleAssemblyTipComponent:OnSelectTimeCell(index)
    for i = 1, #self._timeCellBts do
        self._timeCellBts[i].selectedRoot:SetVisible(i == index)
        self._timeCellBts[i].normalRoot:SetVisible(i ~= index)
    end
    self._selectedIndex = index
    self:RefreshTime()
    self:RefreshBtn()
end

function HUDSelectTroopBattleAssemblyTipComponent:OnClickBtnGo()
    self._parameter.onGotoButtonClicked(self._timeCellBts[self._selectedIndex].time)
end

function HUDSelectTroopBattleAssemblyTipComponent:OnBtnDisableGotoClicked()
    if self.curPPP < self.costPPP then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_tilibuzu"))
    elseif not self._timeOk then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_Pathfinding_failed"))
    elseif not self._leftTimeOk then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("WorldExpedition_info_Not_enough_time"))
    elseif self.curItem < self.costItem then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('errCode_23001'))
    elseif not self._noHeavyInjured then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('toast_hp0_march_alert'))
    elseif not self._troopOk then
        local _, error = HUDTroopUtils.CanCreateOrJoinAssemble(self.troopInfo)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("toast_team_busy", I18N.Get(error)))
    end
end

function HUDSelectTroopBattleAssemblyTipComponent:RefreshTime()
    self._timeOk = false
    self._leftTimeOk = false
    if self._preFetchTimeInfo then
        self._timeOk = true
        local preFetchTime = math.ceil(self._preFetchTimeInfo.CostTimeSec + ConfigRefer.ConstMain:SlgTeamTrusteeshipTroopCostTimeBackoff())
        self._p_text_march_time_value.text = ("%ds"):format(preFetchTime)
        local assembleTime = 0
        if self._parameter.listParam.joinAssembleTeam then
            local team = ModuleRefer.AllianceModule:GetMyAllianceAllianceTeamInfoByTeamId(self._parameter.listParam.joinAssembleTeam)
            if team then
                assembleTime = team.StartTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
            end
        else
            assembleTime = self._timeCellBts[self._selectedIndex].time
        end
        if preFetchTime < assembleTime then
            self._leftTimeOk = true
        end
    elseif self._preFetchTimeInfoError then
        self._p_text_march_time_value.text = "--:--"
    else
        self._p_text_march_time_value.text = I18N.Get("alliance_team_jisuan")
    end
end

function HUDSelectTroopBattleAssemblyTipComponent:OnTimePreFetch(key, info)
    if self._checkPreFetchKey ~= key then
        return
    end
    self._preFetchTimeInfo = info
    self._preFetchTimeInfoError = false
    self:RefreshTime()
    self:RefreshBtn()
end

function HUDSelectTroopBattleAssemblyTipComponent:OnTimePreFetchFailed(key, errorCode)
    if self._checkPreFetchKey ~= key then
        return
    end
    self._preFetchTimeInfo = nil
    self._preFetchTimeInfoError = true
    self:RefreshTime()
    self:RefreshBtn()
end

function HUDSelectTroopBattleAssemblyTipComponent:Tick(dt)
    if not self._parameter or not self._parameter.listParam.joinAssembleTeam or not self._preFetchTimeInfo or not self._timeOk or not self._leftTimeOk then
        return
    end
    self:RefreshTime()
    self:RefreshBtn()
end

function HUDSelectTroopBattleAssemblyTipComponent:LateUpdateKeepInRange()
    local rect = self._selfRect.rect
    local recMin = rect.min
    local worldMin = self._selfRect:TransformPoint(CS.UnityEngine.Vector3(recMin.x, recMin.y))
    local UICamera = g_Game.UIManager:GetUICamera()
    local screenMinPos = UICamera:WorldToScreenPoint(worldMin)
    if screenMinPos.y > 1 then
        local p = self._selfRect.anchoredPosition
        if math.abs(p.y) < 0.01 then
            return
        end
        if p.y < 0 then
            p.y = 0
            self._selfRect.anchoredPosition = p
            return
        end
    end
    screenMinPos.y = 1
    local parentLocalMin = self._selfRect.parent:InverseTransformPoint(worldMin)
    worldMin = UICamera:ScreenToWorldPoint(screenMinPos)
    local localPos = self._selfRect.parent:InverseTransformPoint(worldMin)
    local oldPos = self._selfRect.anchoredPosition
    oldPos.y = oldPos.y + (localPos.y - parentLocalMin.y)
    self._selfRect.anchoredPosition = oldPos

    local arrowPos = self._p_arrow_2.transform.localPosition
    arrowPos.y = self._parameter.arrowPosY
    self._p_arrow_2.transform.localPosition = arrowPos
end

return HUDSelectTroopBattleAssemblyTipComponent