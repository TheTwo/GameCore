---scene:scene_slg_popup_troop

local BaseUIMediator = require('BaseUIMediator')
local UIMediatorNames = require('UIMediatorNames')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local DBEntityType = require('DBEntityType')
local I18N = require('I18N')
local RPPType = require('RPPType')
local SlgBattlePowerHelper = require('SlgBattlePowerHelper')
local HUDSelectTroopAssembleTimePreFetch = require("HUDSelectTroopAssembleTimePreFetch")
local TimeFormatter = require("TimeFormatter")
local HUDLogicPartDefine = require("HUDLogicPartDefine")
local HUDTroopUtils = require("HUDTroopUtils")

---@class HUDSelectTroopList : BaseUIMediator
local HUDSelectTroopList = class("HUDSelectTroopList",BaseUIMediator)

---@class HUDSelectTroopListGoParameter
---@field isEscrow boolean
---@field escrowType wds.CreateAllianceAssembleType

function HUDSelectTroopList:OnCreate(param)
    self.textTroopList = self:Text('p_text_troop_list', I18N.Get("circlemenu_sendtroop"))
    self.tableviewproTroopList = self:TableViewPro('p_troop_list')
    self.goCheck = self:GameObject('p_check')
    ---@type CS.StatusRecordParent
    self.statusrecordparentChildToggleSet = self:BindComponent('child_toggle_set', typeof(CS.StatusRecordParent))
    self.btnChildToggleSet = self:Button('child_toggle_set', Delegate.GetOrCreate(self, self.OnBtnChildToggleSetClicked))    
    self.goCheck:SetActive(false)

    --Tip Component
    self.goCheckTip = self:GameObject('p_item_tips_check')
    ---@type HUDSelectTroopBattleTipComponent
    self.compCheckTip = self:LuaObject('p_item_tips_check')
    self.goCheckTip:SetActive(false)

    self.btnSet = self:Button('p_btn_set', Delegate.GetOrCreate(self, self.OnSetClicked))

    self._preFetchTargetHelper = HUDSelectTroopAssembleTimePreFetch.new()
end

---@class HUDSelectTroopListData
---@field tile MapRetrieveResult
---@field entity table
---@field purpose wrpc.MovePurpose
---@field isSE boolean
---@field catchPet boolean
---@field tid number @MapInstanceConfigCell:Id()
---@field interactorId number @wds.SlgInteractor.Id
---@field isPersonalInteractor boolean
---@field worldPetData table
---@field showAutoFinish boolean
---@field showBack boolean
---@field needPower number @最低战力需求，如果是抓宠则为抓宠物品拥有数量
---@field recommendPower number @推荐战力，如果是抓宠则为抓宠物品推荐数量
---@field costPPP number
---@field filter nil|fun(troopInfo:TroopInfo):boolean
---@field overrideItemClickGoFunc nil|fun(data:HUDSelectTroopListItemData)
---@field isAssemble boolean @是否是开启集结
---@field trusteeshipRule TeamTrusteeshipRuleConfigCell @集结配置
---@field isCollectingRes boolean @是否采集资源
---@field joinAssembleTeam number|nil @加入集结的teamId, nil 则是创建
---@field isEscrow boolean @是否是托管
---@field escrowToggleOn boolean
---@field noEscrowChoice table<wds.CreateAllianceAssembleType, boolean>|nil
---@field moveToPos CS.DragonReborn.Vector2Short|fun():CS.DragonReborn.Vector2Short|nil

---@param i number
---@param troop TroopInfo
---@param param HUDSelectTroopListData
---@param host HUDSelectTroopList
---@return HUDSelectTroopListItemData
function HUDSelectTroopList.MakeHUDSelectTroopListItemData(i, troop, param, host)
    ---@type HUDSelectTroopListItemData
    local data = {}
    data.index = i
    data.troopInfo = troop
    data.data = param
    data.troopList = host
    data.selected = false
    data.isAssemble = param.isAssemble
    data.isEscrow = param.isEscrow
    data.chooseEscrow = host and host._chooseEscrow
    data.escrowType = param.isEscrow and host and host._escrowType or nil
    data.noEscrowChoice = param.noEscrowChoice
    data.onSelectEscrowType = host and Delegate.GetOrCreate(host, host.OnSelectEscrowType)
    data.onToggleChooseEscrow = host and Delegate.GetOrCreate(host, host.OnToggleChooseEscrow)
    data.joinAssembleTeamId = param.joinAssembleTeam
    data.preFetchCache = host and host._preFetchTargetHelper
    return data
end

