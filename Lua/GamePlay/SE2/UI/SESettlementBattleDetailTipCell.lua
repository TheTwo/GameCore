local NumberFormatter = require("NumberFormatter")

local BaseUIComponent = require("BaseUIComponent")

---@class SESettlementBattleDetailTipCellData
---@field Hero HeroInfoData
---@field Pet CommonPetIconBaseData
---@field serverData wrpc.LevelEntityBattleInfo
---@field MaxValue {OutDam:number, TakeDam:number, OutHeal:number}

---@class SESettlementBattleDetailTipCell:BaseUIComponent
---@field new fun():SESettlementBattleDetailTipCell
---@field super BaseUIComponent
local SESettlementBattleDetailTipCell = class('SESettlementBattleDetailTipCell', BaseUIComponent)

function SESettlementBattleDetailTipCell:OnCreate(param)
    ---@type HeroInfoItemSmallComponent
    self._p_card_hero = self:LuaObject("p_card_hero")
    ---@type CommonPetIconSmall
    self._p_card_pet = self:LuaObject("p_card_pet")
    self._p_text_harm_num = self:Text("p_text_harm_num")
    self._p_progress_power_harm = self:Slider("p_progress_power_harm")
    self._p_text_injured_num = self:Text("p_text_injured_num")
    self._p_progress_power_injured = self:Slider("p_progress_power_injured")
    self._p_text_treat_num = self:Text("p_text_treat_num")
    self._p_progress_power_treat = self:Slider("p_progress_power_treat")
end

---@param data SESettlementBattleDetailTipCellData
function SESettlementBattleDetailTipCell:OnFeedData(data)
    if data.Hero then
        self._p_card_hero:SetVisible(true)
        self._p_card_pet:SetVisible(false)
        self._p_card_hero:FeedData(data.Hero)
    elseif data.Pet then
        self._p_card_hero:SetVisible(false)
        self._p_card_pet:SetVisible(true)
        self._p_card_pet:FeedData(data.Pet)
    else
        self._p_card_hero:SetVisible(false)
        self._p_card_pet:SetVisible(false)
    end
    self._p_text_harm_num.text = NumberFormatter.NumberAbbr(data.serverData.OutDam, true)
    self._p_text_injured_num.text = NumberFormatter.NumberAbbr(data.serverData.TakeDam, true)
    self._p_text_treat_num.text = NumberFormatter.NumberAbbr(data.serverData.OutHeal, true)
    self._p_progress_power_harm.value = math.inverseLerp(0, data.MaxValue.OutDam, data.serverData.OutDam)
    self._p_progress_power_injured.value = math.inverseLerp(0, data.MaxValue.TakeDam, data.serverData.TakeDam)
    self._p_progress_power_treat.value = math.inverseLerp(0, data.MaxValue.OutHeal, data.serverData.OutHeal)
end

return SESettlementBattleDetailTipCell