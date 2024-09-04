local I18N = require('I18N')
local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local TimerUtility = require("TimerUtility")

---@class NewLandformMediatorParameter
---@field landCfgId number @LandConfigCell Id

---@class NewLandformMediator:BaseUIMediator
---@field new fun():NewLandformMediator
---@field super BaseUIMediator
local NewLandformMediator = class('LandformUnlockMediator', BaseUIMediator)

local CLOSE_DELAY = 1

---@param param NewLandformMediatorParameter
function NewLandformMediator:OnCreate(param)
    self.landCfgid = param.landCfgId

    self.imgLandform = self:Image('p_icon')
    self.txtName = self:Text('p_text_power')
end

function NewLandformMediator:OnShow(param)
    self:RefreshUI()

    TimerUtility.DelayExecute(function() 
        self:CloseSelf()
    end, CLOSE_DELAY)
end

function NewLandformMediator:OnHide(param)
end

function NewLandformMediator:RefreshUI()
    local landCfgCell = ConfigRefer.Land:Find(self.landCfgid)
    g_Game.SpriteManager:LoadSprite(landCfgCell:Icontips(), self.imgLandform)
    self.txtName.text = I18N.Get(landCfgCell:Name())
end

return NewLandformMediator