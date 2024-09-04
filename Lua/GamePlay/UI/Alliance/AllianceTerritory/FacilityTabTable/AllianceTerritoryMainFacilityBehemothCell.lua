local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local ArtResourceUtils = require("ArtResourceUtils")
local EventConst = require("EventConst")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local DBEntityType = require("DBEntityType")
local ConfigRefer = require("ConfigRefer")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local UIHelper = require("UIHelper")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceTerritoryMainFacilityBehemothCell:BaseUIComponent
---@field new fun():AllianceTerritoryMainFacilityBehemothCell
---@field super BaseUIComponent
local AllianceTerritoryMainFacilityBehemothCell = class('AllianceTerritoryMainFacilityBehemothCell', BaseUIComponent)

function AllianceTerritoryMainFacilityBehemothCell:OnCreate(param)
    self._p_icon_facility = self:Image("p_icon_facility")
    self._p_text_lv_facility = self:Text("p_text_lv_facility")
    self._p_text_name_facility = self:Text("p_text_name_facility")
    self._p_text_constructed = self:Text("p_text_constructed")
    self._p_text_behemoth = self:Text("p_text_behemoth")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickBtnDetail))
    self._p_btn_view = self:Button("p_btn_view", Delegate.GetOrCreate(self, self.OnClickBtnView))
    self._p_status_lock = self:GameObject("p_status_lock")
    self._child_comp_btn_b_l = self:Button("child_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnClickBtnBuild))
    self._p_text = self:Text("p_text", "alliance_behemothActivity_button_goto")
    self._p_text_position = self:Text("p_text_position")
end

---@param data AllianceTerritoryMainFacilityCellData
function AllianceTerritoryMainFacilityBehemothCell:OnFeedData(data)
    self._data = data
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(self._data.config:Image()), self._p_icon_facility)
    self._p_text_lv_facility.text = tostring(self._data.config:Level())
    self._p_text_name_facility.text = I18N.Get(self._data.config:Name())
    self._p_text_behemoth:SetVisible(false)
    self._p_text_position.text = string.Empty
    if self._data.config:Type() == FlexibleMapBuildingType.BehemothDevice then
        local behemoth = ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
        local deviceLv = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel()
        if behemoth and deviceLv then
            self._p_text_behemoth:SetVisible(true)
            self._p_text_behemoth.text = I18N.Get(behemoth:GetRefKMonsterDataConfig(deviceLv):Name())
        end
    end
    if data.serverData and #data.serverData > 0 then
        self._p_status_lock:SetVisible(false)
        self._p_text_constructed:SetVisible(true)
        self._p_btn_view:SetVisible(data.serverData and #data.serverData > 0)
        self._p_text_constructed.text = I18N.GetWithParams("alliance_bj_yijianzao", #data.serverData)
        self._child_comp_btn_b_l:SetVisible(false)
        local first = data.serverData[1]
        self._p_text_position.text = ("X:%d,Y:%d"):format(math.floor(first.Pos.X + 0.5), math.floor(first.Pos.Y + 0.5))
    else
        self._p_status_lock:SetVisible(false)
        self._p_btn_view:SetVisible(false)
        self._p_text_constructed:SetVisible(false)
        self._child_comp_btn_b_l:SetVisible(true)
        UIHelper.SetGray(self._child_comp_btn_b_l.gameObject, not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.BuildBehemothDevice)) 
    end
end

function AllianceTerritoryMainFacilityBehemothCell:OnClickBtnDetail()
    ---@type AllianceBuildingDetailMediatorParameter
    local parameter = {}
    parameter.isUnlocked = ModuleRefer.AllianceTechModule:IsBuildingTechSatisfy(self._data.config) and ModuleRefer.AllianceTechModule:IsBuildingAllianceCenterSatisfy(self._data.config) and ModuleRefer.KingdomConstructionModule:GetBuildingLimitCount(self._data.config) > 0
    parameter.buildingConfig = self._data.config
    parameter.clickRectTrans = self._p_btn_detail:GetComponent(typeof(CS.UnityEngine.RectTransform))
    g_Game.UIManager:Open(UIMediatorNames.AllianceBuildingDetailMediator, parameter)
end

function AllianceTerritoryMainFacilityBehemothCell:OnClickBtnView()
    for _, v in pairs(self._data.serverData) do
        self:GetParentBaseUIMediator():CloseSelf()
        AllianceWarTabHelper.GoToCoord(v.Pos.X, v.Pos.Y)
        return
    end
end

function AllianceTerritoryMainFacilityBehemothCell:OnClickBtnBuild()
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.BuildBehemothDevice) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Alliance_no_permission_toast"))
        return
    end
    local mapBuildings = ModuleRefer.VillageModule:GetAllVillageMapBuildingBrief()
    local allianceCenter = ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillageId()
    local building = allianceCenter and mapBuildings[allianceCenter]
    if not allianceCenter then
        building = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
    end
    local targetPosX = nil
    local targetPosY = nil
    if building then
        targetPosX,targetPosY = building.Pos.X,building.Pos.Y
    else
       local p = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
        targetPosX,targetPosY = p.X,p.Y
    end
    self:GetParentBaseUIMediator():CloseSelf()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.AllianceMainMediator)
    AllianceWarTabHelper.GoToCoord(targetPosX, targetPosY, false, nil, nil, nil, function()
        ---@type KingdomConstructionModeUIMediatorParameter
        local param = {}
        param.chooseTab = 0
        param.chooseType = self._data.config:Type()
        g_Game.UIManager:Open(UIMediatorNames.KingdomConstructionModeUIMediator, param)
    end)
end

return AllianceTerritoryMainFacilityBehemothCell