---@param param HUDSelectTroopListData
function HUDSelectTroopList:OnShow(param)
    self._preFetchTargetHelper:Init()
    ---@type HUDSelectTroopListItemData[]
    self.datas = {}
    self.targetParam = param

    if param.entity and ModuleRefer.PlayerModule:IsFriendly(param.entity.Owner) then
        param.needPower = -1
        param.recommendPower = -1
        param.costPPP = 0
    end

    self.needPower = param.needPower
    self.recommendPower = param.recommendPower
    local troops = ModuleRefer.SlgInterfaceModule:GetMyTroops(true) or {}
    self.tableviewproTroopList:Clear()
    self._escrowType = nil
    self._chooseEscrow = param.isEscrow and param.escrowToggleOn

    if param.isEscrow then
        self._escrowType = self:ChooseDefaultEscrowTypeByTargetInfo(param and param.entity and param.entity.ID, param and param.entity.TypeHash)
    end
    local troopCount = 0
    for i, troop in ipairs(troops) do
        if param.filter then
            if not param.filter(troop) then
                goto continue
            end
        end
        
        ---@type HUDSelectTroopListItemData
        local data = HUDSelectTroopList.MakeHUDSelectTroopListItemData(i, troop, param, self)
        self.datas[#self.datas + 1] = data
        self.tableviewproTroopList:AppendData(data)
        troopCount = troopCount + 1
        ::continue::
    end

    g_Game.EventManager:AddListener(EventConst.ON_SELECT_LEFT_TROOP, Delegate.GetOrCreate(self, self.OnClickTab))

    self:OnClickTab(self:GetDefaultTroopIndex())

    if HUDSelectTroopList.IsMultiSelectType(param) and troopCount > 1  then
        self.goCheck:SetActive(true)
        self.statusrecordparentChildToggleSet:Play(0)
    else
        self.goCheck:SetActive(false)
    end

    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.troopComp, false)
end

function HUDSelectTroopList.IsMultiSelectType(param)
    if param.isAssemble then
        return false
    end

    if param.isSE then
        return false
    end

    if param.isCollectingRes then
        return false
    end

    if param.tile == nil and param.entity == nil then
        return false
    end

    return true
end

function HUDSelectTroopList:OnHide(param)
    self._preFetchTargetHelper:Release()
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_LEFT_TROOP, Delegate.GetOrCreate(self, self.OnClickTab))
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.troopComp, true)
end

function HUDSelectTroopList:OnClickTab(index)
    if self.selectAll then
        self:OnBtnChildToggleSetClicked()
    end
    local hasSelected = false
    local dataIndex
    for i, data in ipairs(self.datas) do
        data.selected = data.index == index
        if data.index == index then
            dataIndex = i
            hasSelected = true
        end
    end
    if hasSelected then
        self.tableviewproTroopList:SetToggleSelect(self.datas[dataIndex])
    else
        self.tableviewproTroopList:UnSelectAll()
    end
end

function HUDSelectTroopList:OnItemMulitToggle(index,select)
    if not self.selectAll then return end    

    if select then
        self.datas[index].selected = true
        self.tableviewproTroopList:SetMultiSelect(self.datas[index])
    else
        self.datas[index].selected = false
        self.tableviewproTroopList:UnSelectMulti(self.datas[index])
    end

    if not select then
        local selectCount = 0
        local firstSelectIndex = -1
        for key, value in pairs(self.datas) do
            if value.selected then
                selectCount = selectCount + 1
                if firstSelectIndex < 0 then
                    firstSelectIndex = value.index
                end
            end
        end
        if selectCount <= 1 then
            if firstSelectIndex < 0 then
                firstSelectIndex = 1
            end
            self:OnClickTab(firstSelectIndex)
        end
    end
    if self.selectAll then
        self:SetupAllSelectTipInfo()
    end
end

function HUDSelectTroopList:OnBtnChildToggleSetClicked(args)
    if not self.selectAll then
        --Select All Presets
        self.selectAll = true        
        self.statusrecordparentChildToggleSet:Play(1)
        for key, value in pairs(self.datas) do
            if value.troopInfo.locked then
                value.selected = false
                self.tableviewproTroopList:UnSelectMulti(value)
            else
                local heroCfgID = ModuleRefer.TroopModule:GetPresetLeadHeroId(value.troopInfo.preset)
                if heroCfgID > 0 then
                    value.selected = true
                    self.tableviewproTroopList:SetMultiSelect(value)
                else
                    value.selected = false
                    self.tableviewproTroopList:UnSelectMulti(value)
                end
            end
        end
        
        self.goCheckTip:SetActive(true)
        self:SetupAllSelectTipInfo()           
    else
        self.selectAll = false
        self.statusrecordparentChildToggleSet:Play(0)
        for key, value in pairs(self.datas) do
            value.selected = false
        end
        self.tableviewproTroopList:UnSelectAll()
        self.goCheckTip:SetActive(false)        
        self:OnClickTab(self:GetDefaultTroopIndex())
    end 
