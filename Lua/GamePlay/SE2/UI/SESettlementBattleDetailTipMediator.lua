--- scene:scene_se_settlement_tips_data

local UIHelper = require("UIHelper")
local SEEnvironment = require("SEEnvironment")
local ModuleRefer = require("ModuleRefer")

local BaseUIMediator = require("BaseUIMediator")

---@class SESettlementBattleDetailTipMediatorParameter
---@field serverData wrpc.SeBattleStatisticParam

---@class SESettlementBattleDetailTipMediator:BaseUIMediator
---@field new fun():SESettlementBattleDetailTipMediator
---@field super BaseUIMediator
local SESettlementBattleDetailTipMediator = class('SESettlementBattleDetailTipMediator', BaseUIMediator)

function SESettlementBattleDetailTipMediator:ctor()
    SESettlementBattleDetailTipMediator.super.ctor(self)
    ---@type CS.DragonReborn.UI.BaseComponent[]
    self._cells = {}
end

function SESettlementBattleDetailTipMediator:OnCreate(param)
    self._p_text_tips = self:Text("p_text_tips", "#战斗数据")
    self._p_text_title_harm = self:Text("p_text_title_harm", "#伤害")
    self._p_text_title_injured = self:Text("p_text_title_injured", "#承伤")
    self._p_text_title_treat = self:Text("p_text_title_treat", "#回血")
    ---@see SESettlementBattleDetailTipCell
    self._p_item_data = self:LuaBaseComponent("p_item_data")
    self._p_item_data:SetVisible(false)
end

---@param maxValues {OutDam:number, TakeDam:number, OutHeal:number}
---@param serverData wrpc.LevelEntityBattleInfo
function SESettlementBattleDetailTipMediator.CompareMaxValue(maxValues, serverData)
    for key, v in pairs(maxValues) do
        local serverValue = serverData[key] or 0
        if v < serverValue then
            maxValues[key] = serverValue
        end
    end
end

---@param param SESettlementBattleDetailTipMediatorParameter
function SESettlementBattleDetailTipMediator:OnOpened(param)
    self._clickNormalExit = param.clickToExitNormalSe
    self:ReleaseCells()
    local playerData = param.serverData.PlayerInfos[ModuleRefer.PlayerModule:GetPlayerId()]
    if not playerData then return end
    ---@type {OutDam:number, TakeDam:number, OutHeal:number}
    local maxValues = {}
    maxValues.OutDam = 0
    maxValues.TakeDam = 0
    maxValues.OutHeal = 0
    local cellsData = {}
    for _, v in pairs(playerData.HeroInfos) do
        ---@type SESettlementBattleDetailTipCellData
        local cellData = {}
        ---@type HeroInfoData
        local heroData = {}
        heroData.heroData = ModuleRefer.HeroModule:GetHeroByCfgId(v.ConfigId)
        cellData.Hero = heroData
        cellData.serverData = v
        cellData.MaxValue = maxValues
        SESettlementBattleDetailTipMediator.CompareMaxValue(maxValues, v)
        table.insert(cellsData, cellData)
    end
    for _, v in pairs(playerData.PetInfos) do
        local petData = ModuleRefer.PetModule:GetPetByID(v.CompId)
        ---@type CommonPetIconBaseData
        local data = {}
        data.id = v.CompId
        data.cfgId = v.ConfigId
        data.level = petData.Level
        ---@type SESettlementBattleDetailTipCellData
        local cellData = {}
        cellData.Pet = data
        cellData.serverData = v
        cellData.MaxValue = maxValues
        SESettlementBattleDetailTipMediator.CompareMaxValue(maxValues, v)
        table.insert(cellsData, cellData)
    end
    self._p_item_data:SetVisible(true)
    local cellParent = self._p_item_data.transform.parent
    for _, v in ipairs(cellsData) do
        local cell = UIHelper.DuplicateUIComponent(self._p_item_data, cellParent)
        table.insert(self._cells, cell)
        cell:FeedData(v)
    end
    self._p_item_data:SetVisible(false)
end

function SESettlementBattleDetailTipMediator:OnClose(data)
    self:ReleaseCells()
end

function SESettlementBattleDetailTipMediator:ReleaseCells()
    for i, v in pairs(self._cells) do
        UIHelper.DeleteUIComponent(v)
        self._cells[i] = nil
    end
end

return SESettlementBattleDetailTipMediator