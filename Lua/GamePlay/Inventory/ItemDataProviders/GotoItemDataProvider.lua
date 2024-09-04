local FunctionalItemDataProvider = require("FunctionalItemDataProvider")
local GuideUtils = require("GuideUtils")
local I18N = require("I18N")
---@class GotoItemDataProvider : FunctionalItemDataProvider
local GotoItemDataProvider = class("GotoItemDataProvider", FunctionalItemDataProvider)

function GotoItemDataProvider:CanUse()
    return self:DefaultUseChecker()
end

function GotoItemDataProvider:GetUseText()
    return I18N.Get("goto")
end

function GotoItemDataProvider:Use(usageNum, callback)
    GuideUtils.GotoByGuide(self.itemCfg:UseGoto())
    if callback then
        callback()
    end
end

return GotoItemDataProvider