end

function HUDSelectTroopList:SetupAllSelectTipInfo()
    if not self.targetParam  then return end    
    ---@type HUDSelectTroopBattleTipParam
    local tipCompData = {}
    tipCompData.listParam = self.targetParam
    -- 全选不显示自动回城按钮
    tipCompData.showBack = false
    tipCompData.onBackToggleClicked = nil
    tipCompData.onGotoButtonClicked = Delegate.GetOrCreate(self,self.OnAllSelectBtnGotoClicked)
    tipCompData.allowEscrow = self.targetParam.isEscrow
    tipCompData.selectedCount = 0
    tipCompData.selectedTroopIdxSet = {}
    tipCompData.noEscrowChoice = self.targetParam.noEscrowChoice
    tipCompData.chooseEscrow = self._chooseEscrow
    tipCompData.data = self.targetParam
    tipCompData.escrowType = self.targetParam.isEscrow and self._escrowType or nil
    local allPower = 0
    local allTroopHp = 0    
    local allCollectAmount = 0
    local collectTime = 0
    if self.datas and #self.datas > 0 then
        local myTroops = ModuleRefer.SlgInterfaceModule:GetMyTroops() or {}
        for key, value in pairs(self.datas) do
            if value.selected then
                local preset = value.troopInfo.preset
                local troopHp = ModuleRefer.SlgInterfaceModule:GetTroopHpByPreset(preset)
                local power = ModuleRefer.SlgInterfaceModule:GetTroopPowerByPreset(preset)
                allPower = allPower + power
                allTroopHp = allTroopHp + troopHp
              
                ---@type TroopInfo
                local troopInfo
                tipCompData.selectedCount = tipCompData.selectedCount + 1
                for index, v in pairs(myTroops) do
                    if v == value.troopInfo then
                        tipCompData.selectedTroopIdxSet[index] = true
                        troopInfo = v
                        break
                    end
                end

                local entity = self.targetParam.entity
                if entity and entity.TypeHash == DBEntityType.ResourceField then
                    local amount, time = ModuleRefer.MapResourceFieldModule:PrecalculateCollectInfo(troopInfo, preset, entity)
                    allCollectAmount = allCollectAmount + amount
                    collectTime = time
                end
            end
        end
    end
    tipCompData.troopPower = allPower
    tipCompData.troopHp = allTroopHp
    tipCompData.troopCollectAmount = allCollectAmount
    tipCompData.troopCollectTime = collectTime
    self.compCheckTip:FeedData(tipCompData)
end

---@param args HUDSelectTroopListGoParameter|nil
function HUDSelectTroopList:OnAllSelectBtnGotoClicked(args)
    ---Only SlgBattle
    ---Can not send mulit troops to SE
    local selectEntity = self.targetParam.entity
    local targetTile = self.targetParam.tile
    local purpose = self.targetParam.purpose    
    if (selectEntity or targetTile) then        		 
        local function GotoAction()
            local slgModule = ModuleRefer.SlgInterfaceModule    
            local petModule = ModuleRefer.PetModule    
            ---@type TroopData[]
            local troopDatas = {}
            for key, value in pairs(self.datas) do
                if value.selected then
                    local troopInfo = value.troopInfo
                    local troopCtrl = nil
                    if troopInfo.troopId then
                        petModule:UnwatchTroopForWorldPetCatch(troopInfo.troopId)   
                        troopCtrl = slgModule:GetTroopCtrl(troopInfo.troopId)
                    end

                    table.insert(troopDatas, {
                        troop = troopCtrl,   
                        presetIndex = value.index,
                    })
                end
            end
            if selectEntity then
                if args and args.isEscrow and args.escrowType then
                    local indexArray = {}
                    for i, v in ipairs(troopDatas) do
                        table.insert(indexArray, v.presetIndex)
                    end
                    slgModule:TroopEscrowToEntityViaData(nil, nil, selectEntity.ID, args.escrowType, indexArray, function(cmd, isSuccess, rsp)
                        if isSuccess then
                            if isSuccess then
                                local startTime = slgModule:GetTroopEscrowStartTimeByPresetIndex(indexArray[1]) or 0
                                local leftTime = startTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
                                if leftTime > 0 then
                                    ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("village_hosting_success_tips", TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)))
                                else
                                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("village_toast_hosting_success"))
                                end
                            end
                        end
                    end)
                else
                    slgModule:MoveTroopsToEntity(troopDatas,selectEntity.ID,purpose)
                end
            elseif targetTile then
                local coord = CS.DragonReborn.Vector2Short(targetTile.X, targetTile.Z)
                slgModule:MoveTroopsToCoord(troopDatas,coord,purpose)
            end
        end          
      
        local allPower = 0        
        if self.datas and #self.datas > 0 then
            for key, value in pairs(self.datas) do
                if value.selected then
                    allPower = allPower + ModuleRefer.SlgInterfaceModule:GetTroopPowerByPreset(value.troopInfo.preset)                          
                end
            end
        end

        local compareResult = SlgBattlePowerHelper.ComparePower(allPower,self.targetParam.needPower,self.targetParam.recommendPower)        
        if compareResult == 2 then
            SlgBattlePowerHelper.ShowRaisePowerPopup( RPPType.Slg,GotoAction)
        else
            GotoAction()
        end
        
	end
    self:CloseSelf()
