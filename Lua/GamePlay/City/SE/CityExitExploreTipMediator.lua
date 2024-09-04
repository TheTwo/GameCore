
--- scene:scene_hud_explore_toast_end
local Delegate = require("Delegate")

local BaseUIMediator = require("BaseUIMediator")

---@class CityExitExploreTipMediatorParameter
---@field tipText string
---@field delayClose number|nil

---@class CityExitExploreTipMediator:BaseUIMediator
---@field new fun():CityExitExploreTipMediator
---@field super BaseUIMediator
local CityExitExploreTipMediator = class('CityExitExploreTipMediator', BaseUIMediator)

function CityExitExploreTipMediator:ctor()
    CityExitExploreTipMediator.super.ctor(self)
    self._delayClose = nil
end

function CityExitExploreTipMediator:OnCreate()
    self._p_text_name = self:Text("p_text_name")
end

---@param param CityExitExploreTipMediatorParameter
function CityExitExploreTipMediator:OnShow(param)
    self._p_text_name.text = param.tipText
    self._delayClose = param.delayClose
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityExitExploreTipMediator:OnHide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityExitExploreTipMediator:Tick(dt)
    if not self._delayClose then return end
    self._delayClose = self._delayClose - dt
    if self._delayClose < 0 then
        self._delayClose = nil
        self:CloseSelf()
    end
end

return CityExitExploreTipMediator