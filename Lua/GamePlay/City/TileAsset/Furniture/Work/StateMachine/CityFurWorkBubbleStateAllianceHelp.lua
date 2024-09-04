local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
local Utils = require("Utils")

local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")

---@class CityFurWorkBubbleStateAllianceHelp:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateAllianceHelp
---@field super CityFurWorkBubbleStateBase
local CityFurWorkBubbleStateAllianceHelp = class('CityFurWorkBubbleStateAllianceHelp', CityFurWorkBubbleStateBase)

function CityFurWorkBubbleStateAllianceHelp:ctor(furnitureId, tileAsset)
    CityFurWorkBubbleStateAllianceHelp.super.ctor(self, furnitureId, tileAsset)
    ---@type City3DBubbleStandard
    self._bubble = nil
end

function CityFurWorkBubbleStateAllianceHelp:GetName()
    return CityFurWorkBubbleStateBase.Names.AllianceHelp
end

function CityFurWorkBubbleStateAllianceHelp:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

function CityFurWorkBubbleStateAllianceHelp:Exit()
    if self._bubble then
        if Utils.IsNotNull(self._bubble.transform) then
            UIHelper.SetGray(self._bubble.transform.gameObject, false)
        end
    end
    self._bubble = nil
    CityFurWorkBubbleStateAllianceHelp.super.Exit(self)
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateAllianceHelp:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    self._bubble:ShowBubble("sp_item_icon_help")
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
    UIHelper.SetGray(self._bubble.transform.gameObject, not ModuleRefer.AllianceModule:IsInAlliance())
end

function CityFurWorkBubbleStateAllianceHelp:OnBubbleUnload()
    if self._bubble then
        UIHelper.SetGray(self._bubble.transform.gameObject, false)
        self._bubble:ClearTrigger()
        self._bubble = nil
    end
end

function CityFurWorkBubbleStateAllianceHelp:OnClick()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_help_nonealliance_toast"))
        ModuleRefer.AllianceModule:MarkShowGreyHelpRequestBubble()
        return true
    end
    local configId = self.furniture.configId
    ModuleRefer.AllianceModule:RequestAllianceHelp(nil, CityFurWorkBubbleStateAllianceHelp.OnRequestAllianceHelpRet, configId, self.furnitureId, self.furniture:GetUpgradingWorkId())
    return true
end

---@param isSuccess boolean
function CityFurWorkBubbleStateAllianceHelp.OnRequestAllianceHelpRet(isSuccess, _)
    if isSuccess then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_help_seekhelp_toast"))
    end
end

return CityFurWorkBubbleStateAllianceHelp