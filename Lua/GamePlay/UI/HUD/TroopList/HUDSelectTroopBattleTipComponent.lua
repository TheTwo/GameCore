
local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local Utils = require('Utils')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local DBEntityType = require('DBEntityType')
local SlgBattlePowerHelper = require('SlgBattlePowerHelper')
local TimeFormatter = require("TimeFormatter")
local SlgUtils = require("SlgUtils")

---@class HUDSelectTroopBattleTipComponent : BaseUIMediator
local HUDSelectTroopBattleTipComponent = class("HUDSelectTroopBattleTipComponent",BaseUIComponent)

---@type CS.UnityEngine.Vector3[]
local fourCornersArray = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Vector3), 4)

function HUDSelectTroopBattleTipComponent:ctor()
    BaseUIComponent.ctor(self)
    self._eventAdd = false
end

function HUDSelectTroopBattleTipComponent:OnCreate(param)
    self._selfRect = self:RectTransform("")
    --battle tips components
    self.goItemTips = self:GameObject('p_item_tips')
    --BattleTips: troop info
    self.goContent = self:GameObject('content')
    self.textPowerLable = self:Text('p_text_my_power_lable')
    self.textPower = self:Text('p_text_my_power_value')
    self.goRecommandGroup = self:GameObject("group_recommand")
    self.textRecommendLable = self:Text('p_text_recommend_lable')
    self.textRecommand = self:Text('p_text_recommend_value')
    --BattleTips: compare info
    self.goCompare = self:GameObject('p_status')
    self.textCompare = self:Text('p_text_status')
    self.iconCompare = self:Image('p_icon_status_1')
    --BattleTips: goto button
    ---@type BistateButton
    self.btnGoto = self:LuaObject('p_btn_goto')
	self.backText = self:Text("p_text_back", "autoback_introducing")
	---@type CS.StatusRecordParent
	self.backToggle = self:BindComponent("p_back_toggle", typeof(CS.StatusRecordParent))
	self.backToggleButton = self:Button("p_back_toggle", Delegate.GetOrCreate(self, self.OnBackToggleClick))

    -- Escrow 托管部分
    self._p_choose = self:GameObject("p_choose")

    self._p_text_title_choose = self:Text("p_text_title_choose", "village_info_Select_agent")

    self._p_group_troop = self:GameObject("p_group_troop")
    self._p_text_title_troop = self:Text("p_text_title_troop", "village_info_proxy_defender")
    self._p_text_title_expired_troop = self:Text("p_text_title_expired_troop", "village_info_expired")
    self._p_img_select_troop = self:GameObject("p_img_select_troop")
    ---@type HUDSelectTroopBattleTipEscrowToggle
    self._child_toggle_troop = self:LuaObject("child_toggle_dot")

    self._p_group_village = self:GameObject("p_group_village")
    self._p_text_title_village = self:Text("p_text_title_village")
    self._p_text_title_expired_village = self:Text("p_text_title_expired_village", "village_info_expired")
    self._p_img_select_village = self:GameObject("p_img_select_village")
    ---@type HUDSelectTroopBattleTipEscrowToggle
    self._child_toggle_village = self:LuaObject("child_toggle_village")

    self._p_info = self:GameObject("p_info")
    self._p_text_info = self:Text("p_text_info", "village_info_proxy")
    self._p_text_time = self:Text("p_text_time")
    self._p_text_time_1 = self:Text("p_text_time_1")
    self._p_text_position = self:Text("p_text_position")
    self._p_text_position_1 = self:Text("p_text_position_1")
    self._p_agency = self:GameObject("p_agency")
    ---@type HUDSelectTroopBattleTipEscrowToggle
    self._child_toggle_agency = self:LuaObject("child_toggle_agency")
    self._p_text_agency = self:Text("p_text_agency", "village_info_proxy_acting")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickEscrowDetailInfo))
    
    self._p_group_collect = self:GameObject("p_group_collect")
    self._p_title_collect_num = self:Text("p_title_collect_num", "mining_info_collection_volume")
    self._p_text_collect_num = self:Text("p_text_collect_num")
    self._p_title_collect_time = self:Text("p_title_collect_time", "mining_info_collection_duration")
    self._p_text_collect_time = self:Text("p_text_collect_time")

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

    ---@type CS.UnityEngine.UI.MaskableGraphic[]
    local graphics = self:GameObject(""):GetComponentsInChildren(typeof(CS.UnityEngine.UI.MaskableGraphic), true)
    for i = 0, graphics.Length - 1 do
        -- 2024.03.29 之前部队做了滑动，tips需要跟着滑动但不能被裁切掉，现在部队不会滑动，ue要求下面这行注释掉
        -- graphics[i].maskable = false
    end
