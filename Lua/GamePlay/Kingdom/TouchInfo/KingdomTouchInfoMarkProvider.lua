local ModuleRefer = require("ModuleRefer")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local DBEntityType = require("DBEntityType")
local UIMediatorNames = require("UIMediatorNames")

local TouchMenuBasicInfoDatumMarkProvider = require("TouchMenuBasicInfoDatumMarkProvider")

---@class KingdomTouchInfoMarkProvider:TouchMenuBasicInfoDatumMarkProvider
---@field new fun(tile:MapRetrieveResult, isHighLod:boolean):KingdomTouchInfoMarkProvider
---@field super TouchMenuBasicInfoDatumMarkProvider
local KingdomTouchInfoMarkProvider = class('KingdomTouchInfoMarkProvider', TouchMenuBasicInfoDatumMarkProvider)

TouchMenuBasicInfoDatumMarkProvider.AllowTileEntityTypes = {
    [DBEntityType.CastleBrief] = true,
    [DBEntityType.Village] = true,
    [DBEntityType.Pass] = true,
    [DBEntityType.ResourceField] = true,
    [DBEntityType.TransferTower] = true,
    [DBEntityType.DefenceTower] = true,
    [DBEntityType.EnergyTower] = true,
}

---@param tile MapRetrieveResult
---@param isHighLod boolean
function KingdomTouchInfoMarkProvider:ctor(tile, isHighLod)
    TouchMenuBasicInfoDatumMarkProvider.ctor(self)
    ---@type MapRetrieveResult
    self.tile = tile
    self.isHighLod = isHighLod
end

function KingdomTouchInfoMarkProvider:ShowMarkBtn()
    local check = ModuleRefer.AllianceModule:IsInAlliance() and ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel)
    if not check then
        return false
    end
    if not self.tile or not self.tile.X or not self.tile.Z then
        return
    end
    if self.isHighLod then
        return true
    end
    if not self.tile.entity or not self.tile.entity.TypeHash then
        return false
    end
    return TouchMenuBasicInfoDatumMarkProvider.AllowTileEntityTypes[self.tile.entity.TypeHash]
end

function KingdomTouchInfoMarkProvider:GetMarkState()
    local hasSignal = ModuleRefer.SlgModule:HasSignalOnTile(self.tile)
    return hasSignal and 1 or 0
end

function KingdomTouchInfoMarkProvider:OnClickBtnMark(btnTrans)
    if ModuleRefer.AllianceModule:IsInAlliance() and ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel) then
        if ModuleRefer.SlgModule:HasSignalOnTile(self.tile) then
            local id,_ = ModuleRefer.SlgModule:GetSignalOnTile(self.tile)
            if id then
                ModuleRefer.SlgModule:RemoveSignal(id, btnTrans)
            end
        else
            ---@type UIBattleSignalPopupMediatorParameter
            local parameter = {}
            parameter.tile = self.tile
            g_Game.UIManager:Open(UIMediatorNames.UIBattleSignalPopupMediator, parameter)
        end
    end
end

return KingdomTouchInfoMarkProvider