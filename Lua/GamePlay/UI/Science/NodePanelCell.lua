local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
-- local CastleUnlockTechStageParameter = require("CastleUnlockTechStageParameter")
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local TimerUtility = require('TimerUtility')
local NodePanelCell = class('NodePanelCell',BaseTableViewProCell)

function NodePanelCell:OnCreate()
    self.tableviewproTableContent = self:TableViewPro('p_table_cell')
    self.cellSize = self:BindComponent("", typeof(CS.CellSizeComponent))
    self.goTablePanelContent = self:GameObject('Content')
    self.goPopupNewStage = self:GameObject('p_popup_new_stage')
    --self.btnBase = self:Button('p_btn_base', Delegate.GetOrCreate(self, self.OnBtnBaseClicked))
    self.textHingNew = self:Text('p_text_hing_new', I18N.Get("tech_btn_nextstage"))
end
function NodePanelCell:OnShow()
    g_Game.EventManager:AddListener(EventConst.ON_REFRESH_TECH_STAGE, Delegate.GetOrCreate(self, self.RefreshSingleTech))
end
function NodePanelCell:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_REFRESH_TECH_STAGE, Delegate.GetOrCreate(self, self.RefreshSingleTech))
end

function NodePanelCell:OnFeedData(stageId)
    self.tableviewproTableContent:Clear()
    self.stageId = stageId
    self.maxX = ModuleRefer.ScienceModule:GetStageMaxX(stageId)
    local maxWidth = 0
    for i = 1, self.maxX do
        maxWidth = maxWidth + 1
        self.tableviewproTableContent:AppendData(stageId * 10000 + i)
    end
    local stageCfg = ConfigRefer.CityTechStage:Find(stageId)
    local isLastStage = stageCfg:NextStage() == 0
    if not isLastStage then
        maxWidth = maxWidth + 1
        self.tableviewproTableContent:AppendData(stageId * 10000, 1) --不能传相同table进去，所以先stageId*10000
    end
    self.tableviewproTableContent:RefreshAllShownItem(false)
    local curStageId = ModuleRefer.ScienceModule:GetCurScienceStage()
    if stageId == curStageId + 1 then
        local isShow = ModuleRefer.ScienceModule:IsMeetAllStageConditions(curStageId)
        self.goPopupNewStage:SetActive(isShow)
    else
        self.goPopupNewStage:SetActive(false)
    end
    g_Game.EventManager:TriggerEvent(EventConst.ON_ADD_TECH_STAGE, self.stageId)
    self.goTablePanelContent.transform.sizeDelta = CS.UnityEngine.Vector2(maxWidth * 720 ,self.goTablePanelContent.transform.sizeDelta.y)
end

function NodePanelCell:RefreshSingleTech(researchingId)
    local teachCfg = ConfigRefer.CityTechTypes:Find(researchingId)
    self.tableviewproTableContent:UpdateData(teachCfg:Stage() * 10000 + teachCfg:X())
end

function NodePanelCell:SetDynamicCellRectSize(size)
    self.cellSize.Width = size.x
    self.cellSize.transform.sizeDelta = size
    self.tableviewproTableContent.gameObject.transform.sizeDelta = size
end

function NodePanelCell:OnRecycle()
    g_Game.EventManager:TriggerEvent(EventConst.ON_REMOVE_TECH_STAGE, self.stageId)
end

-- function NodePanelCell:OnBtnBaseClicked()
--     local param = CastleUnlockTechStageParameter.new()
--     param.args.ConfigId = self.stageId
--     param:Send(self.btnBase.transform)
-- end

return NodePanelCell