end

---@class HUDSelectTroopBattleTipParam
---@field listParam HUDSelectTroopListData
---@field troopHp number
---@field troopPower number
---@field troopCollectAmount number
---@field troopCollectTime number
---@field showAutoFinish boolean
---@field autoFinish boolean
---@field showBack boolean
---@field autoBack boolean
---@field disableGotoButton boolean
---@field onGotoButtonClicked fun(args:HUDSelectTroopListGoParameter|nil)
---@field onDisableGotoButtonClicked fun(args:HUDSelectTroopListGoParameter|nil)
---@field onBackToggleClicked fun()
---@field allowEscrow boolean
---@field chooseEscrow boolean
---@field escrowType wds.CreateAllianceAssembleType
---@field onEscrowTypeChanged fun(escrowType:wds.CreateAllianceAssembleType)
---@field onEscrowToggleChanged fun(isOn:boolean)
---@field selectedCount number
---@field selectedTroopIdxSet table<number, boolean>
---@field noEscrowChoice table<wds.CreateAllianceAssembleType, boolean>|nil
---@field preset wds.TroopPreset

---@param param HUDSelectTroopBattleTipParam
function HUDSelectTroopBattleTipComponent:OnFeedData(param)
    self.param = param.listParam
    self.troopHP = param.troopHp
    self.troopPower = param.troopPower
    self.troopCollectAmount = param.troopCollectAmount
    self.troopCollectTime = param.troopCollectTime

    self.showAutoFinish = param.showAutoFinish
    self.showBack = param.showBack
    self.autoBack = param.autoBack

    self.onGotoButtonClicked = param.onGotoButtonClicked
    self.onDisableGotoButtonClicked = param.onDisableGotoButtonClicked
    self.onBackToggleClicked = param.onBackToggleClicked
    self.allowEscrow = param.allowEscrow
    self.troopCount = param.selectedCount
    self.escrowType = param.escrowType
    self.noEscrowChoice = param.noEscrowChoice
    self.selectedTroopIdxSet = param.selectedTroopIdxSet
    self.onEscrowTypeChanged = param.onEscrowTypeChanged
    self.onEscrowToggleChanged = param.onEscrowToggleChanged
    self.chooseEscrow = self.allowEscrow and param.chooseEscrow
    self.disableGotoButton = param.disableGotoButton
    self.preset = param.preset
    self:SetupInfo()
end

