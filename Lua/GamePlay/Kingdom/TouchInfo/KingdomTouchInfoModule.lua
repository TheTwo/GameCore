local BaseModule = require("BaseModule")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")

---@class KingdomTouchInfoModule : BaseModule
local KingdomTouchInfoModule = class('KingdomTouchInfoModule', BaseModule)
local KingdomMapUtils = require("KingdomMapUtils")

function KingdomTouchInfoModule:OnRegister()
    self.scene = KingdomMapUtils.GetKingdomScene()
    if self.scene and self.scene.AddLodChangeListener then
        self.scene:AddLodChangeListener(Delegate.GetOrCreate(self, self.OnLodChanged))
    end
end

function KingdomTouchInfoModule:OnRemove()
    if self.scene and self.scene.RemoveLodChangeListener then
        self.scene:RemoveLodChangeListener(Delegate.GetOrCreate(self, self.OnLodChanged))
    end
end

function KingdomTouchInfoModule:OnLodChanged()
    self:Hide()
end

function KingdomTouchInfoModule:IsShow()
    return self:GetCurrent() ~= nil
end

---@return TouchInfoMediator
function KingdomTouchInfoModule:GetCurrent()
    return g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.TouchMenuUIMediator)
end

---@param data TouchInfoData
function KingdomTouchInfoModule:Show(data)
    if not data or not KingdomMapUtils.IsMapState() then
        return
    end

    ModuleRefer.SlgModule:CloseTroopMenu()
    require("TouchMenuUIMediator").OpenSingleton(data)
end

function KingdomTouchInfoModule:Hide()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.TouchMenuUIMediator)
end

function KingdomTouchInfoModule:RefreshCurrentTouchMenu(entity)
    local currentTile = KingdomMapUtils.GetCurrentTile()
    if currentTile and entity and currentTile.entity and currentTile.entity.ID == entity.ID then
        if ModuleRefer.KingdomTouchInfoModule:IsShow() then
            ModuleRefer.KingdomTouchInfoModule:Hide()
            local lod = KingdomMapUtils.GetLOD()
            local data = KingdomTouchInfoFactory.CreateDataFromKingdom(currentTile, lod)
            ModuleRefer.KingdomTouchInfoModule:Show(data)
        end
    end
end


return KingdomTouchInfoModule
