--- scene:scene_hud_explore_settlement

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local FunctionClass = require("FunctionClass")
local UIMediatorNames = require("UIMediatorNames")
local SEEnvironment = require("SEEnvironment")

---@class SEExploreSettlementMediatorParameter
---@field result number @0:结束 1:胜利 2:失败
---@field gainList {itemId:number, count:number}[] @获得物品列表
---@field showTypes table<number, boolean>
---@field seBattleInfo wrpc.SeBattleStatisticParam
---@field exitNormalSe boolean

local BaseUIMediator = require("BaseUIMediator")

---@class SEExploreSettlementMediator:BaseUIMediator
---@field new fun():SEExploreSettlementMediator
---@field super BaseUIMediator
local SEExploreSettlementMediator = class('SEExploreSettlementMediator', BaseUIMediator)

function SEExploreSettlementMediator:ctor()
    SEExploreSettlementMediator.super.ctor(self)
    ---@type table<number, boolean>
    self.showTypes = {}
    ---@type wrpc.SeBattleStatisticParam
    self._seBattleInfo = nil
end

function SEExploreSettlementMediator:OnCreate()
    self._p_status_content = self:StatusRecordParent("p_status_content")
    self._p_text_title_end = self:Text("p_text_title_end", "explore_des_end")
    self._p_text_title_win = self:Text("p_text_title_win", "explore_des_win")
    self._p_text_title_lose = self:Text("p_text_title_lose", "explore_des_lose")

    self._p_group_pet = self:GameObject("p_group_pet")
    self._p_text_pet = self:Text("p_text_pet", "explore_des_petget")
    self._p_table_pet = self:TableViewPro("p_table_pet")
    ---@type CS.TableViewProLayout
    self._p_table_pet_layout = self:BindComponent("p_table_pet", typeof(CS.TableViewProLayout))

    self._p_group_item = self:GameObject("p_group_item")
    self._p_text_reward = self:Text("p_text_reward", "explore_des_itemget")
    self._p_table_reward = self:TableViewPro("p_table_reward")
    ---@type CS.TableViewProLayout
    self._p_table_reward_layout = self:BindComponent("p_table_reward", typeof(CS.TableViewProLayout))
    self._p_text_empty = self:Text("p_text_empty", "explore_des_nothing")

    self._p_text_strengthen = self:Text("p_text_strengthen", "explore_des_rpp")
    self._p_table_way = self:TableViewPro("p_table_way")

    self._p_btn_back = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.OnClickClose))
    self._p_text = self:Text("p_text", "explore_des_exit")
    self._p_btn_data = self:Button("p_btn_data", Delegate.GetOrCreate(self, self.OnClickData))
    self._p_text_data = self:Text("p_text_data", "#数据")
end