function HUDSelectTroopBattleTipComponent:SetupInfo()

    local hasComparePower = self.param.needPower
        and self.param.recommendPower
        and self.param.needPower > 0 and self.param.recommendPower > 0 and not self.param.isCollectingRes
    local canGo = true
    self.errorType = 0
    
    if Utils.IsNotNull(self._p_group_collect) then
        self._p_group_collect:SetVisible(self.param.isCollectingRes)
    end

    ---Power infos and Button status
    if self.param.catchPet then
        self.textPowerLable.text = I18N.Get('expedition_bubble')
        self.textRecommendLable.text = I18N.Get("expedition_recommendBubble")
        canGo = self.param.needPower > 0
        if not canGo then
            self.errorType = self.errorType | 1
        end
    elseif self.param.entity then
        if self.param.isSE then
            self.textPowerLable.text = I18N.Get('expedition_power')
            if hasComparePower then
                self.goRecommandGroup:SetVisible(true)
                self.textRecommendLable.text = I18N.Get('expedition_recommendPower')
            else
                self.goRecommandGroup:SetVisible(false)
            end
        else
            self.textPowerLable.text = I18N.Get('expedition_troops')
            if hasComparePower then
                self.goRecommandGroup:SetVisible(true)
                self.textRecommendLable.text = I18N.Get('expedition_recommendTroops')
            else
                self.goRecommandGroup:SetVisible(false)
            end
        end
    else
        self.textPowerLable.text = I18N.Get('expedition_power')
        if hasComparePower then
            self.goRecommandGroup:SetVisible(true)
            self.textRecommendLable.text = I18N.Get('expedition_recommendPower')
        else
            self.goRecommandGroup:SetVisible(false)
        end        
    end
    
    if self.param.catchPet then
        self.textPower.text = self.param.needPower
        self.goRecommandGroup:SetVisible(true)
        self.textRecommand.text = self.param.recommendPower
    elseif self.param.isCollectingRes then
        self.textPower.text = self.troopPower
        if self.troopCollectAmount <= 0 then
            self._p_text_collect_num.text = ("<color=red>%s</color>"):format(self.troopCollectAmount)
        else
            self._p_text_collect_num.text = tostring(self.troopCollectAmount)
        end
        self._p_text_collect_time.text = TimeFormatter.SimpleFormatTime(self.troopCollectTime)
    else
        self.textPower.text = self.troopPower
        if hasComparePower then
            self.goRecommandGroup:SetVisible(true)
            self.textRecommand.text = self.param.recommendPower
        else
            self.goRecommandGroup:SetVisible(false)
        end
    end
    
    ---Power compare infos
    if not hasComparePower then        
        self.goCompare:SetVisible(false)
    else                
        self.goCompare:SetVisible(true)
        
        local compareResult = 0
        if self.param.catchPet then
            compareResult = self.param.needPower >= self.param.recommendPower and 1 or 2
        else
            compareResult = SlgBattlePowerHelper.ComparePower(self.troopPower,self.param.needPower,self.param.recommendPower)
        end
        
        g_Game.SpriteManager:LoadSprite(SlgBattlePowerHelper.GetPowerCompareIcon(compareResult),self.iconCompare)        
        self.textCompare.text = SlgBattlePowerHelper.GetPowerCompareTipString(compareResult,self.param.catchPet)
    end

    ---Goto button infos
    ---@type BistateButtonParameter
    local buttonParam = {}
    if self.param.costPPP and self.param.costPPP > 0 then
        local player = ModuleRefer.PlayerModule:GetPlayer()               
        local curPPP = player and player.PlayerWrapper2.Radar.PPPCur or 0
        if canGo then
            canGo = curPPP >= self.param.costPPP
        end
        if curPPP < self.param.costPPP then
            self.errorType = self.errorType | 2
        end
        buttonParam.icon = "sp_comp_icon_shape"
        buttonParam.num1 = self.param.costPPP
        buttonParam.num2 = curPPP
    end
    local isInCity = ModuleRefer.SlgModule:IsInCity()

    --Check troop Hp
    if SlgUtils.PresetAllHeroInjured(self.preset, ModuleRefer.SlgModule.battleMinHpPct) then
        canGo = false
        self.errorType = self.errorType | 4
    end
    if self.chooseEscrow then
        if not self.escrowType then
            canGo = false
            self.errorType = self.errorType | 8
        end
    end
    if self.param.isCollectingRes then
        canGo = ModuleRefer.MapResourceFieldModule:CheckCollectTimes()
    end
    
    if isInCity and self.param.catchPet then
        buttonParam.buttonText = I18N.Get("setips_btn_catch")
    elseif isInCity and self.param.isSE then
        buttonParam.buttonText = I18N.Get("circlemenu_joinbattle")
    elseif self.param.isCollectingRes then
        buttonParam.buttonText = I18N.Get("mining_info_collection")
    else
        buttonParam.buttonText = I18N.Get("circlemenu_setoff")
    end
    buttonParam.onClick = Delegate.GetOrCreate(self,self.OnBtnGotoClicked)
    buttonParam.disableClick = Delegate.GetOrCreate(self,self.OnBtnDisableGotoClicked)
    self.btnGoto:FeedData(buttonParam)
    if self.disableGotoButton then
        self.btnGoto:SetEnabled(false)
    else
        self.btnGoto:SetEnabled(canGo)
    end
    ---setup auto back toggle
    if (self.showBack or self.showAutoFinish ) then
		self.backText.gameObject:SetActive(true)		
        if self.showAutoFinish then
            self.backText.text = I18N.Get("autofinish_introducing")
        elseif self.param.isCollectingRes then
            self.backText.text = I18N.Get("mining_info_auto_back")
        else
            self.backText.text = I18N.Get("autoback_introducing")
        end
	else
		self.backText.gameObject:SetActive(false)
	end

    if self.preset then
        for i = 1, #self._p_heroes do
            if self.preset.Heroes[i] then
                local heroCfg = ModuleRefer.HeroModule:GetHeroByCfgId(self.preset.Heroes[i].HeroCfgID)
                self._p_heroes[i]:SetVisible(true)
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
                self._p_pets[i]:SetVisible(true)
                local pet = ModuleRefer.PetModule:GetPetByID(hero.PetCompId)
                self._p_pets[i]:FeedData({id = hero.PetCompId,
                cfgId = pet.ConfigId,
                level = pet.Level})
            else
                self._p_pets[i]:SetVisible(false)
            end
        end
    end

    self:SetupAutoBackToggle(self.autoBack)
    self:SetupAllowEscrowTip(self.allowEscrow, buttonParam, self.noEscrowChoice)
