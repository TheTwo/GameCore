local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local ProtocolId = require('ProtocolId')
local UIMediatorNames = require('UIMediatorNames')
local NewFunctionUnlockIdDefine = require('NewFunctionUnlockIdDefine')

local MapUtils = CS.Grid.MapUtils

---@class HUDMapLodExploreFog : BaseUIComponent
local HUDMapLodExploreFog = class("HUDMapLodExploreFog", BaseUIComponent)

function HUDMapLodExploreFog:OnShow(param)
    self.p_btn_explor_fog = self:Button("p_btn_explor_fog", Delegate.GetOrCreate(self, self.OnButtonClicked))
    self.p_text_explor_num = self:Text("p_text_explor_num")

    g_Game.EventManager:AddListener(EventConst.RADAR_LEVEL_UP, Delegate.GetOrCreate(self, self.OnExploreValueChange))
    g_Game.EventManager:AddListener(EventConst.ON_LANDFORM_SELECT, Delegate.GetOrCreate(self, self.OnLandformSelect))
    g_Game.EventManager:AddListener(EventConst.ON_UNLOCK_WORLD_FOG, Delegate.GetOrCreate(self, self.OnExploreValueChange))
    self:OnExploreValueChange()
end

function HUDMapLodExploreFog:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.RADAR_LEVEL_UP, Delegate.GetOrCreate(self, self.OnExploreValueChange))
    g_Game.EventManager:RemoveListener(EventConst.ON_LANDFORM_SELECT, Delegate.GetOrCreate(self, self.OnLandformSelect))
    g_Game.EventManager:RemoveListener(EventConst.ON_UNLOCK_WORLD_FOG, Delegate.GetOrCreate(self, self.OnExploreValueChange))

end

function HUDMapLodExploreFog:OnLandformSelect(cfgId)
    self.p_btn_explor_fog.gameObject:SetActive(not cfgId or cfgId == 0)
end

function HUDMapLodExploreFog:OnButtonClicked()
    local unlockMist = NewFunctionUnlockIdDefine.UnlockMist
    local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(unlockMist)
    if not unlocked then
        ModuleRefer.NewFunctionUnlockModule:ShowLockedTipToast(unlockMist)
        return
    end

    if ModuleRefer.MapFogModule.allUnlocked then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("mist_toast_nomist"))
        return
    end

    if ModuleRefer.MapFogModule.isPlayingMultiUnlockEffect then
        return
    end

    local costPerMistCell =  ConfigRefer.ConstMain:UnlockPerMistCellCostExploreValue()
    if not ModuleRefer.MapFogModule:IsItemEnough() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("Mist_toast_needmaterial", costPerMistCell))
        require("MapFogModule").UnlockItemGetMore()
        return
    end

    local radarLevel = ModuleRefer.RadarModule:GetRadarLv()
    -- local strongholdLevel = ModuleRefer.PlayerModule:StrongholdLevel()
    if g_Game.UIManager:IsOpenedByName(UIMediatorNames.RadarMediator)  then
        local limitLevel = ConfigRefer.ConstBigWorld:UnlockMistRadarLevel()
        if radarLevel < limitLevel then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("Radar_mist_unlock_tips", limitLevel))
            return
        end
        g_Game.UIManager:Open(UIMediatorNames.MapFogLodExploreUIMediator, true)
    else
        local limitLevel = ConfigRefer.ConstBigWorld:MultiUnlockMistRadarLevel()
        if radarLevel < limitLevel then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("Radar_mist_unlock_tips", limitLevel))
            return
        end
        g_Game.UIManager:Open(UIMediatorNames.MapFogLodExploreUIMediator, false)
    end
end

function HUDMapLodExploreFog:OnExploreValueChange()
    local exploreValue = ModuleRefer.MapFogModule:GetUnlockItemCount()
    self.p_text_explor_num.text = "x" .. tostring(exploreValue)
end

return HUDMapLodExploreFog