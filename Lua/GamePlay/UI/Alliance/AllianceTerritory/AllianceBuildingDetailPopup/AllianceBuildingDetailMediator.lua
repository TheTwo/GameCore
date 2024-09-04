--- scene:scene_league_tips_building_detail

local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local Delegate = require("Delegate")
local Utils = require("Utils")
local EventConst = require("EventConst")
local TipsRectTransformUtils = require("TipsRectTransformUtils")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceBuildingDetailMediatorParameter
---@field buildingConfig FlexibleMapBuildingConfigCell
---@field clickRectTrans CS.UnityEngine.RectTransform
---@field isUnlocked boolean

---@class AllianceBuildingDetailMediator:BaseUIMediator
---@field new fun():AllianceBuildingDetailMediator
---@field super BaseUIMediator
local AllianceBuildingDetailMediator = class('AllianceBuildingDetailMediator', BaseUIMediator)

function AllianceBuildingDetailMediator:OnCreate(param)
    self._p_content = self:Transform("p_content")
    self._p_table_detail = self:TableViewPro("p_table_detail")
    self._p_table_detail_rect = self:RectTransform("p_table_detail")
    self._p_table_detail_layout = self:BindComponent("p_table_detail", typeof(CS.UnityEngine.UI.LayoutElement))
    self._p_icon_arrow_r = self:GameObject("p_icon_arrow_r")
    self._p_icon_arrow_r:SetVisible(false)
    self._p_icon_arrow_l = self:GameObject("p_icon_arrow_l")
    self._p_icon_arrow_l:SetVisible(false)
    self._p_vx_trigger = self:AnimTrigger("p_vx_trigger")
    self._cellHeight = {}
    local prefabArray = self._p_table_detail.cellPrefab
    for i = 0, 4 do
        local cellPrefab = prefabArray[i]
        ---@type CS.CellSizeComponent
        local sizeComp = cellPrefab:GetComponent(typeof(CS.CellSizeComponent))
        self._cellHeight[i] = sizeComp.Height
    end
end

---@param param AllianceBuildingDetailMediatorParameter
function AllianceBuildingDetailMediator:OnOpened(param)
    self._param = param
    self:GenerateTable()
    self._p_vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self:LimitInScreen(param.clickRectTrans)
    self._p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function AllianceBuildingDetailMediator:OnShow(param)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateTick))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function AllianceBuildingDetailMediator:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateTick))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

---@param config FlexibleMapBuildingConfigCell
---@return string
function AllianceBuildingDetailMediator.PreCalculateBuildTimeStr(config)
    local buildValue = config:BuildValue()
    local buildSpeed = config:BuildSpeedValue()
    local buildSpeedTime = config:BuildSpeedTime()
    if buildSpeed > 0 then
        return TimeFormatter.SimpleFormatTimeWithoutZero(buildValue / buildSpeed * buildSpeedTime)
    else
        return "--:--:--"
    end
end

function AllianceBuildingDetailMediator:GenerateTable()
    self._p_table_detail:Clear()
    local buildingConfig = self._param.buildingConfig
    local titleCell = I18N.Get(buildingConfig:Des())
    self._p_table_detail:AppendData(titleCell, 0)
    
    ---@type AllianceBuildingDetailItemCellData
    local infoCell = {}
    infoCell.name = I18N.Get("Alliance_bj_shilizhi")
    infoCell.value = buildingConfig:FactionValue()
    self._p_table_detail:AppendData(infoCell, 1)
    infoCell = {}
    infoCell.name = I18N.Get("alliance_bj_zhandi")
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayout(buildingConfig:Layout())
    infoCell.value = ("%dx%d"):format(layout.SizeX, layout.SizeY)
    self._p_table_detail:AppendData(infoCell, 1)
    infoCell = {}
    infoCell.name = I18N.Get("alliance_bj_jianzaoshijian")
    infoCell.value = AllianceBuildingDetailMediator.PreCalculateBuildTimeStr(buildingConfig)
    self._p_table_detail:AppendData(infoCell, 1)
    infoCell = {}
    infoCell.name = I18N.Get("alliance_bj_naijiudu")
    infoCell.value = tostring(buildingConfig:HP())
    self._p_table_detail:AppendData(infoCell, 1)

    if self._param.isUnlocked then
        local unlockHint = I18N.Get("alliance_bj_quanxian")
        self._p_table_detail:AppendData(unlockHint, 4)
    else
        if buildingConfig:UnlockTechLength() > 0 then
            local unlockHint = I18N.Get("alliance_bj_jiesuotiaojian")
            self._p_table_detail:AppendData(unlockHint, 2)
            for i = 1, buildingConfig:UnlockTechLength() do
                local tech = buildingConfig:UnlockTech(i)
                local techConfig = ConfigRefer.AllianceTechnology:Find(tech)
                if not ModuleRefer.AllianceTechModule:IsTechSatisfy(techConfig) then
                    ---@type AllianceBuildingDetailItemSkillCellData
                    local unlockTechCell = {}
                    unlockTechCell.techConfig = techConfig
                    -- 解锁条件及跳转
                    self._p_table_detail:AppendData(unlockTechCell, 3)
                end
            end
        end
    end
end

---@param clickRectTrans CS.UnityEngine.RectTransform
function AllianceBuildingDetailMediator:LimitInScreen(clickRectTrans)
    self._p_table_detail_layout.preferredHeight = -1
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_table_detail_rect)
    local height = self._p_table_detail.DataSrc:GetContentSize().y + 30
    if height > 540 then
        self._p_table_detail_layout.preferredHeight = 540
        self._p_table_detail_rect:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, 540)
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_table_detail_rect)
    else
        self._p_table_detail_layout.preferredHeight = height
        self._p_table_detail_rect:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, height)
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_table_detail_rect)
    end
    TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(clickRectTrans, self._p_table_detail_rect)
end

function AllianceBuildingDetailMediator:LateUpdateTick()
    if not self._param or Utils.IsNull(self._param.clickRectTrans) then
        return
    end
    self:LimitInScreen(self._param.clickRectTrans)
end

function AllianceBuildingDetailMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

return AllianceBuildingDetailMediator