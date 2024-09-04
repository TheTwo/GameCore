local ConfigRefer = require("ConfigRefer")
local CultivateCalcProviderFactory = require("CultivateCalcProviderFactory")
local I18N = require("I18N")
local GuideUtils = require("GuideUtils")
---@class CultivateDataProvider
local CultivateDataProvider = class("CultivateDataProvider")

function CultivateDataProvider:ctor(id, preset)
    self.id = id
    self.preset = preset
    self.cfg = ConfigRefer.CultivateType:Find(id)

    self.calcProvider = CultivateCalcProviderFactory.CreateProvider(self.cfg:CalcKey(), preset, self.cfg:CalcType(), self.cfg:LevelCoeff())
end

---@return number
function CultivateDataProvider:GetCurCultivateValue()
    return self.calcProvider:CalcCultivateValue()
end

---@param lvl number
---@return number
function CultivateDataProvider:GetRecommandCultivateValue(lvl)
    return self.cfg:RecommandPowers(lvl):CultivateValue()
end

function CultivateDataProvider:GetCultivatePrecent(lvl)
    return self:GetCurCultivateValue() / self:GetRecommandCultivateValue(lvl)
end

function CultivateDataProvider:GetName()
    return I18N.Get(self.cfg:Name())
end

function CultivateDataProvider:GetGotoId()
    return self.cfg:Goto()
end

function CultivateDataProvider:OnGoto()
    if self.cfg:Goto() > 0 then
        GuideUtils.GotoByGuide(self.cfg:Goto())
    end
end

return CultivateDataProvider