end

function HUDSelectTroopBattleTipComponent:SetupAutoBackToggle(autoBack)
    if not self.showBack and not self.showAutoFinish then
        return
    end
    if autoBack then
        self.backToggle:ApplyStatusRecord(1)
    else
        self.backToggle:ApplyStatusRecord(0)
    end
end

function HUDSelectTroopBattleTipComponent:GetChooseTroopLimitCount()
    return 1
end

function HUDSelectTroopBattleTipComponent:GetChooseVillageLimitCount()
    return 1
end

---@return wds.VillageAllianceWarInfo|nil
function HUDSelectTroopBattleTipComponent:GetEscrowTargetInfo()
    if not self.param or not self.param.entity then
        return nil
    end
    local typeHash = self.param.entity.TypeHash
    local villageWarInfos
    if typeHash == DBEntityType.Village or typeHash == DBEntityType.Pass then
        villageWarInfos  = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
    elseif typeHash == DBEntityType.BehemothCage then
        villageWarInfos = ModuleRefer.AllianceModule:GetMyAllianceBehemothCageWar()
    end
    if not villageWarInfos then return nil end
    for _, v in pairs(villageWarInfos) do
        if v.VillageId == self.param.entity.ID then
            return v
        end
    end
    return nil
end

---@param info wds.VillageAllianceWarInfo|nil
---@return number|nil
function HUDSelectTroopBattleTipComponent:GetEscrowTargetStartTime(info)
    if not info then
        return nil
    end
    return info.StartTime
end

---@param escrowType number @wds.CreateAllianceAssembleType
---@return number, number @all,selectedInCount
function HUDSelectTroopBattleTipComponent:GetTargetHasEscrowTypeCount(escrowType, selectedIdxSet)
    if not self.param or not self.param.entity then
        return 0,0
    end
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData then
        return 0,0
    end
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    local assembleInfo = allianceData.AllianceAssembleInfo.TargetAssembleInfo
    local count = 0
    local selectedInCount = 0
    for _, v in pairs(assembleInfo) do
        if v.TargetInfo.Id == self.param.entity.ID then
            for _, p in pairs(v.PlayerInfos) do
                if p.PlayerInfo.PlayerId == myPlayerId then
                    local countMap = {}
                    for _, troopInfo in pairs(p.TroopInfo) do
                        --这里数据可敬重复 排除重复
                        if not countMap[troopInfo.QueueIndex] then
                            countMap[troopInfo.QueueIndex] = true
                            if troopInfo.Type == escrowType then
                                count = count + 1
                                if selectedIdxSet and selectedIdxSet[troopInfo.QueueIndex+1] then
                                    selectedInCount = selectedInCount + 1
                                end
                            end
                        end
                    end
                    return count, selectedInCount
                end
            end
        end
    end
    return 0,0
