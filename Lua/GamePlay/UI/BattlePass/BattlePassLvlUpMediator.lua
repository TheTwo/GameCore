local BaseUIMediator = require("BaseUIMediator")
local BattlePassConst = require("BattlePassConst")
local Delegate = require("Delegate")
---@class BattlePassLvlUpMediator : BaseUIMediator
local BattlePassLvlUpMediator = class("BattlePassLvlUpMediator", BaseUIMediator)
---@scene scene_battlepass_popup_level_up

---@class BattlePassLvlUpMediatorParam
---@field originalLvl number
---@field currentLvl number

local I18N_KEYS = BattlePassConst.I18N_KEYS

function BattlePassLvlUpMediator:OnCreate()
    self.textDesc = self:Text("p_text_lv", I18N_KEYS.LVL_UP)
    self.textLv = self:Text("p_text_desc")
    ---@type CS.UnityEngine.Animation
    self.anim = self:BindComponent("p_group", typeof(CS.UnityEngine.Animation))
    ---@type LuaBehaviourAnimationEventReceiver
    self.animEventReceiver = self:BindComponent('p_group', typeof(CS.DragonReborn.LuaBehaviourAnimationEventReceiver)).Instance
    self.animEventReceiver:SetEventCallback(Delegate.GetOrCreate(self, self.OnAnimEvent))
end

---@param param BattlePassLvlUpMediatorParam
function BattlePassLvlUpMediator:OnOpened(param)
    self.originalLvl = param.originalLvl
    self.currentLvl = param.currentLvl
    self.textLv.text = string.format("%d", self.originalLvl)
end

---@param event string
function BattlePassLvlUpMediator:OnAnimEvent(event)
    if event == "End" then
        self:CloseSelf()
    elseif event == "LvlUp" then
        self.textLv.text = string.format("%d", self.currentLvl)
    end
end

return BattlePassLvlUpMediator