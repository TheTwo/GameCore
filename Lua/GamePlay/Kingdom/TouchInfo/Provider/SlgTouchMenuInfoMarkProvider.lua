local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityType = require("DBEntityType")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local UIMediatorNames = require("UIMediatorNames")
local MapRetrieveResult = require("MapRetrieveResult")
local KingdomMapUtils = require("KingdomMapUtils")

local TouchMenuBasicInfoDatumMarkProvider = require("TouchMenuBasicInfoDatumMarkProvider")

---@class SlgTouchMenuInfoMarkProvider:TouchMenuBasicInfoDatumMarkProvider
---@field new fun():SlgTouchMenuInfoMarkProvider
---@field super TouchMenuBasicInfoDatumMarkProvider
local SlgTouchMenuInfoMarkProvider = class('SlgTouchMenuInfoMarkProvider', TouchMenuBasicInfoDatumMarkProvider)

function SlgTouchMenuInfoMarkProvider:ctor()
    TouchMenuBasicInfoDatumMarkProvider.ctor(self)
    self._targetId = nil
    ---@type wds.BehemothCage
    self._wrapEntity = nil
end

---@param entity wds.MapMob
function SlgTouchMenuInfoMarkProvider:Setup(entity)
    self._entity = entity
    self._targetId = nil
    self._wrapToBehemothCage = false
    self._wrapEntity = nil
    if entity then
        if entity.TypeHash == DBEntityType.MapMob then
            self._targetId = entity.ID
            if entity.MobInfo.BehemothCageId ~= 0 then
                self._wrapEntity = g_Game.DatabaseManager:GetEntity(entity.MobInfo.BehemothCageId, DBEntityType.BehemothCage)
                if self._wrapEntity then
                    self._targetId = entity.MobInfo.BehemothCageId 
                end
            end
        end
    end
    return self
end

function SlgTouchMenuInfoMarkProvider:ShowMarkBtn()
    if not self._targetId then
        return false
    end
    return ModuleRefer.AllianceModule:IsInAlliance() and ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel)
end

function SlgTouchMenuInfoMarkProvider:GetMarkState()
    if not self._targetId then
        return 0
    end
    return ModuleRefer.SlgModule:HasSignalOnEntity(self._targetId) and 1 or 0
end

function SlgTouchMenuInfoMarkProvider:OnClickBtnMark(btnTrans)
    if not self:ShowMarkBtn() then
        return 0
    end
    local id,_ = ModuleRefer.SlgModule:GetSignalOnEntity(self._targetId)
    if id then
        ModuleRefer.SlgModule:RemoveSignal(id, btnTrans)
    else
        ---@type UIBattleSignalPopupMediatorParameter
        local parameter = {}
        if self._wrapEntity then
            local pos = self._wrapEntity.MapBasics.Position
            local sizeX,sizeY,_ = KingdomMapUtils.GetLayoutSize(self._wrapEntity.MapBasics.LayoutCfgId)
            parameter.tile = MapRetrieveResult.new(pos.X, pos.Y, {}, self._wrapEntity,nil, sizeX, sizeY)
        else
            parameter.entity = self._entity
            parameter.troopId = self._targetId
        end
        g_Game.UIManager:Open(UIMediatorNames.UIBattleSignalPopupMediator,parameter)
    end
end

return SlgTouchMenuInfoMarkProvider