end

function HUDSelectTroopBattleTipComponent:SetupAllowEscrowTip(allow, buttonParam, noEscrowChoice)
    self._p_agency:SetVisible(false) --(allow) 托管战斗功能不要了
    
    self._p_choose:SetVisible(allow and self.chooseEscrow)
    self._p_info:SetVisible(allow and self.chooseEscrow)

    local battleTroopIsExpired = false
    local battleVillageIsExpired = false

    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local targetVillageInfo = self:GetEscrowTargetInfo()
    if targetVillageInfo then
        battleTroopIsExpired = targetVillageInfo.Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder or nowTime >= targetVillageInfo.EndTime
        battleVillageIsExpired = targetVillageInfo.Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction or nowTime >= targetVillageInfo.EndTime
    end
    if battleTroopIsExpired and self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack then
        self.escrowType = nil
        self:OnEscrowToggleChooseTroop(false)
        if self.onEscrowTypeChanged then
            self.onEscrowTypeChanged(self.escrowType)
        end
    end
    if battleVillageIsExpired and self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability then
        self.escrowType = nil
        self:OnEscrowToggleChooseTroop(false)
        if self.onEscrowTypeChanged then
            self.onEscrowTypeChanged(self.escrowType)
        end
    end

    self._p_img_select_troop:SetVisible(self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack)
    self._p_img_select_village:SetVisible(self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability)
    local setPos = false
    if self.param.entity then
        if self.param.entity.TypeHash == DBEntityType.Village or self.param.entity.TypeHash == DBEntityType.Pass then
            local mapBuilding = ConfigRefer.FixedMapBuilding:Find(self.param.entity.MapBasics.ConfID)
            if mapBuilding then
                setPos = true
                self._p_text_position.text = ("Lv.%s %s"):format(mapBuilding:Level(), I18N.Get(mapBuilding:Name()))
                self._p_text_position_1.text = ("X:%s,Y:%s"):format(math.floor(self.param.entity.MapBasics.Position.X), math.floor(self.param.entity.MapBasics.Position.Y))
            end
        elseif self.param.entity.TypeHash == DBEntityType.BehemothCage then
            local mapBuilding = ConfigRefer.FixedMapBuilding:Find(self.param.entity.BehemothCage.ConfigId)
            if mapBuilding then
                setPos = true
                self._p_text_position.text = ("Lv.%s %s"):format(mapBuilding:Level(), I18N.Get(mapBuilding:Name()))
                self._p_text_position_1.text = ("X:%s,Y:%s"):format(math.floor(self.param.entity.MapBasics.Position.X), math.floor(self.param.entity.MapBasics.Position.Y))
            end
        end
    end

    local escrowOnTroopCount = 0
    local escrowOnVillageCount = 0
    if self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability then
        local a,b = self:GetTargetHasEscrowTypeCount(self.escrowType, self.selectedTroopIdxSet)
        escrowOnVillageCount = self.troopCount + a - b
    elseif self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack then
        local a,b = self:GetTargetHasEscrowTypeCount(self.escrowType, self.selectedTroopIdxSet)
        escrowOnTroopCount = self.troopCount + a - b
    end
    
    local limitOnTroop = self:GetChooseTroopLimitCount()
    local limitOnVillage = self:GetChooseVillageLimitCount()
    if escrowOnTroopCount > limitOnTroop then
        self._p_text_title_troop.text = I18N.GetWithParams("village_info_efender", ("(<color=red>%d</color>/%d)"):format(escrowOnTroopCount, limitOnTroop))
    else
        self._p_text_title_troop.text = I18N.GetWithParams("village_info_efender", ("(%d/%d)"):format(escrowOnTroopCount, limitOnTroop))
    end
    if escrowOnVillageCount > limitOnVillage then
        self._p_text_title_village.text = I18N.GetWithParams("village_info_defense", ("(<color=red>%d</color>/%d)"):format(escrowOnVillageCount, limitOnVillage))
    else
        self._p_text_title_village.text = I18N.GetWithParams("village_info_defense", ("(%d/%d)"):format(escrowOnVillageCount, limitOnVillage)) 
    end

    self._p_text_title_expired_troop:SetVisible(battleTroopIsExpired)
    self._p_text_title_expired_village:SetVisible(battleVillageIsExpired)
    if allow and self.chooseEscrow then
        if self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability then
            if escrowOnVillageCount > limitOnVillage then
                buttonParam.buttonText = I18N.Get("village_info_limit_exceeded")
                self.btnGoto:FeedData(buttonParam)
                self.btnGoto:SetEnabled(false)
            elseif battleVillageIsExpired then
                self.btnGoto:SetEnabled(false)
            end
        elseif self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack then
            if escrowOnTroopCount > limitOnTroop then
                buttonParam.buttonText = I18N.Get("village_info_limit_exceeded")
                self.btnGoto:FeedData(buttonParam)
                self.btnGoto:SetEnabled(false)
            elseif battleTroopIsExpired then
                self.btnGoto:SetEnabled(false)
            end
        end 
    end

    ---@type HUDSelectTroopBattleTipEscrowToggleData
    local escrowToggleData = {}
    escrowToggleData.isOn = self.chooseEscrow
    escrowToggleData.onToggleChanged = Delegate.GetOrCreate(self, self.OnSwitchChooseEscrow)
    self._child_toggle_agency:FeedData(escrowToggleData)
    
    ---@type HUDSelectTroopBattleTipEscrowToggleData
    local chooseTroopToggleData = {}
    chooseTroopToggleData.isOn = self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack
    chooseTroopToggleData.onToggleChanged = Delegate.GetOrCreate(self, self.OnEscrowToggleChooseTroop)
    self._child_toggle_troop:FeedData(chooseTroopToggleData)

    ---@type HUDSelectTroopBattleTipEscrowToggleData
    local chooseVillageToggleData = {}
    chooseVillageToggleData.isOn = self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability
    chooseVillageToggleData.onToggleChanged = Delegate.GetOrCreate(self, self.OnEscrowToggleChooseVillage)
    self._child_toggle_village:FeedData(chooseVillageToggleData)
    self._p_choose:SetVisible(self.allowEscrow and table.isNilOrZeroNums(noEscrowChoice))
    
    local startTime = self:GetEscrowTargetStartTime(targetVillageInfo)
    if not startTime then
        self._p_text_time:SetVisible(false)
        self._p_text_time_1:SetVisible(false)
    else
        self._p_text_time:SetVisible(true)
        self._p_text_time.text = ("UTC %s"):format(TimeFormatter.TimeToDateTimeStringUseFormat(startTime, "HH:mm:ss"))
        self._p_text_time_1:SetVisible(true)
        self._p_text_time_1.text = TimeFormatter.TimeToDateTimeStringUseFormat(startTime, "yyyy/MM/dd")
    end