---@param param SEExploreSettlementMediatorParameter
function SEExploreSettlementMediator:OnOpened(param)
    self._exitNormalSe = param.exitNormalSe
    self._seBattleInfo = param.seBattleInfo
    self._p_btn_data:SetVisible(param.seBattleInfo ~= nil)
    table.clear(self.showTypes)
    for i, v in pairs(param.showTypes) do
        self.showTypes[i] = v
    end
    self._p_status_content:SetState(param.result)
    local isFailedMode = param.result == 2
    self.isSuc = param.result == 1
    if isFailedMode then
        self._p_text_pet.alignment = CS.UnityEngine.TextAnchor.MiddleLeft
        self._p_text_reward.alignment = CS.UnityEngine.TextAnchor.MiddleLeft
    else
        self._p_text_pet.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
        self._p_text_reward.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
    end
    ---@type {config:ItemConfigCell, count:number}[]
    local petList = {}
    ---@type {config:ItemConfigCell, count:number}[]
    local itemList = {}
    for _, idCountPair in ipairs(param.gainList) do
        local itemConfig = ConfigRefer.Item:Find(idCountPair.itemId)
        if not itemConfig then
            goto continue
        end
        if itemConfig:AutoBringToSeBag() then
            goto continue
        end
        if itemConfig:FunctionClass() == FunctionClass.AddPet then
            table.insert(petList, { config = itemConfig, count = idCountPair.count })
        else
            table.insert(itemList, { config = itemConfig, count = idCountPair.count })
        end
        :: continue ::
    end
    local isEmpty = true
    self._p_group_pet:SetVisible(#petList > 0)
    self._p_group_item:SetVisible(#itemList > 0)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_group_pet.transform.parent:GetComponent(typeof(CS.UnityEngine.RectTransform)))
    if #petList > 0 then
        isEmpty = false
        self._p_table_pet:Clear()
        if isFailedMode then
            self._p_table_pet_layout.childAlignment = CS.UnityEngine.TextAnchor.MiddleLeft
        else
            self._p_table_pet_layout.childAlignment = CS.UnityEngine.TextAnchor.MiddleCenter
        end
        for _, v in ipairs(petList) do
            for i = 1, v.count do
                ---@type SEExploreSettlementPetCellData
                local cellData = {}
                cellData.itemConfig = v.config
                self._p_table_pet:AppendData(cellData)
            end
        end
    end
    if #itemList > 0 then
        isEmpty = false
        self._p_table_reward:Clear()
        if isFailedMode then
            self._p_table_reward_layout.childAlignment = CS.UnityEngine.TextAnchor.MiddleLeft
        else
            self._p_table_reward_layout.childAlignment = CS.UnityEngine.TextAnchor.MiddleCenter
        end
        for _, v in ipairs(itemList) do
            ---@type SEExploreSettlementItemCellData
            local cellData = {}
            cellData.itemConfig = v.config
            cellData.count = v.count
            self._p_table_reward:AppendData(cellData)
        end
    end
    self._p_text_empty:SetVisible(isEmpty)
    if isFailedMode then
        self:GenerateStrengthenTableCells()
    end
end

function SEExploreSettlementMediator:GenerateStrengthenTableCells()
    ---@type {index:number, minSubType:number, config:PowerProgressResourceConfigCell}[]
    local showIndexes = {}
    local strongHoldLv = ModuleRefer.PlayerModule:StrongholdLevel()
    local recommendCfg = ConfigRefer.RecommendPowerTable:Find(strongHoldLv)
    for i = 1, recommendCfg:SubTypePowersLength() do
        local subTypePower = recommendCfg:SubTypePowers(i)
        local config = self:GetProviderConfig(subTypePower)
        if config then
            if self.showTypes[subTypePower:SubType()] then
                showIndexes[#showIndexes + 1] = { index = i, config = config }
            end
        end
    end
    local playerData = ModuleRefer.PlayerModule:GetPlayer()
    local subTypePowers = playerData.PlayerWrapper2.PlayerPower.SubTypePowers
    local minSubType,minPriority
    local minPercent = math.maxinteger
    ---@type {index:number, percent:number, config:PowerProgressResourceConfigCell}[]
    local results = {}
    local priorityIndex = self:GetPriority()
    for _, info in ipairs(showIndexes) do
        local index = info.index
        local subTypePower = recommendCfg:SubTypePowers(index)
        local subType = subTypePower:SubType()
        local subPower = subTypePower:PowerValue()
        local curPower = subTypePowers[subType] or 0
        if subPower <= 0 then
            subPower = 1
        end
        local percent = curPower / subPower
        if percent < minPercent and percent < 1 then
            minPercent = percent
            minSubType = subType
            minPriority = info.config:Priority(priorityIndex)
        end
        if percent == minPercent and minPriority > info.config:Priority(priorityIndex) then
            minSubType = subType
            minPriority = info.config:Priority(priorityIndex)
        end
        results[#results + 1] = { index = index, percent = math.floor(percent * 1000), config = info.config }
    end
    local sortFunc = function(a, b)
        if a.config:Priority(priorityIndex) ~ b.config:Priority(priorityIndex) then
            return a.config:Priority(priorityIndex) < b.config:Priority(priorityIndex)
        else
            return a.index < b.index
        end
    end
    table.sort(results, sortFunc)
    self._p_table_way:Clear()
    for _, info in ipairs(results) do
        ---@type SEExploreSettlementStrengthenCellData
        local cellData = {}
        cellData.index = info.index
        cellData.minSubType = minSubType
        cellData.config = info.config
        self._p_table_way:AppendData(cellData)
    end
end

---@return PowerProgressResourceConfigCell
function SEExploreSettlementMediator:GetProviderConfig(subTypePower)
    for _, config in ConfigRefer.PowerProgressResource:ipairs() do
        if config:PowerSubTypes() == subTypePower:SubType() then
            local sysIndex = config:Unlock()
            if sysIndex and sysIndex > 0 then
                local isOpen = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex)
                if isOpen then
                    return config
                end
            else
                return config
            end
        end
    end
    return nil
end

function SEExploreSettlementMediator:GetPriority()
    local priorityIndex = 1
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local payNumber = player.PlayerWrapper2.PlayerPay.AccPay or 0
    local payConstNumber = ConfigRefer.ConstMain:PlayerPaymentTierParamLength()
    for i = 1, payConstNumber do
        local curPay = ConfigRefer.ConstMain:PlayerPaymentTierParam(i)
        if i < payConstNumber then
            local nextPay = ConfigRefer.ConstMain:PlayerPaymentTierParam(i + 1)
            if payNumber >= nextPay and payNumber < curPay then
                priorityIndex = i + 1
            elseif payNumber >= curPay then
                priorityIndex = 1
            end
        elseif i == payConstNumber then
            if payNumber <= curPay then
                priorityIndex = payConstNumber + 1
            end
        end
    end
    return priorityIndex
end

function SEExploreSettlementMediator:OnClickClose()
    self:CloseSelf()
    if not  self._exitNormalSe then return end
    local env = SEEnvironment.Instance()
    if env then
        env:RequestLeave(nil, not self.isSuc)
    end
end

function SEExploreSettlementMediator:OnClickData()
    ---@type SESettlementBattleDetailTipMediatorParameter
    local params = {}
    params.serverData = self._seBattleInfo
    g_Game.UIManager:Open(UIMediatorNames.SESettlementBattleDetailTipMediator, params)
end

return SEExploreSettlementMediator