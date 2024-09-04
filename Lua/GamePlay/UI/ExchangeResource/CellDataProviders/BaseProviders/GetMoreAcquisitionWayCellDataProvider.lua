local BaseGetMoreCellDataProvider = require("BaseGetMoreCellDataProvider")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
---@class GetMoreAcquisitionWayCellDataProvider : BaseGetMoreCellDataProvider
local GetMoreAcquisitionWayCellDataProvider = class("GetMoreAcquisitionWayCellDataProvider", BaseGetMoreCellDataProvider)

function GetMoreAcquisitionWayCellDataProvider:ctor(itemId, gotoIndex)
    GetMoreAcquisitionWayCellDataProvider.super.ctor(self)
    self.gotoIndex = gotoIndex
    self.itemId = itemId
end

function GetMoreAcquisitionWayCellDataProvider:ShowGotoBtn()
    local itemConfig = ConfigRefer.Item:Find(self.itemId)
    local getMoreCfg = ConfigRefer.GetMore:Find(itemConfig:GetMoreConfig())
    if not getMoreCfg then
        return false
    end
    local sysEntry = getMoreCfg:Goto(self.gotoIndex):UnlockSystem()
    return sysEntry == 0 or ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysEntry)
end

function GetMoreAcquisitionWayCellDataProvider:OnGoto(args)
    args:CloseSelf()
    require('GuideUtils').GotoItemAccess(self.itemId, self.gotoIndex)
end

function GetMoreAcquisitionWayCellDataProvider:GetDesc()
    local itemConfig = ConfigRefer.Item:Find(self.itemId)
    local getMoreCfg = ConfigRefer.GetMore:Find(itemConfig:GetMoreConfig())
    if not getMoreCfg then
        return string.Empty
    end
    return I18N.Get(getMoreCfg:Goto(self.gotoIndex):Desc())
end

return GetMoreAcquisitionWayCellDataProvider