end

function HUDSelectTroopBattleTipComponent:OnSwitchChooseEscrow(isOn)
    self.chooseEscrow = isOn
    if self.onEscrowToggleChanged then
        self.onEscrowToggleChanged(isOn)
    end
    self:SetupInfo()
end

function HUDSelectTroopBattleTipComponent:OnEscrowToggleChooseTroop(isOn, skipRefresh)
    if isOn and self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack then
        return
    end
    if not isOn and self.escrowType ~= wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack then
        return
    end
    if isOn then
        self.escrowType = wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack
    else
        self.escrowType = wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability
    end
    if isOn then
        self._child_toggle_village:SetToggle(false)
    end
    if skipRefresh then
        return
    end
    self:SetupInfo()
    if self.onEscrowTypeChanged then
        self.onEscrowTypeChanged(self.escrowType)
    end
end

function HUDSelectTroopBattleTipComponent:OnEscrowToggleChooseVillage(isOn, skipRefresh)
    if isOn and self.escrowType == wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability then
        return
    end
    if not isOn and self.escrowType ~= wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability then
        return
    end
    if isOn then
        self.escrowType = wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability
    else
        self.escrowType = wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack
    end
    if isOn then
        self._child_toggle_troop:SetToggle(false)
    end
    if skipRefresh then
        return
    end
    self:SetupInfo()
    if self.onEscrowTypeChanged then
        self.onEscrowTypeChanged(self.escrowType)
    end