end

function HUDSelectTroopList:OnSelectEscrowType(type)
    self._escrowType = type
end

function HUDSelectTroopList:OnToggleChooseEscrow(isOn)
    self._chooseEscrow = isOn
end

---@return wds.VillageAllianceWarInfo|nil
function HUDSelectTroopList:ChooseDefaultEscrowTypeByTargetInfo(targetId, targetType)
    if not targetId then
        return nil
    end
    ---@type table<number, wds.VillageAllianceWarInfo>|nil
    local villageWarInfos = nil
    if targetType == DBEntityType.Village then
        villageWarInfos = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
        
    elseif targetType == DBEntityType.BehemothCage  then
        villageWarInfos = ModuleRefer.AllianceModule:GetMyAllianceBehemothCageWar()
    end
    if villageWarInfos then
        for _, v in pairs(villageWarInfos) do
            if v.VillageId == targetId then
                local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
                local battleTroopIsExpired = v.Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleSolder or nowTime >= v.EndTime
                local battleVillageIsExpired = v.Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_BattleConstruction or nowTime >= v.EndTime
                if battleTroopIsExpired and battleVillageIsExpired then
                    return nil
                end
                if battleTroopIsExpired then
                    return wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Durability
                end
                return wds.CreateAllianceAssembleType.CreateAllianceAssembleType_Attack
            end
        end
    end
    return nil
end

function HUDSelectTroopList:GetDefaultTroopIndex()    
    if self.targetParam.isSE then
        return self:GetDefaultTroopIndex_SE()
    else
        return self:GetDefaultTroopIndex_Slg()
    end
end

---@param troopInfo TroopInfo
function HUDSelectTroopList.GetStatePriority(troopInfo)
    local preset = troopInfo.preset

    if preset.Status == wds.TroopPresetStatus.TroopPresetInHome or preset.Status == wds.TroopPresetStatus.TroopPresetIdle then
        return -200
    end

    if preset.BasicInfo.Battling or preset.BasicInfo.BackToCity then
        return -100
    end

    return 0
end

---@private
function HUDSelectTroopList:GetDefaultTroopIndex_Slg()
    local list = {}

    for _, data in ipairs(self.datas) do
        if data.troopInfo == nil then
            goto continue
        end

        if data.troopInfo.locked then
            goto continue
        end

        local preset = data.troopInfo.preset
        if preset == nil then
            goto continue
        end

        local heroCfgID = ModuleRefer.TroopModule:GetPresetLeadHeroId(preset)
        if heroCfgID <= 0 then
            goto continue
        end

        local item = 
        {
            index = data.index,
            priority = HUDSelectTroopList.GetStatePriority(data.troopInfo),
            power = ModuleRefer.SlgInterfaceModule:GetTroopPowerByPreset(data.troopInfo.preset)
        }

        table.insert(list, item)

        ::continue::
    end

    table.sort(list, function(x, y)
        if x.priority ~= y.priority then
            return x.priority < y.priority 
        end

        if x.power ~= y.power then
            return x.power > y.power
        end

        return x.index < y.index
    end)
    
    if #list > 0 then
        return list[1].index
    end

    return 0
end

---@private
function HUDSelectTroopList:GetDefaultTroopIndex_SE()
    local index = 0
    local maxPower = 0
    for i, data in ipairs(self.datas) do               
        local power = ModuleRefer.SlgInterfaceModule:GetTroopPowerByPreset(data.troopInfo.preset)
        if power > maxPower then
            maxPower = power
            index = data.index
        end      
    end
    return index
end

function HUDSelectTroopList:OnSetClicked()
    g_Game.UIManager:Open(UIMediatorNames.UITroopMediator)
end

return HUDSelectTroopList
