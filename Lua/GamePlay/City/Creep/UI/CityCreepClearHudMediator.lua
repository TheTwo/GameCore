-- scene:scene_creepclean_limit

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

local BaseUIMediator = require("BaseUIMediator")

---@class CityCreepClearHudMediatorParameter
---@field count number
---@field limit number

---@class CityCreepClearHudMediator:BaseUIMediator
---@field new fun():CityCreepClearHudMediator
---@field super BaseUIMediator
local CityCreepClearHudMediator = class('CityCreepClearHudMediator', BaseUIMediator)

function CityCreepClearHudMediator:ctor()
    BaseUIMediator.ctor(self)
    self._limit = nil
    self._count = nil
end

function CityCreepClearHudMediator:OnCreate(param)
    ---@type CS.StatusRecordParent
    self._p_group_limitaiton = self:BindComponent("p_group_limitaiton", typeof(CS.StatusRecordParent))
    self._p_img_warning = self:GameObject("p_img_warning")
    self._p_text_description = self:Text("p_text_description", "spray_limit_toast")
    self._p_text_quantity = self:Text("p_text_quantity")
end

function CityCreepClearHudMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.UI_CITY_CREEP_LIMIT_UPDATE, Delegate.GetOrCreate(self, self.OnCountAndLimitUpdate))
end

---@param param CityCreepClearHudMediatorParameter
function CityCreepClearHudMediator:OnOpened(param)
    self:OnCountAndLimitUpdate(param.count, param.limit)
end

function CityCreepClearHudMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_CREEP_LIMIT_UPDATE, Delegate.GetOrCreate(self, self.OnCountAndLimitUpdate))
end

function CityCreepClearHudMediator:OnCountAndLimitUpdate(count, limit, turnToRed)
    self._p_text_quantity.text = string.format("%d/%d", count, limit)
    if turnToRed then
        self._p_group_limitaiton:SetState(1)
    else
        self._p_group_limitaiton:SetState(0)
    end
end

return CityCreepClearHudMediator