end

function HUDSelectTroopBattleTipComponent:OnBtnGotoClicked()
    if self.onGotoButtonClicked then
        ---@type HUDSelectTroopListGoParameter
        local args = {}
        args.isEscrow = self.chooseEscrow
        args.escrowType = self.escrowType
        self.onGotoButtonClicked(args)
    end
end

function HUDSelectTroopBattleTipComponent:OnBtnDisableGotoClicked()
    if self.errorType & 2 > 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_tilibuzu"))
    elseif self.errorType & 4 > 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("toast_hp0_march_alert"))
    elseif self.errorType & 1 > 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('rpp_des_pet'))
    end
    if not ModuleRefer.MapResourceFieldModule:CheckCollectTimes() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('mine_toast_today_max'))
    end
    if self.onDisableGotoButtonClicked then
        self.onDisableGotoButtonClicked()
    end
end

function HUDSelectTroopBattleTipComponent:OnBackToggleClick()
    if self.onBackToggleClicked then
        self.onBackToggleClicked()
    end
end

function HUDSelectTroopBattleTipComponent:OnShow(param)
    self:SetupEvents(true)
end

function HUDSelectTroopBattleTipComponent:OnHide(param)
    self:SetupEvents(false)
end

function HUDSelectTroopBattleTipComponent:OnClose(data)
    self:SetupEvents(false)
end

function HUDSelectTroopBattleTipComponent:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateKeepInRange))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateKeepInRange))
    end
end

function HUDSelectTroopBattleTipComponent:LateUpdateKeepInRange()
    self._selfRect:GetWorldCorners(fourCornersArray)
    local uiCamera = g_Game.UIManager:GetUICamera()
    local lt = uiCamera:WorldToViewportPoint(fourCornersArray[1])
    local yChange = 0
    if lt.y > 1 then
        lt.y = 1
        local wp = uiCamera:ViewportToWorldPoint(lt)
        yChange = wp.y - fourCornersArray[1].y
    else
        local lb = uiCamera:WorldToViewportPoint(fourCornersArray[0])
        if lb.y < 0 then
            lb.y = 0
            local wp = uiCamera:ViewportToWorldPoint(lb)
            yChange = wp.y - fourCornersArray[0].y
        end
    end

    if math.abs(yChange) > 0.001 then
        local wp = self._selfRect.position
        wp.y = wp.y + yChange
        self._selfRect.position = wp
    end
end

function HUDSelectTroopBattleTipComponent:OnClickEscrowDetailInfo()
    ---@type TextToastMediatorParameter
    local param = {}
    if self.param and self.param.entity and self.param.entity.TypeHash == DBEntityType.BehemothCage then
        param.content = I18N.Get("alliance_behemoth_rule_Automatpoints")
    else
        param.content = I18N.Get("village_tips_proxy")
    end
    param.clickTransform = self._p_btn_detail:GetComponent(typeof(CS.UnityEngine.RectTransform))
    ModuleRefer.ToastModule:ShowTextToast(param)
end

return HUDSelectTroopBattleTipComponent