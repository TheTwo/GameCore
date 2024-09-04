local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateCanProcess:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateCanProcess
local CityFurWorkBubbleStateCanProcess = class("CityFurWorkBubbleStateCanProcess", CityFurWorkBubbleStateBase)
local Delegate = require("Delegate")
local CityWorkType = require("CityWorkType")
local ConfigRefer = require("ConfigRefer")
local CityProcessUtils = require("CityProcessUtils")
local CityProcessV2UIParameter = require("CityProcessV2UIParameter")
local CityMaterialProcessV2UIParameter = require("CityMaterialProcessV2UIParameter")
local UIMediatorNames = require("UIMediatorNames")

function CityFurWorkBubbleStateCanProcess:GetName()
    return CityFurWorkBubbleStateBase.Names.CanProcess
end

function CityFurWorkBubbleStateCanProcess:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateCanProcess:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()

    self._bubble:ShowBubble(self:GetWorkCfgIcon())
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStateCanProcess:OnBubbleUnload()
    if self._bubble then
        self._bubble:ClearTrigger()
        self._bubble = nil
    end
end

function CityFurWorkBubbleStateCanProcess:OnClick()
    if self.furniture:CanDoCityWork(CityWorkType.Process) then
        return self:OnClickProcess()
    elseif self.furniture:CanDoCityWork(CityWorkType.MaterialProcess) then
        return self:OnClickMaterialProcess()
    end
    return true
end

function CityFurWorkBubbleStateCanProcess:OnClickProcess()
    local workCfgId = self.furniture:GetWorkCfgId(CityWorkType.Process)
    if workCfgId == 0 then return true end

    local tile = self:GetTile()
    if tile == nil then return true end

    local param = CityProcessV2UIParameter.new(tile)
    g_Game.UIManager:Open(UIMediatorNames.CityProcessV2UIMediator, param)
    return true
end

function CityFurWorkBubbleStateCanProcess:OnClickMaterialProcess()
    local workCfgId = self.furniture:GetWorkCfgId(CityWorkType.MaterialProcess)
    if workCfgId == 0 then return true end
    
    local tile = self:GetTile()
    if tile == nil then return true end

    local param = CityMaterialProcessV2UIParameter.new(tile)
    g_Game.UIManager:Open(UIMediatorNames.CityProcessV2UIMediator, param)
    return true
end

function CityFurWorkBubbleStateCanProcess:GetWorkCfgIcon()
    if self.furniture:CanDoCityWork(CityWorkType.Process) then
        return ConfigRefer.CityWork:Find(self.furniture:GetWorkCfgId(CityWorkType.Process)):CircleMenuIcon()
    elseif self.furniture:CanDoCityWork(CityWorkType.MaterialProcess) then
        return ConfigRefer.CityWork:Find(self.furniture:GetWorkCfgId(CityWorkType.MaterialProcess)):CircleMenuIcon()
    end
    return ""
end

return CityFurWorkBubbleStateCanProcess